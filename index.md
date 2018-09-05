
<!-- README.md is generated from README.Rmd. Please edit that file -->

# ijtiff <img src="man/figures/logo.png" align="right" height=140/>

This is a general purpose TIFF I/O utility for R. The [`tiff`
package](https://cran.r-project.org/package=tiff) already exists but
`ijtiff` adds some functionality and overcomes some bugs therein.

  - `ijtiff` can write TIFF files whose pixel values are real
    (floating-point) numbers; `tiff` cannot.
  - `ijtiff` can read and write *text images*; `tiff` cannot.
  - `tiff` struggles to interpret channel information and gives cryptic
    errors when reading TIFF files written by the *ImageJ* software;
    `ijtiff` works smoothly with these images.

The github repo of `ijtiff` is at <https://github.com/ropensci/ijtiff>.

## Installation

You can install the released version of strex from
[CRAN](https://CRAN.R-project.org) with:

``` r
install.packages("strex")
```

You can install the released version of strex from
[CRAN](https://CRAN.R-project.org) with:

``` r
devtools::install_github("rorynolan/strex")
```

## How to use the package

The following articles contain all you need to get going:

  - [Alphordering
    Numbers](https://rorynolan.github.io/strex/articles/alphordering-numbers.html)
    tells you how to fix the pesky problem of numbers in file names not
    complying with alphabetical order.
  - [Argument
    Matching](https://rorynolan.github.io/strex/articles/argument-matching.html)
    showcases `strex::match_arg()`, an improvement on
    `base::match.arg()` which allows one to ignore case during argument
    matching.
  - [Before and
    After](https://rorynolan.github.io/strex/articles/before-and-after.html)
    is for the common problem where you want to get the bit of a string
    before or after an occurrence of a pattern.
  - [Numbers Within
    Strings](https://rorynolan.github.io/strex/articles/numbers-in-strings.html)
    shows how to deal with the common problem of extracting numeric
    information contained within larger strings.
  - [Important
    Miscellany](https://rorynolan.github.io/strex/articles/important-miscellany.html)
    is the rest, and there’s a lot.
