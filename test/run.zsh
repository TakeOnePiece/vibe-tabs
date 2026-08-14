#!/bin/zsh
set -euo pipefail

TEST_DIR="${0:A:h}"
PROJECT_ROOT="${TEST_DIR:h}"
TEST_OUTPUT="$(mktemp)"
INVALID_OUTPUT="$(mktemp)"
trap '/bin/rm -f "$TEST_OUTPUT" "$INVALID_OUTPUT"' EXIT

VIBE_TABS_TEST_OUTPUT="$TEST_OUTPUT" \
  VIBE_TABS_SESSION_COMMAND="$TEST_DIR/capture-args.zsh" \
  "$PROJECT_ROOT/bin/vibe-tabs" "$TEST_DIR/fixtures/config.yml"

[[ "$(wc -l < "$TEST_OUTPUT" | tr -d ' ')" == "2" ]]
first_line="$(sed -n '1p' "$TEST_OUTPUT")"
second_line="$(sed -n '2p' "$TEST_OUTPUT")"

[[ "$first_line" == --layout\|even-horizontal\|--profile\|Pro\|--new-window\|alpha-test-mac\|/tmp\|* ]]
[[ "$second_line" == --layout\|tiled\|--profile\|Ocean\|beta-test-mac\|/tmp\|* ]]
[[ "$second_line" != *"--new-window"* ]]

first_codex="$(print -r -- "$first_line" | tr '|' '\n' | tail -n 1 | sed 's/^vibe-json://')"
second_gemini="$(print -r -- "$second_line" | tr '|' '\n' | sed -n '7p' | sed 's/^vibe-json://')"
print -r -- "$first_codex" | base64 -D | jq -e '.agent == "codex" and .dangerous == true and .args == ""' >/dev/null
print -r -- "$second_gemini" | base64 -D | jq -e '.agent == "gemini" and .dangerous == true and .args == "--model gemini-2.5-pro"' >/dev/null

if VIBE_TABS_SESSION_COMMAND="$TEST_DIR/capture-args.zsh" \
  VIBE_TABS_TEST_OUTPUT="$INVALID_OUTPUT" \
  "$PROJECT_ROOT/bin/vibe-tabs" "$TEST_DIR/fixtures/invalid-dangerous.yml" >"$INVALID_OUTPUT" 2>&1; then
  print -u2 "Expected invalid dangerous-mode configuration to fail"
  exit 1
fi

rg -q 'Invalid session entry' "$INVALID_OUTPUT"
osacompile -o /tmp/VibeTabTest.scpt "$PROJECT_ROOT/libexec/open-vibe-tab.applescript"
osacompile -o /tmp/VibeTabsAppTest.scpt "$PROJECT_ROOT/libexec/open-vibe-tabs.applescript"
dangerous_args="$(osascript \
  -e 'set testedScript to load script POSIX file "/tmp/VibeTabTest.scpt"' \
  -e "return testedScript's effectiveAgentArgs(\"codex\", true, \"--model gpt\", \"\")")"
[[ "$dangerous_args" == "--model gpt --yolo" ]]

print "All tests passed"
