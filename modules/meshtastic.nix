{
  config,
  pkgs,
  inputs,
  username,
  ...
}:

{
  imports = [
  ];

  environment.systemPackages = with pkgs; [
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
