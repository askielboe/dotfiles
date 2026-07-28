{ lib, ... }:
{
  # Spotlight is trimmed, not killed. The hard constraint on macOS Tahoe: Mail's
  # in-app search is built on the Spotlight index of ~/Library/Mail (on the data
  # volume, mounted at /). Disabling indexing there is exactly what breaks Mail
  # search. Since Mail search must keep working, the indexing daemons (mds,
  # spotlightknowledged, media/photoanalysisd) MUST keep running — they cannot be
  # turned off without losing Mail. So we don't fight that here.
  #
  # What we DO declaratively:
  #   - Assert boot/data-volume indexing stays ON, so Mail search survives any
  #     earlier `mdutil` fiddling or a `pmset restoredefaults`-style reset.
  #   - Disable Siri/Spotlight Suggestions + Lookup (the part you don't use).
  #
  # The Cmd+Space hotkey is already disabled in system.nix. Index *size* is trimmed
  # out-of-band via System Settings → Spotlight → Privacy (GUI, not declarable) and
  # by disabling indexing on external volumes — see the plan's manual steps.
  # DEVONthink's own search is independent of system Spotlight and is unaffected.
  #
  # postActivation runs as root at the end of `darwin-rebuild switch` (`hs`).
  # mkAfter so this concatenates with the postActivation.text in power.nix /
  # firewall-prune.nix (the option is types.lines).
  system.activationScripts.postActivation.text = lib.mkAfter ''
    echo "spotlight: ensuring boot-volume indexing stays ON (Mail search needs it)" >&2
    /usr/bin/mdutil -i on / || true
  '';

  # Turn off Siri/Spotlight Suggestions + Lookup suggestions (per-user domain).
  system.defaults.CustomUserPreferences = {
    "com.apple.lookup.shared".LookupSuggestionsDisabled = true;
  };
}
