{ pkgs, ... }:
{
  extraPlugins = [
    (pkgs.vimUtils.buildVimPlugin {
      name = "nvim-recorder";
      src = pkgs.fetchFromGitHub {
        owner = "chrisgrieser";
        repo = "nvim-recorder";
        rev = "d29bcb91f0abe3ef0db7ff48152295f13056e467";
        sha256 = "sha256-Sk2zb7QrXwyP7dSmxE0MFxvufJ9H7q0ICtZogcZ0kV0=";
      };
    })
  ];

  plugins.lualine.settings.sections.lualine_z = [
    {
      __raw = ''require("recorder").recordingStatus'';
    }
  ];

  extraConfigLua = ''
    require("recorder").setup({
      slots = { "a", "b" },
      mapping = {
        startStopRecording = "q",
        playMacro = "Q",
        switchSlot = "<leader>q",
      },
      useNerdfontIcons = true,
    })
  '';
}
