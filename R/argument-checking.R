#' Get allowed TIFF tag names
#'
#' @return Character vector of allowed tag names (normalized)
#' @noRd
get_allowed_tags <- function() {
  c(
    "xresolution", "yresolution", "resolutionunit", "orientation",
    "xposition", "yposition", "copyright", "artist", "documentname",
    "datetime", "imagedescription", "compression", "bitspersample",
    "photometric"
  )
}

#' Extract tags from image attributes
#'
#' Looks at the attributes of an image and extracts any that correspond
#' to allowed TIFF tags (after normalization).
#'
#' @param img An image array
#' @return Named list of tags extracted from attributes
#' @noRd
get_tags_from_attributes <- function(img) {
  attrs <- attributes(img)

  # Remove standard array attributes that aren't tags
  # Also exclude tags that are stored as strings in attributes but need
  # integers when writing (like resolutionunit and orientation)
  standard_attrs <- c("dim", "dimnames", "class", "names", "tags_by_frame")
  attrs <- attrs[!names(attrs) %in% standard_attrs]

  if (length(attrs) == 0) {
    return(list())
  }

  allowed_tags <- get_allowed_tags()

  # Normalize attribute names and check if they match allowed tags
  normalized_names <- purrr::map_chr(names(attrs), normalize_tag_name)
  # PhotometricInterpretation attribute -> the writable `photometric` tag.
  # This rename must happen BEFORE the allowed-tags filter below, because
  # normalize_tag_name() turns "PhotometricInterpretation" into
  # "photometricinterpretation", which is not itself an allowed tag name.
  normalized_names[normalized_names == "photometricinterpretation"] <- "photometric"

  # Keep only attributes that match allowed tags
  matching_indices <- normalized_names %in% allowed_tags

  if (!any(matching_indices)) {
    return(list())
  }

  # Extract matching attributes with normalized names
  result <- attrs[matching_indices]
  names(result) <- normalized_names[matching_indices]

  # Exclude tags that are stored as human-readable strings in read_tif
  # attributes but need integer codes when writing
  # (resolutionunit comes as "inch"/"cm" but needs 1/2/3,
  #  orientation comes as "top_left" etc. but needs 1-8)
  excluded_tags <- c("resolutionunit", "orientation")
  result <- result[!names(result) %in% excluded_tags]

  # Silently drop an auto-extracted `photometric` whose value this writer
  # cannot produce (Palette/CMYK/YCbCr/CIELab/TransparencyMask/...) so that
  # round-tripping such an image does not hard-error. Only an EXPLICIT
  # `tags_to_write = list(photometric = ...)` with an unwritable value should
  # error (handled in argchk_write_tif).
  if ("photometric" %in% names(result)) {
    pm <- result[["photometric"]]
    writable <- c("whiteiszero", "miniswhite", "blackiszero", "minisblack", "rgb")
    ok <- (is.character(pm) && tolower(pm) %in% writable) ||
      (is.numeric(pm) && pm %in% c(0, 1, 2))
    if (!ok) result[["photometric"]] <- NULL # drop, do not error, on round-trip
  }

  result
}

#' Validate and normalize tags_to_write
#'
#' @param tags_to_write Named list of tags to write
#' @return Named list with canonical tag names
#' @noRd
validate_tags_to_write <- function(tags_to_write) {
  if (is.null(tags_to_write)) {
    return(list())
  }

  checkmate::assert_list(tags_to_write, names = "named")

  allowed_tags <- get_allowed_tags()

  normalized_names <- purrr::map_chr(names(tags_to_write), normalize_tag_name)
  invalid_names <- normalized_names[!normalized_names %in% allowed_tags]

  if (length(invalid_names) > 0) {
    rlang::abort(c(
      "Invalid tag names in `tags_to_write`.",
      x = paste("Invalid tags:", paste(invalid_names, collapse = ", ")),
      i = paste("Allowed tags:", paste(allowed_tags, collapse = ", "))
    ))
  }

  names(tags_to_write) <- normalized_names
  tags_to_write
}

#' Validate a string tag
#' @noRd
validate_string_tag <- function(tags, tag_name) {
  if (!is.null(tags[[tag_name]])) {
    checkmate::assert_string(tags[[tag_name]], null.ok = FALSE)
  }
}

#' Validate a numeric tag with optional bounds
#' @noRd
validate_numeric_tag <- function(tags, tag_name, lower = -Inf) {
  if (!is.null(tags[[tag_name]])) {
    checkmate::assert_numeric(tags[[tag_name]], len = 1, lower = lower,
                              null.ok = FALSE)
  }
}

#' Validate an integer tag with allowed values
#' @noRd
validate_enum_tag <- function(tags, tag_name, allowed_values,
                               tag_label = tag_name) {
  if (!is.null(tags[[tag_name]])) {
    checkmate::assert_integerish(tags[[tag_name]], len = 1,
                                  null.ok = FALSE)
    if (!tags[[tag_name]] %in% allowed_values) {
      rlang::abort(
        c(paste0("If specifying `", tag_label, "`, it must be one of: ",
                 paste(allowed_values, collapse = ", "), "."),
          x = stringr::str_glue("You have used '{tags[[tag_name]]}'.")
        )
      )
    }
  }
}

#' Perform argument checking for [write_tif()].
#'
#' This functions checks whether the arguments to [write_tif()] are OK. Then
#' it modifies them a bit to prepare them for the rest of the [write_tif()]
#' function, returning them as a named list.
#'
#' @inheritParams write_tif
#'
#' @return A named list.
#'
#' @noRd
argchk_write_tif <- function(img, path, bits_per_sample, compression,
                             overwrite, msg, tags_to_write,
                             to_memory = FALSE) {
  if (!to_memory) {
    checkmate::assert_string(path)
    path <- stringr::str_replace_all(path, stringr::coll("\\"), "/") # windows
  }
  checkmate::assert_scalar(bits_per_sample)
  checkmate::assert(
    checkmate::check_string(bits_per_sample),
    checkmate::check_int(bits_per_sample)
  )
  if (isTRUE(checkmate::check_string(bits_per_sample))) {
    if (startsWith("auto", tolower(bits_per_sample))) {
      bits_per_sample <- "auto"
    } else {
      rlang::abort(
        c(
          paste(
            "If `bits_per_sample` is a string, then 'auto' is the only",
            "allowable value."
          ),
          x = stringr::str_glue(
            "You have ",
            "`bits_per_sample = '{bits_per_sample}'`."
          )
        )
      )
    }
  } else {
    if (!bits_per_sample %in% c(8, 16, 32)) {
      rlang::abort(
        c("If specifying `bits_per_sample`, it must be one of 8, 16 or 32.",
          x = stringr::str_glue("You have used '{bits_per_sample}'.")
        )
      )
    }
  }
  checkmate::assert_string(compression)
  checkmate::assert_flag(overwrite)
  if (!to_memory) {
    if (endsWith(tolower(path), ".tiff") || endsWith(tolower(path), ".tif")) {
      path <- paste0(strex::str_before_last_dot(path), ".tif")
    }
    path <- strex::str_give_ext(path, "tif")
    if (file.exists(path) && (!overwrite)) {
      rlang::abort(
        c(
          stringr::str_glue(
            "The file {path}, already exists and `overwrite` ",
            "is set to `FALSE`."
          ),
          x = "To enable overwriting, use `overwrite = TRUE`."
        )
      )
    }
  }
  checkmate::assert_array(img)
  checkmate::assert_array(img, min.d = 2, max.d = 4)
  checkmate::assert_numeric(img)
  img <- ijtiff_img(img)
  compressions <- c(
    none = 1L, RLE = 2L, LZW = 5L, PackBits = 32773L, JPEG = 7L,
    deflate = 8L, Zip = 8L
  )
  compression <- strex::match_arg(compression, names(compressions),
    ignore_case = TRUE
  )
  compression <- compressions[compression]
  checkmate::assert_flag(msg)

  # Extract tags from image attributes
  attr_tags <- get_tags_from_attributes(img)

  # Merge attribute tags with tags_to_write, with tags_to_write taking precedence
  if (length(attr_tags) > 0) {
    if (is.null(tags_to_write)) {
      tags_to_write <- attr_tags
    } else {
      # Add attribute tags that aren't already in tags_to_write
      for (tag_name in names(attr_tags)) {
        if (!tag_name %in% names(tags_to_write)) {
          tags_to_write[[tag_name]] <- attr_tags[[tag_name]]
        }
      }
    }
  }

  # Validate and normalize tags_to_write
  tags_to_write <- validate_tags_to_write(tags_to_write)

  # If bits_per_sample="auto" and tags_to_write has bitspersample, override
  if (bits_per_sample == "auto" && !is.null(tags_to_write$bitspersample)) {
    bits_per_sample <- tags_to_write$bitspersample
    # Validate the override value
    checkmate::assert_scalar(bits_per_sample)
    if (!bits_per_sample %in% c(8, 16, 32)) {
      rlang::abort(
        c("If specifying `bitspersample` in tags_to_write, it must be one of 8, 16 or 32.",
          x = stringr::str_glue("You have used '{bits_per_sample}'.")
        )
      )
    }
    # Remove bitspersample from tags_to_write since it's handled separately
    tags_to_write$bitspersample <- NULL
  }

  # If compression="none" and tags_to_write has compression, override
  if (compression == 1L && !is.null(tags_to_write$compression)) {
    compression_from_tags <- strex::match_arg(
      tags_to_write$compression,
      names(compressions),
      ignore_case = TRUE
    )
    compression <- compressions[compression_from_tags]
    # Remove compression from tags_to_write since it's handled separately
    tags_to_write$compression <- NULL
  }

  # Validate numeric tags
  validate_numeric_tag(tags_to_write, "xresolution", lower = 0)
  validate_numeric_tag(tags_to_write, "yresolution", lower = 0)
  validate_numeric_tag(tags_to_write, "xposition")
  validate_numeric_tag(tags_to_write, "yposition")

  # Validate enum tags
  validate_enum_tag(tags_to_write, "resolutionunit", c(1, 2, 3))
  validate_enum_tag(tags_to_write, "orientation", 1:8)

  # Translate/validate `photometric` (surviving auto-extracted value, or an
  # explicit one from `tags_to_write`) into the integer TIFF photometric
  # code. Auto-extracted values were already filtered to writable ones in
  # get_tags_from_attributes(); an EXPLICIT unwritable value errors here.
  if (!is.null(tags_to_write$photometric)) {
    pm <- tags_to_write$photometric
    codes <- c(
      WhiteIsZero = 0L, MinIsWhite = 0L, BlackIsZero = 1L,
      MinIsBlack = 1L, RGB = 2L
    )
    if (is.character(pm)) {
      if (!tolower(pm) %in% tolower(names(codes))) {
        rlang::abort(c(
          "`photometric` must be one of WhiteIsZero, BlackIsZero, or RGB.",
          x = stringr::str_glue("You supplied '{pm}', which this writer cannot produce.")
        ))
      }
      key <- strex::match_arg(pm, names(codes), ignore_case = TRUE)
      tags_to_write$photometric <- codes[[key]]
    } else {
      checkmate::assert_integerish(pm, len = 1)
      if (!pm %in% c(0L, 1L, 2L)) {
        rlang::abort("`photometric` code must be 0 (WhiteIsZero), 1 (BlackIsZero) or 2 (RGB).")
      }
      tags_to_write$photometric <- as.integer(pm)
    }
    # RGB requires 3 (RGB) or 4 (RGBA) planes -- reject an invalid combination
    # rather than writing a malformed TIFF other readers will refuse.
    if (identical(tags_to_write$photometric, 2L)) {
      n_planes <- if (length(dim(img)) >= 3) dim(img)[3] else 1L
      if (!n_planes %in% c(3L, 4L)) {
        rlang::abort(c(
          "`photometric = \"RGB\"` requires a 3- or 4-channel image.",
          x = stringr::str_glue("Your image has {n_planes} channel(s).")
        ))
      }
    }
  }

  # Validate string tags
  purrr::walk(
    c("copyright", "artist", "documentname", "imagedescription"),
    ~ validate_string_tag(tags_to_write, .x)
  )

  # Check and format datetime if provided
  if (!is.null(tags_to_write$datetime)) {
    # Try to convert to datetime using lubridate
    dt <- tryCatch(
      {
        lubridate::as_datetime(tags_to_write$datetime)
      },
      error = function(e) {
        stop("datetime must be convertible to a valid date-time using lubridate::as_datetime(). ",
          "The final format should be 'YYYY:MM:DD HH:MM:SS'.",
          call. = FALSE
        )
      }
    )

    if (is.na(dt)) {
      stop("datetime must be convertible to a valid date-time using lubridate::as_datetime(). ",
        "The final format should be 'YYYY:MM:DD HH:MM:SS'.",
        call. = FALSE
      )
    }

    # Format to TIFF datetime format "YYYY:MM:DD HH:MM:SS"
    tags_to_write$datetime <- format(dt, "%Y:%m:%d %H:%M:%S")
  }

  if (to_memory) path <- NULL
  list(
    img = img, path = path, bits_per_sample = bits_per_sample,
    compression = compression, overwrite = overwrite, msg = msg,
    tags_to_write = tags_to_write
  )
}
