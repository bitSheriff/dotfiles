{ config, pkgs, ... }:

{
  imports = [
  ];

  programs.yazi.settings.keymap = {
    mgr = {
      prepend_keymap = [
        {
          on = "R";
          run = "plugin rsync";
          desc = "Copy files using rsync";
        }
        {
          on = "L";
          run = "plugin lazygit";
          desc = "Open lazygit";
        }
        {
          on = "l";
          run = "plugin smart-enter";
          desc = "Enter the child directory, or open the file";
        }
        {
          on = "<Right>";
          run = "plugin smart-enter";
          desc = "Enter the child directory, or open the file";
        }
      ];
    };
  };

}
