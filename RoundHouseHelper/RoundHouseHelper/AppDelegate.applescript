--
--  AppDelegate.applescript
--  RoundHouseHelper
--
--  Created by Christian on 5/6/13.
--  Copyright (c) 2013 Drivetime. All rights reserved.
--

script AppDelegate
	property parent : class "NSObject"
    property theWindow : missing value
	property originalView : missing value
	property newView : missing value
	property blankView : missing value
	
	on applicationWillFinishLaunching_(aNotification)
		-- Insert code here to initialize your application before any files are opened 
	end applicationWillFinishLaunching_
	
	on applicationShouldTerminate_(sender)
		-- Insert code here to do any housekeeping before your application quits 
		return current application's NSTerminateNow
	end applicationShouldTerminate_
    
    -- View changing handler for multiple view changes.
    on changeView_(sender)
		-- get frame of replacement view
		if sender's superview() = originalView then
			set theFrame to newView's frame()
            else
			set theFrame to originalView's frame()
		end if
		tell theWindow
			-- get frame required for window
			set theFrame to frameRectForContentRect_(theFrame)
			-- get individual values for the new view and the window
			set {origin:{x:frameX, y:frameY}, |size|:{|width|:frameWidth, height:frameHeight}} to theFrame
			set {origin:{x:windowX, y:windowY}, |size|:{|width|:windowWidth, height:windowHeight}} to frame()
			-- calculate new frame
			set newOrigin to {x:windowX - (frameWidth - windowWidth) / 2, y:windowY - frameHeight + windowHeight}
			set newFrame to {origin:newOrigin, |size|:{|width|:frameWidth, height:frameHeight}}
			set newFrame to my adjustFrame_forScreenOfWindow_(newFrame, theWindow)
			-- put in blank view
			setContentView_(blankView)
			-- resize window
			setFrame_display_animate_(newFrame, true, true)
			-- put in the replacement view
			if sender's superview() = originalView then
				setContentView_(newView)
            else
				setContentView_(originalView)
			end if
		end tell
	end changeView_
	
	on adjustFrame_forScreenOfWindow_(proposedFrame, aWindow)
		set {origin:{x:windowX, y:windowY}, |size|:{|width|:windowWidth, height:windowHeight}} to proposedFrame
		set screenFrame to aWindow's screen()'s visibleFrame()
		set {origin:{x:frameX, y:frameY}, |size|:{|width|:frameWidth, height:frameHeight}} to screenFrame
		-- check left
		if windowX < frameX then set windowX to frameX
		--check right
		if windowX + windowWidth > frameX + frameWidth then set windowX to frameX + frameWidth - windowWidth
		-- check bottom
		if windowY < frameY then set windowY to frameY
		return {origin:{x:windowX, y:windowY}, |size|:{|width|:windowWidth, height:windowHeight}}
	end adjustFrame_forScreenOfWindow_
    
    on SimpleResize_(sender) -- connected to Resize button in Interface Builder
		set thisWindow to sender's |window|() -- get the window to be resized
		set theFrame to (thisWindow's frame()) as record
		-- the frame record is in the form: {origin:{x:theLeft, y:theBottom}, |size|:{|width|:theWidth, height:theHeight}}
		if height of |size| of theFrame < 300 then
			set y of origin of theFrame to ((y of origin of theFrame) as integer) - 540 + (height of |size| of theFrame) as integer
			set height of |size| of theFrame to 540
			tell thisWindow to setFrame_display_animate_(theFrame, true, true)
        else
			set y of origin of theFrame to ((y of origin of theFrame) as integer) - 270 + (height of |size| of theFrame) as integer
			set height of |size| of theFrame to 270
			tell thisWindow to setFrame_display_(theFrame, true)
		end if
	end doResize_
	
    on log_event(themessage)
        set theLine to (do shell script "date  +'%Y-%m-%d %H:%M:%S'" as string) & " " & themessage
        do shell script "echo " & theLine & " >> ~/Library/Logs/RoundHouseHelper.log"
    end log_event
    
end script