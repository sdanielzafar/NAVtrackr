#' Create and save a report from Toggl
#'
#' @description This high-level function logs onto InsideNCI, get your toggl report
#' for the indicated period end date and formats it (`get_toggl_entries()`), and
#' inserts it into a timesheet. Lastly it saves the timesheet so that you can open
#' it up and do a quick QC or add comments before it is submitted.
#'
#' @param user the user's Navigant username
#' @param period_end_date the period end date to make the timesheet for, defaults
#' for the previous Saturday but can run the next saturday easily by setting
#' this value to `get_Sat(prev = F)`
#' @param locality the NCI locality, e.g. CO-BOULDER, CA-SF, or IL-C
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
report_create <- function(user = Sys.info()[["user"]], period_end_date = get_Sat(), locality = "CO-BOULDER") {
  # this should run Sunday at 8:00 AM CT for the previous week

  options(warn = -1)

  # Verifying Toggl and Pushover keys
  verify_keys()
  toggl <- Sys.getenv("TOGGL_TOKEN")
  notify <- Sys.getenv("PUSHOVER_KEY")
  if (nchar(notify) != 30) notify <- NULL

  # A - Logging in and creating the report ---------------------------------------
  session <- NAVlogin(user)

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
  tryCatch({
    add_loc_form <- session %>%
      html_node("form[name=win0]") %>%
      html_form %>%
      set_values(
        ICAction = "EX_ICLIENT_WRK_OK_PB",
        EX_TIME_HDR_LOCALITY = locality
      )
  }, error = function(e) {
    stop("Time report for ", period_end_date, " already exists")
    })

  session %<>% submit_form(form = add_loc_form,
                           submit = 'EX_TIME_HDR_LOCALITY')

  # B - Saving the report ------------------------------------------------------

  # use method to get toggl entries
  entries <- get_toggl_entries(period_end_date, toggl)

  # saving the report with the working bill codes
  session %<>%
    ts_fill_save(entries, notify)

}




