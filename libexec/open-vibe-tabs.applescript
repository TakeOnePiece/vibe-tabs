-- macOS app entry point. The command handles YAML and legacy configs.

use scripting additions

on run argv
	set homeFolder to my homeDirectory()
	set launcherBin to my resolveExecutable("vibe-tabs", {homeFolder & "/bin/vibe-tabs", "/opt/homebrew/bin/vibe-tabs", "/usr/local/bin/vibe-tabs"})
	set launchCommand to quoted form of launcherBin
	if (count of argv) is 1 then
		set launchCommand to launchCommand & " " & quoted form of (item 1 of argv)
	else if (count of argv) > 1 then
		error "Usage: vibe-tabs [config-file]"
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
end run

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
