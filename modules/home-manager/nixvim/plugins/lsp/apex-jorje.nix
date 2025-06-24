{ pkgs }:

pkgs.fetchurl {
  url = "https://github.com/forcedotcom/salesforcedx-vscode/raw/f95d12156e2fff1539cfce8d6abbfc22036aed00/packages/salesforcedx-vscode-apex/jars/apex-jorje-lsp.jar";
  sha256 = "09987k6nzvnfnv9lb6f0izbxnywa9qh518p0q9zab1ccsjnsvnll";
}
