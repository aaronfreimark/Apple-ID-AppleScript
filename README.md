Batch Apple ID Creator
----------------------

[![Stories in Backlog](https://badge.waffle.io/brandonusher/Apple-ID-AppleScript.svg?label=Backlog&title=Backlog)](http://waffle.io/brandonusher/Apple-ID-AppleScript)
[![Stories in Ready](https://badge.waffle.io/brandonusher/apple-id-applescript.svg?label=Ready&title=Ready)](http://waffle.io/brandonusher/apple-id-applescript)
[![Stories in Progress](https://badge.waffle.io/brandonusher/apple-id-applescript.svg?label=In%20Progress&title=In%20Progress)](http://waffle.io/brandonusher/apple-id-applescript)

If possible, please donate as I spend my free time fixing and upkeeping this script.

BTC: 12afnPSYfnbzV8wgu6zv69j9eMTtV2GktC

### Purpose & Features

Deploying a great quantity of iOS devices means creating a great
quantity of Apple IDs. This script allows automated Apple ID creation
from a spreadsheet. Apple IDs are created without a credit card, which
is great for many deployments. There is a “dry run” feature to test the
script without actually creating the Apple ID.

### Requirements

-   **IMPORTANT**: Apple uses a velocity check to prevent too many Apple
    IDs from a single IP address. You must contact your Apple business
    representative to request that your IP address is whitelisted for a
    short time.
-   Being [AppleScript][], this runs only on Macs.
-   [iTunes 11.2.2][] is currently required. Future versions may break the
    script.
-   [UI Scripting][] allows us to script otherwise non-scriptbale
    interfaces. Turn this on in System Preferences \> Accessibility and
    check “Enable access for assistive devices.”
-   Apple has [strong password requirements][]. Account creation will
    fail if the passwords are too weak.

### Instructions

A template CSV file is included. Create csv file. Then run the script.


#### CSV file tips

* keep the column headers,
* fill out all columns, 
* use comma as a column separator,
* don't leave empty lines,
* use MS Excel or Numbers to create file,
* don't include the "- " in front of the security questions,
* leave last column blank,
* for the state just use the two letter initial, ie "NY" not "NY - New York" as its listed in iTunes,
* for the month in birth date use month names with capital first letter, ie "January" for january,


### Security Questions

As of iTunes 10.6.1 Apple has required three security questions. The
Batch Apple ID Creator allows you to choose the questions from the list
below. Each question should be copied into the appropriate spreadsheet
column (Security Question 1, 2 or 3) exactly as typed below.

#### Security Question 1

-   What is the first name of your best friend in high school?
-   What was the name of your first pet?
-   What was the first thing you learned to cook?
-   What was the first film you saw in the theater?
-   Where did you go the first time you flew on a plane?
-   What is the last name of your favorite elementary school teacher?

#### Security Question 2

-   What is your dream job?
-   What is your favorite children's book?
-   What was the model of your first car?
-   What was your childhood nickname?
-   Who was your favorite film star or character in school?
-   Who was your favorite singer or band in high school?

#### Security Question 3

-   In what city did your parents meet?
-   What was the first name of your first boss?
-   What is the name of the street where you grew up?
-   What is the name of the first beach you visited?
-   What was the first album that you purchased?
-   What is the name of your favorite sports team?

### Known Bugs

Errors are not handled gracefully. Although some errors are recoverable,
if the script stops, it loses track of its progress. Edit the
spreadsheet to continue.

At the end of this script, Apple will send a verification email to the
Apple ID. To complete verification, click the link in the message, then
re-enter the account address and password.

### Download

The files are downloadable from GitHub:
https://github.com/brandonusher/Apple-ID-AppleScript Feel free to fork
and improve.

### Acknowledgments

This script was originally created by Enterprise iOS user [Greg
Moore][], who works for Hope Public Schools in Hope, Arkansas. [Aaron
Freimark][] then updated the script to work with iTunes 10.6.1 and the
multiple recovery questions. Discuss on [EnterpriseiOS.com][]. This
script or derivatives must not be sold. If you make it better, please
give back to the community that brought it to you.

The base for this script was created by [Aaron Freimark][1]

Updated version brought to you by [Brandon Usher][]

  [AppleScript]: http://developer.apple.com/applescript/
  [iTunes 11.2.2]: http://www.apple.com/itunes/
  [UI Scripting]: http://www.mactech.com/articles/mactech/Vol.21/21.06/UserInterfaceScripting/index.html
  [strong password requirements]: http://support.apple.com/kb/TS1728
  [Greg Moore]: http://www.enterpriseios.com/users/Eight_Quarter_Bit
  [Aaron Freimark]: http://www.enterpriseios.com/users/Aaron_Freimark
  [EnterpriseiOS.com]: http://www.enterpriseios.com/wiki/Batch_Apple_ID_Generator
  [1]: https://github.com/aaronfreimark/Apple-ID-AppleScript
  [Brandon Usher]: https://github.com/brandonusher
