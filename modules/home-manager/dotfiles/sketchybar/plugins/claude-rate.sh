#!/bin/bash
# Live Claude output-token throughput: a rolling 60s burn rate computed from the
# local Claude Code session logs at ~/.claude/projects/**/*.jsonl. The usage
# endpoint (claude-usage.sh) exposes only utilisation percentages, no token
# counts — these logs are the only local source of real token numbers. Logs land
# only when a response completes, so this is a burn rate (Σ output tokens of
# responses finished in the last WINDOW seconds ÷ WINDOW), not an instantaneous
# speedometer; it reads 0 when idle.

# shellcheck source=../colors.sh
source "$CONFIG_DIR/colors.sh"

WINDOW=60          # rolling burn-rate window (seconds)
GRAPH_MAX=300      # tok/s mapped to graph full-scale (tune to taste)
LOG_DIR="$HOME/.claude/projects"

now="$(date +%s)"
cutoff=$(( now - WINDOW ))

# Only recently-touched logs can hold in-window messages (2min covers the 60s
# window + slack). A single API response writes several assistant lines that
# share one requestId and repeat the same output_tokens (e.g. 12404 across 4
# lines) — dedup by requestId (sort -u) before summing. fromjson? tolerates the
# partial last line of a log being appended to live.
sum="$(fd -e jsonl . "$LOG_DIR" --changed-within 2min -X cat 2>/dev/null \
  | jq -Rr --argjson cut "$cutoff" '
      fromjson?
      | select(.type == "assistant" and .requestId != null)
      | select((.timestamp | sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601) >= $cut)
      | [.requestId, (.message.usage.output_tokens // 0)] | @tsv' \
  | sort -u | awk -F'\t' '{ s += $2 } END { print s + 0 }')"
sum="${sum:-0}"
rate=$(( sum / WINDOW ))

# Normalise to the 0–1 range the graph plots, clamped at full-scale.
frac="$(awk -v r="$rate" -v m="$GRAPH_MAX" 'BEGIN { f = r / m; if (f > 1) f = 1; printf "%.3f", f }')"

# Peach brand while active; dim when idle, red at/above full-scale.
color="$PEACH"
fill=0x30fab387
if [ "$rate" -eq 0 ]; then
  color="$OVERLAY0"
elif [ "$rate" -ge "$GRAPH_MAX" ]; then
  color="$RED"
  fill=0x30f38ba8
fi

sketchybar --set "$NAME" \
  label="${rate}/s" \
  label.color="$color" \
  icon.color="$color" \
  graph.color="$color" \
  graph.fill_color="$fill" \
  --push "$NAME" "$frac"
