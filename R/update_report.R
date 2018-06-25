library(rvest)
library(notifyR)
library(magrittr)
library(httr)

session <- NAVlogin("dzafar", "09po;l)(POp")

url <- "https://fs.insidenci.com/psp/fsprd/EMPLOYEE/ERP/c/ADMINISTER_EXPENSE_FUNCTIONS.TE_TIME_ENTRY.GBL"

session %<>% jump_to(url)

# access iframe
iframe_url <- session %>%
  html_nodes("iframe") %>%
  magrittr::extract(1) %>%
  html_attr("src")

session %<>% jump_to(iframe_url)

#
#ICSrchTypeClassic
