


### Test environments


* local OS X install, R 3.5.1
* ubuntu 14.04 (on travis-ci), R 3.5.1
* Windows Server 2012 (on AppVeyor), R 3.5.1
* win-builder (devel and release)



### R CMD check results


0 ERRORs | 0 WARNINGs | 0 NOTEs



### Reverse dependencies


There are 3 reverse dependencies: `detrendr`, `nandb` and `autothresholdr`. This update does not break any of these.
  * See https://github.com/ropensci/ijtiff/blob/master/revdep/checks.rds for full check results.
    
    

### Fix


* This is a fix for Solaris which lacks `-ljbig`.
* It also trims the package extdata to ensure the package is below 5MB on all platforms, eliminating NOTEs.