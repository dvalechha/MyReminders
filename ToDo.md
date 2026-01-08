Feature List:

## General
1. Rename reference to Custos from MyReminder. Ideal if we can use create a property file and refer the app name from there. The same propeerty file, can be used latter for other hard coded values or showing Exception msgs -- Done

2. How to navigate back to app home, if I have move further in the app. IOS/Andoid back is always an option but shouldn't there be an option on the app control, like a home or something ? -- Done

3. For sign up confirmation and pwd reset emails being sent , how can we customize it to reflect that the emails are from Custos and not from SupaBase ? I dont want to reveal my server technology to users.

## Login
1. If user has entered an email on the main screen, carry that fwd on the pwd reset screen -- Done
2. IOS: 
    2.1. Allow user to save creds on keychain -- Done
    2.2. Upon account deletion/pwd change, keychain should be updated accordingly -- Done
3. Android:
  3.1. TBD
4. Build criteria logic for pwd strength -- Done
5. Build eye for hide/show password -- Done
6. We have added a Display name on the SignUp page, I was wondering if we can use the display name as the Icon for settings instead of the default 3 bar style settings icon ? -- Done

## Sign Up screen
1. Build eye for hide/show password on password and confirm-password fields -- Done

## Full Agenda:
- Build the view
- Should allow control back to home

## Post-Completion Cleanup:
1. After password reset, when the flow is going back to main Login screen, somehow we need to hide the Logout flash screen
2. After clicking on the email link to reset pwd, the control is back on the app but there is a delay for approx 2-3 secs before loading the pwd screen
3. Upon Logout from Subs, Tasks and Appointment screen, there is a small transition back to Home and the Logout. Can this be improved by not showing Home View for a split second ?
4. Login screen seems slow sometimes
5. Logging statement (DEV vs Prod)
6. The confirmation emails on sign-up and pwd reset, are coming from SupaBase, which is expected. Is it possible to make it come from the app "Custos" ?

Bugs:
- Home button brings user back to the same view he was last one

## Pro Features
1. LLM Integration for advanced Natural Language Processing.
2. Integration with Google Calendar for appointment management.