
# library(rvest)
# library(notifyR)
#
# # start session
# legacy <- html_session("http://legacy.insidenci.com/web/appdir.nsf")
#
# # fill out the login form
# login_form <- legacy %>%
#   html_node("form[name=_DominoForm]") %>%
#   html_form() %>%
#   set_values(
#     Username = "dzafar",
#     Password = "Tummygoat165!"
#     )
#
# # hack the submit form
# fake_submit_button <- list(name = "fakesubmit",
#                            type = "submit",
#                            value = NULL,
#                            checked = NULL,
#                            disabled = NULL,
#                            readonly = NULL,
#                            required = FALSE)
# attr(fake_submit_button, "class") <- "input"
#
# login_form[["fields"]][["submit"]] <- fake_submit_button
#
# # login
# logged_in <- legacy %>% submit_form(form = login_form, submit = "submit")
#
# # jump to the projection-entry piece
# input_proj <- logged_in %>%
#   jump_to("http://legacy.insidenci.com/nci/billproj.nsf/ByLastName/D170B2FB086F73DF86257FE1003C9885/?OpenDocument")
#
# # fill in the new value
# proj_form <- input_proj %>%
#   html_node("form[name=_BillProj]") %>%
#   html_form() %>%
#   set_values(
#     'B12' = 30
#   )
#
# # hack and submit the new entry
# proj_form[["fields"]][["submit"]] <- fake_submit_button
# submitted <- submit_form(input_proj, proj_form)
#
# notifyR::send_push(user = "uwgfo3jdcsfw7s9vuix824t8ky4d2m", "Legacy Util Updated")
