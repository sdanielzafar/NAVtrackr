# NAVtrackr
A tool to move time entries from Toggl to PeopleSoft for Navigant Consulting.

# Getting started with NAVtrackr

Required:
- usage of Toggl for time keeping (https://toggl.com/toggl-desktop/)
- access to the Navigant RStudio cluster
- enough time to change over your time codes to the format needed for NAVtrackr

Nice to have:
- a little bit of coding experience
- Pushover installed on your phone (https://pushover.net/)

1. Get your toggl token at the bottom of this page (https://toggl.com/app/profile)
2. Decide if you want to use NotifyR (helpful for cron jobs). This app will let R text message you about whatever you want. In this case it will text you when the timesheets are saved. More importantly, if there are errors it will text you the error it got so you can problem-solve. Right now the only other way to reproduce the error would be to run the script in R. I highly recommend this as it is very easy to use and useful for other R projects where you want to be kept up to date for long-running R jobs. Plus it's $5 (less than a burrito) and lasts forever. If you decide to, install the app on your cellphone and get the ID.
3. Put these tokens into an `.Renviron` file. This will set your keys as environment variables when R loads. Doing this is a little tricky because the `.Renviron` file lives on your home directory on NFS so you can only access it through Rstudio or SSH.
  
      a. To write this file using Rstudio, start a new R session no associated with any project (it should say "Project: (None)") on the top right hand side. Then use the file explorer to see if there is a file called `.Renviron`. If so then open that up and edit it. Otherwise create a new R script and save it with the file name `.Renviron` (protip: can also do this with an SSH client using the commands `cd ~; vim .Renviron;`).
  
      b. Write the following lines into `.Renviron`
          
          TOGGL_TOKEN="<your toggl token>" 
          PUSHOVER_KEY="<your pushover key>"

      c. Save and exit. 
  
      d. (Optional) you can set the permissions on this file such that only you can read it, if you're into that sort of thing. Just SSH in and run the `chmod` command of your choice (probably `chmod 711 .Renviron`). If you want to be 100% NAVhip, use the new `NAVsecret` to do this :) 
  
4. Grab a beer and change over your toggl project codes to a consistent format that `NAVtrackr` can read. This is going to follow the format example cases:

        [some text] [billcode]:[task]

        [some text] [billcode]:[task1]:[task2]

        [some text] [billcode1]:[task1]&[billcode2]:[task2] 80/20                           (ratio specified)

        [some text] [billcode1]:[task1]&[billcode2]:[task2]                                 (ratio inferred as 50/50)

        [some text] [billcode1]:[task1]&[billcode2]:[task2]&[billcode3]:[task3] 50/25/25

        [some text] [billcode1]:[task1]&[billcode2]:[task2]&[billcode3]:[task3]             (ratio inferred as 33/33/33)

This part is crucial. For the code, see the function get_toggl_entries().

More details:

If there is a single bill code, but there is more than one task you have two options:

- Even time split: Use a colon to separate the task codes (`SRP PM 123456:001:002`)
- Assigned Ratios: Use the multiple bill code format (`SRP PM 123456:001&123456:002 60/40`)

Specified ratios must be integers, but do not need to add up to 100. Can be 1/3 instead of 25/75.

Here are bad bill codes:

    123456 task 001 Client X (wrong structure)
    Client X split between 365158:567 and 379342:321 (' and ' instead of '&')
    Client X savings 365158:567 & 379342:321 (spaces next to the '&')
    Client X PM 213283:789&213283:732&213283:721 0.3/0.3/0.3 (ratio is not an integer)

Here are good bill codes:

    Client X 123456:001
    Client X PM 123456:001:002:003:004
    Client X split between 365158:567&379342:321
    Client X savings 365158:567&379342:321
    Client X PM 213283:789&213283:732&213283:721 33/33/33

Now you are ready to run the scripts! 

5. Load up R (new session, so .Renviron loads) and type in `library(NAVtrackr)`
6. Run the code: `report_create()`
  - this will get your password from your NAVsecret vault OR pop up a dialog box where you can enter your password to log onto InsideNCI
  - This will automatically create a timesheet for the previous Saturday, but if you want to make it for the upcoming saturday, you can run this command instead: `report_create(period_end_date = get_Sat(prev = F))` 
7. If your toggl projects are in order this will result in "Timesheet Saved"
8. Log in to InsideNCI and take a look at your saved timesheet.

# Troubleshooting
`NAVtrackr` has pretty good error handling, but the one area that has issues is when you enter a time code that *can* be parsed but is not valid ([see issue 3](https://github.com/sdanielzafar/NAVtrackr/issues/3)). This results in the following error:

      Error in ts_fill_save(., entries, notify) :
        Timesheet error: Invalid value -- press the prompt button or hyperlink for a list of valid values (15,11)The value entered in
        the field does not match one of the allowable values.&nbsp; You can see the allowable values by pressing the Prompt button or 
        hyperlink.<a class=

When this happens to me I usually just go into InsideNCI and manually try out any new codes in a new timesheet to see if they exist. 
