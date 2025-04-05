# Anticonf (tm) script by Jeroen Ooms (2018)
# This script will query 'pkg-config' for the required cflags and ldflags.
# If pkg-config is unavailable or does not find the library, try setting
# INCLUDE_DIR and LIB_DIR manually via e.g:
# R CMD INSTALL --configure-vars='INCLUDE_DIR=/.../include LIB_DIR=/.../lib'

# Library settings
PKG_CONFIG_NAME <- "libtiff-4"
PKG_DEB_NAME <- "libtiff-dev"
PKG_RPM_NAME <- "libtiff-devel"
PKG_BREW_NAME <- "libtiff"
PKG_TEST_HEADER <- "<tiff.h>"
PKG_LIBS <- "-ltiff -ljpeg -lz"

PKGCONFIG_CFLAGS <- PKGCONFIG_LIBS <- ""

PKG_CFLAGS <- system2("echo", "$PKG_CFLAGS", stdout = TRUE)

# Use pkg-config if available
pkg_config_available <- tryCatch(
  suppressWarnings(
    isTRUE(
      as.logical(
        nchar(
          system2("pkg-config", "--version", stdout = TRUE)
        )
      )
    )
  ),
  error = function(cnd) FALSE
)
if (pkg_config_available) {
  cat("Found pkg-config!", "\n")
  PKGCONFIG_CFLAGS <- tryCatch(
    suppressWarnings(
      system2("pkg-config",
        c("--cflags", "--silence-errors", PKG_CONFIG_NAME),
        stdout = TRUE
      )
    ),
    error = function(cnd) ""
  )
  PKGCONFIG_LIBS <- tryCatch(
    suppressWarnings(
      system2("pkg-config",
        c("--libs", PKG_CONFIG_NAME),
        stdout = TRUE
      )
    ),
    error = function(cnd) ""
  )
  PKGCONFIG_STATIC_LIBS <- tryCatch(
    suppressWarnings(
      system2("pkg-config",
        c("--libs", "--static", PKG_CONFIG_NAME),
        stdout = TRUE
      )
    ),
    error = function(cnd) ""
  )
  pkgconfig_success <- any(
    sapply(
      list(PKGCONFIG_CFLAGS, PKGCONFIG_LIBS, PKGCONFIG_STATIC_LIBS),
      \(x) isTRUE(nchar(x) > 0)
    )
  )
  if (pkgconfig_success) {
    if (length(PKGCONFIG_CFLAGS) == 0) PKGCONFIG_CFLAGS <- ""
    PKGCONFIG_LIBS <- paste(PKGCONFIG_LIBS, PKGCONFIG_STATIC_LIBS)
    # Split by whitespace, remove empty strings, and make unique
    pkg_libs_parts <- strsplit(PKGCONFIG_LIBS, "[[:space:]]+")[[1]]
    pkg_libs_parts <- pkg_libs_parts[pkg_libs_parts != ""]
    PKGCONFIG_LIBS <- trimws(paste(unique(pkg_libs_parts), collapse = " "))
  }
}

# Note that cflags may be empty in case of success
INCLUDE_DIR <- system2("echo", "$INCLUDE_DIR", stdout = TRUE)
LIB_DIR <- system2("echo", "$LIB_DIR", stdout = TRUE)
if (nchar(INCLUDE_DIR) || nchar(LIB_DIR)) {
  cat("Found INCLUDE_DIR and/or LIB_DIR!", "\n")
  PKG_CFLAGS <- paste0("-I", INCLUDE_DIR, " ", PKG_CFLAGS)
  PKG_LIBS <- paste0("-L", LIB_DIR, " ", PKG_LIBS)
} else {
  if (nchar(PKGCONFIG_CFLAGS) || nchar(PKGCONFIG_LIBS)) {
    cat("Found pkg-config cflags and/or libs for libtiff!", "\n")
    PKG_CFLAGS <- PKGCONFIG_CFLAGS
    PKG_LIBS <- PKGCONFIG_LIBS
  } else {
    cat("Did not find pkg-config cflags or libs for libtiff.", "\n")
  }
}

# pkg-config often says -ljbig and -lLerc are necessary but they seem not to be
for (lib in c("jbig", "[Ll]erc")) {
  # Remove -ljbig or -lLerc libraries
  pattern <- paste0("(^|[[:space:]])-l", lib, "($|[[:space:]])")
  PKG_LIBS <- gsub(pattern, "\\1\\2", PKG_LIBS)
}


PKG_LIBS <- trimws(PKG_LIBS)
PKG_CFLAGS <- trimws(PKG_CFLAGS)

# For debugging
cat(paste0("Using PKG_CFLAGS=", PKG_CFLAGS), "\n")
cat(paste0("Using PKG_LIBS=", PKG_LIBS), "\n")

# Find compiler
CC <- system2(paste0(R.home(), "/bin/R"),
  c("CMD", "config", "CC"),
  stdout = TRUE
)
CFLAGS <- system2(paste0(R.home(), "/bin/R"),
  c("CMD", "config", "CFLAGS"),
  stdout = TRUE
)
CPPFLAGS <- system2(paste0(R.home(), "/bin/R"),
  c("CMD", "config", "CPPFLAGS"),
  stdout = TRUE
)

# Test configuration
test_failed <- as.logical(
  system(
    paste(
      'echo "#include', PKG_TEST_HEADER, '" |',
      CC, CPPFLAGS, PKG_CFLAGS, CFLAGS, "-E -xc - >/dev/null 2>&1"
    )
  )
)

if (test_failed) {
  cat(
    "------------------------- ANTICONF ERROR ---------------------------\n",
    paste0(
      "Configuration failed because ", PKG_CONFIG_NAME, " was not found. \n",
      " Try installing:\n",
      "  * deb: ", PKG_DEB_NAME, " (Debian, Ubuntu, etc)\n",
      "  * rpm: ", PKG_RPM_NAME, " (Fedora, EPEL)\n",
      "  * brew: ", PKG_BREW_NAME, " (OSX)\n",
      " If ", PKG_CONFIG_NAME, " is already installed, check that 'pkg-config'",
      "\n", " is in your PATH and PKG_CONFIG_PATH contains a ",
      " ", PKG_CONFIG_NAME, ".pc file.\n",
      " If pkg-config is unavailable,",
      " you can set INCLUDE_DIR and LIB_DIR\n manually via:\n",
      " `R CMD INSTALL --configure-vars='INCLUDE_DIR=... LIB_DIR=...'`\n",
      "--------------------------------------------------------------------"
    )
  )
} else { # Write to Makevars
  # Use base R to write the Makevars file
  makevars_content <- paste0(
    "PKG_CPPFLAGS=", PKG_CFLAGS, "\n",
    "PKG_LIBS=", PKG_LIBS
  )
  # When R CMD INSTALL runs this script, we need to write to "src/Makevars" directly
  writeLines(makevars_content, "src/Makevars")
}
