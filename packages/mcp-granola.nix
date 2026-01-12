{ pkgs, src }:

pkgs.python312Packages.buildPythonApplication {
  pname = "mcp-granola";
  version = "0.1.0";
  inherit src;
  pyproject = true;
  build-system = [ pkgs.python312Packages.hatchling ];
  dependencies = with pkgs.python312Packages; [
    mcp
    pydantic
    typing-extensions
  ];
  meta.mainProgram = "granola-mcp-server";
}
