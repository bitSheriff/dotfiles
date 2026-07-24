{
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkForce;
in
{
  AppAutoUpdate = false;
  BackgroundAppUpdate = false;
  BlockAboutAddons = false;
  BlockAboutConfig = false;
  BlockAboutProfiles = false;
  BlockAboutSupport = true;
  CaptivePortal = false;

  Cookies = {
    Allow = [ "http://example.org/" ];
    AllowSession = [ "http://example.edu/" ];
    Block = [ "http://example.edu/" ];
    Locked = true;
    Behavior = "reject-foreign";
    BehaviorPrivateBrowsing = "reject";
  };

  DefaultDownloadDirectory = "\${home}/Downloads";
  DisableAppUpdate = true;
  DisableFeedbackCommands = true;
  DisableBuiltinPDFViewer = true; # Considered a security liability
  DisableFirefoxStudies = true;
  DisableFirefoxAccounts = true; # Disable Firefox Sync
  DisableFirefoxScreenshots = true; # No screenshots?
  DisableForgetButton = true; # Thing that can wipe history for X time, handled differently
  DisableMasterPasswordCreation = true; # To be determined how to handle master password
  DisableProfileImport = true; # Purity enforcement: Only allow nix-defined profiles
  DisableProfileRefresh = true; # Disable the Refresh Firefox button on about:support and support.mozilla.org
  DisableSetDesktopBackground = true; # Remove the “Set As Desktop Background…” menuitem when right clicking on an image, because Nix is the only thing that can manage the backgroud
  # DisableSystemAddonUpdate = true; # Do not allow addon updates
  DisablePocket = true;
  DisableFormHistory = true;
  DisablePasswordReveal = true;

  DisableTelemetry = true;
  DisplayBookmarksToolbar = "never"; # "always" | "never" | "newtab"
  DisplayMenuBar = "never"; # "always", "never", "default-on", "default-off"

  /*
    Ref: https://mullvad.net/en/help/dns-over-https-and-dns-over-tls#browsers

    DNS service uses DNS over HTTPS (DoH) and DNS over TLS (DoT). This protects your DNS queries from being snooped on by third parties when not connected to our VPN service as your DNS queries are encrypted between your device and our DNS server.

    This service is primarily meant to be used when you are disconnected from our VPN service, or on devices where it's not possible or desirable to connect to the VPN. When you are already connected to our VPN service the security benefits of using encrypted DNS is negligible and it will always be slower than using the DNS resolver on the VPN server that you are connected to.

    Firefox (desktop version)

    Hostname        	       | Ads 	\ Trackers | Malware | Adult | Gambling | Social media |
                             \      \          \
    dns.mullvad.net 	  	   \   	  \  	       \
    adblock.dns.mullvad.net  \   	  \   ✅     \   ✅
    base.dns.mullvad.net 	   \   ✅ \	  ✅     \   ✅
    extended.dns.mullvad.net \   	  \   ✅     \   ✅        ✅ 	  	       ✅
    family.dns.mullvad.net 	 \      \   ✅     \   ✅        ✅        ✅ 	 ✅
    all.dns.mullvad.net    	 \      \   ✅     \   ✅        ✅        ✅  	 ✅ 	       ✅

    Click on the menu button in the top right corner and select Settings.
    Click on Privacy & Security in the left column.
    Scroll down to the bottom.
    Under Enable secure DNS using select Max Protection.
    Under Choose provider click on the drop down list and select Custom.
    In the text field that appears, paste one of the following, then press Enter on your keyboard to set it.

    https://dns.mullvad.net/dns-query
    https://adblock.dns.mullvad.net/dns-query
    https://base.dns.mullvad.net/dns-query
    https://extended.dns.mullvad.net/dns-query
    https://family.dns.mullvad.net/dns-query
    https://all.dns.mullvad.net/dns-query

    Check for DNS leak => https://mullvad.net/en/check
  */

  DNSOverHTTPS = {
    Enabled = true;
    ProviderURL = "https://family.dns.mullvad.net/dns-query";
    Locked = true;
    ExcludedDomains = [ "example.com" ];
    Fallback = true;
  };

  DontCheckDefaultBrowser = true; # Stop being attention whore

  DownloadDirectory = "\${home}/Downloads";

  EnableTrackingProtection = {
    Value = true;
    Locked = true;
    Cryptomining = true;
    Fingerprinting = true;
    EmailTracking = true;
    # Exceptions = ["https://example.com"]
  };
  EncryptedMediaExtensions = {
    Enabled = true;
    Locked = true;
  };

  ExtensionUpdate = true;

  FirefoxHome = {
    Search = false;
    TopSites = true;
    SponsoredTopSites = false; # Fuck you
    Highlights = false;
    Pocket = false;
    SponsoredPocket = false; # Fuck you
    Snippets = false;
    Locked = true;
  };
  FirefoxSuggest = {
    WebSuggestions = false;
    SponsoredSuggestions = false; # Fuck you
    ImproveSuggest = false;
    Locked = true;
  };

  Handlers = {
    mimeTypes = {
      "application/msword" = {
        action = "useSystemDefault";
        ask = false;
      };
    };
    schemes = {
      mailto = {
        action = "useHelperApp";
        ask = true;
        handlers = [
          {
            name = "Gmail";
            uriTemplate = "https://mail.google.com/mail/?extsrc=mailto&url=%s";
          }
        ];
      };
    };
    extensions = {
      pdf = {
        action = "useHelperApp";
        ask = true;
        handlers = [
          {
            name = "Zathura PDF Viewer";
            path = "${pkgs.zathura}/bin/zathura";
          }
        ];
      };
    };
  };

  HardwareAcceleration = true;

  ManualAppUpdateOnly = true;
  NoDefaultBookmarks = true;
  PasswordManagerEnabled = false;

  PDFjs = {
    Enabled = false;
    EnablePermissions = false;
  };

  # Preferences Affected: permissions.default.camera, permissions.default.microphone, permissions.default.geo, permissions.default.desktop-notification, media.autoplay.default, permissions.default.xr
  Permissions = {
    Camera = {
      # 		Allow = [https =//example.org,https =//example.org =1234];
      # 		Block = [https =//example.edu];
      BlockNewRequests = false; # false => Firefox shows the permission prompt per-site
      Locked = false; # false => allow changing the setting in the UI
    };
    Microphone = {
      Allow = [ ];
      Block = [ ];
      BlockNewRequests = false; # false => Firefox shows the permission prompt per-site
      Locked = false; # false => allow changing the setting in the UI
    };
    Location = {
      # 		Allow = [https =//example.org];
      # 		Block = [https =//example.edu];
      BlockNewRequests = true;
      Locked = true;
    };
    Notifications = {
      Allow = [ "http://localhost:8096/*" ]; # Jellyfin
      Block = [ "https://google.com/*" ];
      BlockNewRequests = true;
      Locked = true;
    };
    Autoplay = {
      # 		Allow = [https =//example.org];
      # 		Block = [https =//example.edu];
      Default = "block-audio"; # allow-audio-video | block-audio | block-audio-video;
      Locked = true;
    };
  };

  PictureInPicture = {
    Enabled = true;
    Locked = true;
  };

  PopupBlocking = {
    Allow = [ "https://example.com/*" ];
    Default = true;
    Locked = true;
  };

  PromptForDownloadLocation = false; # true | false

  Proxy = {
    #  Mode = "autoConfig"; # "none" | "system" | "manual" | "autoDetect" | "autoConfig",
    #  Locked = true;
    #  HTTPProxy = "hostname",
    #  UseHTTPProxyForAllProtocols": true | false,
    #  SSLProxy": "hostname",
    #  FTPProxy": "hostname",
    #  SOCKSProxy": "hostname",
    #  SOCKSVersion": 4 | 5,
    #  Passthrough": "<local>",
    #  AutoConfigURL": "URL_TO_AUTOCONFIG",
    #  AutoLogin": true | false,
    #  UseProxyForDNS": true | false
  };

  RequestedLocales = [ "en-US" ];

  SanitizeOnShutdown = {
    Cache = true;
    Cookies = false;
    Downloads = true;
    FormData = false;
    History = false;
    Sessions = false;
    SiteSettings = false;
    OfflineApps = true;
    Locked = true;
  };
  # Preferences Affected: privacy.sanitize.sanitizeOnShutdown, privacy.clearOnShutdown.cache, privacy.clearOnShutdown.cookies, privacy.clearOnShutdown.downloads, privacy.clearOnShutdown.formdata, privacy.clearOnShutdown.history, privacy.clearOnShutdown.sessions, privacy.clearOnShutdown.siteSettings, privacy.clearOnShutdown.offlineApps

  SearchBar = "separate"; # "unified" | "separate"

  # -------------------------------------------
  # -- This policy is only available on the ESR
  # -------------------------------------------
  SearchEngines = {
    PreventInstalls = true;
    Default = "DuckDuckGo";
    Remove = [ "Google" ];
    Add = [
      {
        Name = "Example1";
        URLTemplate = "https://www.example.org/q={searchTerms}";
        Method = "GET";
        IconURL = "https://www.example.org/favicon.ico";
        Alias = "example";
        Description = "Description";
        PostData = "name=value&q={searchTerms}";
        SuggestURLTemplate = "https://www.example.org/suggestions/q={searchTerms}";
      }
    ];
  };

  SearchSuggestEnabled = true;
  ShowHomeButton = true;
  StartDownloadsInTempDirectory = true;
  # Web page translation is done completely on the client, so there is no data or privacy risk.
  TranslateEnabled = true;

  # Prevent Firefox from messaging the user in certain situations.
  UserMessaging = {
    ExtensionRecommendations = false;
    FeatureRecommendations = false;
    UrlbarInterventions = false;
    SkipOnboarding = true;
    MoreFromMozilla = false;
    FirefoxLabs = true;
    WhatsNew = false;
    Locked = true;
  };

  UseSystemPrintDialog = true; # allow me to print in a4 size :)

  WebsiteFilter = {
    Block = [ "http://example.org/*" ];
    Exceptions = [ "http://example.org/articles/*" ];
  };
}
