# NAVtrackr
A tool to move time entries from Toggl to PeopleSoft for Navigant Consulting

# Getting started with NAVtrackr

Get your toggl token at the bottom of this page (https://toggl.com/app/profile)
Decide if you want to use NotifyR (helpful for cron jobs). This app will let R text message you about whatever you want. In this case it will text you when the timesheets are saved. More importantly, if there are errors it will text you the error it got so you can problem-solve. Right now the only other way to reproduce the error would be to run the script in R. I highly recommend this as it is very easy to use and useful for other R projects where you want to be kept up to date for long-running R jobs. Plus it's $5 (less than a burrito) and lasts forever. If you decide to, install the app on your cell and get the ID.
Put these tokens into an .Renviron file. This will set your keys as environment variables when R loads. To do this:
Make a text file called .Renviron on your rstudio_home folder if it does not already exist. The path should beY:\rstudio_home\<your username>\.Renviron
Write the following lines: TOGGL_TOKEN="<your toggl token>" PUSHOVER_KEY="<your pushover key>"
Save and exit. Optionally you can set the permissions on this file such that only you can read it, if you're into that sort of thing. Just go to the file properties >> Security >> Advanced >> Disable Inheritance and add yourself in the Permission entries.
Grab a beer and change over your toggl project codes to a consistent format that NAVtrackr can read. This is going to follow the format example cases:
[some text] [billcode]:[task] 

[some text] [billcode]:[task1]:[task2]

[some text] [billcode1]:[task1]&[billcode2]:[task2] 80/20                                               (ratio specified)

[some text] [billcode1]:[task1]&[billcode2]:[task2]                                                           (ratio inferred as 50/50)

[some text] [billcode1]:[task1]&[billcode2]:[task2]&[billcode3]:[task3] 50/25/25

[some text] [billcode1]:[task1]&[billcode2]:[task2]&[billcode3]:[task3]                       (ratio inferred as 33/33/33)

This part is crucial. For the code, see the function get_toggl_entries().

More details:

If there is a single bill code, but there is more than one task you have two options:

Even time split: Use a colon to separate the task codes (SRP PM 123456:001:002)
Assigned Ratios: Use the multiple bill code format (SRP PM 123456:001&123456:002 60/40)
Specified ratios must be integers, but do not need to add up to 100. Can be 1/3 instead of 25/75.

Here are bad bill codes:

123456 task 001 ComEd (wrong structure)

TEP split between 365158:567 and 379342:321 (' and ' instead of '&')

TEP savings 365158:567 & 379342:321 (spaces next to the '&')

Unisource PM 213283:789&213283:732&213283:721 0.3/0.3/0.3 (ratio is not an integer)

Here are good bill codes:

ComEd 123456:001

ComEd PM 123456:001:002:003:004

TEP split between 365158:567&379342:321

TEP savings 365158:567&379342:321

Unisource PM 213283:789&213283:732&213283:721 33/33/33

Now you are ready to run the scripts! Load up R (new session, so .Renviron loads) and use library(NAVtrackr)
Run the code: report_create([your NAV username], [your NAV password]) (for the previous week, you can run it today for the incomplete next week with arg period_end_date = get_Sat(prev = F))
If your toggl projects are in order this will result in "Timesheet Saved"
Log in to insidenci and take a look at your saved timesheet.
