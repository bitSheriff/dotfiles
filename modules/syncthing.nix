{
  config,
  pkgs,
  activeUsers,
  ...
}:

{
  imports = [
  ];

  environment.systemPackages = with pkgs; [
  ];

  services.syncthing = {
    enable = true;
    user = "benjamin";
    dataDir = "/home/benjamin/.config/syncthing";
    configDir = "/home/benjamin/.config/syncthing";
  };

  networking.hosts = {
    "127.0.0.1" = [ "syncthing.local" ];
  };

  services.nginx = {
    virtualHosts."syncthing.local" = {
      listen = [
        {
          addr = "127.0.0.1";
          port = 80;
        }
      ];
      locations."/" = {
        proxyPass = "http://127.0.0.1:8384";
        proxyWebsockets = true;
      };
    };
  };

}
