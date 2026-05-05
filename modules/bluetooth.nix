{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
  ];

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;
      };
    };
  };

  services.blueman.enable = true;
  environment.systemPackages = with pkgs; [
    bluez # provides bluetoothctl
    bluetui # TUI for bluetooth
  ];

}
