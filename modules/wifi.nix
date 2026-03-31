{ config, lib, ... }:
let
  # Add your networks here. The name must match the SSID exactly.
  wifi_networks = [
    { name = "Coffee Shop"; }
    { name = "Nothing WiFi"; }
  ];

  mkPskName = name: "${lib.replaceStrings [ " " ] [ "_" ] name}_PSK";
in
{
  # We use sops.templates to create the NetworkManager connection files 
  # directly in the system-connections directory.
  sops.secrets = lib.listToAttrs (map (net: {
    name = mkPskName net.name;
    value = { sopsFile = ../encrypted/wifi_credentials.yaml; };
  }) wifi_networks);

  sops.templates = lib.listToAttrs (map (net: {
    name = "${net.name}.nmconnection";
    value = {
      path = "/etc/NetworkManager/system-connections/${net.name}.nmconnection";
      mode = "0600";
      # Automatically restart NetworkManager when this file changes
      restartUnits = [ "NetworkManager.service" ];
      content = ''
        [connection]
        id=${net.name}
        uuid=${builtins.hashString "sha256" net.name}
        type=wifi
        autoconnect=true

        [wifi]
        mode=infrastructure
        ssid=${net.name}

        [wifi-security]
        key-mgmt=wpa-psk
        psk=${config.sops.placeholder."${mkPskName net.name}"}

        [ipv4]
        method=auto

        [ipv6]
        addr-gen-mode=stable-privacy
        method=auto
      '';
    };
  }) wifi_networks);
}
