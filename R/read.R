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
#' are IMAGEDEPTH, BITSPERSAMPLE, SAMPLESPERPIXEL, SAMPLEFORMAT, PLANARCONFIG,
#' COMPRESSION, THRESHHOLDING, XRESOLUTION, YRESOLUTION, RESOLUTIONUNIT, INDEXED
#' and ORIENTATION. More tags should be added in a subsequent version of this
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
  path %<>% prep_path()
  frames %<>% prep_frames()
  withr::local_dir(attr(path, "path_dir"))
  checkmate::assert_logical(msg, max.len = 1)
  checkmate::assert_string(list_safety)
  list_safety %<>% filesstrings::match_arg(c("error", "warning", "none"),
    ignore_case = TRUE
  )
  tags1 <- read_tags(path, frames = 1)[[1]]
  prep <- prep_read(path, frames, tags1, tags = FALSE)
  out <- .Call("read_tif_C", path.expand(path), prep$frames,
    PACKAGE = "ijtiff"
  ) %>% {
    .[prep$back_map]
  }
  checkmate::assert_list(out)
  ds <- dims(out)
  if (filesstrings::all_equal(ds)) {
    d <- ds[[1]]
    attrs1 <- attributes(out[[1]])
    if (colormap_or_ij_channels(out, prep, d)) {
      out %<>% purrr::map(compute_desired_plane)
    }
    out %<>% unlist()
    dim(out) <- c(d[1:2], prep$n_ch, length(out) / prod(c(d[1:2], prep$n_ch)))
    attrs1$dim <- NULL
    do_call_list <- c(list(img = out), attrs1)
    out <- do.call(ijtiff_img, do_call_list)
  }
  if (is.list(out)) {
    if (list_safety == "error") {
      stop("`read_tif()` tried to return a list.")
    } else if (list_safety == "warning") {
      warning("`read_tif()` is returning a list.")
    } else {
      if (msg) {
        message("Reading a list of images with differing dimensions . . .")
      }
    }
  } else if (msg) {
    ints <- attr(out, "sample_format") == "uint"
    bps <- attr(out, "bits_per_sample") %>% {
      dplyr::case_when(
        . == 8 ~ "an 8-bit, ",
        . == 16 ~ "a 16-bit, ",
        . == 32 ~ "a 32-bit, ",
        TRUE ~ "a 0-bit, "
      )
    }
    dim(out) %>% {
      pretty_msg(
        "Reading ", path, ": ", bps, .[1], "x", .[2], " pixel image of ",
        ifelse(ints, "unsigned integer", "floating point"), " type. Reading ",
        .[3], " channel", ifelse(.[3] > 1, "s", ""), " and ", .[4],
        " frame", ifelse(.[4] > 1, "s", ""), " . . ."
      )
    }
  }
  out <- fix_res_unit(out)
  if (msg) pretty_msg("\b Done.")
  out
}

#' @rdname read_tif
#' @export
tif_read <- function(path, frames = "all", list_safety = "error", msg = TRUE) {
  read_tif(path = path, frames = frames, list_safety = list_safety, msg = msg)
}


#' Read TIFF tag information without actually reading the image array.
#'
#' TIFF files contain metadata about images in their _TIFF tags_. This function
#' is for reading this information without reading the actual image.
#'
#' @inheritParams read_tif
#' @param frames Which frames do you want to read tags from. Default first frame
#'   only. To read from the 2nd and 7th frames, use `frames = c(2, 7)`, to read
#'   from all frames, use `frames = "all"`.
#'
#' @return A list of lists.
#'
#' @author Simon Urbanek, Kent Johnson, Rory Nolan.
#'
#' @seealso [read_tif()]
#'
#' @examples
#' read_tags(system.file("img", "Rlogo.tif", package = "ijtiff"))
#' read_tags(system.file("img", "Rlogo-banana.tif", package = "ijtiff"),
#'   frames = c(2, 4)
#' )
#' @export
read_tags <- function(path, frames = 1) {
  frames %<>% prep_frames()
  path %<>% prep_path()
  withr::local_dir(attr(path, "path_dir"))
  if (isTRUE(all.equal(frames, 1,
    check.attributes = FALSE, check.names = FALSE
  ))) {
    return(
      list(frame1 = .Call("read_tags_C", path, 1L, PACKAGE = "ijtiff")[[1]])
    )
  }
  tags1 <- read_tags(path, frames = 1)[[1]]
  prep <- prep_read(path, frames, tags1, tags = TRUE)
  out <- .Call("read_tags_C", path, prep$frames, PACKAGE = "ijtiff") %>%
    .[prep$back_map]
  frame_nums <- prep$frames[prep$back_map]
  if (!is.na(prep$n_slices) && prep$n_dirs != prep$n_slices) {
    frame_nums <- ceiling(frame_nums / prep$n_ch)
  }
  names(out) <- paste0("frame", filesstrings::nice_nums(frame_nums))
  out
}

#' @rdname read_tags
#' @export
tags_read <- function(path, frames = 1) {
  read_tags(path = path, frames = frames)
}
