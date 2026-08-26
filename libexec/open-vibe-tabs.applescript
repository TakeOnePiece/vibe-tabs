-- macOS app entry point. The command handles YAML and legacy configs.

use scripting additions

on run argv
	if (count of argv) > 1 then error "Usage: vibe-tabs [config-file]"
	if (count of argv) is 1 then
		my launchProjects(item 1 of argv)
	else
		my launchProjects("")
	end if
end run

on launchProjects(configPath)
	set homeFolder to my homeDirectory()
	set launcherBin to my resolveExecutable("vibe-tabs", {homeFolder & "/bin/vibe-tabs", "/opt/homebrew/bin/vibe-tabs", "/usr/local/bin/vibe-tabs"})
	set launchCommand to quoted form of launcherBin
	if configPath is not "" then
		set launchCommand to launchCommand & " " & quoted form of configPath
	end if
	try
		do shell script launchCommand
	on error errorMessage number errorNumber
		if errorMessage contains "Accessibility" then
			set dialogResult to display dialog "Vibe Tabs needs Accessibility access to create native Terminal tabs." & return & return & "Enable Vibe Tabs in System Settings, then click the Dock icon again." buttons {"Cancel", "Open Settings"} default button "Open Settings" with icon caution
			if button returned of dialogResult is "Open Settings" then do shell script "/usr/bin/open 'x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility'"
		else
			display dialog "Vibe Tabs could not open your projects." & return & return & errorMessage buttons {"OK"} default button "OK" with icon stop
		end if
	end try
end launchProjects

on open theItems
	set homeFolder to my homeDirectory()
	set addBin to my resolveExecutable("vibe-tabs-add", {homeFolder & "/bin/vibe-tabs-add", "/opt/homebrew/bin/vibe-tabs-add", "/usr/local/bin/vibe-tabs-add"})
	set addedNames to {}
	repeat with droppedItem in theItems
		set itemPath to POSIX path of (droppedItem as text)
		try
			do shell script quoted form of addBin & " --gui " & quoted form of itemPath
			set end of addedNames to itemPath
		on error errorMessage number errorNumber
			-- Exit code 3 means the dialog was cancelled, so skip this folder quietly.
			if errorNumber is not 3 then
				display dialog "Vibe Tabs could not add that project." & return & return & errorMessage buttons {"OK"} default button "OK" with icon stop with title "Add to Vibe Tabs"
			end if
		end try
	end repeat
	if (count of addedNames) > 0 then
		set summaryText to (count of addedNames) as text
		if (count of addedNames) is 1 then
			set summaryText to "Added 1 project to your Vibe Tabs config."
		else
			set summaryText to "Added " & summaryText & " projects to your Vibe Tabs config."
		end if
		set dialogResult to display dialog summaryText buttons {"Done", "Open Now"} default button "Open Now" with title "Add to Vibe Tabs"
		if button returned of dialogResult is "Open Now" then my launchProjects("")
	end if
end open

on resolveExecutable(commandName, fallbackPaths)
	try
		set resolvedPath to do shell script "/bin/zsh -lc " & quoted form of ("command -v " & commandName & " 2>/dev/null")
		if resolvedPath is not "" then return resolvedPath
	on error
	end try

	repeat with fallbackPath in fallbackPaths
		try
			do shell script "/bin/test -x " & quoted form of (contents of fallbackPath)
			return contents of fallbackPath
		on error
		end try
	end repeat
	error "Required command not found: " & commandName
end resolveExecutable

on homeDirectory()
	set homeFolder to POSIX path of (path to home folder)
	if homeFolder ends with "/" then set homeFolder to text 1 thru -2 of homeFolder
	return homeFolder
end homeDirectory
