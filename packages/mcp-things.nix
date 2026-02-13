{ pkgs, src }:

let
  things-py = pkgs.python312Packages.buildPythonPackage {
    pname = "things-py";
    version = "1.0.0";
    format = "wheel";
    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/e4/31/3ac1f88d40a9f03d761e08be9c89f6419b41e8be7941c3909929445df246/things_py-1.0.0-py3-none-any.whl";
      hash = "sha256-m8bKAg9J82hq6c0qYQyo8Ai9mQxtCLF7PrgMLrGdz2k=";
    };
    doCheck = false;
  };

  fastmcp = pkgs.python312Packages.fastmcp.overridePythonAttrs (old: {
    pythonRelaxDeps = [ "mcp" ];
    doCheck = false;
  });
in

pkgs.python312Packages.buildPythonApplication {
  pname = "things-mcp";
  version = "0.7.2";
  inherit src;
  pyproject = true;
  build-system = [ pkgs.python312Packages.hatchling ];
  dependencies = with pkgs.python312Packages; [
    fastmcp
    httpx
    things-py
  ];
  meta.mainProgram = "things-mcp";
}
