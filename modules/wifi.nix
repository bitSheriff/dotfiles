{ config, lib, ... }:
{
  # This stays here because it's a system-level service
  networking.wireless = {
    enable = true;
    secretsFile = config.sops.templates."wireless-secrets".path;
    networks = {
      "Coffee Shop".pskRaw = "@Coffee_Shop_PSK@";
    };
  };

  # Define the secret here so the system can access it at boot
  sops.secrets."wifi_credentials" = {
    format = "yaml";
    sopsFile = ../encrypted/wifi_credentials.yaml;
  };

  sops.templates."wireless-secrets".content = ''
    ${lib.concatStringsSep "\n" (
      map (
        network: "${lib.replaceStrings [ " " ] [ "_" ] network.name}_PSK=\"${network.password}\""
      ) config.sops.placeholder."wifi_credentials".wifi_list
    )}
  '';
}
