# NAVlogin <- function(un) {
#   require(magrittr)
#   require(rvest)
#
#
#   pass <- rstudioapi::showPrompt(
#     "Authenication",
#     paste0("Enter Navigant password for user '", un, "'"),
#     default = "")
#
#   url <- "https://www.insidenci.com/psp/paprd/?cmd=login"
#   session <- html_session(url)
#
#   login_form <- session %>%
#     html_node("form[name=login]") %>%
#     html_form() %>%
#     set_values(
#       userid = un,
#       pwd = pass
#     )
#
#   session %>%
#     submit_form(form = login_form, submit = "Submit")
# }
