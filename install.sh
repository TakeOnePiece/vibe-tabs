#!/bin/zsh
set -e

SCRIPT_PATH="${0:A}"
PROJECT_ROOT="${SCRIPT_PATH:h}"
BIN_DIR="$HOME/bin"
APP_DIR="$HOME/Applications"
APP_PATH="$APP_DIR/Vibe Tabs.app"

mkdir -p "$BIN_DIR" "$APP_DIR"
ln -sfn "$PROJECT_ROOT/bin/vibe-tab" "$BIN_DIR/vibe-tab"
ln -sfn "$PROJECT_ROOT/bin/vibe-tabs" "$BIN_DIR/vibe-tabs"
ln -sfn "$PROJECT_ROOT/bin/vibe-tabs-add" "$BIN_DIR/vibe-tabs-add"

if [[ ! -e "$HOME/.vibe-tabs.yml" && ! -e "$HOME/.vibe-tabs.yaml" ]]; then
	cp "$PROJECT_ROOT/.vibe-tabs.yml.example" "$HOME/.vibe-tabs.yml"
	print "Created ~/.vibe-tabs.yml from the example"
fi

/usr/bin/osacompile -o "$APP_PATH" "$PROJECT_ROOT/libexec/open-vibe-tabs.applescript"
cp "$PROJECT_ROOT/assets/VibeTabs.icns" "$APP_PATH/Contents/Resources/VibeTabs.icns"
/usr/bin/plutil -replace CFBundleIconFile -string VibeTabs "$APP_PATH/Contents/Info.plist"
/usr/bin/plutil -remove CFBundleIconName "$APP_PATH/Contents/Info.plist" 2>/dev/null || true
/usr/bin/plutil -replace CFBundleIdentifier -string com.takeonepiece.vibetabs "$APP_PATH/Contents/Info.plist"
# Accept dropped folders so a project can be added by dragging it onto the icon.
/usr/bin/plutil -replace CFBundleDocumentTypes -json '[{"CFBundleTypeName":"Project Folder","CFBundleTypeRole":"Editor","LSHandlerRank":"None","LSItemContentTypes":["public.folder"]}]' "$APP_PATH/Contents/Info.plist"
/usr/bin/touch "$APP_PATH"
/usr/bin/codesign --force --deep --sign - "$APP_PATH" >/dev/null

print "Installed commands:"
print "  $BIN_DIR/vibe-tab"
print "  $BIN_DIR/vibe-tabs"
print "  $BIN_DIR/vibe-tabs-add"
print "Installed app:"
print "  $APP_PATH"
print "Config:"
print "  $HOME/.vibe-tabs.yml"
