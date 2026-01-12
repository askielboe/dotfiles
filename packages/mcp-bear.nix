{ pkgs, src }:

pkgs.python312Packages.buildPythonApplication {
  pname = "mcp-bear";
  version = "0.5.2";
  inherit src;
  pyproject = true;
  build-system = [ pkgs.python312Packages.hatchling ];
  dependencies = with pkgs.python312Packages; [
    fastapi
    mcp
    pydantic
    requests
    rich-click
    uvicorn
  ];
  meta.mainProgram = "mcp-bear";
}
