
#' Login to insideNCI
#'
#' @param un the user's Navigant username
#' @param pass the user's Navigant password
#'
#' @return an rvest html session logged into insidenNCI
#'
#' @import magrittr
#' @import rvest
#' @export
NAVlogin <- function(un, pass) {

  url <- "https://www.insidenci.com/psp/paprd/?cmd=login"
  session <- html_session(url)

  login_form <- session %>%
    html_node("form[name=login]") %>%
    html_form() %>%
    set_values(
      userid = un,
      pwd = pass
    )

  session %>%
    submit_form(form = login_form, submit = "Submit")
}

# get weekday indexes
week_days <- dplyr::data_frame(
  day = weekdays(as.Date(3, "1970-01-01", tz = "GMT") + 0:6),
  index = 1:7
)


#' get the previous Saturday
#'
#' @param d the day, as class `Date`
#' @param prev if set to `TRUE` it find the previous Saturday, `FALSE` finds the next
#'
#' @return a Saturday with class `Date`
#' @export
get_Sat <- function(d = Sys.Date(), prev = T) {
  # this gets the upcoming Saturday, unless prev = T
  prev_days <- seq(d - 6, d, by = 'day')
  next_days <- seq(d, d + 6, by = 'day')
  id_Sat <- function(.x) {
    .x[weekdays(.x) == 'Saturday']
    }
  if (!prev) {
    return(id_Sat(next_days))
  } else {
    return(id_Sat(prev_days))
  }
}

#' get the next Sunday
#'
#' @param d the day, as class `Date`
#'
#' @return the next Sunday with class `Date`
#' @export
get_Sun <- function(d = Sys.Date()) {
  prev_days <- seq(d - 6, d, by = 'day')
  prev_days[weekdays(prev_days) == 'Sunday']
}

#' get the most recent Sunday
#'
#' @param d the day, as class `Date`
#'
#' @return the previous Sunday with class `Date`
#' @export
get_last_Sat <- function(d = Sys.Date()) {
  prev = get_Sat() - 1
  prev_days <- seq(prev - 6, prev, by = 'day')
  prev_days[weekdays(prev_days) == 'Saturday']
}

# access content in an iframe
get_iframe <- function(session, url) {

  session %<>% jump_to(url)

  iframe_url <- session %>%
    html_nodes("iframe") %>%
    magrittr::extract(1) %>%
    html_attr("src")

  session %>% jump_to(iframe_url)
}

set_vals_batch <- function(form, .l) {
  do.call(function(...) {
    set_values(form, ...)
  }, .l)
}

# this function appends a submit bottom to a form
add_submit <- function(form) {

  fake_submit_button <- list(name = "Submit",
                             type = "Submit",
                             value = NULL,
                             checked = NULL,
                             disabled = NULL,
                             readonly = NULL,
                             required = FALSE)
  attr(fake_submit_button, "class") <- "input"

  form[["fields"]][["submit"]] <- fake_submit_button

  form

}


