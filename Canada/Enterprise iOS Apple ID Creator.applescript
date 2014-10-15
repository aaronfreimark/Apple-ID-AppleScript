(*
code to find all elements on iTunes page, for use with "verifyPage()"

tell application "System Events"
	set elementCount to count of every UI element of UI element 1 of scroll area 3 of window 1 of application process "iTunes"
	set everyElement to every UI element of UI element 1 of scroll area 3 of window 1 of application process "iTunes"

	set everyProperty to {}
	repeat with loopCounter from 1 to (count of items in everyElement)
		try
			set everyProperty to everyProperty & 1
			set item loopCounter of everyProperty to (properties of item loopCounter of everyElement)
		end try
	end repeat

	set everyTitle to {}
	repeat with loopCounter from 1 to (count of items in everyProperty)
		set everyTitle to everyTitle & ""
		try
			set item loopCounter of everyTitle to (title of item loopCounter of everyProperty)
		end try
	end repeat

end tell

*)

--TO DO:

--write itunes running check
--write file output section for account status column
--write check for account status of "completed" or "skipped"

--Global Vars

--Used for storing a list of encountered errors. Written to by various handlers, read by checkForErrors()
global errorList
set errorList to {}

--Used for controlling the running or abortion of the script. Handler will run as long as scriptAction is "Continue". Can also be set to "Abort" to end script, or "Skip User" to skip an individual user.
global scriptAction
set scriptAction to "Continue"

--Store the current user number (based off line number in CSV file)
global currentUser
set currentUserNumber to 0

--Used for completing every step in the process, except actually creating the Apple ID. Also Pauses the script at various locations so the user can verify everything is working properly.
property dryRun : true

--Used to store the file location of the iBooks "App Page Shortcut". Updated dynamically on run to reference a child folder of the .app bundle (Yes, I know this isn't kosher)
-- AF 2012-05-14 Open location instead of .inetloc
property ibooksLinkLocation : "itms://itunes.apple.com/us/app/ibooks/id364709193?mt=8"

--Master delay timer for slowing the script down at specified sections. Usefull for tweaking the entire script's speed
property masterDelay : 1

--Maximum time (in seconds) the script will wait for a page to load before giving up and throwing an error
property netDelay : 30

--Used at locations in script that will be vulnerable to slow processing. Multiplied by master delay. Tweak for slow machines. May be added to Net Delay.
property processDelay : 1

--How often should the script check that something has loaded/is ready
property checkFrequency : 0.25

--Used to store supported iTunes versions
property supportedItunesVersions : {"11.2.2", "11.3", "11.3.1", "11.4"}

--Used for checking if iTunes is loading a page
property itunesAccessingString : "Accessing iTunes Store…"

(*
	Email
	Password
	Secret Question 1
	Secret Answer 1
	Secret Question 2
	Secret Answer 2
	Secret Question 3
	Secret Answer 3
	Month Of Birth
	Day Of Birth
	Year Of Birth
	First Name
	Last Name
	Address Street
	Address City
	Address State
	Address Zip
	Phone Area Code
	Phone Number
	Account Status
*)

--Properties for storing possible headers to check the source CSV file for. Source file will be checked for each of the items to locate the correct columns
property emailHeaders : {"Email", "Email Address"}
property passwordHeaders : {"Password", "Pass"}
property secretQuestion1Headers : {"Secret Question 1"}
property secretAnswer1Headers : {"Secret Answer 1"}
property secretQuestion2Headers : {"Secret Question 2"}
property secretAnswer2Headers : {"Secret Answer 2"}
property secretQuestion3Headers : {"Secret Question 3"}
property secretAnswer3Headers : {"Secret Answer 3"}
property monthOfBirthHeaders : {"Month", "Birth Month", "Month of Birth"}
property dayOfBirthHeaders : {"Day", "Birth Day", "Day Of Birth"}
property yearOfBirthHeaders : {"Year", "Birth Year", "Year Of Birth"}
property firstNameHeaders : {"First Name", "First", "fname"}
property lastNameHeaders : {"Last Name", "Last", "lname"}
property addressStreetHeaders : {"Street", "Street Address", "Address Street"}
property addressCityHeaders : {"City", "Address City"}
property addressStateHeaders : {"State", "Address State"}
property addressZipHeaders : {"Zip Code", "Zip", "Address Zip"}
property phoneAreaCodeHeaders : {"Area Code", "Phone Area Code"}
property phoneNumberHeaders : {"Phone Number", "Phone"}
property rescueEmailHeaders : {"Rescue Email (Optional)", "Rescue Email"}
property accountStatusHeaders : {"Account Status"} --Used to keep track of what acounts have been created


set userDroppedFile to false

--Check to see if a file was dropped on this script
on open droppedFile
	set userDroppedFile to true
	MainMagic(userDroppedFile, droppedFile)
end open

--Launch the script in interactive mode if no file was dropped (if file was dropped on script, this will never be run, because of the "on open" above)
set droppedFile to ""
MainMagic(userDroppedFile, droppedFile)

on MainMagic(userDroppedFile, droppedFile)
	--CHECK ITUNES SUPPORT-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------CHECK ITUNES SUPPORT--
	
	set itunesVersion to version of application "iTunes"
	set itunesVersionIsSupported to false
	
	repeat with versionCheckLoopCounter from 1 to (count of items in supportedItunesVersions)
		if item versionCheckLoopCounter of supportedItunesVersions is equal to itunesVersion then
			set itunesVersionIsSupported to true
			exit repeat
		end if
	end repeat
	
	if itunesVersionIsSupported is false then
		set scriptAction to button returned of (display dialog "iTunes is at version " & itunesVersion & return & return & "It is unknown if this version of iTunes will work with this script." & return & return & "You may abort now, or try running the script anyway." buttons {"Abort", "Continue"} default button "Abort") as text
	end if
	
	if scriptAction is "Continue" then
		--LOAD USERS FILE-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------LOAD USERS FILE--
		
		set usersFile to loadUsersFile(userDroppedFile, droppedFile) --Load the users file. Returns a list of columns from the source file
		
		if scriptAction is "Continue" then
			--Split out header information from each of the columns
			set headers to {}
			
			repeat with headerRemoverLoopCounter from 1 to (count of items in usersFile)
				
				set headers to headers & "" --Add an empty item to headers
				
				set item headerRemoverLoopCounter of headers to item 1 of item headerRemoverLoopCounter of usersFile --Save the header from the column
				
				set item headerRemoverLoopCounter of usersFile to (items 2 thru (count of items in item headerRemoverLoopCounter of usersFile) of item headerRemoverLoopCounter of usersFile) --Remove the header from the column
				
			end repeat
			
			set userCount to (count of items in item 1 of usersFile) --Counts the number of users
			
			--seperated column contents (not really necessarry, but it makes everything else a whole lot more readable)
			set appleIdEmailColumnContents to item 1 of usersFile
			set appleIdPasswordColumnContents to item 2 of usersFile
			
			set appleIdSecretQuestion1ColumnContents to item 3 of usersFile
			set appleIdSecretAnswer1ColumnContents to item 4 of usersFile
			set appleIdSecretQuestion2ColumnContents to item 5 of usersFile
			set appleIdSecretAnswer2ColumnContents to item 6 of usersFile
			set appleIdSecretQuestion3ColumnContents to item 7 of usersFile
			set appleIdSecretAnswer3ColumnContents to item 8 of usersFile
			set monthOfBirthColumnContents to item 9 of usersFile
			set dayOfBirthColumnContents to item 10 of usersFile
			set yearOfBirthColumnContents to item 11 of usersFile
			
			set userFirstNameColumnContents to item 12 of usersFile
			set userLastNameColumnContents to item 13 of usersFile
			set addressStreetColumnContents to item 14 of usersFile
			set addressCityColumnContents to item 15 of usersFile
			set addressStateColumnContents to item 16 of usersFile
			set addressZipColumnContents to item 17 of usersFile
			set phoneAreaCodeColumnContents to item 18 of usersFile
			set phoneNumberColumnContents to item 19 of usersFile
			set appleIdRescueColumnContents to item 20 of usersFile
			set accountStatusColumnContents to item 21 of usersFile
			
			
			--PREP-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------PREP--
			
			--Ask user if they want to perform a dry run, and give them a chance to cancel
			set scriptRunMode to button returned of (display dialog "Would you like to preform a ''dry run'' of the script?" & return & return & "A ''dry run'' will run through every step, EXCEPT actually creating the Apple IDs." buttons {"Actually Create Apple IDs", "Dry Run", "Cancel"}) as text
			if scriptRunMode is "Actually Create Apple IDs" then set dryRun to false
			if scriptRunMode is "Dry Run" then set dryRun to true
			if scriptRunMode is "Cancel" then set scriptAction to "Abort"
			
			--CREATE IDS-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------CREATE IDS--
			if scriptAction is not "Abort" then
				set accountStatusSetByCurrentRun to {}
				set currentUserNumber to 0
				repeat with loopCounter from 1 to userCount
					
					--Increment our current user, just so other handlers can know what user we are on
					set currentUserNumber to currentUserNumber + 1
					
					--Get a single user's information from the column contents
					set appleIdEmail to item loopCounter of appleIdEmailColumnContents
					set appleIdPassword to item loopCounter of appleIdPasswordColumnContents
					
					set appleIdSecretQuestion1 to item loopCounter of appleIdSecretQuestion1ColumnContents
					set appleIdSecretAnswer1 to item loopCounter of appleIdSecretAnswer1ColumnContents
					set appleIdSecretQuestion2 to item loopCounter of appleIdSecretQuestion2ColumnContents
					set appleIdSecretAnswer2 to item loopCounter of appleIdSecretAnswer2ColumnContents
					set appleIdSecretQuestion3 to item loopCounter of appleIdSecretQuestion3ColumnContents
					set appleIdSecretAnswer3 to item loopCounter of appleIdSecretAnswer3ColumnContents
					set rescueEmail to item loopCounter of appleIdRescueColumnContents
					set monthOfBirth to item loopCounter of monthOfBirthColumnContents
					set dayOfBirth to item loopCounter of dayOfBirthColumnContents
					set yearOfBirth to item loopCounter of yearOfBirthColumnContents
					
					set userFirstName to item loopCounter of userFirstNameColumnContents
					set userLastName to item loopCounter of userLastNameColumnContents
					set addressStreet to item loopCounter of addressStreetColumnContents
					set addressCity to item loopCounter of addressCityColumnContents
					set addressState to item loopCounter of addressStateColumnContents
					set addressZip to item loopCounter of addressZipColumnContents
					set phoneAreaCode to item loopCounter of phoneAreaCodeColumnContents
					set phoneNumber to item loopCounter of phoneNumberColumnContents
					set accountStatus to item loopCounter of accountStatusColumnContents
					
					delay masterDelay
					
					SignOutItunesAccount() ---------------------------------------------------------------------------------------------------------------------------------------------------------Signout Apple ID that is currently signed in (if any)
					
					--delay 10
					
					installIbooks() ---------------------------------------------------------------------------------------------------------------------------------------------------------------------Go to the iBooks App page location to kick off Apple ID creation with no payment information
					
					delay 1 --Fix so iTunes is properly tested for, instead of just manually delaying
					
					repeat
						set lcdStatus to GetItunesStatusUntillLcd("Does Not Match", itunesAccessingString, 4, "times. Check for:", 120, "intervals of", 0.25, "seconds") ------------------------Wait for iTunes to open (if closed) and the iBooks page to load
						if lcdStatus is "Matched" then exit repeat
						delay masterDelay
					end repeat
					
					
					CheckForErrors() ------------------------------------------------------------------------------------------------------------------------------------------------------------------Checks for errors that may have been thrown by previous handler
					if scriptAction is "Abort" then exit repeat -----------------------------------------------------------------------------------------------------------------------------------If an error was detected and the user chose to abort, then end the script
					
					ClickCreateAppleIDButton() -----------------------------------------------------------------------------------------------------------------------------------------------------Click "create Apple ID" button on pop-up window
					ClickContinueOnPageOne() ------------------------------------------------------------------------------------------------------------------------------------------------------Click "Continue" on the page with the title "Welcome to the iTunes Store"
					CheckForErrors() ------------------------------------------------------------------------------------------------------------------------------------------------------------------Checks for errors that may have been thrown by previous handler
					if scriptAction is "Abort" then exit repeat -----------------------------------------------------------------------------------------------------------------------------------If an error was detected and the user chose to abort, then end the script
					
					AgreeToTerms() -------------------------------------------------------------------------------------------------------------------------------------------------------------------Check the "I have read and agreed" box and then the "Agree" button
					CheckForErrors() ------------------------------------------------------------------------------------------------------------------------------------------------------------------Checks for errors that may have been thrown by previous handler
					if scriptAction is "Abort" then exit repeat -----------------------------------------------------------------------------------------------------------------------------------If an error was detected and the user chose to abort, then end the script
					
					log {"Creating ", appleIdEmail}
					
					ProvideAppleIdDetails(appleIdEmail, appleIdPassword, appleIdSecretQuestion1, appleIdSecretAnswer1, appleIdSecretQuestion2, appleIdSecretAnswer2, appleIdSecretQuestion3, appleIdSecretAnswer3, rescueEmail, monthOfBirth, dayOfBirth, yearOfBirth) ----------------Fills the first page of apple ID details. Birth Month is full text, like "January". Birth Day and Birth Year are numeric. Birth Year is 4 digit
					CheckForErrors() ------------------------------------------------------------------------------------------------------------------------------------------------------------------Checks for errors that may have been thrown by previous handler
					if scriptAction is "Abort" then exit repeat -----------------------------------------------------------------------------------------------------------------------------------If an error was detected and the user chose to abort, then end the script
					
					ProvidePaymentDetails(userFirstName, userLastName, addressStreet, addressCity, addressState, addressZip, phoneAreaCode, phoneNumber) -------------Fill payment details, without credit card info
					CheckForErrors() ------------------------------------------------------------------------------------------------------------------------------------------------------------------Checks for errors that may have been thrown by previous handler
					if scriptAction is "Abort" then exit repeat -----------------------------------------------------------------------------------------------------------------------------------If an error was detected and the user chose to abort, then end the script
					
					if scriptAction is "Continue" then ----------------------------------------------------------------------------------------------------------------------------------------------If user was successfully created...
						set accountStatusSetByCurrentRun to accountStatusSetByCurrentRun & ""
						set item loopCounter of accountStatusSetByCurrentRun to "Created" ----------------------------------------------------------------------------------------------Mark user as created
					end if
					
					if scriptAction is "Skip User" then ----------------------------------------------------------------------------------------------------------------------------------------------If a user was skipped...
						set accountStatusSetByCurrentRun to accountStatusSetByCurrentRun & ""
						set item loopCounter of accountStatusSetByCurrentRun to "Skipped" ----------------------------------------------------------------------------------------------Mark user as "Skipped"
						set scriptAction to "Continue" ----------------------------------------------------------------------------------------------------------------------------------------------Set the Script back to "Continue" mode
					end if
					
					if scriptAction is "Stop" then exit repeat
					
				end repeat
				
				--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------Display dialog boxes that confirm the exit status of the script
				
				activate
				if scriptAction is "Abort" then display dialog "Script was aborted" buttons {"OK"}
				if scriptAction is "Stop" then display dialog "Dry run completed" buttons {"OK"}
				if scriptAction is "Continue" then display dialog "Script Completed Successfully" buttons {"OK"}
				
				
				--Fix for multiple positive outcomes
				if itunesVersionIsSupported is false then --If the script was run against an unsupported version of iTunes...
					if scriptAction is "Continue" then --And it wasn't aborted...
						if button returned of (display dialog "Would you like to add iTunes Version " & itunesVersion & " to the list of supported iTunes versions?" buttons {"Yes", "No"} default button "No") is "Yes" then --...then ask the user if they want to add the current version of iTunes to the supported versions list
							set supportedItunesVersions to supportedItunesVersions & itunesVersion
							display dialog "iTunes version " & itunesVersion & " succesfully added to list of supported versions."
						end if
					end if
				end if
			end if
		end if
	end if
	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------End main function
	
end MainMagic

(*_________________________________________________________________________________________________________________________________________*)

--FUNCTIONS-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------FUNCTIONS--

on loadUsersFile(userDroppedFile, chosenFile)
	if userDroppedFile is false then set chosenFile to "Choose"
	set readFile to ReadCsvFile(chosenFile) --Open the CSV file and read its raw contents
	set readFile to ParseCsvFile(readFile) --Parse the values into a list of lists
	
	set listOfColumnsToFind to {"Email", "Password", "Secret Question 1", "Secret Answer 1", "Secret Question 2", "Secret Answer 2", "Secret Question 3", "Secret Answer 3", "Month Of Birth", "Day Of Birth", "Year Of Birth", "First Name", "Last Name", "Address Street", "Address City", "Address State", "Address Zip", "Phone Area Code", "Phone Number", "Rescue Email (Optional)", "Account Status"}
	
	--Locate the columns in the file
	set findResults to {}
	repeat with columnFindLoopCounter from 1 to (count of items in listOfColumnsToFind)
		set findResults to findResults & ""
		set item columnFindLoopCounter of findResults to findColumn((item columnFindLoopCounter of listOfColumnsToFind), readFile) --FindColumn Returns a list of two items. The first item is either "Found" or "Not Found". The second item (if the item was "found") will be a numerical reference to the column that was found, based on its position in the source file
	end repeat
	
	--Verify that the columns were found, and resolve any missing columns
	repeat with columnVerifyLoopCounter from 1 to (count of items in findResults)
		if scriptAction is "Continue" then
			if item 1 of item columnVerifyLoopCounter of findResults is "Found" then --Check if the current item to be located was found
				set item columnVerifyLoopCounter of findResults to item 2 of item columnVerifyLoopCounter of findResults --Remove the verification information and set the item to just the column number
			else --If a column is missing
				--Ask the user what they would like to do
				set missingColumnResolution to button returned of (display dialog "The script was unable to locate the " & item columnVerifyLoopCounter of listOfColumnsToFind & " column. The script cannot continue without this information." & return & return & "What would you like to do?" buttons {"Abort Script", "Manually Locate Column"}) as text
				
				--If the user chose to abort
				if missingColumnResolution is "Abort Script" then set scriptAction to "Abort"
				
				--If the user chose to manually locate the column
				if missingColumnResolution is "Manually Locate Column" then
					--Create a list of the columns to choose from, complete with a number at the beginning of each item in the list
					set columnList to {}
					repeat with createColumnListLoopCounter from 1 to (count of items in readFile) --Each loop will create an entry in the list of choices corresponding to the first row of a column in the original source file
						set columnList to columnList & ((createColumnListLoopCounter as text) & " " & item 1 of item createColumnListLoopCounter of readFile) --Dynamically add an incremented number and space to the beginning of each item in the list of choices, and then add the contents of the first row of the column chosen for this loop
					end repeat
					
					--Present the list of column choices to the user
					set listChoice to choose from list columnList with prompt "Which of the items below is an example of ''" & item columnVerifyLoopCounter of listOfColumnsToFind & "''" --Ask user which of the choices matches what we are looking for
					if listChoice is false then --If the user clicked cancel in the list selection dialog box
						set scriptAction to "Abort"
					else
						set item columnVerifyLoopCounter of findResults to (the first word of listChoice as number) --Set the currently evaluating entry of findResults to the column NUMBER (determined by getting the first word of list choice, which corresponds to column numbers) the user selected
					end if
				end if
				
			end if
		else --If an abort has been thrown
			exit repeat
		end if
	end repeat
	
	--Retrieve the contents of the found columns
	if scriptAction is "Continue" then
		set fileContents to {}
		repeat with contentRetrievalLoopCounter from 1 to (count of items in findResults)
			set fileContents to fileContents & ""
			set item contentRetrievalLoopCounter of fileContents to getColumnContents((item contentRetrievalLoopCounter of findResults), readFile)
		end repeat
	end if
	
	if scriptAction is "Continue" then
		return fileContents
	end if
	
end loadUsersFile

on findColumn(columnToFind, fileContents)
	
	--BEGIN FIND EMAIL																							BEGIN FIND EMAIL
	if columnToFind is "Email" then
		return findInList(emailHeaders, fileContents)
	end if
	
	--BEGIN FIND PASSWORD																						BEGIN FIND PASSWORD
	if columnToFind is "Password" then
		return findInList(passwordHeaders, fileContents)
	end if
	
	--BEGIN FIND SECRET QUESTION																				BEGIN FIND SECRET QUESTION
	if columnToFind is "Secret Question 1" then
		return findInList(secretQuestion1Headers, fileContents)
	end if
	
	--BEGIN FIND SECRET ANSWER																					BEGIN FIND SECRET ANSWER
	if columnToFind is "Secret Answer 1" then
		return findInList(secretAnswer1Headers, fileContents)
	end if
	
	--BEGIN FIND SECRET QUESTION 2																				BEGIN FIND SECRET QUESTION 2
	if columnToFind is "Secret Question 2" then
		return findInList(secretQuestion2Headers, fileContents)
	end if
	
	--BEGIN FIND SECRET ANSWER 2																					BEGIN FIND SECRET ANSWER 2
	if columnToFind is "Secret Answer 2" then
		return findInList(secretAnswer2Headers, fileContents)
	end if
	
	--BEGIN FIND SECRET QUESTION  3																				BEGIN FIND SECRET QUESTION 3
	if columnToFind is "Secret Question 3" then
		return findInList(secretQuestion3Headers, fileContents)
	end if
	
	--BEGIN FIND SECRET ANSWER 3																					BEGIN FIND SECRET ANSWER 3
	if columnToFind is "Secret Answer 3" then
		return findInList(secretAnswer3Headers, fileContents)
	end if
	
	--BEGIN FIND BIRTH MONTH 																					BEGIN FIND BIRTH MONTH
	if columnToFind is "Month Of Birth" then
		return findInList(monthOfBirthHeaders, fileContents)
	end if
	
	--BEGIN FIND BIRTH DAY 																						BEGIN FIND BIRTH DAY
	if columnToFind is "Day Of Birth" then
		return findInList(dayOfBirthHeaders, fileContents)
	end if
	
	--BEGIN FIND BIRTH YEAR 																						BEGIN FIND BIRTH YEAR
	if columnToFind is "Year Of Birth" then
		return findInList(yearOfBirthHeaders, fileContents)
	end if
	
	--BEGIN FIND LAST NAME																						BEGIN FIND LAST NAME
	if columnToFind is "First Name" then
		return findInList(firstNameHeaders, fileContents)
	end if
	
	--BEGIN FIND LAST NAME																						BEGIN FIND LAST NAME
	if columnToFind is "Last Name" then
		return findInList(lastNameHeaders, fileContents)
	end if
	
	--BEGIN FIND ADDRESS STREET																				BEGIN FIND ADDRESS STREET
	if columnToFind is "Address Street" then
		return findInList(addressStreetHeaders, fileContents)
	end if
	
	--BEGIN FIND ADDRESS CITY																					BEGIN FIND ADDRESS CITY
	if columnToFind is "Address City" then
		return findInList(addressCityHeaders, fileContents)
	end if
	
	--BEGIN FIND ADDRESS STATE																					BEGIN FIND ADDRESS STATE
	if columnToFind is "Address State" then
		return findInList(addressStateHeaders, fileContents)
	end if
	
	--BEGIN FIND ADDRESS ZIP																					BEGIN FIND ADDRESS ZIP
	if columnToFind is "Address Zip" then
		return findInList(addressZipHeaders, fileContents)
	end if
	
	--BEGIN FIND PHONE AREA CODE																				BEGIN FIND PHONE AREA CODE
	if columnToFind is "Phone Area Code" then
		return findInList(phoneAreaCodeHeaders, fileContents)
	end if
	
	--BEGIN FIND PHONE NUMBER																					BEGIN FIND PHONE NUMBER
	if columnToFind is "Phone Number" then
		return findInList(phoneNumberHeaders, fileContents)
	end if
	
	--BEGIN FIND RESCUE EMAIL																					BEGIN FIND RESCUE EMAIL
	if columnToFind is "Rescue Email (Optional)" then
		return findInList(rescueEmailHeaders, fileContents)
	end if
	
	--BEGIN FIND ACCOUNT STATUS																				BEGIN FIND ACCOUNT STATUS
	if columnToFind is "Account Status" then
		return findInList(accountStatusHeaders, fileContents)
	end if
	
end findColumn

-----------------------------------------

on findInList(matchList, listContents)
	try
		set findState to "Not Found"
		set findLocation to 0
		repeat with columnItemLoopCounter from 1 to (count of items of (item 1 of listContents))
			repeat with testForMatchLoopCounter from 1 to (count of matchList)
				if item columnItemLoopCounter of (item 1 of listContents) is item testForMatchLoopCounter of matchList then
					set findState to "Found"
					set findLocation to columnItemLoopCounter
					exit repeat
				end if
			end repeat
			if findState is "Found" then exit repeat
		end repeat
		return {findState, findLocation} as list
	on error
		display dialog "Hmm Well, I was looking for something in the file, and something went wrong." buttons "Bummer"
		return 0
	end try
end findInList

-----------------------------------------

--BEGIN GET COLUMN CONTENTS																								BEGIN GET COLUMN CONTENTS
on getColumnContents(columnToGet, fileContents)
	set columnContents to {}
	repeat with loopCounter from 1 to (count of items of fileContents)
		set columnContents to columnContents & 1
		set item loopCounter of columnContents to item columnToGet of item loopCounter of fileContents
	end repeat
	return columnContents
end getColumnContents

-----------------------------------------

on ReadCsvFile(chosenFile)
	--Check to see if we are being passed a method instead of a file to open
	set method to ""
	try
		if chosenFile is "Choose" then
			set method to "Choose"
		end if
	end try
	
	try
		if method is "Choose" then
			set chosenFile to choose file
		end if
		
		set fileOpened to (characters 1 thru -((count every item of (name extension of (info for chosenFile))) + 2) of (name of (info for chosenFile))) as string
		set testResult to TestCsvFile(chosenFile)
		
		if testResult is yes then
			set openFile to open for access chosenFile
			set fileContents to read chosenFile
			close access openFile
			return fileContents
		end if
		
	on error
		close access openFile
		display dialog "Something bjorked when oppening the file!" buttons "Well bummer"
		return {}
	end try
end ReadCsvFile

-----------------------------------------

on TestCsvFile(chosenFile)
	set chosenFileKind to type identifier of (info for chosenFile)
	if chosenFileKind is "CSV Document" then
		return yes
	else
		if chosenFileKind is "public.comma-separated-values-text" then
			return yes
		else
			display dialog "Silly " & (word 1 of the long user name of (system info)) & ", that file is not a .CSV!" buttons "Oops, my bad"
			return no
		end if
	end if
end TestCsvFile

-----------------------------------------

on ParseCsvFile(fileContents)
	try
		set parsedFileContents to {} --Instantiate our list to hold parsed file contents
		set delimitersOnCall to AppleScript's text item delimiters --Copy the delimiters that are in place when this handler was called
		set AppleScript's text item delimiters to "," --Set delimiter to commas
		
		--Parse each line (paragraph) from the unparsed file contents
		set lineCount to (count of paragraphs in fileContents)
		repeat with loopCounter from 1 to lineCount --Loop through each line in the file, one at a time
			set parsedFileContents to parsedFileContents & 1 --Add a new item to store the parsed paragraph
			set item loopCounter of parsedFileContents to (every text item of paragraph loopCounter of fileContents) --Parse a line from the file into individual items and store them in the item created above
		end repeat
		
		set AppleScript's text item delimiters to delimitersOnCall --Set Applescript's delimiters back to whatever they were when this handler was called
		return parsedFileContents --Return our fancy parsed contents
	on error
		display dialog "Woah! Um, that's not supposed to happen." & return & return & "Something goofed up bad when I tried to read the file!" buttons "Ok, I'll take a look at the file"
		return fileContents
	end try
end ParseCsvFile

-----------------------------------------

on verifyPage(expectedElementString, expectedElementLocation, expectedElementCount, verificationTimeout, requiresGroup)
	tell application "System Events"
		--
		repeat until description of scroll area 1 of window 1 of application process "iTunes" is "Apple logo"
			delay (masterDelay * processDelay)
		end repeat
		
		my GetItunesStatusUntillLcd("Does Not Match", itunesAccessingString, 4, "times. Check for:", (verificationTimeout * (1 / checkFrequency)), "intervals of", checkFrequency, "seconds")
		(*repeat
			set lcdStatus to my GetItunesStatusUntillLcd("Does Not Match", itunesAccessingString, 4, "times. Check for:", (verificationTimeout * (1 / checkFrequency)), "intervals of", checkFrequency, "seconds")
			if lcdStatus is "Matched" then exit repeat
			delay masterDelay
		end repeat*)
		
		set elementCount to count every UI element of UI element 1 of scroll area 1 of splitter group 1 of splitter group 1 of window 1 of application process "iTunes"
		
		repeat with timeoutLoopCounter from 1 to verificationTimeout --Loop will be ended before reaching verificationTimeout if the expectedElementString is successfully located
			if timeoutLoopCounter is equal to verificationTimeout then return "unverified"
			
			if expectedElementCount is 0 then set expectedElementCount to elementCount --Use 0 to disable element count verification
			
			if elementCount is equal to expectedElementCount then
				set everyTitle to {}
				
				if requiresGroup then
					set elementToTest to UI element expectedElementLocation of group 1 of UI element 1 of scroll area 1 of splitter group 1 of splitter group 1 of window 1 of application process "iTunes"
				else
					set elementToTest to UI element expectedElementLocation of UI element 1 of scroll area 1 of splitter group 1 of splitter group 1 of window 1 of application process "iTunes"
				end if
				
				set elementProperties to properties of elementToTest
				
				try
					set elementString to title of elementProperties
					--set elementString to (text items 1 through (count of text items in expectedElementString) of elementString) as string
				end try
				if elementString is equal to expectedElementString then
					return "verified"
				end if
			end if
			delay 1
		end repeat
	end tell
end verifyPage

-----------------------------------------

on CheckForErrors()
	if scriptAction is "Continue" then --This is to make sure a previous abort hasn't already been thrown.
		if errorList is not {} then --If there are errors in the list
			
			set errorAction to button returned of (display dialog "Errors were detected. What would you like to do?" buttons {"Abort", "Skip User", "Review"} default button "Review") as string
			
			if errorAction is "Abort" then
				set scriptAction to "Abort" --This sets the global abort action
				return "Abort" --This breaks out of the remainder of the error checker
			end if
			
			if errorAction is "Review" then
				repeat with loopCounter from 1 to (count of items in errorList) --Cycle through all the errors in the list
					if errorAction is "Abort" then
						set scriptAction to "Abort" --This sets the global abort action
						return "Abort" --This breaks out of the remainder of the error checker
					else
						set errorAction to button returned of (display dialog "Showing error " & loopCounter & " of " & (count of items in errorList) & ":" & return & return & item loopCounter of errorList & return & return & "What would you like to do?" buttons {"Abort", "Manually Correct"} default button "Manually Correct") as string
						if errorAction is "Manually Correct" then set errorAction to button returned of (display dialog "Click continue when the error has been corrected." & return & "If you cannot correct the error, then you may skip this user or abort the entire script" buttons {"Abort", "Skip User", "Continue"} default button "Continue") as string
					end if
				end repeat
				set errorList to {} --Clear errors if we've made it all the way through the loops
				set scriptAction to errorAction
			end if
			
		end if --for error check
	end if --for abort check
end CheckForErrors

-----------------------------------------

on SignOutItunesAccount()
	if scriptAction is "Continue" then --This is to make sure an abort hasn't been thrown
		tell application "System Events"
			--Tell iTunes to open iBooks. Still submits information to Apple but moves the script along much faster
			tell application "iTunes" to open location ibooksLinkLocation
			delay masterDelay
			
			repeat until description of scroll area 1 of window 1 of application process "iTunes" is "Apple logo"
				delay (masterDelay * processDelay)
			end repeat
			
			set storeMenu to menu "Store" of menu bar item "Store" of menu bar 1 of application process "iTunes"
			set storeMenuItems to title of every menu item of storeMenu
		end tell
		
		repeat with loopCounter from 1 to (count of items in storeMenuItems)
			if item loopCounter of storeMenuItems is "Sign Out" then
				tell application "System Events"
					click menu item "Sign Out" of storeMenu
				end tell
			end if
		end repeat
	end if
end SignOutItunesAccount

-----------------------------------------

on GetItunesStatusUntillLcd(matchType, stringToMatch, matchDuration, "times. Check for:", checkDuration, "intervals of", checkFrequency, "seconds")
	set loopCounter to 0
	set matchedFor to 0
	set itunesLcdText to {}
	
	repeat
		set loopCounter to loopCounter + 1
		
		if loopCounter is greater than or equal to (checkDuration * checkFrequency) then
			return "Unmatched"
		end if
		
		set itunesLcdText to itunesLcdText & ""
		tell application "System Events"
			try
				--set item loopCounter of itunesLcdText to value of static text 1 of scroll area 1 of window 1 of application process "iTunes"
				set item loopCounter of itunesLcdText to value of static text 1 of scroll area 1 of window 1 of application process "iTunes"
			end try
		end tell
		
		if matchType is "Matches" then
			if item loopCounter of itunesLcdText is stringToMatch then
				set matchedFor to matchedFor + 1
			else
				set matchedFor to 0
			end if
		end if
		
		if matchType is "Does Not Match" then
			if item loopCounter of itunesLcdText is not stringToMatch then
				set matchedFor to matchedFor + 1
			else
				set matchedFor to 0
			end if
		end if
		
		if matchedFor is greater than or equal to matchDuration then
			return "Matched"
		end if
		delay checkFrequency
	end repeat
	
end GetItunesStatusUntillLcd

-----------------------------------------

on installIbooks()
	delay (masterDelay * processDelay)
	if scriptAction is "Continue" then --This is to make sure an abort hasn't been thrown
		
		-- AF 2012-05-14 Open location instead of .inetloc
		tell application "iTunes" to open location ibooksLinkLocation
		delay (masterDelay * processDelay)
		set pageVerification to verifyPage("iBooks", "iBooks", 42, netDelay, true) --Looking for "iBooks", in the second element, on a page with a count of 39 elements, with a timeout of 5, and it requires the use of "group 1" for checking
		
		if pageVerification is "verified" then --Actually click the button to obtain iBooks
			delay (masterDelay * processDelay)
			tell application "System Events"
				try
					set freeButton to button 1 of group 2 of UI element 1 of scroll area 1 of splitter group 1 of splitter group 1 of window "iTunes" of application process "iTunes"
					if description of freeButton is "$0.00 Free, iBooks" then
						click freeButton
					else
						set errorList to errorList & "Unable to locate install app button by its description."
					end if
				on error
					set errorList to errorList & "Unable to locate install app button by its description."
				end try
			end tell
			set pageVerification to ""
		else --Throw error if page didn't verify
			set errorList to errorList & "Unable to verify that iTunes is open at the iBooks App Store Page."
		end if
		
	end if
end installIbooks

-----------------------------------------

on ClickCreateAppleIDButton()
	delay (masterDelay * processDelay)
	if scriptAction is "Continue" then --This is to make sure an abort hasn't been thrown
		--Verification text for window:
		--get value of static text 1 of window 1 of application process "iTunes" --should be equal to "Sign In to the iTunes Store"
		tell application "System Events"
			if value of static text 1 of window 1 of application process "iTunes" is "Sign In to the iTunes Store" then
				try
					click button "Create Apple ID" of window 1 of application process "iTunes"
				on error
					set errorList to errorList & "Unable to locate and click button ''Create Apple ID'' on ID sign-in window"
				end try
			else
				set errorList to errorList & "Unable to locate sign-in window and click ''Create Apple ID''"
			end if
		end tell
	end if
end ClickCreateAppleIDButton

-----------------------------------------

on ClickContinueOnPageOne()
	delay (masterDelay * processDelay)
	set pageVerification to verifyPage("Welcome to the iTunes Store", "Welcome to the iTunes Store", 12, netDelay, false) ----------Verify we are at page 1 of the Apple ID creation page
	if pageVerification is "verified" then
		
		try
			tell application "System Events"
				set contButton to button "Continue" of UI element 1 of scroll area 1 of splitter group 1 of splitter group 1 of window 1 of application process "iTunes"
				if title of contButton is "Continue" then
					click contButton
				else
					set errorList to errorList & "Unable to locate and click the Continue button on page ''Welcome to iTunes Store''."
				end if
			end tell
		on error
			set errorList to errorList & "Unable to locate and click the Continue button on page ''Welcome to iTunes Store''."
		end try
		
		set pageVerification to ""
	else
		set errorList to errorList & "Unable to verify that iTunes is open at the first page of the Apple ID creation process."
	end if
end ClickContinueOnPageOne

-----------------------------------------

on AgreeToTerms()
	delay (masterDelay * processDelay)
	set pageVerification to verifyPage("Terms and Conditions and Apple Privacy Policy", "Terms and Conditions and Apple Privacy Policy", 16, netDelay, false) ----------Verify we are at page 1 of the Apple ID creation page
	if pageVerification is "verified" then
		tell application "System Events"
			
			--Check box
			try
				set agreeCheckbox to checkbox "I have read and agree to these terms and conditions." of group 4 of UI element 1 of scroll area 1 of splitter group 1 of splitter group 1 of window 1 of application process "iTunes"
				set buttonVerification to title of agreeCheckbox
				if buttonVerification is "I have read and agree to these terms and conditions." then
					click agreeCheckbox
				else
					set errorList to errorList & "Unable to locate and check box ''I have read and agree to these terms and conditions.''"
				end if
			on error
				set errorList to errorList & "Unable to locate and check box ''I have read and agree to these terms and conditions.''"
			end try
			
			--delay (masterDelay * processDelay) --We need to pause a second for System Events to realize we have checked the box
			delay 1
			my CheckForErrors()
			
			
			if scriptAction is "Continue" then
				try
					set agreeButton to button "Agree" of UI element 1 of scroll area 1 of splitter group 1 of splitter group 1 of window 1 of application process "iTunes"
					set buttonVerification to title of agreeButton
					if buttonVerification is "Agree" then
						click agreeButton
					else
						set errorList to errorList & "Unable to locate and click button ''Agree''."
					end if
				on error
					set errorList to errorList & "Unable to locate and click button ''Agree''."
				end try
			else
				set errorList to errorList & "Unable to locate and click button ''Agree''."
			end if
			
		end tell
	end if
	
end AgreeToTerms

-----------------------------------------
on theForm()
	tell application "System Events"
		set theForm to UI element 1 of scroll area 3 of window 1 of application process "iTunes"
		return theForm
	end tell
end theForm

-----------------------------------------

on FillInField(fieldName, theField, theValue)
	tell application "System Events"
		try
			set focused of theField to true
			set value of theField to theValue
			if value of theField is not theValue then
				set errorList to errorList & ("Unable to fill " & fieldName & ".")
			end if
		on error
			set errorList to errorList & ("Unable to fill " & fieldName & ". ")
		end try
	end tell
end FillInField

on FillInKeystroke(fieldName, theField, theValue)
	tell application "System Events"
		set frontmost of application process "iTunes" to true --Verify that iTunes is the front window before performing keystroke event
		try
			set focused of theField to true
			keystroke theValue
		on error
			set errorList to errorList & ("Unable to fill " & fieldName & ". ")
		end try
	end tell
end FillInKeystroke

on FillInPopup(fieldName, theField, theValue, maximum)
	tell application "System Events"
		set frontmost of application process "iTunes" to true --Verify that iTunes is the front window before performing keystroke event
		try
			-- iTunes doesn't allow direct access to popup menus. So we step through instead.
			repeat with loopCounter from 1 to maximum
				if value of theField is theValue then exit repeat
				
				set focused of theField to true
				delay 0.1
				keystroke " " -- Space to open the menu
				keystroke (key code 125) -- down arrow
				keystroke " " -- Space to close the menu
			end repeat
			
			if value of theField is not theValue then set errorList to errorList & ("Unable to fill " & fieldName & ". ")
		on error
			set errorList to errorList & ("Unable to fill " & fieldName & ". ")
		end try
	end tell
end FillInPopup

on ClickThis(fieldName, theField)
	tell application "System Events"
		try
			click theField
		on error
			set errorList to errorList & ("Unable to click " & fieldName & ". ")
		end try
	end tell
end ClickThis

-----------------------------------------

on ProvideAppleIdDetails(appleIdEmail, appleIdPassword, appleIdSecretQuestion1, appleIdSecretAnswer1, appleIdSecretQuestion2, appleIdSecretAnswer2, appleIdSecretQuestion3, appleIdSecretAnswer3, rescueEmail, userBirthMonth, userBirthDay, userBirthYear)
	if scriptAction is "Continue" then --This is to make sure an abort hasn't been thrown
		set pageVerification to verifyPage("Provide Apple ID Details", "Provide Apple ID Details", 0, (netDelay * processDelay), false)
		if pageVerification is "Verified" then
			tell application "System Events"
				set theForm to UI element 1 of scroll area 1 of splitter group 1 of splitter group 1 of window 1 of application process "iTunes"
				-----------
				tell me to FillInField("Email", text field "email@example.com" of group 2 of theForm, appleIdEmail)
				-----------
				tell me to FillInKeystroke("Password", text field "Password" of group 2 of group 3 of theForm, appleIdPassword)
				-----------
				tell me to FillInKeystroke("Retype your password", text field "Retype your password" of group 4 of group 3 of theForm, appleIdPassword)
				-----------
				tell me to FillInPopup("First Security Question", pop up button 1 of group 1 of group 6 of theForm, appleIdSecretQuestion1, 5)
				tell me to FillInField("First Answer", text field 1 of group 2 of group 6 of theForm, appleIdSecretAnswer1)
				-----------
				tell me to FillInPopup("Second Security Question", pop up button 1 of group 1 of group 7 of theForm, appleIdSecretQuestion2, 5)
				tell me to FillInField("Second Answer", text field 1 of group 2 of group 7 of theForm, appleIdSecretAnswer2)
				-----------
				tell me to FillInPopup("Third Security Question", pop up button 1 of group 1 of group 8 of theForm, appleIdSecretQuestion3, 5)
				tell me to FillInField("Third Answer", text field 1 of group 2 of group 8 of theForm, appleIdSecretAnswer3)
				-----------
				tell me to FillInField("Optional Rescue Email", text field "rescue@example.com" of group 11 of theForm, rescueEmail)
				-----------
				tell me to FillInPopup("Day", pop up button 1 of group 1 of group 13 of theForm, userBirthDay, 31)
				tell me to FillInPopup("Month", pop up button 1 of group 2 of group 13 of theForm, userBirthMonth, 12)
				tell me to FillInField("Year", text field "Year" of group 3 of group 13 of theForm, userBirthYear)
				-----------
				set releaseCheckbox to checkbox "New releases and additions to the iTunes Store." of group 15 of theForm
				set newsCheckbox to checkbox "News, special offers, and information about related products and services from Apple." of group 16 of theForm
				if value of releaseCheckbox is 1 then
					tell me to ClickThis("New releases and additions to the iTunes Store.", releaseCheckbox)
				end if
				if value of newsCheckbox is 1 then
					tell me to ClickThis("News, special offers, and information about related products and services from Apple.", newsCheckbox)
				end if
				-----------
				
				my CheckForErrors() --Check for errors before continuing to the next page
				
				if dryRun is true then
					set dryRunSucess to button returned of (display dialog "Did everything fill in properly?" buttons {"Yes", "No"}) as text
					if dryRunSucess is "No" then
						set scriptAction to button returned of (display dialog "What would you like to do?" buttons {"Abort", "Continue"}) as text
					end if
				end if
				
				if scriptAction is "Continue" then
					tell me to click button "Continue" of theForm
				end if
			end tell
		else --(If page didn't verify)
			set errorList to errorList & "Unable to verify that the ''Provide Apple ID Details'' page is open and fill its contents."
		end if
	end if
end ProvideAppleIdDetails

on ProvidePaymentDetails(userFirstName, userLastName, addressStreet, addressCity, addressState, addressZip, phoneAreaCode, phoneNumber)
	if scriptAction is "Continue" then --This is to make sure an abort hasn't been thrown
		set pageVerification to verifyPage("Provide a Payment Method", "Provide a Payment Method", 0, (netDelay * processDelay), false)
		
		if pageVerification is "Verified" then
			tell application "System Events"
				click radio button "None" of radio group 1 of theForm
			end tell
		end if
		
		--Wait for the page to change after selecting payment type
		set checkFrequency to 0.25 --How often (in seconds) the iTunes LCD will be checked to see if iTunes is busy loading the page
		
		repeat
			set lcdStatus to GetItunesStatusUntillLcd("Does Not Match", itunesAccessingString, 4, "times. Check for:", (netDelay * (1 / checkFrequency)), "intervals of", checkFrequency, "seconds")
			if lcdStatus is "Matched" then exit repeat
			delay masterDelay
		end repeat
		
		tell application "System Events"
			try
				set frontmost of application process "iTunes" to true --Verify that iTunes is the front window before performing keystroke event
				set focused of pop up button 1 of group 1 of group 7 of theForm to true
				keystroke "Mr"
			on error
				set errorList to errorList & "Unable to set ''Title' to 'Mr.'"
			end try
			-----------
			try
				set value of text field "First name" of group 1 of group 8 of theForm to userFirstName
			on error
				set errorList to errorList & "Unable to set ''First Name'' field to " & userFirstName
			end try
			-----------
			try
				set value of text field "Last name" of group 2 of group 8 of theForm to userLastName
			on error
				set errorList to errorList & "Unable to set ''Last Name'' field to " & userLastName
			end try
			-----------
			try
				set value of text field "Street" of group 1 of group 9 of theForm to addressStreet
			on error
				set errorList to errorList & "Unable to set ''Street Address'' field to " & addressStreet
			end try
			-----------
			try
				set value of text field "City" of group 1 of group 10 of theForm to addressCity
			on error
				set errorList to errorList & "Unable to set ''City'' field to " & addressCity
			end try
			-----------
			try
				set frontmost of application process "iTunes" to true --Verify that iTunes is the front window before performking keystroke event
				set focused of pop up button "Select a province" of group 2 of group 10 of theForm to true
				keystroke addressState
			on error
				set errorList to errorList & "Unable to set ''Province'' drop-down to " & addressState
			end try
			-----------
			try
				set value of text field "Postal Code" of group 3 of group 10 of theForm to addressZip
			on error
				set errorList to errorList & "Unable to set ''Postal Code'' field to " & addressZip
			end try
			-----------
			try
				set value of text field "Area code" of group 1 of group 11 of theForm to phoneAreaCode
			on error
				set errorList to errorList & "Unable to set ''Area Code'' field to " & phoneAreaCode
			end try
			-----------
			try
				set value of text field "Phone" of group 2 of group 11 of theForm to phoneNumber
			on error
				set errorList to errorList & "Unable to set ''Phone Number'' field to " & phoneNumber
			end try
			-----------
			
			my CheckForErrors()
			
			if dryRun is true then --Pause to make sure all the fields filled properly
				set dryRunSucess to button returned of (display dialog "Did everything fill in properly?" buttons {"Yes", "No"}) as text
				if dryRunSucess is "No" then
					set scriptAction to button returned of (display dialog "What would you like to do?" buttons {"Abort", "Continue"}) as text
				end if
			end if
			
			if dryRun is false then --Click the "Create Apple ID" button as long as we aren't in "Dry Run" mode
				if scriptAction is "Continue" then --Continue as long as no errors occurred
					try
						click button "Create Apple ID" of theForm
					on error
						set errorList to errorList & "Unable to click ''Create Apple ID'' button."
					end try
				end if --End "Continue if no errors" statement
			else --If we are doing a dry run then...
				set dryRunChoice to button returned of (display dialog "Completed. Would you like to stop the script now, continue ''dry running'' with the next user in the CSV (if applicable), or run the script ''for real'' starting with the first user?" buttons {"Stop Script", "Continue Dry Run", "Run ''For Real''"}) as text
				if dryRunChoice is "Stop Script" then set scriptAction to "Stop"
				if dryRunChoice is "Run ''For Real''" then
					set currentUserNumber to 0
					set dryRun to false
				end if
			end if --End "dry Run" if statement
			
		end tell --End "System Events" tell
	end if --End main error check IF
end ProvidePaymentDetails
