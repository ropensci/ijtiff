---
title: '`ijtiff`: An R package for TIFF I/O for ImageJ users'
tags:
  - R
  - file
  - string
authors:
  - name: Rory Nolan
    orcid: 0000-0002-5239-4043
    affiliation: 1
  - name: Sergi Padilla-Parra
    orcid: 0000-0002-8010-9481
    affiliation: 1, 2
affiliations:
  - name: Wellcome Centre Human Genetics, University of Oxford
    index: 1
  - name: Department of Structural Biology, University of Oxford
    index: 2
date: 24 November 2017
bibliography: paper.bib
nocite: | 
  @R, @RStudio, @checkmate, @RSAGA, @magrittr, @filesstrings, @stringr, @purrr, @dplyr, @Rcpp, @fields, @grDevices, @knitr, @testthat, @rmarkdown, @covr, @devtools, @exampletestr, @ImageJ, @BioFormats
---

# Summary
_ImageJ_ is the image viewing and processing GUI of choice for most people in the fields of biology and microscopy. It is free and open-source. `ijtiff` is an R package which can correctly import TIFF files that were saved from _ImageJ_ and to write TIFF files than can be correctly read by _ImageJ_. Due to the sometimes strange way that _ImageJ_ writes files, the original R `tiff` package [@tiff] does not recognise their channel structure. `ijtiff` facilitates writing floating point (real-numbered) TIFF files from R. `ijtiff` reads TIFF pixel values in their native (usually integer) form, whereas `tiff` scales pixel values to the range [0, 1] by default. Hence and for other reasons, `ijtiff` should be viewed as a package with different capabilities and behaviours to the original `tiff` package, and not an extension thereof. TIFF files are not always enough: they have maximum allowed values and their 32-bit floating point real-number representation can lack precision. For these extreme cases, `ijtiff` also supports text image I/O. Text images have no such limitations and are completely compatible with _ImageJ_. 

# References