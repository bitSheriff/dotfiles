{
  config,
  pkgs,
  lib,
  activeUsers,
  ...
}:

{

  environment.systemPackages = with pkgs; [
    qutebrowser
  ];

  home-manager.users.benjamin = lib.mkIf (lib.elem "benjamin" activeUsers) {
        xdg.configFile = {
          "qutebrowser/config.py".source = ./config.py;
          "qutebrowser/keybindings.py".source = ./keybindings.py;
          "qutebrowser/theming.py".source = ./theming.py;
          "qutebrowser/greasemonkey".source = ./greasemonkey;
          "qutebrowser/styles".source = ./styles;
          "qutebrowser/userscripts".source = ./userscripts;
        };
      };

}
