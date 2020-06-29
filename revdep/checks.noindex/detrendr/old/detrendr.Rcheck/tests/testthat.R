library(testthat)
library(detrendr)

if (!detrendr:::win32bit()) test_check("detrendr")
