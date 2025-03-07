#' Read an image stored in the TIFF format
#'
#' Reads an image from a TIFF file/content into a numeric array or list.
#'
#' TIFF files have the capability to store multiple images, each having multiple
#' channels. Typically, these multiple images represent the sequential frames in
#' a time-stack or z-stack of images and hence each of these images has the same
#' dimension. If this is the case, they are all read into a single 4-dimensional
#' array `img` where `img` is indexed as `img[y, x, channel, frame]` (where we
#' have `y, x` to comply with the conventional `row, col` indexing of a matrix -
#' it means that images displayed as arrays of numbers in the R console will
#' have the correct orientation). However, it is possible that the images in the
#' TIFF file have varying dimensions (most people have never seen this), in
#' which case they are read in as a list of images, where again each element of
#' the list is a 4-dimensional array `img`, indexed as `img[y, x, channel,
#' frame]`.
#'
#' A (somewhat random) set of TIFF tags are attributed to the read image. These
#' are ImageDepth, BitsPerSample, SamplesPerPixel, SampleFormat, PlanarConfig,
#' Compression, Threshholding, XResolution, YResolution, ResolutionUnit, Indexed
#' and Orientation. More tags should be added in a subsequent version of this
#' package. You can read about TIFF tags at
#' https://www.awaresystems.be/imaging/tiff/tifftags.html.
#'
#' TIFF images can have a wide range of internal representations, but only the
#' most common in image processing are supported (8-bit, 16-bit and 32-bit
#' integer and 32-bit float samples).
#'
#' @param path A string. The path to the tiff file to read.
#' @param frames Which frames do you want to read. Default all. To read the 2nd
#'   and 7th frames, use `frames = c(2, 7)`.
#' @param list_safety A string. This is for type safety of this function. Since
#'   returning a list is unlikely and probably unexpected, the default is to
#'   error. You can instead opt to throw a warning (`list_safety = "warning"`)
#'   or to just return the list quietly (`list_safety = "none"`).
#' @param msg Print an informative message about the image being read?
#'
#' @return An object of class [ijtiff_img] or a list of [ijtiff_img]s.
#'
#' @note \itemize{ \item 12-bit TIFFs are not supported. \item There is no
#'   standard for packing order for TIFFs beyond 8-bit so we assume big-endian
#'   packing}.
#'
#' @author Simon Urbanek wrote most of this code for the 'tiff' package. Rory
#'   Nolan lifted it from there and changed it around a bit for this 'ijtiff'
#'   package. Credit should be directed towards Lord Urbanek.
#'
#' @seealso [write_tif()]
#'
#' @examples
#' img <- read_tif(system.file("img", "Rlogo.tif", package = "ijtiff"))
#' @export
read_tif <- function(path, frames = "all", list_safety = "error", msg = TRUE) {
  path <- fs::path_expand(path)
  frames <- prep_frames(frames)
  checkmate::assert_logical(msg, max.len = 1)
  checkmate::assert_string(list_safety)
  list_safety <- strex::match_arg(list_safety,
    c("error", "warning", "none"),
    ignore_case = TRUE
  )
  if (msg) message("Reading image from ", path)
  # First read tags from frame 1 to get initial metadata
  tags1 <- translate_tiff_tags(
    .Call("read_tags_C", path, 1L, PACKAGE = "ijtiff")[[1]]
  )
  # Now prepare the read operation with the initial tags
  img_prep <- prep_read(path, frames, tags1, tags = FALSE)
  tags <- .Call("read_tags_C", path, img_prep$frames,
    PACKAGE = "ijtiff"
  )[img_prep$back_map]
  tags <- purrr::map(tags, translate_tiff_tags)
  # Read the image data
  out <- .Call("read_tif_C", path, img_prep$frames,
    PACKAGE = "ijtiff"
  )[img_prep$back_map]
  for (i in seq_along(out)) {
    for (tag_name in names(tags[[i]])) {
      attr(out[[i]], tag_name) <- tags[[i]][[tag_name]]
    }
  }
  ds <- dims(out)
  if (dplyr::n_distinct(ds) == 1) {
    d <- ds[[1]]
    if (colormap_or_ij_channels(out, img_prep, d)) {
      out <- purrr::map(out, compute_desired_plane)
    }
    out <- unlist(out)
    dim(out) <- c(
      d[1:2],
      img_prep$n_ch,
      length(out) / prod(c(d[1:2], img_prep$n_ch))
    )
    attrs1 <- attributes(out[[1]])
    attrs1$dim <- NULL
    out <- do.call(ijtiff_img, c(list(img = out), attrs1))
    for (tag_name in names(tags1)) {
      if (is.null(attr(out, tag_name))) {
        attr(out, tag_name) <- tags1[[tag_name]]
      }
    }
  }
  if (is.list(out)) {
    if (list_safety == "error") {
      stop("`read_tif()` tried to return a list.")
    } else if (list_safety == "warning") {
      warning("`read_tif()` is returning a list.")
    } else if (msg) {
      message("Reading a list of images with differing dimensions . . .")
    }
  } else if (msg) {
    ints <- attr(out, "SampleFormat") %in% c("uint", "uint8", "int")
    bps <- attr(out, "BitsPerSample") %>%
      {
        dplyr::case_when(
          . == 8 ~ "an 8-bit, ",
          . == 16 ~ "a 16-bit, ",
          . == 32 ~ "a 32-bit, ",
          TRUE ~ paste0("a ", ., "-bit, ")
        )
      }
    type <- if (ints) "integer" else "float"
    message(
      stringr::str_glue(
        "Reading {bps}{type} image with dimensions {paste(dim(out), collapse = 'x')} ",
        "(y,x,channel,frame) . . ."
      )
    )
  }
  tags_prep <- prep_read(path, frames, tags1, tags = TRUE)
  tags_by_frame <- read_tags(path, frames)
  attr(out, "tags_by_frame") <- tags_by_frame
  out
}

#' @rdname read_tif
#' @export
tif_read <- function(path, frames = "all", list_safety = "error", msg = TRUE) {
  read_tif(path = path, frames = frames, list_safety = list_safety, msg = msg)
}

# Helper function to map a tag value using the mappings
#'
#' @param tag_name Name of the tag to map
#' @param value Value of the tag to map
#' @param mappings List of tag mappings
#'
#' @return Mapped value of the tag, or the original value if no mapping is
#' found.
#'
#' @noRd
map_tag_value <- function(tag_name, value, mappings) {
  if (is.null(value)) {
    return(NULL)
  }
  value_str <- as.character(value)
  mapping <- mappings[[tag_name]]
  if (!is.null(mapping) && value_str %in% names(mapping)) {
    return(mapping[[value_str]])
  }
  warning("Unknown ", tag_name, " value: ", value_str)
  value
}

#' Helper function to map TIFF tags to human-readable strings
#'
#' @param tags List of TIFF tags to map
#'
#' @return List of mapped TIFF tags
#'
#' @noRd
translate_tiff_tags <- function(tags) {
  # Load tag mappings from JSON
  json_path <- system.file("extdata", "tiff-tag-conversions.json",
    package = "ijtiff"
  )
  mappings <- jsonlite::fromJSON(json_path)
  # Map all tags that have mappings defined in the JSON
  for (tag_name in names(mappings)) {
    if (!is.null(tags[[tag_name]])) {
      tags[[tag_name]] <- map_tag_value(tag_name, tags[[tag_name]], mappings)
    }
  }
  tags
}

#' Read TIFF tag information without actually reading the image array.
#'
#' TIFF files contain metadata about images in their _TIFF tags_. This function
#' is for reading this information without reading the actual image.
#'
#' @param path A string. The path to the tiff file to read.
#' @param frames Which frames do you want to read. Default all. To read the 2nd
#'   and 7th frames, use `frames = c(2, 7)`.
#' @param translate_tags Logical. Should the TIFF tags be translated to
#'   human-readable strings? E.g. `Compression = 1` becomes
#'   `Compression = "none"`.
#'
#' @return A list of lists.
#'
#' @author Simon Urbanek, Kent Johnson, Rory Nolan.
#'
#' @seealso [read_tif()]
#'
#' @examples
#' read_tags(system.file("img", "Rlogo.tif", package = "ijtiff"))
#' @export
read_tags <- function(path, frames = "all", translate_tags = TRUE) {
  path <- fs::path_expand(path)
  frames <- prep_frames(frames)
  # First read tags from frame 1 to get initial metadata
  tags1 <- .Call("read_tags_C", path, 1L, PACKAGE = "ijtiff")[[1]]
  # Now prepare the read operation with the initial tags
  prep <- prep_read(path, frames, tags1, tags = TRUE)
  # Read tags for all requested frames
  out <- .Call("read_tags_C", path, prep$frames,
    PACKAGE = "ijtiff"
  ) %>%
    {
      .[prep$back_map]
    }
  # Apply mappings to each frame's tags
  if (translate_tags) out <- purrr::map(out, translate_tiff_tags)
  # Name the frames
  frame_nums <- prep$frames[prep$back_map]
  if (!is.na(prep$n_slices) && prep$n_dirs != prep$n_slices) {
    frame_nums <- ceiling(frame_nums / prep$n_ch)
  }
  names(out) <- paste0("frame", strex::str_alphord_nums(frame_nums))
  out
}

#' @rdname read_tags
#' @export
tags_read <- function(path, frames = 1) {
  read_tags(path = path, frames = frames)
}
