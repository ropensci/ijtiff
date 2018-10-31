# nandb

Version: 1.0.1

## In both

*   checking tests ...
    ```
     ERROR
    Running the tests in ‘tests/testthat.R’ failed.
    Last 13 lines of output:
      1: expect_equal(deduplicate_cc_nb_filename(path), paste0("detrended_exponential_thresh=4,3_tau=1,2", "_brightness_filt=NA,NA.tif")) at testthat/test-utils.R:65
      2: quasi_label(enquo(object), label)
      3: eval_bare(get_expr(quo), get_env(quo))
      4: deduplicate_cc_nb_filename(path)
      5: filesstrings::count_matches(path, thresh_pattern)
      6: .Defunct("stringr::str_count()", "filesstrings")
      7: stop(paste(msg, collapse = ""), call. = FALSE, domain = NA)
      
      ══ testthat results  ═══════════════════════════════════════════════════════════════════════════════
      OK: 96 SKIPPED: 0 FAILED: 2
      1. Error: deduplicate_nb_filename() works correctly (@test-utils.R#26) 
      2. Error: deduplicate_cc_nb_filename() works correctly (@test-utils.R#65) 
      
      Error: testthat unit tests failed
      Execution halted
    ```

