-- AppleScript to help setup iOS device
-- This will guide Xcode to build the app

tell application "Xcode"
	activate
	delay 2
	
	-- Open the workspace if not already open
	try
		open "/Users/amrhamdy/Documents/Projects/wish_listy/ios/Runner.xcworkspace"
		delay 3
	end try
	
	-- Display instructions
	display dialog "Xcode is now open.

Please do these 3 simple steps:

1️⃣ Click on 'Runner' in the left sidebar (blue icon)

2️⃣ Click on 'Signing & Capabilities' tab at the top

3️⃣ Click 'Add Account...' under Team and sign in with your Apple ID

Then press OK and I'll try to build automatically." buttons {"OK"} default button "OK" with title "iOS Setup Guide"
	
	-- Try to build (this might fail if signing not set up, but it will trigger the Developer Mode prompt)
	tell application "System Events"
		keystroke "b" using command down
	end tell
	
end tell

