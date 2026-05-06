{
  config,
  pkgs,
  inputs,
  ...
}:
let
  unblock_bluetooth = pkgs.writeShellScriptBin "unblock-blueooth" ''
    sudo rfkill unblock bluetooth
  '';
in
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
    unblock_bluetooth
  ];

}
