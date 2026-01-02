{ pkgs, ... }:
{
  home.packages = with pkgs; [
    (python312.withPackages (
      ps: with ps; [
        ipython
        jedi-language-server
        jupyter
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
