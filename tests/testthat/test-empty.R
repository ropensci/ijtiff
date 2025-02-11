library(checkmate)
library(ijtiff)

empty_4d <- array(double(), dim = c(0, 0, 0, 0))
empty_3d <- array(double(), dim = c(0, 0, 0))

# Test empty 4d array
tryCatch(
  {
    enlist_img(empty_4d)
  },
  error = function(e) {
    print("4D array error:")
    print(e$message)
  }
)

# Test empty 3d array
tryCatch(
  {
    enlist_planes(empty_3d)
  },
  error = function(e) {
    print("3D array error:")
    print(e$message)
  }
)
