# shellcheck shell=bash
# Right: the (invisible) system-stats controller + its event. Sourced by
# ../sketchybarrc. Draws nothing itself — it repaints the passive cpu (items/cpu.sh),
# disk (items/disk.sh), and net_up/net_down (items/network.sh) items from one
# system_stats event via ../plugins/stats.sh. Source it after those items so they
# exist when the first event fires.
#
# stats_provider (brew: joncrangle/tap/sketchybar-system-stats) pushes the
# system_stats event every 5s over mach messages — no polling processes.
# It watches every live enN interface (en0 = Wi-Fi, plus any dock/USB Ethernet;
# see stats-provider-launch.sh); stats.sh sums whichever carries traffic.
# The provider runs as its own launchd agent (sketchybar-stats-provider in
# modules/darwin/settings/sketchybar.nix), NOT from here: a backgrounded
# child of this config script lives in sketchybar's KeepAlive process group
# and gets reaped when launchd bounces that job at login, silently killing
# the stats. A supervised agent survives login and restarts if it dies.
# The provider also registers the event itself, but only after it starts, so
# add it here first to keep the subscription order-independent.
sketchybar --add event system_stats

sketchybar --add item stats_controller right \
  --set stats_controller \
    drawing=off \
    script="$PLUGIN_DIR/stats.sh" \
  --subscribe stats_controller system_stats
