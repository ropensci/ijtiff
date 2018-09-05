pee <- function() {  # prepare_error_expectation
  clipr::read_clip() %T>% {
    if (strex::str_elem(.[1], 1) == " ") .[1] <- stringr::str_sub(.[1], 2, -1)
    if (strex::str_elem(.[length(.)], -1) == " ")
      .[length(.)] <- stringr::str_sub(.[length(.)], 1, -2)
  } %>%
    ore::ore.escape() %>%
    paste0(".?") %T>% {
      . <- paste0("\"", ., "\"")
      .[1] <- paste("paste0(", .[1])
      .[length(.)] <- paste0(.[length(.)], ")")
      .[-length(.)] <- paste0(.[-length(.)], ",")
    } %>%
    stringr::str_replace_all("\\\\", "\\\\\\\\") %>%
    styler::style_text() %>%
    clipr::write_clip()
}
