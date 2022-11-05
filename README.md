
<!-- README.md is generated from README.Rmd. Please edit that file -->

# ijtiff <img src="man/figures/logo.png" height="140" align="right">

[![R-CMD-check](https://github.com/ropensci/ijtiff/workflows/R-CMD-check/badge.svg)](https://github.com/ropensci/ijtiff/actions)
[![codecov](https://app.codecov.io/gh/ropensci/ijtiff/branch/master/graph/badge.svg?token=rNNRw2FU0F)](https://app.codecov.io/gh/ropensci/ijtiff)

[![CRAN_Status_Badge](http://www.r-pkg.org/badges/version/ijtiff)](https://cran.r-project.org/package=ijtiff)
![RStudio CRAN
downloads](http://cranlogs.r-pkg.org/badges/grand-total/ijtiff)
![RStudio CRAN monthly
downloads](http://cranlogs.r-pkg.org/badges/ijtiff)

[![Project Status: Active – The project has reached a stable, usable
state and is being actively
developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/)
[![lifecycle](https://img.shields.io/badge/lifecycle-maturing-blue.svg)](https://lifecycle.r-lib.org/articles/stages.html)

[![DOI](http://joss.theoj.org/papers/10.21105/joss.00633/status.svg)](https://doi.org/10.21105/joss.00633)

## Introduction

This is a general purpose TIFF I/O utility for R. The [`tiff`
package](https://cran.r-project.org/package=tiff) already exists for
this purpose but `ijtiff` adds some functionality and overcomes some
bugs therein.

-   `ijtiff` can write TIFF files whose pixel values are real
    (floating-point) numbers; `tiff` cannot.
-   `ijtiff` can read and write *text images*; `tiff` cannot.
-   `tiff` struggles to interpret channel information and gives cryptic
    errors when reading TIFF files written by the *ImageJ* software;
    `ijtiff` works smoothly with these images.

To learn about `ijtiff` and how to use it, visit the package website at
<https://docs.ropensci.org/ijtiff/>.

## Installation

### `libtiff`

`ijtiff` requires you to have the `libtiff` C library installed. To
install `libtiff`:

-   On **Debian Linux**, try `sudo apt-get install libtiff5-dev`, or if
    that fails, try  
    `sudo apt-get install libtiff4-dev`.
-   On **Fedora Linux**, try `sudo yum install libtiff5-dev`, or if that
    doesn’t work, try  
    `sudo yum install libtiff4-dev`.
-   On **Mac**, you need [Homebrew](https://brew.sh/). Then in the
    terminal, run `brew install libtiff`.
-   On **Windows**, no setup is required.

### Installing the release version of the `ijtiff` R package

You can install `ijtiff` from CRAN (recommended) with:

``` r
install.packages("ijtiff")
```

### Installing the development version of the `ijtiff` R package

You can install the development version from GitHub with:

``` r
devtools::install_github("ropensci/ijtiff")
```

## Acknowledgement

This package uses a lot of code from the original `tiff` package by
Simon Urbanek.

## Contribution

Contributions to this package are welcome. The preferred method of
contribution is through a github pull request. Feel free to contact me
by creating an issue. Please note that this project is released with a
[Contributor Code of
Conduct](https://github.com/ropensci/ijtiff/blob/master/CONDUCT.md). By
participating in this project you agree to abide by its terms.

[![ropensci_footer](https://ropensci.org/public_images/ropensci_footer.png)](https://ropensci.org)
