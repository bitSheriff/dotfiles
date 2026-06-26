{
  config,
  pkgs,
  lib,
  activeUsers,
  ...
}:

{
  environment.systemPackages = with pkgs; [
  ];

  ##################
  ## HOME MANAGER ##
  ##################
  home-manager.users.benjamin = lib.mkIf (lib.elem "benjamin" activeUsers) {
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
        search = import ./search.nix;
      };
    };
  };

}
