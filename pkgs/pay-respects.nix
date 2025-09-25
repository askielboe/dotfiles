{ pkgs, ... }:

pkgs.rustPlatform.buildRustPackage rec {
  pname = "pay-respects";
  version = "0.7.6";

  src = pkgs.fetchFromGitHub {
    owner = "iffse";
    repo = "pay-respects";
    rev = "v${version}";
    hash = "sha256-+50MKpZgJqjuUvJeFFv8fMILkJ3cOAN7R7kmlR+98II=";
  };

  cargoHash = "sha256-TJP+GPkXwPvnBwiF0SCkn8NGz/xyrYjbUZKCbUUSqHQ=";

  buildInputs = with pkgs; lib.optionals stdenv.hostPlatform.isDarwin [
    darwin.apple_sdk.frameworks.CoreFoundation
    darwin.apple_sdk.frameworks.Security
    darwin.apple_sdk.frameworks.SystemConfiguration
  ];

  # Build all workspace members including the request-ai module
  cargoBuildFlags = [ "--workspace" ];
  cargoInstallFlags = [ "--workspace" ];

  meta = with pkgs.lib; {
    description = "Terminal command correction with AI support";
    homepage = "https://github.com/iffse/pay-respects";
    license = licenses.agpl3Only;
    maintainers = with maintainers; [ ];
    mainProgram = "pay-respects";
  };
}

