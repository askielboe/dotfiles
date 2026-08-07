{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Track nixpkgs' default python3: Hydra only builds the default package set,
    # so pinning an off-default version (e.g. python312 here) means every package
    # — torch included — gets compiled locally instead of fetched from the cache.
    (python3.withPackages (
      ps: with ps; [
        ipython
        jedi-language-server
        matplotlib
        numpy
        python-lsp-server
        requests
        scipy
        torch
      ]
    ))
  ];
}
