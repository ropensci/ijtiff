#include <Rcpp.h>
using namespace Rcpp;

// [[Rcpp::export]]
List dims_cpp(List lst) {
  const std::size_t sz = lst.size();
  List dims(sz);
  for (std::size_t i = 0; i != sz; ++i) {
    NumericVector mat_i = as<NumericVector>(lst[i]);
    dims[i] = mat_i.attr("dim");
  }
  return dims;
}
