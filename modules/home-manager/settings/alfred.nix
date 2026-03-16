{
  lib,
  private,
  ...
}:
let
  alfredPrefs = "Library/Application Support/Alfred/Alfred.alfredpreferences/preferences";
  localPrefs = "${alfredPrefs}/local/${private.machine.alfredLocalHash}";
  plist = attrs: lib.generators.toPlist { } attrs;

  # All 32 built-in web search engines
  webSearchEngines = [
    "amazon"
    "applemaps"
    "ask"
    "bing"
    "drive"
    "drivesearch"
    "duckduckgo"
    "ebay"
    "facebook"
    "flickr"
    "gmail"
    "gmailsearch"
    "google"
    "gtranslate"
    "help"
    "images"
    "imdb"
    "linkedin"
    "lucky"
    "maps"
    "pinterest"
    "rottentomatoes"
    "twitter"
    "twittersearch"
    "twitteruser"
    "urls"
    "weather"
    "wiki"
    "wolfram"
    "yahoo"
    "youtube"
    "yubnub"
  ];

  # Generate disabled plist for each web search engine
  webSearchFiles = builtins.listToAttrs (
    map (
      engine:
      let
        # urls uses "enabled = false" instead of "disabled = true"
        attrs = if engine == "urls" then { enabled = false; } else { disabled = true; };
      in
      {
        name = "${alfredPrefs}/features/websearch/${engine}/prefs.plist";
        value = {
          text = plist attrs;
        };
      }
    ) webSearchEngines
  );
in
{
  home.file = webSearchFiles // {

    # Appearance
    "${alfredPrefs}/appearance/options/prefs.plist".text = plist {
      hidehat = true;
      hidemenu = true;
      nativedarkmode = true;
    };

    # Default results (global)
    "${alfredPrefs}/features/defaultresults/prefs.plist".text = plist {
      showContacts = false;
      showPreferences = false;
    };

    # File search
    "${alfredPrefs}/features/filesearch/prefs.plist".text = plist {
      quicksearch = false;
    };
    "${alfredPrefs}/features/filesearch/find/prefs.plist".text = plist {
      enabled = false;
    };
    "${alfredPrefs}/features/filesearch/open/prefs.plist".text = plist {
      enabled = false;
    };
    "${alfredPrefs}/features/filesearch/in/prefs.plist".text = plist {
      enabled = false;
    };
    "${alfredPrefs}/features/filesearch/tag/prefs.plist".text = plist {
      enabled = false;
    };

    # Dictionary
    "${alfredPrefs}/features/dictionary/prefs.plist".text = plist {
      definitionsOnly = false;
    };
    "${alfredPrefs}/features/dictionary/define/prefs.plist".text = plist {
      enabled = false;
    };
    "${alfredPrefs}/features/dictionary/spell/prefs.plist".text = plist {
      enabled = false;
    };

    # System commands — all keywords disabled
    "${alfredPrefs}/features/system/prefs.plist".text = plist {
      emptytrashKeywordEnabled = false;
      forcequitKeywordEnabled = false;
      hideKeywordEnabled = false;
      lockKeywordEnabled = false;
      logoutKeywordEnabled = false;
      quitKeywordEnabled = false;
      quitallKeywordEnabled = false;
      restartKeywordEnabled = false;
      screensaverKeywordEnabled = false;
      showtrashKeywordEnabled = false;
      shutdownKeywordEnabled = false;
      sleepKeywordEnabled = false;
      sleepdisplaysKeywordEnabled = false;
      volumedownKeywordEnabled = false;
      volumemuteKeywordEnabled = false;
      volumeupKeywordEnabled = false;
    };

    # Web search (top level)
    "${alfredPrefs}/features/websearch/prefs.plist".text = plist {
      onlyShowEnabledInPrefs = true;
    };

    # Local/machine-specific: hotkey (Cmd+Space)
    "${localPrefs}/hotkey/prefs.plist".text = plist {
      default = {
        key = 49;
        mod = 1048576;
        string = " ";
      };
    };

    # Local: default results scope
    "${localPrefs}/features/defaultresults/prefs.plist".text = plist {
      scope = [
        "/Applications/Xcode.app/Contents/Applications"
        "/Developer/Applications"
        "/opt/homebrew/Cellar"
        "/System/Library/CoreServices/Applications"
        "/usr/local/Cellar"
      ];
    };

    # Local: default results scope options
    "${localPrefs}/features/defaultresults/scope/prefs.plist".text = plist {
      includehome = false;
    };
  };
}
