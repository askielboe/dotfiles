_: {
  security.pam.services.sudo_local = {
    touchIdAuth = true;
    watchIdAuth = true;
    reattach = true;
  };

  # Let straightwire auto-recover a driver-wedged USB DAC by bouncing coreaudiod.
  # Scoped to exactly `killall coreaudiod` — nothing else runs passwordless.
  environment.etc."sudoers.d/straightwire-coreaudiod".text =
    "askielboe ALL=(root) NOPASSWD: /usr/bin/killall coreaudiod\n";
}
