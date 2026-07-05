{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
  ];

  hardware.keyboard.zsa.enable = true;

  environment.systemPackages =
    with pkgs;
    [
      keymapp # for ZSA keyboards
      ttyper # terminal typing game
    ]
    ++ lib.optionals (config.networking.hostName == "rhodos") [
      solaar # logitec devices
    ];

}
