{ pkgs }:

let
  version = "0.16.0";
  sources = {
    aarch64-darwin = {
      url = "https://github.com/borgbase/vykar/releases/download/v${version}/vykar-v${version}-aarch64-apple-darwin.tar.gz";
      hash = "sha256-7HGZOWC+hnmw146x1av+CVIOATjSWhukb7wsnHX8iWU=";
    };
    x86_64-linux = {
      url = "https://github.com/borgbase/vykar/releases/download/v${version}/vykar-v${version}-x86_64-unknown-linux-gnu.tar.gz";
      hash = "sha256-eEP77y+qfFmuQvQGzaMr5e1fQnsG5joJexxVC0nllFY=";
    };
    aarch64-linux = {
      url = "https://github.com/borgbase/vykar/releases/download/v${version}/vykar-v${version}-aarch64-unknown-linux-gnu.tar.gz";
      hash = "sha256-dNR4RF5tAhAFppmBrv7ruYruYlVV9uZZReGthCkRLrw=";
    };
  };
  src =
    sources.${pkgs.stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${pkgs.stdenv.hostPlatform.system}");
in
pkgs.stdenv.mkDerivation {
  pname = "vykar";
  inherit version;

  src = pkgs.fetchurl {
    inherit (src) url hash;
  };

  sourceRoot = ".";

  nativeBuildInputs = pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.autoPatchelfHook ];

  installPhase = ''
    runHook preInstall
    install -Dm755 vykar $out/bin/vykar
    install -Dm755 vykar-server $out/bin/vykar-server
  '' + pkgs.lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
    install -Dm755 vykar-gui $out/bin/vykar-gui
  '' + pkgs.lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
    mkdir -p "$out/Applications"
    cp -R "Vykar Backup.app" "$out/Applications/"
  '' + ''
    runHook postInstall
  '';

  meta = {
    description = "Fast, encrypted, deduplicated backup tool written in Rust";
    homepage = "https://vykar.borgbase.com/";
    platforms = [
      "aarch64-darwin"
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "vykar";
  };
}
