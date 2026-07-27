# Code folding
{
  plugins = {
    nvim-ufo = {
      enable = true;
      settings = {
        providerSelector = ''
          function(bufnr, filetype, buftype)
            return { 'lsp', 'indent' }
          end
        '';
      };
    };
  };
  opts = {
    foldlevel = 99;
    foldlevelstart = 99;
    foldenable = true;
  };
}
