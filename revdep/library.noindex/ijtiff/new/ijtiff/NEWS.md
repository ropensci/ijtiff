# `ijtiff` 2.0.0

## BREAKING CHANGES
* `get_tiff_tags_reference()` is now `tif_tags_reference()`.
* `count_imgs()` is now `count_frames()`.

## NEW FEATURES
* It is now possible to read only certain frames of a TIFF image thanks to the `frames` argument of `read_tif()`.
* `read_tif()` and `read_tags()` now have the aliases `tif_read()` and `tags_read()` to comply with the rOpenSci `objevt_verb()` style.


# `ijtiff` 1.5.1

## BUG FIXES
* Require necessary version of `glue`.
* Fix dimension-related bug in `as_EBImage()`.
* Require latest (less-buggy) `filesstrings`.


# `ijtiff` 1.5.0

## NEW FEATURES
* Allow ZIP compression (which seems to be the best).

## BUG FIXES
* `write_txt_img()` was using decimal points for integers (e.g. 3.000 instead of just 3).


# `ijtiff` 1.4.2

## BUG FIXES
* Hacky fix for `configure` script to deal with lack of `-ljbig` on Solaris.
* Trim the package to below 5MB by compressing a few TIFF files.


# `ijtiff` 1.4.1

## NEW FEATURES
* The package is now lighter in appearance because it doesn't explicitly depend on `tibble`.

## BUG FIXES
* The configure script now allows for needing `--static` with `pkg-config`.


# `ijtiff` 1.4.0

## NEW FEATURES
* A `pkgdown` website.

## MINOR IMPROVEMENTS
* Better vignettes.
* Better error messages.


# `ijtiff` 1.3.0

## NEW FEATURES
* Conversion functions `linescan_to_stack()` and `stack_to_linescan()` useful for FCS data.


# `ijtiff` 1.2.0

## MINOR IMPROVEMENTS
* Improved the description of the package in DESCRIPTION, vignette and README.
* Added a hex sticker.
* Limited support for tiled images thanks to new author Kent Johnson.
* `write_tif()` is now slightly (<10%) faster.
* `write_tif()` messages are now more informative.


# `ijtiff` 1.1.0 

## NEW FEATURES
* `count_imgs()` counts the number of images in a TIFF file without reading the images themselves.
* `read_tags()` reads the tags from TIFF images without reading the images themselves.

## MINOR IMPROVEMENTS
* Now includes citation information.
* C code is more readable.
* `display()` is more flexible, accepting 3 and 4-dimensional arrays, just displaying the first frame from the first channel.


## `ijtiff` 1.0.0

#### PEER REVIEW
* The package is now peer reviewed by ROpenSci.


## `ijtiff` 0.3.0

#### MINOR IMPROVEMENTS
* Improve README and vignette with more tangible and fun example.

#### BUG FIXES
* Fix windows `libtiff` issues (thanks to Jeroen Ooms).
* Found some ImageJ-written TIFFs that weren't being read correctly and fixed that.
* Fix `protection stack overflow` error for TIFFs with many images.


## `ijtiff` 0.2.0
* First CRAN release.

#### MINOR IMPROVEMENTS
* Include handy shortcuts for 2- and 3-dimensional arrays.
* Messasges to inform the user about what kind of image is being read/written.


## `ijtiff` 0.1.0

* First github release.
