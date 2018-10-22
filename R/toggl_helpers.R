
#' Get Toggl time for a single day
#'
#' @param date the day to get the time for
#' @param toggl_token the Toggl token of interest
#' @param min what to round the minues to, default 5
#'
#' @return a dataframe will the user's times for the day
#' @import httr
#' @import dplyr
#' @import purrr
#' @import stringr
#' @importFrom tidyr unnest
#' @export
get_toggl_day <- function(date, toggl_token, min = 5) {

  if (date > Sys.Date()) return(NULL)

  # get the workspaces, people can have more than one
  workspaces <- content(GET("https://www.toggl.com/api/v8/workspaces",
              authenticate(toggl_token,"api_token"),
              encode = "json")) %>%
    bind_rows() %>%
    select(name, id)

  # some workspaces can have more than one user, each user is assigned a uid,
  # so need to get that to make sure we don't pull another's hours
  uid <- content(GET("https://www.toggl.com/api/v8/me",
              authenticate(toggl_token,"api_token"),
              encode = "json")) %>%
    purrr::pluck("data") %>%
    purrr::pluck("id")

  pull_workspace <- function(id, uid, date) {

    url <-
      sprintf(
        "https://toggl.com/reports/api/v2/summary?user_ids=%s&workspace_id=%s&since=%s&until=%s&user_agent=api_test",
        uid,
        id,
        format(date, "%Y-%m-%d"),
        format(date, "%Y-%m-%d")
      )

    wp <- content(GET(url,
                      authenticate(toggl_token, "api_token"),
                      encode = "json")) %>%
      purrr::pluck("data") %>%
      jsonlite:::simplify(simplifyDataFrame = TRUE)

    if (is.null(wp)) return(NULL)

    # this chunk deals with strange project code formats
    data.frame(id = wp$id, wp$title, time = wp$time) %>%
      select(-one_of(c("color","hex_color", "client"))) %>%
      mutate(bill_code = str_extract_all(project, "[0-9]{6}") %>%
               map_chr(paste, collapse = ":"),
             tasks = str_extract_all(project, ":[0-9]{3}") %>%
               map_chr(paste, collapse = "") %>%
               map2_chr(str_length(.), ~substr(.x, 2, .y)),
             ratio = str_extract(project, "[0-9]{2}/[0-9]{2}.*?$"),
             hours = round(time/3600/1000, 2)) %>%
      as_data_frame
  }

  returned <- workspaces %>%
    tidyr::nest(id, .key = "id") %>%
    mutate(toggl_data = pmap(list(id), pull_workspace, uid, date)) %>%
    filter(toggl_data %>% map_lgl(~any(class(.) == "tbl")))

  if (nrow(returned) == 0) return(NULL)

  Sys.sleep(1)

  returned %>%
    tidyr::unnest(toggl_data) %>%
    transmute(
      bill_code,
      tasks,
      hours = round(ceiling(hours*60 %/% min)*min/60, 2),
      ratio,
      workspace = name)
}


#' Get weekly Toggl entries since date
#'
#' @param date the date to get the Toggl entries from. Should be class `Date`.
#' @param toggl_token the user's toggl token
#'
#' @description This method pull Toggl entries from the date provided to the
#' preceeding Sunday and then format them into a clean dataframe. Make sure
#' that your Toggl projects follow the Toggl project guidelines (see below)
#'
#' @return a data frame with billed hours.
#'
#' @details Make sure to follow the Toggl project format guidelines or this
#' function will not work and (hopefully) produce an error.
#' The required structure is as below:
#'
#' For single bill codes:
#' "Client Task 123456:001"
#' or
#' "Client Task 123456:001:002:003"
#' for multiple tasks, time is split evenly
#'
#' For multiple bill codes use the following structure:
#' "Client Task 123456:001&987654:002"
#' or
#' "Client Task 123456:001&987654:002 80/20"
#' or
#' "Client Task 123456:001&987654:002&345678:003 60/20/20"
#'
#' Ratios are optionally specified integers (no decimals) and do not need to sum 100.
#'
#' @import dplyr
#' @import purrr
#' @import stringr
#' @export
get_toggl_entries <- function(date = Sys.Date(), toggl_token) {

  # Get days on current time period
  days <- seq(get_Sun(date), date, by = "day")

  # get times from toggl for the days
  entries <- days %>%
    map(get_toggl_day, toggl_token) %>%
    set_names(days) %>%
    bind_rows(.id = "Date")

  if (is.null(entries)) stop("No time entires for ", date, ", no updates needed")

  # this chunk is for entries with a single bill code, one or more tasks
  single_bc <- entries %>%
    filter(!grepl(":", bill_code)) %>%
    transmute(
      Date,
      bill_code,
      task = as.list(str_split(tasks, ":")),
      hours = map2_dbl(task, hours, ~.y/length(.x))) %>%
    unnest(task)

  # now we need to treat the entries with multiple bill codes
  # sets a default of 50/50, 33/33/33, or 25/25/25/25 for 2, 3, and 4 codes.
  tryCatch({
    if (nrow(filter(entries, grepl(":", bill_code))) > 0) {
      all_bc <- entries %>%
        filter(grepl(":", bill_code)) %>%
        mutate(num = str_split(bill_code, ":") %>% map(length),
               ratio = case_when(
                 is.na(ratio) ~ map_chr(num, ~ paste0(rep(1/.*100, .), collapse = "/")),
                 TRUE         ~ ratio
               ),
               codes = str_split(bill_code, ":") %>%
                 map2(str_split(tasks, ":"), ~paste0(.x, ":", .y)),
               ratio = str_split(ratio, "/") %>% map(as.numeric),
               sum = map_dbl(ratio, sum),
               frac = map2(ratio, sum, `/`),
               hours = map2(frac, hours, `*`)) %>%
        unnest(codes, hours) %>%
        select(Date, codes, hours) %>%
        tidyr::separate(codes, into = c("bill_code", "task"), sep = ":") %>%
        # bind with the above and arrange
        bind_rows(single_bc)
      } else all_bc <- single_bc
  }, error = function(e) message("Multiple bill code not formatted correctly"))

  if (exists("all_bc")) {
    # checking parsing errors
    parse_error <- list()
    parse_error[["No bill or task code parsed"]] <- all_bc %>%
      filter(bill_code == "" & task == "")
    parse_error[["No bill code parsed"]] <- all_bc %>%
      filter(bill_code == "")
    parse_error[["No task code parsed"]] <- all_bc %>%
      filter(task == "")

    err <- parse_error %>%
      keep(~ nrow(.) > 0)

    err %>%
      walk2(names(.), function(.x, .y) {
        message(.y, " on date(s): ", paste(unique(.x$Date), collapse = ", "))
      })
  }

  if (length(err) > 0 | !exists("all_bc")) stop("Toggl project parser failure")

  all_bc %>%
    mutate(hours = round(hours, 2)) %>%
    group_by(Date, bill_code, task) %>%
    summarise(hours = sum(hours)) %>%
    arrange(Date, desc(bill_code), task) %>%
    ungroup
}
