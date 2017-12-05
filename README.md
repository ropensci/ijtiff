
<!-- README.md is generated from README.Rmd. Please edit that file -->
ijtiff
======

The goal of the `ijtiff` R package is to correctly import TIFF files that were saved from *ImageJ* and to write TIFF files than can be correctly read by *ImageJ*. It may also satisfy some non-*ImageJ* TIFF requirements that you might have. This is not an extension of the original `tiff` package, it behaves differently. Hence, if this package isn't satisfying your TIFF needs, it's definitely worth checking out the original `tiff` package.

[![Travis-CI Build Status](https://travis-ci.org/rorynolan/ijtiff.svg?branch=master)](https://travis-ci.org/rorynolan/ijtiff) [![AppVeyor Build Status](https://ci.appveyor.com/api/projects/status/github/rorynolan/ijtiff?branch=for_appveyor&svg=true)](https://ci.appveyor.com/project/rorynolan/ijtiff) [![codecov](https://codecov.io/gh/rorynolan/ijtiff/branch/master/graph/badge.svg)](https://codecov.io/gh/rorynolan/ijtiff) [![CRAN\_Status\_Badge](http://www.r-pkg.org/badges/version/ijtiff)](https://cran.r-project.org/package=ijtiff) ![RStudio CRAN downloads](http://cranlogs.r-pkg.org/badges/grand-total/ijtiff) ![RStudio CRAN monthly downloads](http://cranlogs.r-pkg.org/badges/ijtiff) [![Rdocumentation](http://www.rdocumentation.org/badges/version/ijtiff)](http://www.rdocumentation.org/packages/ijtiff) ![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](http://www.repostatus.org/badges/latest/active.svg) [![DOI](https://zenodo.org/badge/111798542.svg)](https://zenodo.org/badge/latestdoi/111798542)

Installation
------------

### `libtiff`

`ijtiff` requires you to have the `libtiff` C library installed. To install `libtiff`:

-   On **Mac** you need [Homebrew](https://brew.sh/). Then in the terminal, run `brew install libtiff`.
-   On **Debian Linux**, try `sudo apt-get install libtiff5`, or if that fails, try `sudo apt-get install libtiff4`.
-   On **Fedora Linux**, try `sudo yum install libtiff5`, or if that doesn't work, try `sudo yum install libtiff4`.
-   On **Windows** for most people, no setup is required 😄, but if you experience problems, check out <http://gnuwin32.sourceforge.net/packages/tiff.htm>.

### The `ijtiff` R package

You can install `ijtiff` from github with:

``` r
# install.packages("devtools")
devtools::install_github("rorynolan/ijtiff")
```

Reading *ImageJ* TIFF files
---------------------------

``` r
path_2ch_ij <- system.file("img", "2ch_ij.tif", package = "ijtiff")
```

`path_2ch_ij` is the path to a 2-channel, five-frame image which was saved from *ImageJ*.

### The original `tiff` library

When we import it with the original `tiff` library:

``` r
img <- tiff::readTIFF(path_2ch_ij, all = TRUE)
#> Warning in tiff::readTIFF(path_2ch_ij, all = TRUE): TIFFReadDirectory:
#> Unknown field with tag 50838 (0xc696) encountered
#> Warning in tiff::readTIFF(path_2ch_ij, all = TRUE): TIFFReadDirectory:
#> Unknown field with tag 50839 (0xc697) encountered
str(img)  # 10 images
#> List of 10
#>  $ : num [1:128, 1:128] 0 0 0 0.00392 0 ...
#>  $ : num [1:128, 1:128] 0 0.00392 0.00392 0.00392 0 ...
#>  $ : num [1:128, 1:128] 0.00392 0.00392 0 0 0 ...
#>  $ : num [1:128, 1:128] 0 0 0 0.00392 0 ...
#>  $ : num [1:128, 1:128] 0 0 0.00392 0 0 ...
#>  $ : num [1:128, 1:128] 0 0 0.00392 0 0 ...
#>  $ : num [1:128, 1:128] 0 0.00392 0 0 0 ...
#>  $ : num [1:128, 1:128] 0 0 0 0.00392 0.00392 ...
#>  $ : num [1:128, 1:128] 0 0 0 0 0 ...
#>  $ : num [1:128, 1:128] 0 0 0 0.00392 0 ...
img[[1]][100:110, 101:105]  # print a section of the first image in the series
#>             [,1]       [,2]        [,3]        [,4]        [,5]
#>  [1,] 0.01176471 0.01176471 0.035294118 0.027450980 0.023529412
#>  [2,] 0.02352941 0.02745098 0.015686275 0.027450980 0.035294118
#>  [3,] 0.05490196 0.02352941 0.031372549 0.031372549 0.035294118
#>  [4,] 0.03921569 0.01568627 0.027450980 0.023529412 0.027450980
#>  [5,] 0.04313725 0.04313725 0.031372549 0.015686275 0.015686275
#>  [6,] 0.02352941 0.02352941 0.039215686 0.011764706 0.007843137
#>  [7,] 0.03137255 0.03529412 0.027450980 0.023529412 0.019607843
#>  [8,] 0.01960784 0.03921569 0.019607843 0.015686275 0.031372549
#>  [9,] 0.01568627 0.01960784 0.015686275 0.007843137 0.019607843
#> [10,] 0.05490196 0.04705882 0.019607843 0.035294118 0.023529412
#> [11,] 0.03137255 0.02352941 0.007843137 0.023529412 0.027450980
```

-   We just get 10 frames, with no information about the two channels.
-   We get annoying warnings about ImageJ's private TIFF tags 50838 and 50839, which are of no interest to the `R` user.
-   The numbers in the image array(s) are (by default) normalized to the range \[0, 1\].

### The `ijtiff` library

When we import the same image with the `ijtiff` library:

``` r
img <- ijtiff::read_tif(path_2ch_ij)
#> Reading a 128x128 pixel image of  type with 2 channels and 5 frames.
dim(img)  # 2 channels, 5 frames
#> [1] 128 128   2   5
img[100:110, 101:105, 1, 1]  # print a section of the first channel, first frame
#>       [,1] [,2] [,3] [,4] [,5]
#>  [1,]    3    3    9    7    6
#>  [2,]    6    7    4    7    9
#>  [3,]   14    6    8    8    9
#>  [4,]   10    4    7    6    7
#>  [5,]   11   11    8    4    4
#>  [6,]    6    6   10    3    2
#>  [7,]    8    9    7    6    5
#>  [8,]    5   10    5    4    8
#>  [9,]    4    5    4    2    5
#> [10,]   14   12    5    9    6
#> [11,]    8    6    2    6    7
```

-   We see the image nicely divided into 2 channels of 5 frames.
-   We get no needless warnings.
-   The numbers in the image are integers, the same as would be seen if one opened the image with ImageJ.

#### Note

`tiff` reads several types of TIFFs correctly, including many that are saved from *ImageJ*. This is just an example of a TIFF type that it doesn't perform so well with.

Floating point TIFFs
--------------------

The original `tiff` library could read but not write floating point (real-numbered) TIFF files. The `ijtiff` library can do both. It automatically decides which type is appropriate when writing.

Advice for all *ImageJ* users
-----------------------------

Base *ImageJ* (similar to the `tiff` R package) does not properly open some perfectly TIFF files[1] (including some TIFF files written by the `tiff` and `ijtiff` R packages). Instead it gives you the error message: *imagej can only open 8 and 16 bit/channel images*. These images in fact can be opened in *ImageJ* using the wonderful *BioFormats* plugin. See <https://imagej.net/Bio-Formats>.

Acknowledgement
===============

This package uses a lot of code from the original `tiff` package by Simon Urbanek.

Contribution
============

Contributions to this package are welcome. The preferred method of contribution is through a github pull request. Feel free to contact me by creating an issue. Please note that this project is released with a [Contributor Code of Conduct](CONDUCT.md). By participating in this project you agree to abide by its terms.

[1] I think native *ImageJ* only likes 1, 3 and 4-channel images and complains about the rest, but I'm not sure about this.
