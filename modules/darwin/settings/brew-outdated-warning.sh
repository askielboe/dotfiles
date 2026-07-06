#!/usr/bin/env bash
# Best-effort, non-fatal warning: flag declared Homebrew *formulae* (not casks, and
# not their dependencies) that have a newer version available. Invoked at the tail of
# the nix-darwin Homebrew activation (as root); drops to the primary user to run brew,
# since Homebrew refuses to run as root.
#
# Freshness tracks brew's last metadata refresh (autoUpdate is off in homebrew.nix),
# so it may under-report — run `brew update` occasionally to keep it honest. It never
# blocks activation: every path exits 0.
#
# Usage: brew-outdated-warning.sh <primary-user> <formula-leaf-name>...
set -u

primaryUser="$1"
shift
declaredFormulae=" $* " # space-padded so the case glob below matches whole words

brewBin=""
for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
  if [ -x "$candidate" ]; then
    brewBin="$candidate"
    break
  fi
done
[ -n "$brewBin" ] || exit 0

# brew must not run as root; drop to the primary user (no password needed under root).
# HOMEBREW_NO_AUTO_UPDATE keeps this a fast, local version comparison (no network).
outdated=$(/usr/bin/sudo --user="$primaryUser" --set-home \
  /usr/bin/env HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_ANALYTICS=1 \
  "$brewBin" outdated --formula --verbose 2>/dev/null || true)

# `brew outdated` prints either a short name or a tap-qualified one (e.g.
# `max-sixty/worktrunk/wt`); match on the leaf so both forms hit our declared list.
report=$(printf '%s\n' "$outdated" | while IFS= read -r line; do
  [ -z "$line" ] && continue
  name="${line%% *}"
  leaf="${name##*/}"
  case "$declaredFormulae" in
  *" $leaf "*) echo "$line" ;;
  esac
done)

[ -n "$report" ] || exit 0

echo ""
echo "⚠️  Outdated Homebrew formulae (declared in nix — candidates for nixpkgs or removal):"
printf '%s\n' "$report" | while IFS= read -r reportLine; do
  echo "      $reportLine"
done
echo "   → run 'brew upgrade <name>' to bump, or migrate it to nixpkgs."
echo ""
