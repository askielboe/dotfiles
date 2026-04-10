{ lib, ... }:
let
  # Extension IDs to auto-install in Chromium.
  # Chromium reads External Extensions JSON files on startup and installs
  # extensions from the Chrome Web Store update server automatically.
  extensionIds = [
    "fcoeoabgfenejglbffodgkkbkcdhcgfn" # Claude
    "aeblfdkhhhdcdjpifhhbdiojplfjncoa" # 1Password
  ];

  mkExternalExtensionJson = id: {
    name = "Library/Application Support/Chromium/External Extensions/${id}.json";
    value.text = builtins.toJSON {
      external_update_url = "https://clients2.google.com/service/update2/crx";
    };
  };
in
{
  home.file = builtins.listToAttrs (map mkExternalExtensionJson extensionIds);
}
