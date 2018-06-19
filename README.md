
<!-- README.md is generated from README.Rmd. Please edit that file -->

# ijtiff <img src="man/figures/sticker.png" height="200" align="right">

[![Travis-CI Build
Status](https://travis-ci.org/ropensci/ijtiff.svg?branch=master)](https://travis-ci.org/ropensci/ijtiff)
[![AppVeyor Build
Status](https://ci.appveyor.com/api/projects/status/github/ropensci/ijtiff?branch=master&svg=true)](https://ci.appveyor.com/project/ropensci/ijtiff)
[![codecov](https://codecov.io/gh/ropensci/ijtiff/branch/master/graph/badge.svg)](https://codecov.io/gh/ropensci/ijtiff)
[![CRAN\_Status\_Badge](http://www.r-pkg.org/badges/version/ijtiff)](https://cran.r-project.org/package=ijtiff)
![RStudio CRAN
downloads](http://cranlogs.r-pkg.org/badges/grand-total/ijtiff)
![RStudio CRAN monthly
downloads](http://cranlogs.r-pkg.org/badges/ijtiff)
[![Rdocumentation](http://www.rdocumentation.org/badges/version/ijtiff)](http://www.rdocumentation.org/packages/ijtiff)
[![](https://badges.ropensci.org/164_status.svg)](https://github.com/ropensci/onboarding/issues/164)
[![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](http://www.repostatus.org/badges/latest/active.svg)](http://www.repostatus.org/#active)
[![lifecycle](https://img.shields.io/badge/lifecycle-maturing-blue.svg)](https://www.tidyverse.org/lifecycle/#maturing)
[![DOI](http://joss.theoj.org/papers/10.21105/joss.00633/status.svg)](https://doi.org/10.21105/joss.00633)
[![DOI](https://zenodo.org/badge/122435081.svg)](https://zenodo.org/badge/latestdoi/122435081)

## TL;DR

This is a general purpose TIFF I/O utility for R. The `tiff` package
already exists but `ijtiff` is necessary because *ImageJ* sometimes
writes channel information in TIFF files in a peculiar way, meaning that
most ordinary TIFF reading softwares (e.g. `tiff`) don’t read this
channel information correctly. `ijtiff` knows about *ImageJ*’s
peculiarities, so it can be relied upon to read *ImageJ*-written TIFF
files correctly.

## Introduction

The *ImageJ* software (<https://imagej.nih.gov/ij>) is a widely-used
image viewing and processing software, particularly popular in
microscopy and life sciences. It supports the TIFF image format (and
many others). It reads TIFF files perfectly, however it can sometimes
write them in a peculiar way, meaning that when other softwares try to
read TIFF files written by *ImageJ*, mistakes can be made.

The goal of the `ijtiff` R package is to correctly import TIFF files
that were saved from *ImageJ* and to write TIFF files than can be
correctly read by *ImageJ*. It may also satisfy some non-*ImageJ* TIFF
requirements that you might have. This is not an extension of the
original `tiff` package; it behaves differently. Hence, if this package
isn’t satisfying your TIFF needs, it’s definitely worth checking out the
original `tiff` package.

#### Frames and Channels in TIFF files

  - In a volumetric image, *frames* are typically the different
    z-slices. In a time-stack of images (i.e. a video), each frame
    represents a time-point.
  - There is one *channel* per colour. A conventional colour image is
    made up of 3 colour channels: red, green and blue. A grayscale
    (black and white) image has just one channel. It’s possible to
    acquire two channels (e.g. red an blue but not green), five channels
    (e.g. infrared, red, green, blue and ultraviolet), or any number at
    all, but these cases are seen mostly in specialist imaging fields
    like microscopy.

#### The Peculiarity of *ImageJ* TIFF files

*Note*: If you don’t care about the particulars of TIFF files or how
this package works on the inside, feel free to skip this subsection.

It is common to use `TIFFTAG_SAMPLESPERPIXEL` to record the number of
channels in a TIFF image, however *ImageJ* sometimes leaves
`TIFFTAG_SAMPLESPERPIXEL` with a value of 1 and instead encodes the
number of channels in `TIFFTAG_IMAGEDESCRIPTION` which might look
something like `"ImageJ=1.51 images=16 channels=2 slices=8"`.

A conventional TIFF reader would miss this channel information (becaus
it is in an unusual place). `ijtiff` does not miss it. We’ll see an
example below.

*Note*: These peculiar *ImageJ*-written TIFF files are still bona fide
TIFF files according to the TIFF specification. They just break with
common conventions of encoding channel information.

## Installation

### `libtiff`

`ijtiff` requires you to have the `libtiff` C library installed. To
install `libtiff`:

  - On **Debian Linux**, try `sudo apt-get install libtiff5-dev`, or if
    that fails, try  
    `sudo apt-get install libtiff4-dev`.
  - On **Fedora Linux**, try `sudo yum install libtiff5-dev`, or if that
    doesn’t work, try  
    `sudo yum install libtiff4-dev`.
  - On **Mac**, you need [Homebrew](https://brew.sh/). Then in the
    terminal, run `brew install libtiff`.
  - On 64-bit **Windows**, no setup is required 😄. If you have 32-bit
    windows, you need to install `libtiff` from
    <http://gnuwin32.sourceforge.net/packages/tiff.htm>.

### Installing the release version of the `ijtiff` R package

You can install `ijtiff` from CRAN (recommended) with:

``` r
install.packages("ijtiff")
```

### Installing the development version of the `ijtiff` R package

You can install the development version from GitHub with:

``` r
if (!require(devtools)) install.packages("devtools")
devtools::install_github("rorynolan/ijtiff")
```

## Reading *ImageJ* TIFF files

``` r
path_2ch_ij <- system.file("img", "Rlogo-banana-red_green.tif", 
                           package = "ijtiff")
```

`path_2ch_ij` is the path to a TIFF file which was made in *ImageJ* from
the R logo dancing banana GIF used in the README of Jeroen Ooms’
`magick` package. The TIFF is a time-stack containing only the red and
green channels of the first, third and fifth frames of the original GIF.
Here’s the full gif:

![](inst/img/Rlogo-banana.gif)

Here are the red and green channels of the first, third and fifth frames
of the TIFF:

![](man/figures/red-and-green-banana-1.png)<!-- -->

### The original `tiff` package

When we import it with the original `tiff` package:

``` r
img <- tiff::readTIFF(path_2ch_ij, all = TRUE)
#> Warning in tiff::readTIFF(path_2ch_ij, all = TRUE): TIFFReadDirectory:
#> Unknown field with tag 50838 (0xc696) encountered
#> Warning in tiff::readTIFF(path_2ch_ij, all = TRUE): TIFFReadDirectory:
#> Unknown field with tag 50839 (0xc697) encountered
str(img)  # 10 images
#> List of 6
#>  $ : num [1:155, 1:200] 1 1 1 1 1 1 1 1 1 1 ...
#>  $ : num [1:155, 1:200] 1 1 1 1 1 1 1 1 1 1 ...
#>  $ : num [1:155, 1:200] 1 1 1 1 1 1 1 1 1 1 ...
#>  $ : num [1:155, 1:200] 1 1 1 1 1 1 1 1 1 1 ...
#>  $ : num [1:155, 1:200] 1 1 1 1 1 1 1 1 1 1 ...
#>  $ : num [1:155, 1:200] 1 1 1 1 1 1 1 1 1 1 ...
img[[1]][100:110, 50:60]  # print a section of the first image in the series
#>            [,1]      [,2]      [,3]      [,4]      [,5]      [,6]
#>  [1,] 0.6627451 0.6627451 0.6549020 0.6627451 0.7058824 0.9215686
#>  [2,] 0.6745098 0.6431373 0.6745098 0.6431373 0.6431373 0.6745098
#>  [3,] 0.6549020 0.6627451 0.6431373 0.6627451 0.6627451 0.6431373
#>  [4,] 0.6431373 0.6431373 0.6627451 0.6431373 0.6627451 0.6431373
#>  [5,] 0.6745098 0.6745098 0.6431373 0.6627451 0.6431373 0.6627451
#>  [6,] 0.6745098 0.6431373 0.6431373 0.6431373 0.6549020 0.6549020
#>  [7,] 0.6549020 0.6549020 0.6431373 0.6549020 0.6549020 0.6431373
#>  [8,] 0.6431373 0.6549020 0.6431373 0.6549020 0.6431373 0.6431373
#>  [9,] 0.6431373 0.6745098 0.6431373 0.6431373 0.6431373 0.6549020
#> [10,] 0.6431373 0.6549020 0.6431373 0.6549020 0.6431373 0.6431373
#> [11,] 0.6431373 0.6431373 0.6431373 0.6431373 0.6431373 0.6431373
#>            [,7]      [,8]      [,9]     [,10]     [,11]
#>  [1,] 1.0000000 1.0000000 1.0000000 1.0000000 1.0000000
#>  [2,] 0.8705882 1.0000000 1.0000000 1.0000000 1.0000000
#>  [3,] 0.6627451 0.7803922 1.0000000 1.0000000 1.0000000
#>  [4,] 0.6627451 0.6431373 0.7058824 0.9058824 1.0000000
#>  [5,] 0.6431373 0.6627451 0.6431373 0.6431373 0.8039216
#>  [6,] 0.6549020 0.6431373 0.6431373 0.6549020 0.6431373
#>  [7,] 0.6431373 0.6549020 0.6431373 0.6431373 0.6431373
#>  [8,] 0.6549020 0.6431373 0.6549020 0.6431373 0.6431373
#>  [9,] 0.6431373 0.6431373 0.6431373 0.6431373 0.6431373
#> [10,] 0.6431373 0.6431373 0.6431373 0.6431373 0.6431373
#> [11,] 0.6549020 0.6431373 0.6431373 0.6431373 0.6431373
```

  - We just get a list of 6 frames, with no information about the
    channels.
  - We get annoying warnings about ImageJ’s private TIFF tags 50838 and
    50839, which are of no interest to the `R` user.
  - The numbers in the image array(s) are (by default) normalized to the
    range \[0, 1\].

### The `ijtiff` package

When we import the same image with the `ijtiff` package:

``` r
img <- ijtiff::read_tif(path_2ch_ij)
#> Reading Rlogo-banana-red_green.tif: an 8-bit, 155x200 pixel image of unsigned integer type with 2 channels and 3 frames . . .
#>  Done.
dim(img)  # 2 channels, 3 frames
#> [1] 155 200   2   3
img[100:110, 50:60, 1, 1]  # print a section of the first channel, first frame
#>       [,1] [,2] [,3] [,4] [,5] [,6] [,7] [,8] [,9] [,10] [,11]
#>  [1,]  169  169  167  169  180  235  255  255  255   255   255
#>  [2,]  172  164  172  164  164  172  222  255  255   255   255
#>  [3,]  167  169  164  169  169  164  169  199  255   255   255
#>  [4,]  164  164  169  164  169  164  169  164  180   231   255
#>  [5,]  172  172  164  169  164  169  164  169  164   164   205
#>  [6,]  172  164  164  164  167  167  167  164  164   167   164
#>  [7,]  167  167  164  167  167  164  164  167  164   164   164
#>  [8,]  164  167  164  167  164  164  167  164  167   164   164
#>  [9,]  164  172  164  164  164  167  164  164  164   164   164
#> [10,]  164  167  164  167  164  164  164  164  164   164   164
#> [11,]  164  164  164  164  164  164  167  164  164   164   164
```

  - We see the image nicely represented as an array of channels of
    frames.
  - We get no needless warnings.
  - The numbers in the image are integers, the same as would be seen if
    one opened the image with ImageJ.

#### Note

The original `tiff` package reads several types of TIFFs correctly,
including many that are saved from *ImageJ*. This is just an example of
a TIFF type that it doesn’t perform so well with.

## Floating point TIFFs

The original `tiff` package could read but not write floating point
(real-numbered) TIFF files. The `ijtiff` package can do both. It
automatically decides which type is appropriate when writing.

## Advice for all *ImageJ* users

Base *ImageJ* (similar to the `tiff` R package) does not properly open
some perfectly good TIFF files\[1\] (including some TIFF files written
by the `tiff` and `ijtiff` R packages). Instead it gives you the error
message: *imagej can only open 8 and 16 bit/channel images*. These
images in fact can be opened in *ImageJ* using the wonderful
*BioFormats* plugin. See <https://imagej.net/Bio-Formats>.

## Text Images

TIFF files are limited in which numbers they can represent (they can’t
go outside the 32-bit range). Real-numbered TIFFs can also lack
precision, having only the precision of a 32-bit floating point number.
If TIFF isn’t good enough, you can use text images. Text images are just
plain text files which are tab-separated arrays of pixel values\[2\].
Hence, they are unconstrained in the precision they can offer (but are
very inefficient with memory).

``` r
library(ijtiff)
img[1] <- 2 ^ 99  # too high for TIFF
write_tif(img, "img")  # errors
#> Error in write_tif(img, "img"): The maximum value in 'img' is greater than 2 ^ 32 - 1 and therefore too high to be written to a TIFF file.
write_txt_img(img, "img")  # no problem
```

## Writing TIFF Files with `ijtiff`

`ijtiff::write_tif()` writes TIFF files in the conventional manner, with
the number of channels in `TIFFTAG_SAMPLESPERPIXEL`. It records in
`TIFFTAG_SOFTWARE` that the TIFF file was written with the `ijtiff` R
package. Otherwise, no metadata is recorded.

## Acknowledgement

This package uses a lot of code from the original `tiff` package by
Simon Urbanek.

## Advice for Package Authors

If you’re authoring a package which is to depend on `ijtiff` and you’re
using AppVeyor, be sure to force AppVeyor to use 64-bit architecture.
This avoids some peculiarities of 32-bit AppVeyor which cause `ijtiff`
installations to fail. You can see how to do this in the
[appveyor.yml](appveyor.yml) file in this repository.

## Contribution

Contributions to this package are welcome. The preferred method of
contribution is through a github pull request. Feel free to contact me
by creating an issue. Please note that this project is released with a
[Contributor Code of Conduct](CONDUCT.md). By participating in this
project you agree to abide by its
terms.

[![ropensci\_footer](https://ropensci.org/public_images/ropensci_footer.png)](https://ropensci.org)

1.  I think native *ImageJ* only likes 1, 3 and 4-channel images and
    complains about the rest, but I’m not sure about this.

2.  `read_txt_img()` and `write_txt_img()` are just wrappers of
    `readr::read_tsv()` and `readr::write_tsv()`.
