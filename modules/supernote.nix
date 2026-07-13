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
    supernote-tool
  ];

  environment.etc."libinput/local-overrides.quirks".text = ''
    [Supernote Supernote Nomad]
    MatchVendor=0x2207
    MatchProduct=0x07
    AttrEventCode=+BTN_STYLUS
    AttrPressureRange=197:194
  '';

  services.udev.extraHwdb = ''
    evdev:input:b0003v2207p0007*
     EVDEV_ABS_00=::20
     EVDEV_ABS_01=::20
  '';
}

