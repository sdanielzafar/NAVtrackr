% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/timesheet_helpers.R
\name{ts_fill_save}
\alias{ts_fill_save}
\title{Fill and save a timesheet}
\usage{
ts_fill_save(session, entries, notify = NULL)
}
\arguments{
\item{session}{the rvest html session at the timesheet}

\item{entries}{the formatted entries, from `get_toggl_entries`}

\item{notify}{the notify ID, optional}
}
\value{
an rvest html session
}
\description{
Fill and save a timesheet
}
