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
    
    on defineGlobals()
        global dropletFolder
        global drop1Name
        global drop2Name
        global drop3Name
        global initializing
        
        --initializing turned to false after applicationWillFinishLaunching
        set initializing to true
        --Droplet data
        set dropletFolder to (path to library folder) & "Caches:RoundHouseHelper:Droplets:" as string
        set drop1Name to "Download1_Droplet"
        set drop2Name to "Download2_Droplet"
        set drop3Name to "Download3_Droplet"
        
        log_event("Default Globals Loaded...")
    end defineGlobals
    
    on checkCacheFolders_(sender)
        set CacheFolderList to {"Download1", "Download2", "Download3", "Download4", "Processed", "Prearchive", "Droplets"}
        set CacheFolderLoc to ((path to library folder) & "Caches:" as string) as alias
        set CacheFolderCreated to false
    
        try
            tell application "Finder" to make new folder at CacheFolderLoc with properties {name:"RoundHouseHelper"}
            log_event("Cache Folder 'RoundHouseHelper' created at... " & CacheFolderLoc as string)
        end try
        set RoundHouseHelper_folder to ((path to library folder) & "Caches:RoundHouseHelper:" as string) as alias
        repeat with aFolder in CacheFolderList
            try
                tell application "Finder" to make new folder at RoundHouseHelper_folder with properties {name:aFolder}
                log_event("Cache Folder '" & (aFolder as string) & "' created at... " & RoundHouseHelper_folder as string)
            end try
        end repeat
    end checkCacheFolders_
        
    on checkDroplets_(sender)
        global dropletsExist
        global dropletFolder
        global drop1Name
        global drop2Name
        global drop3Name
        global initializing
        
        log_event("Checking for Droplets...")
        --set defaults
        set dropletsExist to {droplet1exist:false,droplet2exist:false,droplet3exist:false}
        --gets contents of droplets folder
        tell Application "Finder" to set dropFolderCont to every file in (dropletFolder as alias) as string
        --update droplets exists if droplets are found
        if dropFolderCont as text contains drop1Name then
            set droplet1exist of dropletsExist to true
            if initializing is true then log_event("Found " & drop1Name as string)
        end if
        if dropFolderCont as text contains drop2Name then
            set droplet2exist of dropletsExist to true
            if initializing is true then log_event("Found " & drop2Name as string)
        end if
        if dropFolderCont as text contains drop3Name then
            set droplet3exist of dropletsExist to true
            if initializing is true then log_event("Found " & drop3Name as string)
        end if
    end checkDroplets_
            
    
    (* ======================================================================
                    Default "Application will..." Handlers
     ====================================================================== *)
    
    on applicationWillFinishLaunching_(aNotification)
        global initializing
        
        log_event("==========PROGRAM INITILIZE=========")
        --Define Globals
        defineGlobals()
        --Set/Get Preferences
        tell current application's NSUserDefaults to set defaults to standardUserDefaults()
        tell defaults to registerDefaults_({saveFolderloc:((path to desktop)as string)})
        retrieveDefaults_(me)
        --Declare MainView as starting view
        global curView
        set curView to MainView
        --Routine Check Cache folders
        checkCacheFolders_(me)
        --Check for Droplets
        checkDroplets_(me)
        
        --initializing turned to false after applicationWillFinishLaunching
        set initializing to false
	end applicationWillFinishLaunching_
	
	on applicationShouldTerminate_(sender)
        log_event("==========PROGRAM SHUTDOWN==========")
		return current application's NSTerminateNow
	end applicationShouldTerminate_
    
    (* ======================================================================
                   Background Handlers for window/view control
     ====================================================================== *)
    
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
        --Use MyriadHelpers to show cache window as sheet
        tell CacheWindow to showOver_(MainWindow)
        log_event("Clear Cache started")
    end StartClearCache_
    
    on CancelClearCache_(sender)
        --Use MyriadHelpers to close cache sheet
		tell current application's NSApp to endSheet_(CacheWindow)
        log_event("Cancel Clear Cache")
	end ClearCacheCancelButton_
    
    on OpenPreferences_(sender)
        --open preferences window
        PreferencesWindow's makeKeyAndOrderFront_(me)
        log_event("Opened Preferences")
        updateSavefolderLocLabel_(me)
    end OpenPreferences_
    
    on ReshootNew_(sender)
        --Open reshoot/New Window
        ReshootWindow's makeKeyAndOrderFront_(me)
        log_event("Opened Reshoot-New Window")
    end ReshootNew_
    
    (* ======================================================================
                            Handlers for Preferences!
     ====================================================================== *)
    
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
    
    on retrieveDefaults_(sender)
        --Read the preferences from the preferences file
        global saveFolderloc
        tell defaults to set saveFolderloc to objectForKey_("saveFolderloc")
        log_event("Read in Preferences...")
        log_event("Save Folder Location: " & saveFolderloc)
    end retrieveDefaults_
    
    on dropletButtons_(sender)
        global dropletsExist
        global dropletFolder
        global drop1Name
        global drop2Name
        global drop3Name
        global initializing
        
        log_event("Replace Droplet Button..." & (title of sender as string) as string)
        
        --Check for Droplets
        checkDroplets_(me)
        
        --Declare default vars
        set trueName to false
        set removeDroplet to false
        
        --Figure out what droplet we are replacing
        set buttonName to title of sender as string
        set newDropletLoc to (choose file with prompt "Choose new droplet...")
        --Get filename and remove ".app"
        tell app "Finder" to set newDropName to name of newdropletloc
        set newDropName to (text 1 thru text -5 of newDropName) as string
        --Subtract last character on new droplet location because it adds a ":" to the end of .app files
        set newDropletLoc to newDropletLoc as string
        if (the last character of newDropletLoc is ":") then set newDropletLoc to (text 1 thru -2 of newDropletLoc) as string
        
        --Check new droplet name and allow/disallow renaming of file
        if buttonName = "Droplet 1" then
            if newDropName = drop1Name then set trueName to true
            set dropName to drop1Name
            if droplet1exist of dropletsExist is true then set removeDroplet to true
        else if buttonName = "Droplet 2" then
            if newDropName = drop2Name then set trueName to true
            set dropName to drop2Name
            if droplet2exist of dropletsExist is true then set removeDroplet to true
        else if buttonName = "Droplet 3" then
            if newDropName = drop3Name then set trueName to true
            set dropName to drop3Name
            if droplet3exist of dropletsExist is true then set removeDroplet to true
        end if
        
        --delete the old droplet
        if removeDroplet is true then
            do shell script "rm -rf " & quoted form of POSIX path of (dropletFolder & dropName & ".app" as string)
            log_event("Removed old droplet...")
        end if
        try
            --Try to copy in new droplet
            do shell script "cp -rf " & quoted form of POSIX path of newDropletLoc & " " & quoted form of POSIX path of dropletFolder
            log_event("Copied new droplet...")
            --If name is false then change the name
            if trueName is false then
                do shell script "mv " & quoted form of POSIX path of (dropletFolder & newDropName & ".app" as string) & " " & quoted form of POSIX path of (dropletFolder & dropName & ".app" as string)
                log_event("Renamed new droplet...")
            end if
            --log change
            log_event("New Droplet successful!")
            --Check for Droplets again. Temp initializing true
            set initializing to true
            checkDroplets_(me)
            set initializing to false
            
            on error errmsg
                tell me to display dialog "Error when attempting to replace droplet"
                log_event("Add/New Droplet Failed...")
        end try
    end dropletButtons_
    
    (* ======================================================================
                                Hanlder for logging!
     ====================================================================== *)
	
    on log_event(themessage)
        --Log event, then write to rolling log file.
        log themessage
        set theLine to (do shell script "date  +'%Y-%m-%d %H:%M:%S'" as string) & " " & themessage
        do shell script "echo " & theLine & " >> ~/Library/Logs/RoundHouseHelper.log"
    end log_event
    
end script