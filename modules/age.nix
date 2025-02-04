{ config, ... }:

{
  age.secrets.anthropic.file = ../secrets/anthropic.age;
  age.secrets.rclone = {
    file = ../secrets/rclone.age;
    path = "${config.home.homeDirectory}/.config/rclone/rclone.conf";
  };
  age.secrets.resticprofile = {
    file = ../secrets/resticprofile.age;
    path = "${config.home.homeDirectory}/.config/resticprofile/profiles.yaml";
  };
}
