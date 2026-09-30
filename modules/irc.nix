{
  config, # Top-level NixOS config
  pkgs,
  inputs,
  lib,
  activeUsers,
  ...
}:
{
  imports = [ ];

  environment.systemPackages = with pkgs; [ ];

  ##################
  ## HOME MANAGER ##
  ##################
  home-manager.users.benjamin =
    lib.mkIf (lib.elem "benjamin" activeUsers && config.cfg.socials.irc.enable)
      (
        { config, osConfig, ... }: {

          # Theme is owned by Stylix (modules/stylix) - do not set
          # settings.theme here, it conflicts. Font family is Stylix's too;
          # only the size is overridden below - halloy reads a bit small at
          # the shared cfg.stylix.fontsize, so bump it here rather than in
          # modules/stylix (which would affect every app using
          # fonts.sizes.applications, not just halloy).
          programs.halloy = {
            enable = true;
            settings = {
              runtime.backend.hardware = "best";
              font.size = lib.mkForce (osConfig.cfg.stylix.fontsize + 2);
              servers = {
                # liberachat = {
                #   server = "irc.libera.chat";
                #   channels = [
                #     "#halloy"
                #     "#nixos"
                #     "#technicalrenaissance" # Joshua Blais Community
                #   ];
                #   nickname = "bitSheriff";
                #   alt_nicks = [
                #     "bitSheriff_"
                #     "bitSheriff__"
                #   ];
                #
                #   # Authentication with SSL
                #   sasl.external = {
                #     cert = "${config.sops.secrets.irc_libera_cert.path}";
                #     key = "${config.sops.secrets.irc_libera_key.path}";
                #   };
                #   # send messages on sever connect event
                #   on_connect = [
                #     "/mode bitSheriff +x" # hide your IP
                #   ];
                # };

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
                  channels = [
                    "#halloy"
                    "#nixos"
                    "#technicalrenaissance" # Joshua Blais Community
                  ];
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

          xdg.mimeApps = {
            enable = true;
            defaultApplications = {
              "x-scheme-handler/irc" = [ "halloy.desktop" ];
              "x-scheme-handler/ircs" = [ "halloy.desktop" ];
            };
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
        }
      );
}
