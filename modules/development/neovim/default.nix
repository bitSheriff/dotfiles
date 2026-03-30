{ config, pkgs, ... }:

{
  imports = [
    ./looks.nix
    ./keybindings.nix
  ];

  environment.systemPackages = with pkgs; [
    neovim
  ];

  programs.nvf = {
    enable = true;
    settings.vim = {
      viAlias = false;
      vimAlias = true;
      theme = {
        enable = true;
        name = "dracula";
        style = "dark";
      };
      lsp = {
        enable = true;
      };
      languages = {
          enableLSP = true;
          enableTreesitter = true;
          # Languages
          nix.enable = true;
          rust.enable = true;
          bash.enable = true;
        };
      telescope.enable = true;
      autocomplete.nvim-cmp.enable = true;
      git.gitsigns.enable = true;
    };
  };
}
