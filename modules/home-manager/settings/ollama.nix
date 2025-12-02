{ pkgs, ... }:

{
  services = {
    ollama = {
      enable = false;
    };
  };
}
