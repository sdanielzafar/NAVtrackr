#' Create and save a report from Toggl
#'
#' @description This high-level function logs onto InsideNCI, get your toggl report
#' for the indicated period end date and formats it (`get_toggl_entries()`), and
#' inserts it into a timesheet. Lastly it saves the timesheet so that you can open
#' it up and do a quick QC or add comments before it is submitted.
#'
#' @param user the user's Navigant username
#' @param pass the user's Navigant password
#' @param period_end_date the period end date to make the timesheet for, defaults
#' for the previous Saturday but can run the next saturday easily by setting
#' this value to `get_Sat(prev = F)`
#'
#' @return the resultant html session, can be parsed for errors
#' @import rvest
#' @import notifyR
#' @import magrittr
#'
#' @examples
#'
#' # for the last timesheet
#' report_create("dzafar", "password")
#'
#' # for the upcoming timesheet
#' report_create("dzafar", "password", period_end_date = get_Sat(prev = F))
#'
#' @export
report_create <- function(user, pass, period_end_date = get_Sat()) {
  # this should run Sunday at 8:00 AM CT for the previous week

  options(warn = -1)

  # read in the user keys
  user_keys <- system.file("extdata", "user_keys.csv", package = "NAVtrackr") %>%
    read.csv(stringsAsFactors = F) %>%
    .[, .$username == user]

  if (nchar(user_keys$notify) != 30) user_keys$notify <- NULL

  if (nrow(user_keys) == 0) {
    stop("Confirm that you have added your toggl and notify tokens")
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




