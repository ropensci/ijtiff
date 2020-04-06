# detrendr

<details>

* Version: 0.6.5
* Source code: https://github.com/cran/detrendr
* URL: https://rorynolan.github.io/detrendr, https://www.github.com/rorynolan/detrendr
* BugReports: https://www.github.com/rorynolan/detrendr/issues
* Date/Publication: 2020-03-16 19:50:02 UTC
* Number of recursive dependencies: 100

Run `revdep_details(,"detrendr")` for more info

</details>

## In both

*   checking whether package ‘detrendr’ can be installed ... ERROR
    ```
    Installation failed.
    See ‘/Users/rnolan/Dropbox/DPhil/Misc/RStuff/ijtiff/revdep/checks.noindex/detrendr/new/detrendr.Rcheck/00install.out’ for details.
    ```

## Installation

### Devel

```
* installing *source* package ‘detrendr’ ...
** package ‘detrendr’ successfully unpacked and MD5 sums checked
** using staged installation
** libs
clang++ -std=gnu++11 -I"/Library/Frameworks/R.framework/Resources/include" -DNDEBUG  -I"/Users/rnolan/Dropbox/DPhil/Misc/RStuff/ijtiff/revdep/library.noindex/detrendr/Rcpp/include" -I"/Users/rnolan/Dropbox/DPhil/Misc/RStuff/ijtiff/revdep/library.noindex/detrendr/RcppParallel/include" -isysroot /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk -I/usr/local/include  -fPIC  -Wall -g -O2  -c RcppExports.cpp -o RcppExports.o
clang++ -std=gnu++11 -I"/Library/Frameworks/R.framework/Resources/include" -DNDEBUG  -I"/Users/rnolan/Dropbox/DPhil/Misc/RStuff/ijtiff/revdep/library.noindex/detrendr/Rcpp/include" -I"/Users/rnolan/Dropbox/DPhil/Misc/RStuff/ijtiff/revdep/library.noindex/detrendr/RcppParallel/include" -isysroot /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk -I/usr/local/include  -fPIC  -Wall -g -O2  -c anyNA.cpp -o anyNA.o
clang++ -std=gnu++11 -I"/Library/Frameworks/R.framework/Resources/include" -DNDEBUG  -I"/Users/rnolan/Dropbox/DPhil/Misc/RStuff/ijtiff/revdep/library.noindex/detrendr/Rcpp/include" -I"/Users/rnolan/Dropbox/DPhil/Misc/RStuff/ijtiff/revdep/library.noindex/detrendr/RcppParallel/include" -isysroot /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk -I/usr/local/include  -fPIC  -Wall -g -O2  -c col_stats_parallel.cpp -o col_stats_parallel.o
clang++ -std=gnu++11 -I"/Library/Frameworks/R.framework/Resources/include" -DNDEBUG  -I"/Users/rnolan/Dropbox/DPhil/Misc/RStuff/ijtiff/revdep/library.noindex/detrendr/Rcpp/include" -I"/Users/rnolan/Dropbox/DPhil/Misc/RStuff/ijtiff/revdep/library.noindex/detrendr/RcppParallel/include" -isysroot /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk -I/usr/local/include  -fPIC  -Wall -g -O2  -c frame_utils.cpp -o frame_utils.o
In file included from frame_utils.cpp:6:
In file included from /Users/rnolan/Dropbox/DPhil/Misc/RStuff/ijtiff/revdep/library.noindex/detrendr/RcppParallel/include/RcppParallel.h:6:
In file included from /Users/rnolan/Dropbox/DPhil/Misc/RStuff/ijtiff/revdep/library.noindex/detrendr/RcppParallel/include/RcppParallel/TinyThread.h:9:
In file included from /Users/rnolan/Dropbox/DPhil/Misc/RStuff/ijtiff/revdep/library.noindex/detrendr/RcppParallel/include/tthread/tinythread.h:83:
In file included from /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include/unistd.h:655:
/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include/gethostuuid.h:39:17: error: unknown type name 'uuid_t'
int gethostuuid(uuid_t, const struct timespec *) __OSX_AVAILABLE_STARTING(__MAC_10_5, __IPHONE_NA);
                ^
In file included from frame_utils.cpp:6:
In file included from /Users/rnolan/Dropbox/DPhil/Misc/RStuff/ijtiff/revdep/library.noindex/detrendr/RcppParallel/include/RcppParallel.h:6:
In file included from /Users/rnolan/Dropbox/DPhil/Misc/RStuff/ijtiff/revdep/library.noindex/detrendr/RcppParallel/include/RcppParallel/TinyThread.h:9:
In file included from /Users/rnolan/Dropbox/DPhil/Misc/RStuff/ijtiff/revdep/library.noindex/detrendr/RcppParallel/include/tthread/tinythread.h:83:
/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include/unistd.h:662:27: error: unknown type name 'uuid_t'; did you mean 'uid_t'?
int      getsgroups_np(int *, uuid_t);
                              ^
/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include/sys/_types/_uid_t.h:31:31: note: 'uid_t' declared here
typedef __darwin_uid_t        uid_t;
                              ^
In file included from frame_utils.cpp:6:
In file included from /Users/rnolan/Dropbox/DPhil/Misc/RStuff/ijtiff/revdep/library.noindex/detrendr/RcppParallel/include/RcppParallel.h:6:
In file included from /Users/rnolan/Dropbox/DPhil/Misc/RStuff/ijtiff/revdep/library.noindex/detrendr/RcppParallel/include/RcppParallel/TinyThread.h:9:
In file included from /Users/rnolan/Dropbox/DPhil/Misc/RStuff/ijtiff/revdep/library.noindex/detrendr/RcppParallel/include/tthread/tinythread.h:83:
/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include/unistd.h:664:27: error: unknown type name 'uuid_t'; did you mean 'uid_t'?
int      getwgroups_np(int *, uuid_t);
                              ^
/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include/sys/_types/_uid_t.h:31:31: note: 'uid_t' declared here
typedef __darwin_uid_t        uid_t;
                              ^
In file included from frame_utils.cpp:6:
In file included from /Users/rnolan/Dropbox/DPhil/Misc/RStuff/ijtiff/revdep/library.noindex/detrendr/RcppParallel/include/RcppParallel.h:6:
In file included from /Users/rnolan/Dropbox/DPhil/Misc/RStuff/ijtiff/revdep/library.noindex/detrendr/RcppParallel/include/RcppParallel/TinyThread.h:9:
In file included from /Users/rnolan/Dropbox/DPhil/Misc/RStuff/ijtiff/revdep/library.noindex/detrendr/RcppParallel/include/tthread/tinythread.h:83:
/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include/unistd.h:727:31: error: unknown type name 'uuid_t'; did you mean 'uid_t'?
int      setsgroups_np(int, const uuid_t);
                                  ^
/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include/sys/_types/_uid_t.h:31:31: note: 'uid_t' declared here
typedef __darwin_uid_t        uid_t;
                              ^
In file included from frame_utils.cpp:6:
In file included from /Users/rnolan/Dropbox/DPhil/Misc/RStuff/ijtiff/revdep/library.noindex/detrendr/RcppParallel/include/RcppParallel.h:6:
In file included from /Users/rnolan/Dropbox/DPhil/Misc/RStuff/ijtiff/revdep/library.noindex/detrendr/RcppParallel/include/RcppParallel/TinyThread.h:9:
In file included from /Users/rnolan/Dropbox/DPhil/Misc/RStuff/ijtiff/revdep/library.noindex/detrendr/RcppParallel/include/tthread/tinythread.h:83:
/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include/unistd.h:729:31: error: unknown type name 'uuid_t'; did you mean 'uid_t'?
int      setwgroups_np(int, const uuid_t);
                                  ^
/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include/sys/_types/_uid_t.h:31:31: note: 'uid_t' declared here
typedef __darwin_uid_t        uid_t;
                              ^
5 errors generated.
make: *** [frame_utils.o] Error 1
ERROR: compilation failed for package ‘detrendr’
* removing ‘/Users/rnolan/Dropbox/DPhil/Misc/RStuff/ijtiff/revdep/checks.noindex/detrendr/new/detrendr.Rcheck/detrendr’

```
### CRAN

```
* installing *source* package ‘detrendr’ ...
** package ‘detrendr’ successfully unpacked and MD5 sums checked
** using staged installation
** libs
clang++ -std=gnu++11 -I"/Library/Frameworks/R.framework/Resources/include" -DNDEBUG  -I"/Users/rnolan/Dropbox/DPhil/Misc/RStuff/ijtiff/revdep/library.noindex/detrendr/Rcpp/include" -I"/Users/rnolan/Dropbox/DPhil/Misc/RStuff/ijtiff/revdep/library.noindex/detrendr/RcppParallel/include" -isysroot /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk -I/usr/local/include  -fPIC  -Wall -g -O2  -c RcppExports.cpp -o RcppExports.o
clang++ -std=gnu++11 -I"/Library/Frameworks/R.framework/Resources/include" -DNDEBUG  -I"/Users/rnolan/Dropbox/DPhil/Misc/RStuff/ijtiff/revdep/library.noindex/detrendr/Rcpp/include" -I"/Users/rnolan/Dropbox/DPhil/Misc/RStuff/ijtiff/revdep/library.noindex/detrendr/RcppParallel/include" -isysroot /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk -I/usr/local/include  -fPIC  -Wall -g -O2  -c anyNA.cpp -o anyNA.o
clang++ -std=gnu++11 -I"/Library/Frameworks/R.framework/Resources/include" -DNDEBUG  -I"/Users/rnolan/Dropbox/DPhil/Misc/RStuff/ijtiff/revdep/library.noindex/detrendr/Rcpp/include" -I"/Users/rnolan/Dropbox/DPhil/Misc/RStuff/ijtiff/revdep/library.noindex/detrendr/RcppParallel/include" -isysroot /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk -I/usr/local/include  -fPIC  -Wall -g -O2  -c col_stats_parallel.cpp -o col_stats_parallel.o
clang++ -std=gnu++11 -I"/Library/Frameworks/R.framework/Resources/include" -DNDEBUG  -I"/Users/rnolan/Dropbox/DPhil/Misc/RStuff/ijtiff/revdep/library.noindex/detrendr/Rcpp/include" -I"/Users/rnolan/Dropbox/DPhil/Misc/RStuff/ijtiff/revdep/library.noindex/detrendr/RcppParallel/include" -isysroot /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk -I/usr/local/include  -fPIC  -Wall -g -O2  -c frame_utils.cpp -o frame_utils.o
In file included from frame_utils.cpp:6:
In file included from /Users/rnolan/Dropbox/DPhil/Misc/RStuff/ijtiff/revdep/library.noindex/detrendr/RcppParallel/include/RcppParallel.h:6:
In file included from /Users/rnolan/Dropbox/DPhil/Misc/RStuff/ijtiff/revdep/library.noindex/detrendr/RcppParallel/include/RcppParallel/TinyThread.h:9:
In file included from /Users/rnolan/Dropbox/DPhil/Misc/RStuff/ijtiff/revdep/library.noindex/detrendr/RcppParallel/include/tthread/tinythread.h:83:
In file included from /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include/unistd.h:655:
/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include/gethostuuid.h:39:17: error: unknown type name 'uuid_t'
int gethostuuid(uuid_t, const struct timespec *) __OSX_AVAILABLE_STARTING(__MAC_10_5, __IPHONE_NA);
                ^
In file included from frame_utils.cpp:6:
In file included from /Users/rnolan/Dropbox/DPhil/Misc/RStuff/ijtiff/revdep/library.noindex/detrendr/RcppParallel/include/RcppParallel.h:6:
In file included from /Users/rnolan/Dropbox/DPhil/Misc/RStuff/ijtiff/revdep/library.noindex/detrendr/RcppParallel/include/RcppParallel/TinyThread.h:9:
In file included from /Users/rnolan/Dropbox/DPhil/Misc/RStuff/ijtiff/revdep/library.noindex/detrendr/RcppParallel/include/tthread/tinythread.h:83:
/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include/unistd.h:662:27: error: unknown type name 'uuid_t'; did you mean 'uid_t'?
int      getsgroups_np(int *, uuid_t);
                              ^
/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include/sys/_types/_uid_t.h:31:31: note: 'uid_t' declared here
typedef __darwin_uid_t        uid_t;
                              ^
In file included from frame_utils.cpp:6:
In file included from /Users/rnolan/Dropbox/DPhil/Misc/RStuff/ijtiff/revdep/library.noindex/detrendr/RcppParallel/include/RcppParallel.h:6:
In file included from /Users/rnolan/Dropbox/DPhil/Misc/RStuff/ijtiff/revdep/library.noindex/detrendr/RcppParallel/include/RcppParallel/TinyThread.h:9:
In file included from /Users/rnolan/Dropbox/DPhil/Misc/RStuff/ijtiff/revdep/library.noindex/detrendr/RcppParallel/include/tthread/tinythread.h:83:
/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include/unistd.h:664:27: error: unknown type name 'uuid_t'; did you mean 'uid_t'?
int      getwgroups_np(int *, uuid_t);
                              ^
/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include/sys/_types/_uid_t.h:31:31: note: 'uid_t' declared here
typedef __darwin_uid_t        uid_t;
                              ^
In file included from frame_utils.cpp:6:
In file included from /Users/rnolan/Dropbox/DPhil/Misc/RStuff/ijtiff/revdep/library.noindex/detrendr/RcppParallel/include/RcppParallel.h:6:
In file included from /Users/rnolan/Dropbox/DPhil/Misc/RStuff/ijtiff/revdep/library.noindex/detrendr/RcppParallel/include/RcppParallel/TinyThread.h:9:
In file included from /Users/rnolan/Dropbox/DPhil/Misc/RStuff/ijtiff/revdep/library.noindex/detrendr/RcppParallel/include/tthread/tinythread.h:83:
/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include/unistd.h:727:31: error: unknown type name 'uuid_t'; did you mean 'uid_t'?
int      setsgroups_np(int, const uuid_t);
                                  ^
/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include/sys/_types/_uid_t.h:31:31: note: 'uid_t' declared here
typedef __darwin_uid_t        uid_t;
                              ^
In file included from frame_utils.cpp:6:
In file included from /Users/rnolan/Dropbox/DPhil/Misc/RStuff/ijtiff/revdep/library.noindex/detrendr/RcppParallel/include/RcppParallel.h:6:
In file included from /Users/rnolan/Dropbox/DPhil/Misc/RStuff/ijtiff/revdep/library.noindex/detrendr/RcppParallel/include/RcppParallel/TinyThread.h:9:
In file included from /Users/rnolan/Dropbox/DPhil/Misc/RStuff/ijtiff/revdep/library.noindex/detrendr/RcppParallel/include/tthread/tinythread.h:83:
/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include/unistd.h:729:31: error: unknown type name 'uuid_t'; did you mean 'uid_t'?
int      setwgroups_np(int, const uuid_t);
                                  ^
/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include/sys/_types/_uid_t.h:31:31: note: 'uid_t' declared here
typedef __darwin_uid_t        uid_t;
                              ^
5 errors generated.
make: *** [frame_utils.o] Error 1
ERROR: compilation failed for package ‘detrendr’
* removing ‘/Users/rnolan/Dropbox/DPhil/Misc/RStuff/ijtiff/revdep/checks.noindex/detrendr/old/detrendr.Rcheck/detrendr’

```
