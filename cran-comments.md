All reverse dependencies have been checked and are OK.

Fixed memory leaks reported by Valgrind by ensuring proper resource cleanup in all code paths, including error conditions. Added finalizers for TIFF resources to ensure they are always properly closed.
