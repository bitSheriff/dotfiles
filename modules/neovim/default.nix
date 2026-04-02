{ config, pkgs, ... }:

{
  imports = [
    ./langs.nix
    ./looks.nix
    ./keymaps.nix
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

      clipboard = {
        enable = true;
        registers = "unnamedplus";
      };

      extraPackages = with pkgs; [
        wl-clipboard
      ];

      options = {
        tabstop = 4;
        shiftwidth = 4;
        expandtab = true;
      };

      telescope.enable = true;
      autocomplete.nvim-cmp.enable = true;
      git.gitsigns.enable = true;
      autopairs.nvim-autopairs.enable = true;
      comments.comment-nvim.enable = true;

      # move lines up and done
      mini.move = {
        enable = true;
        setupOpts = {
          mappings = {
            left = "<A-left>";
            right = "<A-right>";
            down = "<A-down>";
            up = "<A-up>";

            line_left = "<A-left>";
            line_right = "<A-right>";
            line_down = "<A-down>";
            line_up = "<A-up>";
          };
        };
      };
      # highlight training spaces
      mini.trailspace.enable = true;
      # jump anywhere
      utility.motion.flash-nvim.enable = true;
    };
  };
}
