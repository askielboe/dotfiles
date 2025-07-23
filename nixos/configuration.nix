{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Boot loader
  boot.loader.grub = {
    enable = true;
    device = "/dev/vda";
    # Add timeout for recovery
    timeout = 10;
  };

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.trusted-users = [ "root" "@wheel" ];

  # Cachix configuration with personal cache
  nix.settings.substituters = [
    "https://cache.nixos.org/"
    "https://nix-community.cachix.org"
    "https://askielboe-dotfiles.cachix.org"
  ];
  nix.settings.trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "askielboe-dotfiles.cachix.org-1:z9lraZ2RBg4n6fXkSDvQ9v+TuvckynTkhTYChROQMxc="
  ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Time zone and locale
  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable SSH
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
    # Ensure SSH starts early and stays running
    startWhenNeeded = false;
  };

  # Firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
    # Ensure firewall doesn't block existing SSH connections
    checkReversePath = false;
  };

  # Define user account
  users.users.askielboe = {
    isNormalUser = true;
    description = "askielboe";
    extraGroups = [ "wheel" "docker" ];
    shell = pkgs.zsh;
    # Set password for recovery console access
    hashedPassword = "$y$j9T$x4tXRPfOPEADNfeZcBdIq0$U0y6iq9tfA.iyKpg4zxfcRHZDFbPYz.4EEdwx0HJ8j8";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAiEQSoDvicfFl8Es0v6pGlY/NZy7WzxG8Vm7EL/h8eR ShellFish@iPad-23072025"
    ];
  };

  # Enable root login for emergency recovery
  users.users.root = {
    # Set password for root (recovery console access)
    hashedPassword = "$y$j9T$x4tXRPfOPEADNfeZcBdIq0$U0y6iq9tfA.iyKpg4zxfcRHZDFbPYz.4EEdwx0HJ8j8";
  };

  # Enable zsh system-wide
  programs.zsh.enable = true;

  # Enable docker
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };

  # System packages (minimal)
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
    cachix
  ];

  system.stateVersion = "25.05";
}