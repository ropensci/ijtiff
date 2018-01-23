pkgs <- c("xml2", "magrittr", "tidyverse", "janitor")
invisible(lapply(pkgs, library, character.only = TRUE))

get_tag_info <- function(url) {
  xml_table <- read_html(url) %>%
    xml_find_all(".//table") %>%
    getElement(2)
  values <- xml_table %>%
    xml_find_all(".//td") %>%
    xml_text() %>% {
      .[seq(2, length(.), by = 2)]
    }
  titles <- xml_table  %>%
    xml_find_all(".//th") %>%
    xml_text()
  t(values) %>%
    set_colnames(titles) %>%
    as_tibble() %>%
    clean_names()
}
