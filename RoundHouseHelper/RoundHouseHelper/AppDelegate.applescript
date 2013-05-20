--
--  AppDelegate.applescript
--  RoundHouseHelper
--
--  Created by Christian on 5/6/13.
--  Copyright (c) 2013 Drivetime. All rights reserved.
--

script AppDelegate
	property parent : class "NSObject"
    
    property defaults : missing value
    property MainWindow : missing value
	property MainView : missing value
	property SearchView : missing value
	property blankView : missing value
    property CacheWindow : missing value
    property PreferencesWindow : missing value
    property ReshootWindow : missing value
    property savefolderlocLabel : missing value
    
    (* ======================================================================
                            Handlers for Processing! 
     ====================================================================== *)
    
    
    
    (* ======================================================================
                        Handlers for startup & shutdown! 
     ====================================================================== *)
    
    on CheckCacheFolders_(sender)
        set CacheFolderList to {"Download1", "Download2", "Download3", "Download4", "Processed", "Prearchive"}
        set CacheFolderLoc to ((path to library folder) & "Caches:" as string) as alias
        set CacheFolderCreated to false
    
        try
            tell application "Finder" to make new folder at CacheFolderLoc with properties {name:"RoundHouseHelper"}
            log_event("Cache Folder 'RoundHouseHelper' created at... " & CacheFolderLoc as string)
        end try
        set RoundHouseHelper_folder to ((path to library folder) & "Caches:" & "RoundHouseHelper:" as string) as alias
        repeat with aFolder in CacheFolderList
            try
                tell application "Finder" to make new folder at RoundHouseHelper_folder with properties {name:aFolder}
                log_event("Cache Folder '" & (aFolder as string) & "' created at... " & RoundHouseHelper_folder as string)
            end try
        end repeat
    end CheckCacheFolders_
    
    (* ======================================================================
                    Default "Application will..." Handlers
     ====================================================================== *)
    
    on applicationWillFinishLaunching_(aNotification)
        log_event("==========PROGRAM INITILIZE=========")
        --Get Preferences
        tell current application's NSUserDefaults to set defaults to standardUserDefaults()
        tell defaults to registerDefaults_({saveFolderloc:((path to desktop)as string)})
        retrieveDefaults_(me)
        --Declare MainView as starting view
        global curView
        set curView to MainView
        --Routine Check Cache folders
        CheckCacheFolders_(me)
	end applicationWillFinishLaunching_
	
	on applicationShouldTerminate_(sender)
        log_event("==========PROGRAM SHUTDOWN==========")
		return current application's NSTerminateNow
	end applicationShouldTerminate_
    
    (* ======================================================================
     Background Handlers for window/view control, Preferences, logging etc 
     ====================================================================== *)
    
    on retrieveDefaults_(sender)
        --Read the preferences from the preferences file
        global saveFolderloc
        tell defaults to set saveFolderloc to objectForKey_("saveFolderloc")
        updateSavefolderLocLabel_(me)
        log_event("Read in Preferences...")
        log_event("Save Folder Location: " & saveFolderloc)
    end retrieveDefaults_
    
    -- View changing handler for multiple view changes.
    on changeView_(sender)
        global curView
		-- get frame of replacement view
		if curView = MainView then
			set theFrame to SearchView's frame()
            set curView to SearchView
            log_event("Change View to Search Window")
        else
			set theFrame to MainView's frame()
            set curView to MainView
            log_event("Change View to Main Window")
		end if
		tell MainWindow
			-- get frame required for window
			set theFrame to frameRectForContentRect_(theFrame)
			-- get individual values for the new view and the window
			set {origin:{x:frameX, y:frameY}, |size|:{|width|:frameWidth, height:frameHeight}} to theFrame
			set {origin:{x:windowX, y:windowY}, |size|:{|width|:windowWidth, height:windowHeight}} to frame()
			-- calculate new frame
			set newOrigin to {x:windowX - (frameWidth - windowWidth) / 2, y:windowY - frameHeight + windowHeight}
			set newFrame to {origin:newOrigin, |size|:{|width|:frameWidth, height:frameHeight}}
			set newFrame to my adjustFrame_forScreenOfWindow_(newFrame, MainWindow)
			-- put in blank view
			setContentView_(blankView)
			-- resize window
			setFrame_display_animate_(newFrame, true, true)
			-- put in the replacement view
			if sender's superview() = MainView then
				setContentView_(SearchView)
            else
				setContentView_(MainView)
			end if
		end tell
        log_event("Change View Sucessful!")
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
    
    on StartClearCache_(sender)
        log_event("Clear Cache started")
        --Use MyriadHelpers to show cache window as sheet
        tell CacheWindow to showOver_(MainWindow)
    end StartClearCache_
    
    on ClearCacheCancelButton_(sender)
		log_event("Cancel Clear Cache")
        --Use MyriadHelpers to close cache sheet
		tell current application's NSApp to endSheet_(CacheWindow)
	end ClearCacheCancelButton_
    
    on OpenPreferences_(sender)
        --open preferences window
        PreferencesWindow's makeKeyAndOrderFront_(me)
        log_event("Opened Preferences")
    end OpenPreferences_
    
    on ReshootNew_(sender)
        --Open reshoot/New Window
        ReshootWindow's makeKeyAndOrderFront_(me)
        log_event("Opened Reshoot-New Window")
    end ReshootNew_
    
    on updateSavefolderLocLabel_(sender)
        --Update the text field containing the save folder location
        global saveFolderloc
        tell savefolderlocLabel
            setEditable_(1)
            setStringValue_(saveFolderloc)
            setEditable_(0)
        end tell
        log_event("Update save folder location text field.")
    end updateSavefolderLocLabel_
    
    on changeSaveFolderloc_(sender)
        --Change the save folder location
        global saveFolderloc
        set choice to (choose folder) as string
        tell defaults to setObject_forKey_(choice, "saveFolderloc")
        retrieveDefaults_(me)
        log_event("Change Save folder location...")
    end changeSaveFolderloc_
	
    on log_event(themessage)
        --Log event, then write to rolling log file.
        log themessage
        set theLine to (do shell script "date  +'%Y-%m-%d %H:%M:%S'" as string) & " " & themessage
        do shell script "echo " & theLine & " >> ~/Library/Logs/RoundHouseHelper.log"
    end log_event
    
end script