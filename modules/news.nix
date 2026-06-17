{
  config,
  pkgs,
  inputs,
  lib,
  activeUsers,
  ...
}:
{
  imports = [
  ];

  ##################
  ## HOME MANAGER ##
  ##################
  home-manager.users.benjamin = lib.mkIf (lib.elem "benjamin" activeUsers) {
    programs.feedr = {
      enable = true;
      settings = {
        general = {
          max_dashboard_items = 100;
          auto_refresh_interval = 120;
          refresh_enabled = true;
          refresh_rate_limit_delay = 2000;
        };

        network = {
          http_timeout = 15;
          user_agent = "Mozilla/5.0 (compatible; Feedr/1.0; +https://github.com/bahdotsh/feedr)";
        };

        ui = {
          tick_rate = 100;
          error_display_timeout = 3000;
          theme = "dark";
          compact_mode = "auto";
        };

        default_feeds = [
          {
            category = "NixOS";
            url = "https://nixos.org/blog/stories-rss.xml";
          }
          {
            category = "News";
            url = "https://rss.orf.at/news.xml";
          }
          {
            category = "Tech";
            url = "http://stadt-bremerhaven.de/feed";
          }
          {
            category = "Tech";
            url = "https://hnrss.org/frontpage";
          }
        ];
      };
    };
  };
}
