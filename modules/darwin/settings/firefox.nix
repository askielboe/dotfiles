{ pkgs, config, ... }:
{
  environment.systemPackages = [ pkgs.defaultbrowser ];

  system.activationScripts.postActivation.text = ''
    sudo -u ${config.system.primaryUser} ${pkgs.defaultbrowser}/bin/defaultbrowser firefox
  '';
}
