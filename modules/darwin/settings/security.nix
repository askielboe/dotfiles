{ ... }: {
  security = {
    # Enable Touch ID for sudo
    pam.services.sudo_local.touchIdAuth = true;
  };
}
