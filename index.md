
<!-- README.md is generated from README.Rmd. Please edit that file -->

# ijtiff <img src="man/figures/logo.png" align="right" height=140/>

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

The github repo of `ijtiff` is at <https://github.com/ropensci/ijtiff>.

## Installation

You can install the released version of `ijtiff` from
[CRAN](https://CRAN.R-project.org/package=ijtiff) with:

``` r
install.packages("ijtiff")
```

You can install the released version of `ijtiff` from
[GitHub](https://github.com/ropensci/ijtiff) with:

``` r
devtools::install_github("ropensci/ijtiff")
```

## How to use `ijtiff`

The [Reading and Writing
Images](https://ropensci.github.io/ijtiff/articles/reading-and-writing-images.html)
article is probably all you need to know.

## More about `ijtiff`

  - [Text
    Images](https://ropensci.github.io/ijtiff/articles/text-images.html)
    tells you more about what *text images* are and why you might ever
    use them.
  - [The *ImageJ*
    Problem](https://ropensci.github.io/ijtiff/articles/the-imagej-problem.html)
    explains the problem that `tiff` has when reading TIFF files written
    by *ImageJ* and how `ijtiff` fixes this problem.
