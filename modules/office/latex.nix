{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    texliveMedium
  ];
}
