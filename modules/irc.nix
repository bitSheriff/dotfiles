{
  config, # Top-level NixOS config
  pkgs,
  inputs,
  lib,
  activeUsers,
  ...
}:
let
  theme_booberry = {
    general = {
      background = "#452859";
      border = "#DBBFEF";
      horizontal_rule = "#54326F";
      unread_indicator = "#36BF86";
    };

    text = {
      primary = "#D8C8F3";
      secondary = "#AD96BE";
      tertiary = "#ECCDBA";
      success = "#A0F28F";
      error = "#F47868";
    };

    buffer = {
      action = "#E8DCA0";
      background = "#3A224C";
      background_text_input = "#311D41";
      background_title_bar = "#362047";
      border = "#00000000";
      border_selected = "#A4A0E8";
      code = "#CCCCCC";
      highlight = "#64546F";
      nickname = "#A0F28F";
      selection = "#50496D";
      timestamp = "#806D8D";
      topic = "#DBBFEF";
      url = "#82CECF";

      server_messages = {
        default = "#FFCD1D";
      };
    };

    buttons = {
      primary = {
        background = "#00000000";
        background_hover = "#4F2E65";
        background_selected = "#54316C";
        background_selected_hover = "#56326E";
      };

      secondary = {
        background = "#3F2653";
        background_hover = "#44295A";
        background_selected = "#857293";
        background_selected_hover = "#C1A8D3";
      };
    };
  };
in
{
  imports = [ ];

  environment.systemPackages = with pkgs; [ ];

  ##################
  ## HOME MANAGER ##
  ##################
  home-manager.users.benjamin = lib.mkIf (lib.elem "benjamin" activeUsers) (
    { config, ... }: {

      programs.halloy = {
        enable = true;
        settings = {
          theme = "booberry";
          font = {
            family = "Comic Mono";
            size = 13;
          };
          runtime.backend.hardware = "best";
          servers = {
            liberachat = {
              server = "irc.libera.chat";
              channels = [
                "#halloy"
                "#nixos"
              ];
              nickname = "bitSheriff";
              nick_password_file = "${config.sops.secrets.irc_libera_passwordfile.path}";
            };
          };
        };
      };

      xdg.configFile = {
        "halloy/themes/booberry.toml".source =
          (pkgs.formats.toml { }).generate "booberry.toml"
            theme_booberry;
      };

      # Secret defined inside Home Manager
      sops.secrets = {
        irc_libera_passwordfile = {
          sopsFile = ../encrypted/secrets.yaml;
          key = "irc/liberachat";
        };
      };
    }
  );
}
