{
  config,
  pkgs,
  lib,
  ...
}:
let
  # List of unique IDs for your networks.
  # These are the only things visible in your Nix config.
  # You can use hashes or generic names like "wifi_1".
  wifi_ids = [
    "home"
    "hotspot"
    "wifi_1"
    "wifi_2"
    "wifi_3"
  ];
in
{
  # Networking
  networking.networkmanager.enable = true;
  networking.hosts = {
    "127.0.0.1" = [ "syncthing.local" ];
  };
  networking.firewall = rec {
    # needed for KDE Connect
    allowedTCPPortRanges = [
      {
        from = 1714;
        to = 1764;
      }
    ];
    allowedUDPPortRanges = allowedTCPPortRanges;
  };

  services.nginx = {
    enable = true;
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

  # 1. Register the secrets for both SSID and PSK for each ID
  sops.secrets = lib.listToAttrs (
    lib.concatMap (id: [
      {
        name = "${id}_ssid";
        value = {
          sopsFile = ../encrypted/wifi_credentials.yaml;
        };
      }
      {
        name = "${id}_psk";
        value = {
          sopsFile = ../encrypted/wifi_credentials.yaml;
        };
      }
    ]) wifi_ids
  );

  # 2. Generate the NetworkManager connection files using templates
  sops.templates = lib.listToAttrs (
    map (id: {
      name = "${id}.nmconnection";
      value = {
        path = "/etc/NetworkManager/system-connections/${id}.nmconnection";
        mode = "0600";
        owner = "root";
        group = "root";
        restartUnits = [ "NetworkManager.service" ];
        content = ''
          [connection]
          id=${config.sops.placeholder."${id}_ssid"}
          type=wifi
          autoconnect=true

          [wifi]
          mode=infrastructure
          ssid=${config.sops.placeholder."${id}_ssid"}

          [wifi-security]
          key-mgmt=wpa-psk
          psk=${config.sops.placeholder."${id}_psk"}

          [ipv4]
          method=auto

          [ipv6]
          addr-gen-mode=stable-privacy
          method=auto
        '';
      };
    }) wifi_ids
  );
}
