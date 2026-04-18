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
    contact # tui for meshtastic
  ];

  # MESHTASTIC DEVICE ONLY
  # services.meshtasticd = {
  #   enable = true;
  #   user = "benjamin";
  #   settings = {
  #     Lora = {
  #       Module = "auto";
  #     };
  #
  #     Webserver = {
  #       Port = 9443;
  #       RootPath = pkgs.meshtastic-web;
  #     };
  #
  #     General = {
  #       MaxNodes = 200;
  #       MaxMessageQueue = 100;
  #       MACAddressSource = "eth0";
  #     };
  #
  #   };
  #
  # };

}
