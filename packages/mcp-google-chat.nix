{ pkgs }:

let
  version = "1.0.1";
  sources = {
    aarch64-darwin = {
      url = "https://github.com/nguyenvanduocit/google-chat-mcp/releases/download/v${version}/google-chat-mcp_darwin_arm64.tar.gz";
      hash = "sha256-+QozwsoVASJcWhu0V/4/lmG7/ZvrJzgTgEPyzcdCMWc=";
    };
    x86_64-linux = {
      url = "https://github.com/nguyenvanduocit/google-chat-mcp/releases/download/v${version}/google-chat-mcp_linux_amd64.tar.gz";
      hash = "";
    };
  };
  src =
    sources.${pkgs.stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${pkgs.stdenv.hostPlatform.system}");
in
pkgs.stdenv.mkDerivation {
  pname = "mcp-google-chat";
  inherit version;

  src = pkgs.fetchurl {
    inherit (src) url hash;
  };

  sourceRoot = ".";

  installPhase = ''
    install -Dm755 google-chat-mcp $out/bin/google-chat-mcp
  '';

  meta = {
    description = "Google Chat MCP server for AI assistants";
    homepage = "https://github.com/nguyenvanduocit/google-chat-mcp";
    platforms = [
      "aarch64-darwin"
      "x86_64-linux"
    ];
    mainProgram = "google-chat-mcp";
  };
}
