#!/bin/zsh
set -e

SCRIPT_PATH="${0:A}"
PROJECT_ROOT="${SCRIPT_PATH:h}"
BIN_DIR="$HOME/bin"
APP_DIR="$HOME/Applications"
APP_PATH="$APP_DIR/Coding Sessions.app"

mkdir -p "$BIN_DIR" "$APP_DIR"
ln -sfn "$PROJECT_ROOT/bin/coding-session" "$BIN_DIR/coding-session"
ln -sfn "$PROJECT_ROOT/bin/coding-sessions" "$BIN_DIR/coding-sessions"

if [[ ! -e "$HOME/.coding-sessions.yml" && ! -e "$HOME/.coding-sessions.yaml" ]]; then
	cp "$PROJECT_ROOT/.coding-sessions.yml.example" "$HOME/.coding-sessions.yml"
	print "Created ~/.coding-sessions.yml from the example"
fi

/usr/bin/osacompile -o "$APP_PATH" "$PROJECT_ROOT/libexec/open-coding-sessions.applescript"
cp "$PROJECT_ROOT/assets/applet.icns" "$APP_PATH/Contents/Resources/applet.icns"
/usr/bin/touch "$APP_PATH"
/usr/bin/codesign --force --deep --sign - "$APP_PATH" >/dev/null

print "Installed commands:"
print "  $BIN_DIR/coding-session"
print "  $BIN_DIR/coding-sessions"
print "Installed app:"
print "  $APP_PATH"
print "Config:"
print "  $HOME/.coding-sessions.yml"
