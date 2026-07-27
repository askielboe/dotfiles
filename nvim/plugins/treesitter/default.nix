{ pkgs, ... }:
{
  plugins.treesitter = {
    enable = true;
    settings = {
      indent = {
        enable = true;
      };
      highlight = {
        enable = true;
      };
    };
    nixvimInjections = true;
    grammarPackages = pkgs.vimPlugins.nvim-treesitter.allGrammars;
  };

  # nvim-treesitter's `main` branch ships its maintained queries under
  # <plugin>/runtime/queries, but nixpkgs does not add that directory to the
  # runtimepath. The only nix highlight query then found is the stale
  # grammar-bundled one (symlinked in from the tree-sitter-nix repo), which
  # still uses the master-era `#is-not?` predicate that the main branch
  # dropped — so highlighting throws "No handler for is-not?" on every redraw.
  # Prepend the plugin's runtime dir so its up-to-date queries win. Runs in
  # *Pre so the runtimepath is fixed before the first FileType starts (and
  # caches) a treesitter query.
  extraConfigLuaPre = ''
    do
      local init = vim.api.nvim_get_runtime_file("lua/nvim-treesitter/init.lua", false)[1]
      if init then
        local runtime = vim.fn.fnamemodify(init, ":h:h:h") .. "/runtime"
        if (vim.uv or vim.loop).fs_stat(runtime) then
          vim.opt.runtimepath:prepend(runtime)
        end
      end
    end
  '';

  # dbt models are SQL templated with jinja, and the sql grammar errors out
  # on `{{ ... }}` / `{% ... %}` — the ERROR nodes wreck highlighting for the
  # rest of the file. Parse those buffers with the jinja grammar instead
  # (template constructs are first-class, everything between them is a
  # (content) node) and inject the content back into the sql parser as one
  # combined document. The jinja parser is registered under a separate "dbt"
  # language name so the sql injection below stays scoped to these buffers
  # and doesn't leak into ordinary jinja templates (html, yaml, ...).
  extraFiles = {
    "queries/dbt/highlights.scm".text = ''
      ;; inherits: jinja
    '';
    "queries/dbt/injections.scm".text = ''
      ((content) @injection.content
        (#set! injection.language "sql")
        (#set! injection.combined))

      ((comment) @injection.content
        (#set! injection.language "comment"))
    '';
  };

  # Must be registered after nixvim's own nixvim_treesitter FileType autocmd
  # (extraConfigLua lands after plugin setup) so the dbt highlighter replaces
  # the sql one nixvim just started, not the other way around. Buffers with
  # no template markers keep the plain sql parser, and with it treesitter
  # indent (jinja/dbt ship no indent queries).
  extraConfigLua = ''
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("dbt_treesitter", {}),
      pattern = "sql",
      desc = "Use the jinja grammar (as lang 'dbt') for templated SQL",
      callback = function(ev)
        for _, line in ipairs(vim.api.nvim_buf_get_lines(ev.buf, 0, -1, false)) do
          if line:find("{{", 1, true) or line:find("{%", 1, true) or line:find("{#", 1, true) then
            local jinja = vim.api.nvim_get_runtime_file("parser/jinja.*", false)[1]
            if not jinja then
              return
            end
            vim.treesitter.language.add("dbt", { path = jinja, symbol_name = "jinja" })
            vim.treesitter.stop(ev.buf)
            pcall(vim.treesitter.start, ev.buf, "dbt")
            return
          end
        end
      end,
    })
  '';
}
