{
  config,
  pkgs,
  lib,
  activeUsers,
  ...
}:

{
  config = lib.mkIf config.cfg.browser.firefox.enable {
    environment.systemPackages = with pkgs; [
    ];

    ##################
    ## HOME MANAGER ##
    ##################
    home-manager.users.benjamin = lib.mkIf (lib.elem "benjamin" activeUsers) {
      # Tell Stylix which profile to theme. profileNames alone only themes
      # fonts - colorTheme.enable actually recolors the chrome (toolbar,
      # tabs, address bar, ...) via the "Firefox Color" webextension, using
      # the selected base16 palette. Works regardless of desktop (unlike
      # Stylix's GNOME-specific firefoxGnomeTheme option).
      stylix.targets.firefox = {
        profileNames = [ "default" ];
        colorTheme.enable = true;
      };

      programs.firefox = {
        enable = true;
        package = pkgs.firefox;
        configPath = ".mozilla/firefox";
        policies = lib.mkMerge [
          (import ./policies.nix { inherit config pkgs lib; })
          (import ./extensions.nix { inherit config pkgs lib; })
          { }
        ];
        profiles.default = {
          id = 0;
          isDefault = true;
          userContent = import ./userContent.nix;
          userChrome = import ./userChrome.nix;
          settings = import ./settings.nix;
          containers = import ./containers.nix;
          # firefox replaces the symlink with a real file on every launch, so without
          # this every activation tries to back it up and trips over the last backup
          containersForce = true;
          search = import ./search.nix;
          # Stylix's colorTheme target (modules/stylix) writes
          # extensions.settings for the Firefox Color extension it installs -
          # acknowledge that it fully manages extension settings.
          extensions.force = true;
        };
      };
      home.file.".mozilla/firefox/default/search.json.mozlz4".force = lib.mkForce true;
    };
  };

}
