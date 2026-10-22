{
  buildNpmPackage,
  importNpmLock,
  makeWrapper,
  nodejs_26,
}:
buildNpmPackage {
  pname = "browse";
  version = "0.11.3";
  src = ./.;
  nodejs = nodejs_26;

  npmDeps = importNpmLock { npmRoot = ./.; };
  inherit (importNpmLock) npmConfigHook;
  dontNpmBuild = true;

  nativeBuildInputs = [ makeWrapper ];
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/lib/browse" "$out/bin"
    cp -r node_modules "$out/lib/browse/"
    makeWrapper ${nodejs_26}/bin/node "$out/bin/browse" \
      --add-flags "$out/lib/browse/node_modules/browse/bin/run.js" \
      --set BROWSE_DISABLE_UPDATE_CHECK 1 \
      --set BROWSERBASE_TELEMETRY_DISABLED 1 \
      --set-default BROWSE_LOAD_DOTENV 0
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    "$out/bin/browse" --version
    "$out/bin/browse" skills show > /dev/null
    runHook postInstallCheck
  '';
}
