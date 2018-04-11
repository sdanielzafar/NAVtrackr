#' Fill and save a timesheet
#'
#' @param session the rvest html session at the timesheet
#' @param entries the formatted entries, from `get_toggl_entries`
#' @param notify the notify ID, optional
#'
#' @import magrittr
#' @import rvest
#'
#' @return an rvest html session
#' @export
ts_fill_save <- function(session, entries, notify = NULL) {

  # assign lines to bill code/task combos
  code_rows <- entries %>%
    distinct(bill_code, task) %>%
    arrange(desc(bill_code)) %>%
    mutate(row = (1:n()) - 1)

  # get codes in format for input
  to_submit <- entries %>%
    left_join(code_rows, c("bill_code", "task")) %>%
    tidyr::gather(cat, vals, -row, -Date) %>%
    mutate(day = weekdays(as.Date(Date))) %>%
    left_join(week_days, "day") %>%
    arrange(cat, row, index) %>%
    mutate(row = case_when(
      cat == "bill_code" ~ paste0('PROJECT_CODE$', row),
      cat == "task" ~ paste0('ACTIVITY_CODE$', row),
      cat == "hours" ~ paste0('TIME', index, '$', row)
    )) %>%
    distinct(row, vals) %>%
    group_by(row) %>%
    summarise(vals = case_when(
      grepl("ACTIVITY", row) ~ sprintf("%03.f", sum(as.numeric(vals))),
      grepl("PROJECT", row) ~ sprintf("%6.f", sum(as.numeric(vals))),
      grepl("TIME", row) ~ sprintf("%2.2f", sum(as.numeric(vals)))
    )) %>%
    tidyr::spread(row, vals) %>%
    mutate_at(vars(matches("Time")),
              as.numeric) %>%
    as.list

  # set the number of rows in the timesheet
  session %<>% ts_set_rows(nrow(code_rows))

  # inputting values
  filled_ts <- session %>%
    html_node("form[name=win0]") %>%
    html_form %>%
    set_vals_batch(to_submit) %>%
    set_values(
      ICAction = "EX_ICLIENT_WRK_SAVE_PB"
    )

  # submit the form
  session %<>% submit_form(form = filled_ts,
                           submit = 'NCI_QUERY_WRK_URL_5')

  # get the error message if it exists (hope to improve this)
  error <- session %>%
    xml2::read_html() %>%
    html_text() %>%
    sub(".* Message (.*)'PSPUSHBUTTON'.*", "\\1", .)

  period_end_date <- as.Date(entries$Date[1]) %>% get_Sat(prev = F)

  # determine if there is an error
  if (str_length(error) > 2000) {

    # no error, so submitting a success
    if (!is.null(notify)) {
      notifyR::send_push(
        user = notify,
        paste0("Timesheet for ", format(period_end_date, "%m/%d/%Y"), " saved")
      )
      message("Timesheet Saved")
    }

  } else {

    # found an error, giving it to the user
    error %<>% gsub("<.*?>", "", .)
    if (!is.null(notify)) {
      notifyR::send_push(
        user = notify,
        paste0("ERROR in timesheet creation for ", format(period_end_date, "%m/%d/%Y"), ": ", error)
      )
      warning("Timesheet not saved due to error", error)
    }

    stop("Timesheet error: ", error)
  }

  # returning
  return(session)

}



#' Set # of rows in a timesheet
#'
#' @param session the rvest html session at the timesheet page
#' @param n the number of rows needed
#'
#' @import magrittr
#'
#' @return an rvest html session
#' @export
ts_set_rows <- function(session, n) {

  # get current number of rows
  n_pre <- session %>%
    html_node("form[name=win0]") %>%
    html_form %>%
    .[["fields"]] %>%
    names %>%
    .[grepl("TIME.{1,2}\\$", .)] %>%
    sub("TIME.*\\$(.*)$", "\\1", .) %>%
    unique %>%
    as.numeric() %>%
    length

  n_adj <- n - n_pre

  if (n_adj == 0) return(session)

  action <- ifelse(n_adj > 0, "EX_TIME_DTL$new$0$$0", "EX_TIME_DTL$delete$0$$0")

  for (i in 1:abs(n_adj)) {
    add_row_form <- session %>%
      html_node("form[name=win0]") %>%
      html_form() %>%
      set_values(
        ICAction = action
      )

    session %<>%
      submit_form(form = add_row_form,
                  submit = 'NCI_QUERY_WRK_URL_5')
  }

  session
}

