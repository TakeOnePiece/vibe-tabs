-- macOS app entry point. The command handles YAML and legacy configs.

on run argv
	set homeFolder to my homeDirectory()
	set launcherBin to my resolveExecutable("vibe-tabs", {homeFolder & "/bin/vibe-tabs", "/opt/homebrew/bin/vibe-tabs", "/usr/local/bin/vibe-tabs"})
	set launchCommand to quoted form of launcherBin
	if (count of argv) is 1 then
		set launchCommand to launchCommand & " " & quoted form of (item 1 of argv)
	else if (count of argv) > 1 then
		error "Usage: vibe-tabs [config-file]"
	end if
	do shell script launchCommand
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
