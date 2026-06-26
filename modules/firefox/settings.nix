{
  "browser.translations.automaticallyPopup" = false;
  "browser.aboutConfig.showWarning" = false; # disable about:config warning
  "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
  "extensions.activeThemeID" = "{9b615f11-c3a3-46bd-97a8-1721bb8122b9}";
  "browser.startup.page" = 1; # 0=blank, 1=home, 2=last visited page, 3=resume previous session
  "browser.startup.homepage" = "about:home";

  "browser.newtabpage.activity-stream.feeds.weatherfeed" = false;
  "browser.newtabpage.activity-stream.showWeather" = false;
  "browser.newtabpage.activity-stream.sectionOrder" = "topsites";
  "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
  "browser.newtabpage.activity-stream.default.sites" = [ ];

  # NOTE:
  # ------------------------------ #
  # -- Vertical Tabs ------------- #
  # ------------------------------ #
  "sidebar.revamp" = true;
  "sidebar.verticalTabs" = true;
  "browser.ml.chat.enabled" = true;
  "browser.ml.chat.provider" = "https://chatgpt.com";

  "browser.tabs.inTitlebar" = 0;

  "reader.color_scheme" = "custom";
  "reader.colors_menu.enabled" = true; # what does this do ?
  "reader.content_width" = 4;
  "reader.custom_colors.background" = "#11111b";
  "reader.custom_colors.foreground" = "#cdd6f4";
  "reader.custom_colors.selection-highlight" = "#f9e2af";
  "reader.custom_colors.unvisited-links" = "#b4befe";
  "reader.custom_colors.visited-links" = "#f38ba8";
  "reader.errors.includeURLs" = true;

  "geo.provider.network.url" =
    "https://location.services.mozilla.com/v1/geolocate?key=%MOZILLA_API_KEY%"; # use Mozilla geolocation service instead of Google if permission is granted
  # ------------------------------------------- #
  # -- ETP (ENHANCED TRACKING PROTECTION) ----- #
  # ------------------------------------------- #

  "browser.contentblocking.category" = "strict"; # enable ETP Strict Mode [HIDDEN PREF]

  "browser.newtabpage.activity-stream.topSitesRows" = 4; # how many rows for shortcut new tab
  # -- topbar
  "extensions.pocket.enabled" = false; # disables pocket
  # -- Locale
  "browser.search.region" = "US";
  "browser.search.isUS" = false;
  "distribution.searchplugins.defaultLocale" = "en-US";
  "general.useragent.locale" = "en-Us";
  # -- set the font
  # "font.name.monospace.x-western" = font;
  # "font.name.sans-serif.x-western" = font;
  # "font.name.serif.x-western" = font;

  # turn of google safebrowsing (it literally sends a sha sum of everything you download to google)
  "browser.safebrowsing.downloads.remote.block_dangerous" = false;
  "browser.safebrowsing.downloads.remote.block_dangerous_host" = false;
  "browser.safebrowsing.downloads.remote.block_potentially_unwanted" = false;
  "browser.safebrowsing.downloads.remote.block_uncommon" = false;
  "browser.safebrowsing.downloads.remote.url" = false;
  "browser.safebrowsing.downloads.enabled" = false;
  # -- experiments
  "experiments.supported" = false;
  "experiments.enabled" = false;
  "experiments.manifest.uri" = "";
  "extensions.shield-recipe-client.enabled" = false;
  "loop.logDomains" = false;
  # -- third party cookies
  "network.cookie.cookieBehavior" = 1;
  # -- default browser
  "browser.shell.checkDefaultBrowser" = false;
  # -- sponsors
  "browser.newtabpage.activity-stream.system.showSponsored" = false;
  "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
  "browser.urlbar.suggest.quicksuggest.sponsored" = false;
  "services.sync.prefs.sync.browser.newtabpage.activity-stream.showSponsored" = false;
  "services.sync.prefs.sync.browser.newtabpage.activity-stream.showSponsoredTopSites" = false;

  # --
  # -- Pinned shortcuts
  # --
  "browser.newtabpage.pinned" = [

    {
      title = "Github";
      url = "https://github.com/bitSheriff";
    }
    {
      title = "NixOS Search";
      url = "https://search.nixos.org/packages";
    }

    {
      title = "NixOS WiKi";
      url = "https://nixos.wiki/";
    }
    {
      title = "Whatsapp";
      url = "https://web.whatsapp.com/";
    }
    {
      title = "Youtube";
      url = "https://www.youtube.com";
    }
    {
      title = "Reddit";
      url = "https://www.reddit.com";
    }
  ];
}
