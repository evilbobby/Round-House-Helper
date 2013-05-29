--
--  AppDelegate.applescript
--  RoundHouseHelper
--
--  Created by Christian on 5/6/13.
--  Copyright (c) 2013 Drivetime. All rights reserved.
--

script AppDelegate
	property parent : class "NSObject"
    
    --Preferences
    property defaults : missing value
    --Windows
    property MainWindow : missing value
	property MainView : missing value
	property SearchView : missing value
	property blankView : missing value
    property CacheWindow : missing value
    property PreferencesWindow : missing value
    property ReshootWindow : missing value
    property doubleCheckWindow : missing value
    --Main Processing Window
    property MainBar1 : missing value
    property MainBar2 : missing value
    property MainDetail1 : missing value
    property MainDetail2 : missing value
    property ArchiveButton : missing value
    --Searching/Begin Window
    property searchBar1 : missing value
    property searchDetail1 : missing value
    property searchButton1 : missing value
    --Preferences Window
    property savefolderlocLabel : missing value
    property rawFolderloclabel : missing value
    property drop1Indicator : missing value
    property drop2Indicator : missing value
    property drop3Indicator : missing value
    --Cache Window
    property cacheIndicator : missing value
    property cachecancelbutton : missing value
    property cachepausebutton : missing value
    property cachelabel : missing value
    property cancelCache : false
    property pauseCache : false
    property cacheWait : 1
    --Reshoot Window
    property cancelReshootNew : false
    --Master State
    property pauseUser : false
    property reqReshoot : false
    property lastTask : null
    property meFinished : false
    property reshootSel : null
    property CacheCleared : false
    --Download Folders
    property Download1_folder : null
	property Download2_folder : null
	property Download3_folder : null
    property Download4_folder : null
    property processedFolder : null
    --Droplets
    property Droplet1Location : null
    property Droplet2Location : null
    property Droplet3Location : null
    --Image Processing
    property imageNumber : null
    property processNumber : null
    property processImage : null
    property curDownloadFolder : null
    property curBasename : null
    property curDroplet : null
    property processImageName : null
    property Delay1 : 0.3
    --DoubleCheckWindow
    property doubleCheckLabel : missing value
    property doubleCheckHandler : null
    
    
    (* ======================================================================
                            Handlers for Processing! 
     ====================================================================== *)
    
    --CLEAR CACHE HANDLER
    on clearCache()
        global clearCacheTimer
        global ClearCacheCountDown
        global RoundHouseHelper_folder
        
        --Make sure the cancel button was not pressed
        if ClearCacheCountDown = true and cancelCache = false and pauseCache = false then
            --Do 5 second countdown
            log "Clear Cache..." & clearCacheTimer
            tell cacheIndicator to setIntValue_(clearCacheTimer - 1)
            tell cachelabel to setStringValue_("Preparing to Clear Cache...(" & (6 - clearCacheTimer) & ")")
            set clearCacheTimer to clearCacheTimer + 1
            if clearCacheTimer = 7 then
                set ClearCacheCountDown to false
                set clearCacheTimer to 1
            end if
            performSelector_withObject_afterDelay_("clearCache", missing value, cacheWait)
        else if ClearCacheCountDown = false and cancelCache = false and pauseCache = false then
            --After the coutdown we can now clear the cache
            set CacheFolderList to {"Download1", "Download2", "Download3", "Download4", "Processed", "Prearchive"}
            tell cachelabel to setStringValue_("Clearing Cache..." & (item clearCacheTimer of CacheFolderList) as string)
            log_event("Clear Cache...Clearing " & (item clearCacheTimer of CacheFolderList) as string)
            --delete all files in folder
            --CLEAR CACHE DISABLED
            --do shell script "rm -rf " & POSIX path of (RoundHouseHelper_folder & item clearCacheTimer of CacheFolderList & ":*" as string)
            set clearCacheTimer to clearCacheTimer + 1
            if clearCacheTimer = 7 then
                set clearCacheTimer to 1
                set ClearCacheCountDown to true
                tell cachelabel to setStringValue_("Clearing Cache...Done!")
                delay 1
                --reset window
                tell current application's NSApp to endSheet_(CacheWindow)
                tell cacheIndicator to setIntValue_(0)
                set CacheCleared to true
                log_event("Clear Cache...Finished")
            else
                performSelector_withObject_afterDelay_("clearCache", missing value, 0.1)
            end if
        else if pauseCache = true and cancelCache = false then
            --Pause clear cache
            performSelector_withObject_afterDelay_("clearCache", missing value, 1)
        else if cancelCache = true then
            --End clear Cache
            set clearCacheTimer to 1
            set ClearCacheCountDown to true
            tell cachelabel to setStringValue_("Clearing Cache...Canceled!")
            set cancelCache to false
            delay 1
            --Reset window
            tell current application's NSApp to endSheet_(CacheWindow)
            tell cacheIndicator to setIntValue_(0)
            tell cachelabel to setStringValue_("Preparing to Clear Cache...")
            --try to reset the pause button
            try
                tell cachepausebutton to setState_(0)
                set pauseCache to false
            end try
            log_event("Clear Cache...CANCELED BY USER")
            --if window is at Main then change to search window and reset for "start" button
            resetForStart()
        end if
        
        if CacheCleared is true then performSelector_withObject_afterDelay_("startSearch", missing value, 0.5)
    end ClearCache_

    --WAIT FOR THE FIRST IMAGE IN CACHE
    on searchFor()
        log_event("Looking for images...")
        try
            tell application "Finder" to set waitingforFirstimage to (every file in Download1_folder)
            if (item 1 of waitingforFirstimage) exists then
                set meFinished to true
                log_event("Looking for images...Found!")
            end if
        end try
        
        if pauseUser = true then
            performSelector_withObject_afterDelay_("pauseSearch", missing value, 0.1)
            set pauseUser to false
        else if meFinished = true then
            performSelector_withObject_afterDelay_("Prepare", missing value, 1)
            set meFinished to false
        else
            performSelector_withObject_afterDelay_("SearchFor", missing value, 0.5)
        end if
    end searchFor
    
    --PREPARE FOR PROCESSING
    on Prepare()
        set lastTask to "Prepare"
        log_event("Preparing...")
        changeView_(me)
        enableArchive(false)
        tell MainBar1 to startAnimation_(me)
        tell MainBar1 to setMaxValue_(4)
        tell MainBar1 to setIndeterminate_(false)
        tell MainBar2 to startAnimation_(me)
        tell MainBar2 to setMaxValue_(35)
        tell MainBar2 to setIndeterminate_(false)
        tell MainDetail1 to setStringValue_("Preparing to Process Images...")
        tell MainDetail2 to setStringValue_("Total Progress...")
        set processNumber to 1
        
        performSelector_withObject_afterDelay_("determineNextImage", missing value, 1)
    end Prepare
    
    --DETERMINE THE NEXT IMAGE TO PROCESS
    on determineNextImage()
        
        if reshootsel = "A" and processNumber = 1 then
            --Clear out the old images
        else if reshootsel = "B" and processNumber = 18 then
            --Clear out the old images
        end if
        
        log_event("Determining next image...")
        set lastTask to "determineNextImage"
        
        if processNumber ≥ 1 then
            set imageNumber to processNumber
            set curDownloadFolder to Download1_folder
            set curBasename to "TopDown"
            set curDroplet to Droplet1Location
        end if
        if processNumber > 1 then
            set imageNumber to processNumber - 1
            set curDownloadFolder to Download2_folder
            set curBasename to "Hero"
            set curDroplet to Droplet2Location
        end if
        if processNumber = 18 then
            set imageNumber to processNumber - 16
            set curDownloadFolder to Download1_folder
            set curBasename to "TopDown"
            set curDroplet to Droplet1Location
        end if
        if processNumber > 18 then
            set imageNumber to processNumber - 18
            set curDownloadFolder to Download3_folder
            set curBasename to "Open"
            set curDroplet to Droplet3Location
        end if
        
        if processNumber = 35 then
            enableArchive(true)
        end if
        
        if reshootsel = "A" and processNumber = 18 then
            set meFinished to true
            set reshootSel to null
        else if reshootsel = "B" and processNumber = 35 then
            set meFinished to false
            set reshootSel to null
        end if
        
        if imageNumber < 10 then set imageNumber to "0" & imageNumber as string
        
        set processImageName to "_" & curBasename & "_" & imageNumber & ".NEF" as string
        set processNumber to processNumber + 1
        
        log_event("Next Image: " & processImageName)
        
        if pauseUser = true then
            performSelector_withObject_afterDelay_("pauseSearch", missing value, Delay1)
            set pauseUser to false
        else if reqReshoot = true then
            performSelector_withObject_afterDelay_("ReshootNewProcess", missing value, Delay1)
            set reqReshoot to false
        else if meFinished = true then
            --End Processing
            set meFinished to false
        else
            performSelector_withObject_afterDelay_("findNextImage", missing value, Delay1)
        end if
    end determineNextImage
    
    --WAIT FOR THE NEXT IMAGE TO ENTER THE FOLDER
    on findNextImage()
        set lastTask to "findNextImage"
        log "Waiting for image..."
        
        try
            tell app "Finder" to set processImage to (every file in curDownloadFolder whose name contains processImageName)
            if (item 1 of processImage) exists then
                set processImage to item 1 of processImage
                set meFinished to true
                log_event("Image has arrived!")
                log_event("Waiting for image to download...")
            end if
        end try
        
        if pauseUser = true then
            performSelector_withObject_afterDelay_("pauseSearch", missing value, Delay1)
            set pauseUser to false
        else if reqReshoot = true then
            performSelector_withObject_afterDelay_("ReshootNewProcess", missing value, Delay1)
            set reqReshoot to false
        else if meFinished = true then
            performSelector_withObject_afterDelay_("waitForDownload", missing value, Delay1)
            set meFinished to false
        else
            performSelector_withObject_afterDelay_("findNextImage", missing value, Delay1)
        end if
    end fineNextImage
    
    --WAIT FOR THE NEXT IMAGE TO FINISH DOWNLOADING
    on waitForDownload()
        set lastTask to "waitForDownload"
        log "Waiting for download..."
        
        --try
            tell app "Finder" to set oldsize to physical size of processImage
            delay 0.1
            tell app "Finder" to set newsize to physical size of processImage
            if oldsize = newsize then
                --set lookforme to (name of (item 1 of Images_to_process as alias) as string)
                --set lookforme to (text 1 thru ((offset of the "." in lookforme) - 1) in lookforme)
                log_event("Waiting for image to download...Done")
                log_event("Sending image to Photoshop...")
                --Send the image to photoshop using the correct droplet
                tell app "Finder" to open processImage using curDroplet
                set meFinished to true
                log_event("Waiting for Droplet...")
            end if
        --end try
        
        if pauseUser = true then
            performSelector_withObject_afterDelay_("pauseSearch", missing value, Delay1)
            set pauseUser to false
        else if reqReshoot = true then
            performSelector_withObject_afterDelay_("ReshootNewProcess", missing value, Delay1)
            set reqReshoot to false
        else if meFinished = true then
            performSelector_withObject_afterDelay_("waitForDroplet", missing value, Delay1)
            set meFinished to false
        else
            performSelector_withObject_afterDelay_("waitForDownload", missing value, Delay1)
        end if
    end waitForDownload
    
    --WAIT FOR THE DROPLET TO SAVE THE IMAGE
    on waitForDroplet()
        set lastTask to "waitForDroplet"
        log "Waiting for droplet..."
        
        --try
            tell app "Finder" to set processedContents to (every file in processedFolder) as text
            set strippedName to (text 1 thru ((offset of the "." in processImageName) - 1) in processImageName)
            if processedContents contains strippedName then
                set meFinished to true
                log_event("Waiting for Droplet...Done!")
            end if
        --end try
        
        if pauseUser = true then
            performSelector_withObject_afterDelay_("pauseSearch", missing value, Delay1)
            set pauseUser to false
        else if reqReshoot = true then
            performSelector_withObject_afterDelay_("ReshootNewProcess", missing value, Delay1)
            set reqReshoot to false
        else if meFinished = true then
            performSelector_withObject_afterDelay_("determineNextImage", missing value, Delay1)
            set meFinished to false
        else
            performSelector_withObject_afterDelay_("waitForDroplet", missing value, 0.5)
        end if
    end waitForDroplet
    
    --RESHOOT HANDLER MANAGING NEXT TASK
    on ReshootNewProcess()
        if reshootSel = "A" then
            log_event("Reshoot 'A' Selected...")
            set processNumber to 1
            reshootClearCache()
            
        else if reshootSel = "B" then
            log_event("Reshoot 'B' Selected...")
            set processNumber to 18
            
        else if reshootSel = "N" then
            log_event("Reshoot 'New' Selected...")
            
        end if
    end ReshootNewProcess
    
    on enableArchive(state)
        if state = true then
            tell ArchiveButton to setEnabled_(1)
        else
            tell ArchiveButton to setEnabled_(0)
        end if
    end enableArchive
    
    on reshootA()
        set reshootSel to "A"
        set reqReshoot to true
    end reshootA
    
    on reshootB()
        set reshootSel to "B"
        set reqReshoot to true
    end reshootB
    
    on reshootNew()
        set reshootSel to "N"
        set reqReshoot to true
    end reshootNew
    
    on reshootClearCache()
        global RoundHouseHelper_folder
        
        if reshootSel = "A" then
            --Delete the download1 file for A
            log "1"
            tell app "Finder" to set theImage to (every file in RoundHouseHelper_folder whose name contains "_TopDown_01.NEF")
            log theImage
            log "2"
            tell app "Finder" set theImage to item 1 of theImage
            log theImage
            log "3"
            do shell script "rm -rf " & POSIX path of theImage
            --Delete everything in download2
            --do shell script "rm -rf " & POSIX path of (RoundHouseHelper_folder & "Download2:*" as string)
        else if reshootSel = "B" then
            
        end if
    end reshootClearCache
    
    
    (* ======================================================================
                    Default "Application will..." Handlers
     ====================================================================== *)
    
    on applicationWillFinishLaunching_(aNotification)
        global initializing
        
        log_event("==========PROGRAM INITILIZE=========")
        --Define Globals
        defineGlobals()
        --Start at correct View
        changeView_(me)
        --Set/Get Preferences
        tell current application's NSUserDefaults to set defaults to standardUserDefaults()
        tell defaults to registerDefaults_({saveFolderloc:((path to desktop)as string),rawFolderloc:((path to desktop)as string)})
        retrieveDefaults_(me)
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
			if curView = SearchView then
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
    
    on StartClearCacheButton_(sender)
        --Use MyriadHelpers to show cache window as sheet
        log_event("Clear Cache...")
        tell CacheWindow to showOver_(MainWindow)
        clearCache()
    end StartClearCacheButton_
    
    on StartClearCache()
        StartClearCacheButton_(me)
    end StartClearCache
    
    on CancelClearCacheButton_(sender)
        --Use MyriadHelpers to close cache sheet
        set cancelCache to true
	end ClearCacheCancelButton_
    
    on PauseClearCacheButton_(sender)
        --Pause the Clear Cache
        if pauseCache = false then
            log_event("Clear Cache...Paused")
            set pauseCache to true
        else
            log_event("Clear Cache...Resumed")
            set pauseCache to false
        end if
	end PauseCacheCancelButton_
    
    on OpenPreferences_(sender)
        --open preferences window
        log_event("Open Preferences...")
        PreferencesWindow's makeKeyAndOrderFront_(me)
        updateSavefolderLocLabel()
        updateRawfolderLocLabel()
        log_event("Open Preferences...Finished")
    end OpenPreferences_
    
    on ReshootNew_(sender)
        --Open reshoot/New Window
        log_event("Reshoot-New window launched")
        tell ReshootWindow to showOver_(MainWindow)
        --ReshootWindow's makeKeyAndOrderFront_(me)
    end ReshootNew_
    
    on closeReshootNew_(sender)
        --Use MyriadHelpers to close cache sheet
        tell current application's NSApp to endSheet_(ReshootWindow)
        if cancelReshootNew = true then
            log_event("Reshoot-New window closed")
            set cancelReshootNew to false
        end if
	end closeReshootNew_
    
    on ReshootAButton_(sender)
        closeReshootNew_(me)
        areYouSure("Are you sure you want to Reshoot A?","reshootA")
    end ReshootAButton_
        
    on ReshootBButton_(sender)
        closeReshootNew_(me)
        areYouSure("Are you sure you want to Reshoot B?","reshootB")
    end ReshootBButton_
        
    on NewButton_(sender)
        closeReshootNew_(me)
        areYouSure("Are you sure you want to start over?","reshootNew")
    end NewButton_
    
    on cancelReshootNewButton_(sender)
        set cancelReshootNew to true
        closeReshootNew_(me)
    end cancelReshootNewButton_

    on searchButton_(sender)
        if title of sender as string is "Start" then
            --If we still haven't started, clear cache then start searching
            tell searchButton1 to setState_(0)
            StartClearCacheButton_(me)
        else if title of sender as string = "Pause" and state of sender as string = "1" then
            --If we started then, pause the search
            set pauseUser to true
        else if state of sender as string = "0" then
            --If we're paused, resume searching
            resumeSearch()
        end if
    end searchButton
    
    on resetForStart()
        global curView
        
        tell searchDetail1 to setStringValue_("Press Start")
        tell searchButton1 to setTitle_("Start")
        tell searchBar1 to stopAnimation_(me)
        if curView = MainView then changeView_(me)
    end resetForStart
    
    on pauseSearch()
        tell searchDetail1 to setStringValue_("Paused")
        tell searchBar1 to stopAnimation_(me)
        log_event("Paused by User...")
    end pauseSearch
    
    on resumeSearch()
        tell searchDetail1 to setStringValue_("Looking for images...")
        tell searchBar1 to startAnimation_(me)
        log_event("Resumed by User...")
        searchFor()
    end resumeSearch
    
    on startSearch()
        tell searchDetail1 to setStringValue_("Looking for images...")
        tell searchButton1 to setTitle_("Pause")
        tell searchBar1 to startAnimation_(me)
        log_event("Search Start...")
        searchFor()
    end startSearch
    
    on nextStep_(sender)
        set meFinished to true
    end nextStep_
    
    on quickCache_(sender)
        set cacheWait to 0.01
    end quickCache_
    
    on areYouSure(message,nextHandler)
        tell doubleCheckLabel to setStringValue_(message)
        set doubleCheckHandler to nextHandler
        tell doubleCheckWindow to showOver_(MainWindow)
        log_event("Are you sure..." & nextHandler)
    end areYouSure
    
    on doubleCheckYes_(sender)
        tell current application's NSApp to endSheet_(doubleCheckWindow)
        performSelector_withObject_afterDelay_(doubleCheckHandler, missing value, 1)
        log_event("Are you sure...Yes")
        set doubleCheckHandler to null
    end doubleCheckYes_
    
    on doubleCheckNo_(sender)
        tell current application's NSApp to endSheet_(doubleCheckWindow)
        log_event("Are you sure...No")
        set doubleCheckHandler to null
    end doubleCheckNo_

    
    (* ======================================================================
                        Handlers for startup & shutdown!
     ====================================================================== *)
    
    --DEFINE GLOBALS
    on defineGlobals()
        global dropletFolder
        global drop1Name
        global drop2Name
        global drop3Name
        global initializing
        global clearCacheTimer
        global ClearCacheCountDown
        global RoundHouseHelper_folder
        global curView
        
        --Declare MainView as starting view
        set curView to MainView
        --initializing turned to false after applicationWillFinishLaunching
        set initializing to true
        --Droplet data
        set dropletFolder to (path to library folder) & "Caches:RoundHouseHelper:Droplets:" as string
        set drop1Name to "Download1_Droplet"
        set drop2Name to "Download2_Droplet"
        set drop3Name to "Download3_Droplet"
        --ClearCache
        set clearCacheTimer to 1
        set ClearCacheCountDown to true
        --Roundhousehelper cache folder
        set RoundHouseHelper_folder to (path to library folder) & "Caches:RoundHouseHelper:" as string
        
        log_event("Default Globals Loaded...")
    end defineGlobals
    
    --CHECK FOR CACHE FOLDERS
    on checkCacheFolders_(sender)
        global RoundHouseHelper_folder
        
        log_event("Checking for Cache Folders...")
        set CacheFolderList to {"Download1", "Download2", "Download3", "Download4", "Processed", "Prearchive", "Droplets"}
        set CacheFolderLoc to ((path to library folder) & "Caches:" as string) as alias
        
        try
            tell application "Finder" to make new folder at CacheFolderLoc with properties {name:"RoundHouseHelper"}
            log_event("Cache Folder 'RoundHouseHelper' created at... " & CacheFolderLoc as string)
        end try
        repeat with aFolder in CacheFolderList
            try
                tell application "Finder" to make new folder at (RoundHouseHelper_folder as alias) with properties {name:aFolder}
                log_event("Cache Folder '" & (aFolder as string) & "' created at... " & RoundHouseHelper_folder as string)
            end try
        end repeat
        set Download1_folder to ((path to library folder) & "Caches:" & "RoundHouseHelper:Download1" as string) as alias
        set Download2_folder to ((path to library folder) & "Caches:" & "RoundHouseHelper:Download2" as string) as alias
        set Download3_folder to ((path to library folder) & "Caches:" & "RoundHouseHelper:Download3" as string) as alias
        set Download4_folder to ((path to library folder) & "Caches:" & "RoundHouseHelper:Download4" as string) as alias
        set processedFolder to ((path to library folder) & "Caches:" & "RoundHouseHelper:Processed" as string) as alias
        log_event("Checking for Cache Folders...Finished")
    end checkCacheFolders_
    
    --CHECK FOR DROPLETS
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
            tell drop1Indicator to setIntValue_(1)
            else
            tell drop1Indicator to setIntValue_(3)
        end if
        if dropFolderCont as text contains drop2Name then
            set droplet2exist of dropletsExist to true
            if initializing is true then log_event("Found " & drop2Name as string)
            tell drop2Indicator to setIntValue_(1)
            else
            tell drop2Indicator to setIntValue_(3)
        end if
        if dropFolderCont as text contains drop3Name then
            set droplet3exist of dropletsExist to true
            if initializing is true then log_event("Found " & drop3Name as string)
            tell drop3Indicator to setIntValue_(1)
            else
            tell drop3Indicator to setIntValue_(3)
        end if
        set Droplet1Location to (dropletFolder & drop1Name & ".app" as string) as alias
        set Droplet2Location to (dropletFolder & drop2Name & ".app" as string) as alias
        set Droplet3Location to (dropletFolder & drop3Name & ".app" as string) as alias
        log_event("Checking for Droplets...Finished")
    end checkDroplets_
    
    (* ======================================================================
                            Handlers for Preferences!
     ====================================================================== *)
    
    on updateSavefolderLocLabel()
        --Update the text field containing the save folder location
        global saveFolderloc
        tell savefolderlocLabel
            setEditable_(1)
            setStringValue_(saveFolderloc)
            setEditable_(0)
        end tell
        log_event("Update save folder location text field...")
    end updateSavefolderLocLabel
    
    on updateRawfolderLocLabel()
        --Update the text field containing the save folder location
        global rawFolderloc
        tell rawFolderloclabel
            setEditable_(1)
            setStringValue_(rawFolderloc)
            setEditable_(0)
        end tell
        log_event("Update raw folder location text field...")
    end updateRawfolderLocLabel
    
    on changeSaveFolderloc_(sender)
        --Change the save folder location
        global saveFolderloc
        log_event("Change Save folder location...")
        set choice to (choose folder) as string
        tell defaults to setObject_forKey_(choice, "saveFolderloc")
        retrieveDefaults_(me)
        log_event("Change Save folder location...Finished")
    end changeSaveFolderloc_
    
    on changeRawFolderloc_(sender)
        --Change the save folder location
        global rawFolderloc
        log_event("Change Raw folder location...")
        set choice to (choose folder) as string
        tell defaults to setObject_forKey_(choice, "rawFolderloc")
        retrieveDefaults_(me)
        log_event("Change Raw folder location...Finished")
    end changeRawFolderloc_
    
    on retrieveDefaults_(sender)
        --Read the preferences from the preferences file
        global saveFolderloc
        global rawFolderloc
        log_event("Read in Preferences...")
        tell defaults
            set saveFolderloc to objectForKey_("saveFolderloc")
            set rawFolderloc to objectForKey_("rawFolderloc")
        end tell
        log_event("Save Folder Location: " & saveFolderloc)
        log_event("Save Folder Location: " & rawFolderloc)
        log_event("Read in Preferences...Finished")
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
                log_event("Add/New Droplet FAILED...")
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