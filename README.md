
<!-- README.md is generated from README.Rmd. Please edit that file -->

# ijtiff <img src="man/figures/logo.png" height="140" align="right">

[![R-CMD-check](https://github.com/ropensci/ijtiff/workflows/R-CMD-check/badge.svg)](https://github.com/ropensci/ijtiff/actions)

[![Project Status: Inactive – The project has reached a stable, usable
state but is no longer being actively developed; support/maintenance
will be provided as time
allows.](https://www.repostatus.org/badges/latest/inactive.svg)](https://www.repostatus.org/#inactive)

[![CRAN_Status_Badge](https://www.r-pkg.org/badges/version/ijtiff)](https://cran.r-project.org/package=ijtiff)
![RStudio CRAN
downloads](https://cranlogs.r-pkg.org/badges/grand-total/ijtiff)
![RStudio CRAN monthly
downloads](https://cranlogs.r-pkg.org/badges/ijtiff)

[![DOI](http://joss.theoj.org/papers/10.21105/joss.00633/status.svg)](https://doi.org/10.21105/joss.00633)

## Introduction

This is a general purpose TIFF I/O utility for R. The [`tiff`
package](https://cran.r-project.org/package=tiff) already exists for
this purpose but `ijtiff` adds some functionality and overcomes some
bugs therein.

- `ijtiff` can write TIFF files whose pixel values are real
  (floating-point) numbers; `tiff` cannot.
- `ijtiff` can read and write *text images*; `tiff` cannot.
- `tiff` struggles to interpret channel information and gives cryptic
  errors when reading TIFF files written by the *ImageJ* software;
  `ijtiff` works smoothly with these images.

To learn about `ijtiff` and how to use it, visit the package website at
<https://docs.ropensci.org/ijtiff/>.

## Installation

### `libtiff`

`ijtiff` requires you to have the `libtiff` C library installed. To
install `libtiff`:

- On **Debian Linux**, try
  `sudo apt-get install libtiff-dev libbz2-dev libdeflate-dev liblzma-dev libwebp-dev libzstd-dev zlib1g-dev`.
- On **Fedora Linux**, try
  `sudo yum install libtiff-devel libbz2-devel libdeflate-devel liblzma-devel libwebp-devel libzstd-devel zlib-devel`.
- On **Mac**, you need [Homebrew](https://brew.sh/). Then in the
  terminal, run `brew install libtiff`.
- On **Windows**, no setup is required.

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
