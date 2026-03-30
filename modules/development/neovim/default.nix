{ config, pkgs, ... }:

{
  imports = [
    ./looks.nix
    ./keybindings.nix
    ./snippets.nix
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
        null-ls.enable = true;
      };
      languages = {
          enableTreesitter = true;
          # Languages
          nix.enable = true;
          rust.enable = true;
          bash.enable = true;
          just.enable = true;
          json.enable = true;
          markdown.enable = true;
          python.enable = true;
          yaml.enable = true;
        };
      telescope.enable = true;
      autocomplete.nvim-cmp.enable = true;
      git.gitsigns.enable = true;
      autopairs.nvim-autopairs.enable = true;
      comments.comment-nvim.enable = true;
    };
  };
}
