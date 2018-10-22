#
# library(rvest)
# library(notifyR)
# library(magrittr)
# library(httr)
#
# # A - Log in and access iframe -------------------------------------------------
#
# url <- "https://www.insidenci.com/psp/paprd/EMPLOYEE/ERP/c/ADMINISTER_EXPENSE_FUNCTIONS.TE_TIME_ENTRY_INQ.GBL"
#
# session <- html_session(url)
#
# # do initial login
# login_form <- session %>%
#   html_node("form[name=login]") %>%
#   html_form() %>%
#   set_values(
#     userid = "dzafar",
#     pwd = "09po;l)(POp"
#   )
#
# session %<>% submit_form(form = login_form, submit = "Submit")
#
# # form we're looking to edit is in an iframe. Must navigate to it's source
# # instead of the regular url
# iframe_url <- session %>%
#   html_nodes("iframe") %>%
#   magrittr::extract(1) %>%
#   html_attr("src")
#
# session %<>% jump_to(iframe_url)
#
# # B - Get the timesheet to edit ------------------------------------------------
# # get the previous Saturday
# get_Sat <- function(d = Sys.Date()) {
#   prev_days <- seq(d - 6, d, by = 'day')
#   prev_days[weekdays(prev_days) == 'Saturday'] %>%
#     as.character() %>%
#     sub("([0-9]{4})-([0-9]{2})-([0-9]{2})", "\\2/\\3/\\1", .)
# }
#
# # get the time report search form
# report_search_form <- session %>%
#   html_node("form[name=win0]") %>%
#   html_form() %>%
#   set_values(
#     ICAction = "#ICSearch",
#     A1EX_TMINQ_S_VW_PERIOD_END_DT = "02/24/2018"# get_Sat()
#   )
#
# # now if you only have one timesheet it takes you to it,
# # but if there was a previously submitted timesheet it asks
# # you to pick one.
# session %<>% submit_form(form = report_search_form)
#
# # select the timesheet
# get_ts <- session %>%
#   html_node("form[name=win0]") %>%
#   html_form() %>%
#   set_values(
#     ICAction = "#ICRow0"
#   )
#
# session %<>% submit_form(form = get_ts)
#
# session %>% html_form()
#
# session %>%
#   read_html %>%
#   html_text


