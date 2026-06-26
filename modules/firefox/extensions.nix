{ lib, ... }: {
  ExtensionSettings =
    with builtins;
    let
      extension = shortId: uuid: defaultArea: {
        name = uuid;
        value = {
          install_url = "https://addons.mozilla.org/en-US/firefox/downloads/latest/${shortId}/latest.xpi";
          installation_mode = "force_installed"; # normal_installed
          default_area = defaultArea;
          blocked_install_message = "Fucking forget it";
        };
      };
    in
    listToAttrs [
      (extension "*" "" "menupanel")
      (extension "sponsorblock" "sponsorBlocker@ajay.app" "menupanel")
      (extension "darkreader" "addon@darkreader.org" "menupanel")
      (extension "ublock-origin" "uBlock0@raymondhill.net" "menupanel")
      (extension "vimium" "{d7742d87-e61d-4b78-b8a1-b469842139fa}" "menupanel")
      (extension "new-window-without-toolbar" "new-window-without-toolbar@tkrkt.com" "menupanel")
      (extension "1password-x-password-manager" "{d634138d-c276-4fc8-924b-40a0ea21d284}" "navbar")
    ];
  "3rdparty".Extensions = {
    "uBlock0@raymondhill.net".adminSettings = {
      userSettings = rec {
        uiTheme = "dark";
        uiAccentCustom = true;
        uiAccentCustom0 = "#f38ba8";
        cloudStorageEnabled = lib.mkForce false; # Security liability?
        importedLists = [
          "https://raw.githubusercontent.com/abhinandh-s/nixdots/refs/heads/master/dots/uBlockOrigin/filter.txt"
          "https://filters.adtidy.org/extension/ublock/filters/3.txt"
          "https://github.com/DandelionSprout/adfilt/raw/master/LegitimateURLShortener.txt"
        ];
        externalLists = lib.concatStringsSep "\n" importedLists;
      };
      selectedFilterLists = [
        "CZE-0"
        "adguard-generic"
        "adguard-annoyance"
        "adguard-social"
        "adguard-spyware-url"
        "easylist"
        "easyprivacy"
        "https://raw.githubusercontent.com/abhinandh-s/nixdots/refs/heads/master/dots/uBlockOrigin/filter.txt"
        "https://github.com/DandelionSprout/adfilt/raw/master/LegitimateURLShortener.txt"
        "plowe-0"
        "ublock-abuse"
        "ublock-badware"
        "ublock-filters"
        "ublock-privacy"
        "ublock-quick-fixes"
        "ublock-unbreak"
        "urlhaus-1"
      ];
    };
  };
}
