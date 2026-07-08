#!/bin/bash
# Thin wrapper for the gchat item's script. The poller is Python (gchat.py) so it
# can fan the per-space unread checks out across a thread pool; sketchybar just
# needs a script path here. We source colors.sh first so the Catppuccin colour
# vars (TEXT/PEACH/RED/OVERLAY0) reach the poller through the environment, then
# exec Python (on the sketchybar agent's PATH via services.sketchybar.extraPackages).
dir="$(cd "$(dirname "$0")" && pwd)"

# shellcheck source=../colors.sh
source "$dir/../colors.sh"

exec python3 "$dir/gchat.py" "${NAME:-gchat}"
