# Global fallback ~/.editorconfig. Lived in the nixvim tree before that became
# the standalone nvim/ child flake — home.file.* is a home-manager option and
# nixvim standalone mode has no home.* namespace, so the stanza stays here.
{
  home.file.".editorconfig" = {
    text = ''
      root = true

      [*]
      charset = utf-8
      trim_trailing_whitespace = true

      [*.{sh,bash,zsh}]
      indent_style = space
      indent_size = 4

      [Dockerfile*]
      indent_style = space
      indent_size = 4
    '';
  };
}
