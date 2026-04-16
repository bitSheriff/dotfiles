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

    distrobox
    distroshelf # gui for distrobox
  ];

}
