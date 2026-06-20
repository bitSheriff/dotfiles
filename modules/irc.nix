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
  home-manager.users.benjamin =
    { config, ... }:
    lib.mkIf (lib.elem "benjamin" activeUsers) {

      programs.halloy = {
        enable = true;
        settings = {
          theme = "booberry";
          font = {
            family = "Comic Mono";
            size = 15;
          };
          runtime.backend.hardware = "best";
          servers = {
            liberachat = {
              server = "irc.libera.chat";
              channels = [
                "#halloy"
                "#nixos"
                "#technicalrenaissance" # Joshua Blais Community
              ];
              nickname = "bitSheriff";
              alt_nicks = [
                "bitSheriff_"
                "bitSheriff__"
              ];

              # Authentication with SSL
              sasl.external = {
                cert = "${config.sops.secrets.irc_libera_cert.path}";
                key = "${config.sops.secrets.irc_libera_key.path}";
              };
              # send messages on sever connect event
              on_connect = [
                "/mode bitSheriff +x" # hide your IP
              ];
            };

            soju = {
              server = "irc.lowlevelkings.xyz";
              nickname = "bitSheriff";
              port = 6697;
              use_tls = true;
              use_websocket = false;
              websocket_path = "/socket";
              sasl.plain = {
                username = "bitSheriff";
                password_file = "${config.sops.secrets.irc_soju_password.path}";
              };
            };

            twitch = {
              name = "Twitch";
              server = "irc.chat.twitch.tv";
              port = 6697;
              nickname = "banschomin";
              password_file = "${config.sops.secrets.irc_twitch_banschomin.path}";
              tls = true;

            };
          };
          buffer = {
            nickname = {
              # hide the nickname if the user writes (consecutive) within 2m
              hide_consecutive.enabled = {
                smart = 2 * 60;
              };
              brackets = {
                left = "<";
                right = ">";
              };
            };
          };
        };
      };

      xdg.desktopEntries.halloy = {
        name = "Halloy";
        genericName = "IRC Client";
        comment = "IRC client written in Rust";
        exec = "halloy";
        icon = "org.squidowl.halloy";
        terminal = false;
        categories = [
          "Network"
          "Chat"
          "InstantMessaging"
        ];
        mimeType = [
          "x-scheme-handler/irc"
          "x-scheme-handler/ircs"
        ];
      };

      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "x-scheme-handler/irc" = [ "halloy.desktop" ];
          "x-scheme-handler/ircs" = [ "halloy.desktop" ];
        };
      };

      xdg.configFile = {
        "halloy/themes/booberry.toml".source =
          (pkgs.formats.toml { }).generate "booberry.toml"
            theme_booberry;
      };

      # Secret defined inside Home Manager
      sops.secrets = {
        irc_libera_cert = {
          sopsFile = ../encrypted/secrets.yaml;
          key = "irc/liberachat/cert";
        };
        irc_libera_key = {
          sopsFile = ../encrypted/secrets.yaml;
          key = "irc/liberachat/key";
        };
        irc_twitch_banschomin = {
          sopsFile = ../encrypted/secrets.yaml;
          key = "irc/twitch/banschomin";
        };
        irc_soju_password = {
          sopsFile = ../encrypted/secrets.yaml;
          key = "irc/soju/password";
        };
      };
    };
}
