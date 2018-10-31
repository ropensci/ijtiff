


### Test environments


* local OS X install, R 3.5.1
* ubuntu 14.04 (on travis-ci), R 3.5.1
* Windows Server 2012 (on AppVeyor), R 3.5.1
* win-builder (devel and release)



### R CMD check results


0 ERRORs | 0 WARNINGs | 0 NOTEs



### Reverse dependencies


There are 3 reverse dependencies: `detrendr`, `nandb` and `autothresholdr`. This update does not break any of these. However, `nandb` is currently broken. It has undergone a rewrite which depends on new versions of `filesstrings` (already submitted), `ijtiff` (this package), `autothresholdr` and `detrendr`. This new image analysis ecosystem is ready and being submitted in order.
  * See https://github.com/ropensci/ijtiff/blob/master/revdep/problems.md for more.
    
    