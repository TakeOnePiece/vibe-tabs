-- Open one named project in tmux, with one pane per configured coding command.
-- Usage: vibe-tab [session-name] /path/to/project [command ...]

on run argv
	set requestedLayout to "auto"
	set effectiveArgs to argv
	if (count of argv) > 1 and item 1 of argv is "--layout" then
		set requestedLayout to item 2 of argv
		if (count of argv) > 2 then
			set effectiveArgs to items 3 thru -1 of argv
		else
			set effectiveArgs to {}
		end if
	end if

	if (count of effectiveArgs) is 1 then
		openProject(item 1 of effectiveArgs, "", {}, requestedLayout)
	else if (count of effectiveArgs) is 2 then
		openProject(item 2 of effectiveArgs, item 1 of effectiveArgs, {}, requestedLayout)
	else if (count of effectiveArgs) > 2 then
		set paneSpecs to items 3 thru -1 of effectiveArgs
		openProject(item 2 of effectiveArgs, item 1 of effectiveArgs, paneSpecs, requestedLayout)
	else
		error "Usage: vibe-tab [--layout layout] [session-name] /path/to/project [command ...]"
	end if
end run

on openProject(rawFolder, requestedName, configuredPanes, requestedLayout)
	set homeFolder to my homeDirectory()
	set tmuxBin to my resolveExecutable("tmux", {"/opt/homebrew/bin/tmux", "/usr/local/bin/tmux"})
	set projectFolder to my expandHomePath(rawFolder, homeFolder)

	do shell script "/bin/test -d " & quoted form of projectFolder
	set canonicalFolder to do shell script "/bin/zsh -c " & quoted form of ("cd " & quoted form of projectFolder & " && /bin/pwd -P")
	set projectName to do shell script "/usr/bin/basename " & quoted form of canonicalFolder

	if requestedName is "" then set requestedName to projectName
	set sessionName to my slugify(requestedName)
	if sessionName is "" then error "Session name must contain a letter or number"

	set paneSpecs to {}
	repeat with configuredPane in configuredPanes
		set paneSpec to my trimText(contents of configuredPane)
		if paneSpec is not "" then set end of paneSpecs to paneSpec
	end repeat
	if (count of paneSpecs) is 0 then set paneSpecs to {"claude", "codex"}
	set layoutName to my normalizeLayout(requestedLayout)

	set sessionExists to true
	try
		do shell script quoted form of tmuxBin & " has-session -t " & quoted form of ("=" & sessionName)
	on error
		set sessionExists to false
	end try

	if sessionExists is false then
		set paneCommands to {}
		set paneTitles to {}
		set codexRenamePositions to {}
		set panePosition to 0

		repeat with paneSpecRef in paneSpecs
			set panePosition to panePosition + 1
			set paneSpec to contents of paneSpecRef

			if paneSpec is "claude" then
				set paneCommand to my claudeCommand(sessionName, homeFolder)
				set paneTitle to sessionName & "-claude"
			else if paneSpec is "codex" then
				set codexResult to my codexCommand(sessionName, homeFolder)
				set paneCommand to commandText of codexResult
				set paneTitle to sessionName & "-codex"
				if renameAfterLaunch of codexResult then set end of codexRenamePositions to panePosition
			else
				set paneCommand to "/bin/zsh -lc " & quoted form of (paneSpec & "; exec /bin/zsh -l")
				set paneTitle to sessionName & "-" & my commandLabel(paneSpec, panePosition)
			end if

			set end of paneCommands to paneCommand
			set end of paneTitles to paneTitle
		end repeat

		set paneIDs to {}
		set firstPaneCommand to item 1 of paneCommands
		set createCommand to quoted form of tmuxBin & " new-session -d -P -F " & quoted form of "#{pane_id}" & " -s " & quoted form of sessionName & " -c " & quoted form of canonicalFolder & " " & quoted form of firstPaneCommand
		set firstPaneID to do shell script createCommand
		set end of paneIDs to firstPaneID

		if (count of paneCommands) > 1 then
			repeat with panePosition from 2 to count of paneCommands
				set splitCommand to quoted form of tmuxBin & " split-window -h -P -F " & quoted form of "#{pane_id}" & " -t " & quoted form of sessionName & " -c " & quoted form of canonicalFolder & " " & quoted form of (item panePosition of paneCommands)
				set newPaneID to do shell script splitCommand
				set end of paneIDs to newPaneID
			end repeat
		end if

		if (count of paneCommands) > 1 then
			if layoutName is "auto" then
				if (count of paneCommands) is 2 then
					set effectiveLayout to "even-horizontal"
				else
					set effectiveLayout to "tiled"
				end if
			else
				set effectiveLayout to layoutName
			end if
			do shell script quoted form of tmuxBin & " select-layout -t " & quoted form of sessionName & " " & quoted form of effectiveLayout
		end if

		repeat with panePosition from 1 to count of paneIDs
			do shell script quoted form of tmuxBin & " select-pane -t " & quoted form of (item panePosition of paneIDs) & " -T " & quoted form of (item panePosition of paneTitles)
		end repeat
		do shell script quoted form of tmuxBin & " rename-window -t " & quoted form of sessionName & " " & quoted form of sessionName
		do shell script quoted form of tmuxBin & " select-pane -t " & quoted form of firstPaneID

		if (count of codexRenamePositions) > 0 then
			delay 3
			repeat with renamePositionRef in codexRenamePositions
				set codexPaneID to item (contents of renamePositionRef) of paneIDs
				do shell script quoted form of tmuxBin & " send-keys -t " & quoted form of codexPaneID & " -l " & quoted form of ("/rename " & sessionName)
				do shell script quoted form of tmuxBin & " send-keys -t " & quoted form of codexPaneID & " C-m"
				delay 0.5
				do shell script quoted form of tmuxBin & " send-keys -t " & quoted form of codexPaneID & " C-m"
			end repeat
		end if
	end if

	-- Keep tmux from overwriting Terminal's stable custom tab title.
	try
		do shell script quoted form of tmuxBin & " set-option -t " & quoted form of sessionName & " set-titles off"
	on error
	end try

	if my focusNamedTerminalTab(sessionName) then return

	set attachedTTY to ""
	try
		set attachedTTY to do shell script quoted form of tmuxBin & " list-clients -t " & quoted form of sessionName & " -F " & quoted form of "#{client_tty}" & " 2>/dev/null | /usr/bin/head -n 1"
	on error
		set attachedTTY to ""
	end try

	if attachedTTY is not "" then
		if my nameAndFocusTerminalTab(attachedTTY, sessionName) then return
		tell application "Terminal" to activate
		return
	end if

	set attachCommand to quoted form of tmuxBin & " attach-session -t " & quoted form of sessionName
	tell application "Terminal"
		activate
		if (count of windows) is 0 then
			set launchedTab to do script attachCommand
			my waitForTmuxClient(tmuxBin, sessionName)
			set custom title of launchedTab to sessionName
			set title displays custom title of launchedTab to true
		else
			set targetWindow to front window
			set oldTabCount to count of tabs of targetWindow
			tell application "System Events" to key code 17 using command down
			delay 0.3

			if (count of tabs of targetWindow) > oldTabCount then
				set launchedTab to selected tab of targetWindow
				do script attachCommand in launchedTab
				my waitForTmuxClient(tmuxBin, sessionName)
				set custom title of launchedTab to sessionName
				set title displays custom title of launchedTab to true
			else
				set launchedTab to do script attachCommand
				my waitForTmuxClient(tmuxBin, sessionName)
				set custom title of launchedTab to sessionName
				set title displays custom title of launchedTab to true
			end if
		end if
	end tell
end openProject

on claudeCommand(sessionName, homeFolder)
	set claudeBin to my resolveExecutable("claude", {homeFolder & "/.local/bin/claude", homeFolder & "/.claude/local/claude", "/opt/homebrew/bin/claude", "/usr/local/bin/claude"})
	set rgBin to my resolveExecutable("rg", {"/opt/homebrew/bin/rg", "/usr/local/bin/rg"})
	set claudeProjects to homeFolder & "/.claude/projects"
	set titleNeedle to "\"customTitle\":\"" & sessionName & "\""
	set claudeLookup to quoted form of rgBin & " -l -F " & quoted form of titleNeedle & " " & quoted form of claudeProjects & " --glob '*.jsonl' 2>/dev/null | /usr/bin/head -n 1 | /usr/bin/xargs /usr/bin/basename 2>/dev/null | /usr/bin/sed 's/\\.jsonl$//'"
	try
		set claudeSessionID to do shell script claudeLookup
	on error
		set claudeSessionID to ""
	end try

	if claudeSessionID is "" then
		set claudeLaunch to quoted form of claudeBin & " --name " & quoted form of sessionName
	else
		set claudeLaunch to quoted form of claudeBin & " --resume " & quoted form of claudeSessionID & " --name " & quoted form of sessionName
	end if
	return claudeLaunch & "; exec /bin/zsh -l"
end claudeCommand

on codexCommand(sessionName, homeFolder)
	set codexBin to my resolveExecutable("codex", {homeFolder & "/.local/bin/codex", "/opt/homebrew/bin/codex", "/usr/local/bin/codex"})
	set jqBin to my resolveExecutable("jq", {"/opt/homebrew/bin/jq", "/usr/local/bin/jq", "/usr/bin/jq"})
	set codexIndex to homeFolder & "/.codex/session_index.jsonl"
	set codexState to homeFolder & "/.codex/state_5.sqlite"
	set codexLookup to quoted form of jqBin & " -r --arg name " & quoted form of sessionName & " " & quoted form of "select(.thread_name == $name) | .id" & " " & quoted form of codexIndex & " 2>/dev/null | /usr/bin/tail -n 1"
	try
		set codexSessionID to do shell script codexLookup
	on error
		set codexSessionID to ""
	end try

	if codexSessionID is "" then
		set codexLookup to "/usr/bin/sqlite3 " & quoted form of codexState & " " & quoted form of ("SELECT id FROM threads WHERE name='" & sessionName & "' AND archived=0 ORDER BY updated_at DESC LIMIT 1;")
		try
			set codexSessionID to do shell script codexLookup
		on error
			set codexSessionID to ""
		end try
	end if

	set codexExtraArgs to ""
	try
		set codexExtraArgs to do shell script "/bin/zsh -lc " & quoted form of "/usr/bin/printf '%s' \"${VIBE_TABS_CODEX_ARGS-}\""
	on error
		set codexExtraArgs to ""
	end try

	if codexSessionID is "" then
		set codexLaunch to quoted form of codexBin
		if codexExtraArgs is not "" then set codexLaunch to codexLaunch & " " & codexExtraArgs
		return {commandText:(codexLaunch & "; exec /bin/zsh -l"), renameAfterLaunch:true}
	else
		set codexLaunch to quoted form of codexBin & " resume"
		if codexExtraArgs is not "" then set codexLaunch to codexLaunch & " " & codexExtraArgs
		return {commandText:(codexLaunch & " " & quoted form of codexSessionID & "; exec /bin/zsh -l"), renameAfterLaunch:false}
	end if
end codexCommand

on waitForTmuxClient(tmuxBin, sessionName)
	repeat 20 times
		try
			set clientTTY to do shell script quoted form of tmuxBin & " list-clients -t " & quoted form of sessionName & " -F " & quoted form of "#{client_tty}" & " 2>/dev/null | /usr/bin/head -n 1"
			if clientTTY is not "" then
				delay 0.2
				return
			end if
		on error
		end try
		delay 0.25
	end repeat
end waitForTmuxClient

on focusNamedTerminalTab(sessionName)
	tell application "Terminal"
		repeat with terminalWindow in windows
			repeat with terminalTab in tabs of terminalWindow
				try
					if (custom title of terminalTab as text) is sessionName then
						set selected tab of terminalWindow to terminalTab
						set frontmost of terminalWindow to true
						activate
						return true
					end if
				on error
				end try
			end repeat
		end repeat
	end tell
	return false
end focusNamedTerminalTab

on nameAndFocusTerminalTab(clientTTY, sessionName)
	tell application "Terminal"
		repeat with terminalWindow in windows
			repeat with terminalTab in tabs of terminalWindow
				try
					if (tty of terminalTab as text) is clientTTY then
						set custom title of terminalTab to sessionName
						set title displays custom title of terminalTab to true
						set selected tab of terminalWindow to terminalTab
						set frontmost of terminalWindow to true
						activate
						return true
					end if
				on error
				end try
			end repeat
		end repeat
	end tell
	return false
end nameAndFocusTerminalTab

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

on commandLabel(commandText, panePosition)
	set firstWord to do shell script "/usr/bin/printf '%s' " & quoted form of commandText & " | /usr/bin/awk '{print $1}' | /usr/bin/xargs /usr/bin/basename 2>/dev/null"
	set labelText to my slugify(firstWord)
	if labelText is "" then set labelText to "pane-" & panePosition
	return labelText
end commandLabel

on normalizeLayout(layoutName)
	if layoutName is "" or layoutName is "auto" then return "auto"
	if layoutName is "even-horizontal" then return layoutName
	if layoutName is "even-vertical" then return layoutName
	if layoutName is "main-horizontal" then return layoutName
	if layoutName is "main-vertical" then return layoutName
	if layoutName is "tiled" then return layoutName
	error "Unsupported tmux layout: " & layoutName
end normalizeLayout

on slugify(inputText)
	return do shell script "/usr/bin/printf '%s' " & quoted form of inputText & " | /usr/bin/tr -cs '[:alnum:]_-' '-' | /usr/bin/sed 's/^-*//; s/-*$//'"
end slugify

on trimText(inputText)
	return do shell script "/usr/bin/printf '%s' " & quoted form of inputText & " | /usr/bin/sed 's/^[[:space:]]*//; s/[[:space:]]*$//'"
end trimText

on homeDirectory()
	set homeFolder to POSIX path of (path to home folder)
	if homeFolder ends with "/" then set homeFolder to text 1 thru -2 of homeFolder
	return homeFolder
end homeDirectory

on expandHomePath(rawPath, homeFolder)
	if rawPath is "~" then return homeFolder
	if rawPath starts with "~/" then return homeFolder & text 2 thru -1 of rawPath
	return rawPath
end expandHomePath
