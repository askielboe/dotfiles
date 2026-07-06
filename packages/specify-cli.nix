{ pkgs }:

# specify-cli, part of GitHub's Spec Kit: bootstraps projects for Spec-Driven
# Development. Not in nixpkgs, so we package the PyPI sdist directly; hatchling's
# force-include bundles the templates/scripts needed for offline `specify init`.
pkgs.python312Packages.buildPythonApplication {
  pname = "specify-cli";
  version = "0.12.4";
  pyproject = true;

  src = pkgs.fetchurl {
    url = "https://files.pythonhosted.org/packages/23/f6/6613011c3568c7478c930cfb1e64f9c7b940dd6ac5d37f2dd91c07d05b9c/specify_cli-0.12.4.tar.gz";
    hash = "sha256-nAe3BAaEWbLZEqQWvCPeQxQK4HirMoJi3sAYpQcSj1U=";
  };

  build-system = [ pkgs.python312Packages.hatchling ];

  dependencies = with pkgs.python312Packages; [
    click
    json5
    packaging
    pathspec
    platformdirs
    pyyaml
    readchar
    rich
    typer
  ];

  # No test suite ships in the sdist; the CLI is the deliverable.
  doCheck = false;

  meta.mainProgram = "specify";
}
