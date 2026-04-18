{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
  ];

  environment.systemPackages = with pkgs; [
    meshtastic
    meshtasticd
    contact # tui for meshtastic
  ];

  services.meshtasticd = {
    enable = true;
    user = "$username";
    settings = {
      Lora = {
        Module = "auto";
      };

      Webserver = {
        Port = 9443;
        RootPath = pkgs.meshtastic-web;
      };

      General = {
        MaxNodes = 200;
        MaxMessageQueue = 100;
        MACAddressSource = "eth0";
      };

    };

  };

}
