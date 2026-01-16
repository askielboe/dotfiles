{ pkgs, nur, ... }:
let
  addons = nur.legacyPackages.${pkgs.stdenv.hostPlatform.system}.repos.rycee.firefox-addons;
in
{
  launchd.agents.firefox-env = {
    enable = true;
    config = {
      ProgramArguments = [
        "/bin/sh"
        "-c"
        "launchctl setenv MOZ_LEGACY_PROFILES 1; launchctl setenv MOZ_ALLOW_DOWNGRADE 1"
      ];
      RunAtLoad = true;
    };
  };

  programs.firefox = {
    enable = true;
    profileVersion = null;

    arkenfox = {
      enable = true;
      version = "140.0";
    };

    policies = {
      ExtensionSettings = {
        "uBlock0@raymondhill.net" = {
          default_area = "navbar";
          private_browsing = true;
        };
        "{d634138d-c276-4fc8-924b-40a0ea21d284}" = {
          default_area = "navbar";
          private_browsing = true;
        };
        "sponsorBlocker@ajay.app" = {
          default_area = "menupanel";
          private_browsing = true;
        };
        "{c607c8df-14a7-4f28-894f-29571e7bf5e6}" = {
          default_area = "navbar";
          private_browsing = false;
        };
        "wayback_machine@nickcaceres.com" = {
          default_area = "menupanel";
          private_browsing = true;
        };
      };
    };

    profiles.default = {
      isDefault = true;
      extensions.force = true;
      extensions.packages = with addons; [
        onepassword-password-manager
        sponsorblock
        temporary-containers
        ublock-origin
        wayback-machine
      ];

      arkenfox = {
        enable = true;
        enableAllSections = true;
      };

      settings = {
        "browser.tabs.warnOnClose" = false;
        "browser.tabs.warnOnCloseOtherTabs" = false;
        "browser.warnOnQuit" = false;
        "browser.warnOnQuitShortcut" = false;
        "browser.sessionstore.warnOnQuit" = false;
      };

      search = {
        force = true;
        default = "ddg";
        engines = {
          "ddg" = {
            name = "DuckDuckGo";
            urls = [ { template = "https://duckduckgo.com/?q={searchTerms}"; } ];
            icon = "https://duckduckgo.com/favicon.ico";
            definedAliases = [ "@ddg" ];
          };
          "nix packages" = {
            urls = [ { template = "https://search.nixos.org/packages?query={searchTerms}"; } ];
            icon = "https://nixos.org/favicon.ico";
            definedAliases = [ "@np" ];
          };
          "google".metaData.hidden = true;
          "bing".metaData.hidden = true;
        };
      };
    };
  };
}
