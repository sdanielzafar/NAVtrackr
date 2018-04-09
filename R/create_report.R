#' Create and save a report from Toggl
#'
#' @param un the user's Navigant username
#' @param pass the user's Navigant password
#' @param period_end_date the period end date to make the timesheet for, defaults
#' for the previous Saturday but can run the next saturday easily by setting
#' this value to `get_Sat(prev = F)`
#'
#' @return the resultant html session, can be parsed for errors
#' @import rvest
#' @import notifyR
#' @import magrittr
#' @export
report_create <- function(user, pass, period_end_date = get_Sat()) {
  # this should run Sunday at 8:00 AM CT for the previous week

  options(warn = -1)

  # read in the user keys
  user_keys <- read.csv("inst/extdata/user_keys.csv",
                        stringsAsFactors = F) %>%
    .[, .$username == "dzafar"]

  if (nchar(user_keys$notify) != 30) user_keys$notify <- NULL

  if (nrow(user_keys) == 0) {
    stop("Confirm that you have your toggl and notify keys in data/user_keys.csv")
  }

  # A - Logging in and creating the report ---------------------------------------
  session <- NAVlogin(user, pass)

  url <- "https://fs.insidenci.com/psp/fsprd/EMPLOYEE/ERP/c/ADMINISTER_EXPENSE_FUNCTIONS.TE_TIME_ENTRY.GBL"

  session %<>% get_iframe(url)

  # create report for saturday
  create_form <- session %>%
    html_node("form[name=win0]") %>%
    html_form() %>%
    set_values(
      ICAction = "#ICSearch",
      EX_TIME_ADD_VW_PERIOD_END_DT = format(period_end_date, "%m/%d/%Y")
    )

  session %<>% submit_form(form = create_form,
                           submit = '#ICSearch')

  # create blank report with location
  add_loc_form <- session %>%
    html_node("form[name=win0]") %>%
    html_form %>%
    set_values(
      ICAction = "EX_ICLIENT_WRK_OK_PB",
      EX_TIME_HDR_LOCALITY = "CO-BOULDER"
    )

  session %<>% submit_form(form = add_loc_form,
                           submit = 'EX_TIME_HDR_LOCALITY')

  # B - Saving the report ------------------------------------------------------

  # use method to get toggl entries
  entries <- get_toggl_entries(period_end_date, user_keys$toggl)

  # saving the report with the working bill codes
  session %<>%
    ts_fill_save(entries, user_keys$notify)

}




