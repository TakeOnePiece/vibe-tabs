#!/bin/zsh
set -euo pipefail

print -r -- "${(j:|:)@}" >> "$VIBE_TABS_TEST_OUTPUT"
