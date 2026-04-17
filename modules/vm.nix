{
  config,
  pkgs,
  username,
  ...
}:

{

  environment.systemPackages = with pkgs; [
    qemu
    gnome-boxes
  ];

}
