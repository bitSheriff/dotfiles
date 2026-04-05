{
  config,
  pkgs,
  username,
  ...
}:

{

  environment.systemPackages = with pkgs; [
    qutebrowser
  ];

  home-manager.users.${username} =
    { config, lib, ... }:
    {

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
