{
  config,
  pkgs,
  lib,
  activeUsers,
  ...
}:

{
  home-manager.users.benjamin = lib.mkIf (lib.elem "benjamin" activeUsers) {
    programs.fuzzel = {
      enable = true;

      settings = {
        main = {
          dpi-aware = "no";
          width = 30;
          # Font is owned by Stylix (modules/stylix) - do not set here, it conflicts.
          line-height = 20;
          fields = "name,generic,comment,categories,filename,keywords";
          terminal = "kitty -e";
          prompt = "❯   ";
          layer = "overlay";
        };
        # Colors are owned by Stylix (modules/stylix) - do not set
        # programs.fuzzel.settings.colors here, it conflicts.
      };

    };
  };
}
