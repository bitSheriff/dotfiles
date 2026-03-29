{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    anki
    thunderbird
    typst
    zathura
    lazydocker
  ];

}
