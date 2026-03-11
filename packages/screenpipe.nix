{ pkgs }:

let
  version = "0.3.135";
  sources = {
    aarch64-darwin = {
      url = "https://github.com/screenpipe/screenpipe/releases/download/v${version}/screenpipe-${version}-aarch64-apple-darwin.tar.gz";
      hash = "sha256-ZsLMkaAiUCcP/dF9r6GlZh8eO8zmQ8vuZarSWtT9uFo=";
    };
    x86_64-darwin = {
      url = "https://github.com/screenpipe/screenpipe/releases/download/v${version}/screenpipe-${version}-x86_64-apple-darwin.tar.gz";
      hash = "";
    };
    x86_64-linux = {
      url = "https://github.com/screenpipe/screenpipe/releases/download/v${version}/screenpipe-${version}-x86_64-unknown-linux-gnu.tar.gz";
      hash = "";
    };
  };
  src =
    sources.${pkgs.stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${pkgs.stdenv.hostPlatform.system}");
in
pkgs.stdenv.mkDerivation {
  pname = "screenpipe";
  inherit version;

  src = pkgs.fetchurl {
    inherit (src) url hash;
  };

  sourceRoot = ".";

  nativeBuildInputs = pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.autoPatchelfHook ];

  installPhase = ''
    install -Dm755 bin/screenpipe $out/bin/screenpipe
  '';

  meta = {
    description = "AI screen & audio memory for context-aware assistance";
    homepage = "https://github.com/screenpipe/screenpipe";
    platforms = [
      "aarch64-darwin"
      "x86_64-darwin"
      "x86_64-linux"
    ];
    mainProgram = "screenpipe";
  };
}
