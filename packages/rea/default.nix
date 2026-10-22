{
  lib,
  buildNpmPackage,
  importNpmLock,
  makeWrapper,
  nodejs_26,
  procps,
  stdenv,
}:
buildNpmPackage {
  pname = "rea";
  version = "6.7.0";
  src = ./.;
  nodejs = nodejs_26;

  npmDeps = importNpmLock { npmRoot = ./.; };
  inherit (importNpmLock) npmConfigHook;
  dontNpmBuild = true;
  # Optional Frida bindings download native code during installation, outside Nix's fetchers.
  npmRebuildFlags = [ "--ignore-scripts" ];

  nativeBuildInputs = [ makeWrapper ];
  installPhase = ''
    runHook preInstall
    rm -rf node_modules/frida
    mkdir -p "$out/lib/rea" "$out/bin"
    cp -r node_modules "$out/lib/rea/"
    makeWrapper ${nodejs_26}/bin/node "$out/bin/rea" \
      --add-flags "$out/lib/rea/node_modules/rea-agents/scripts/rea.mjs" \
      --prefix PATH : ${
        lib.makeBinPath ([ nodejs_26 ] ++ lib.optionals stdenv.hostPlatform.isLinux [ procps ])
      }
    ln -s rea "$out/bin/rea-agents"
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    "$out/bin/rea" --version
    "$out/bin/rea" --help > /dev/null
    runHook postInstallCheck
  '';

  meta = {
    description = "Reverse engineering CLI and MCP server";
    homepage = "https://github.com/morluto/rea";
    license = lib.licenses.mit;
    mainProgram = "rea";
    platforms = lib.platforms.unix;
  };
}
