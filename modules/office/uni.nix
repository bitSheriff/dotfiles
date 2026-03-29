{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    anki
    thunderbird
    typst
    typesetter              # minimal typst editor
    zathura
    lazydocker
    #octave
    jupyter                 # python jupyter notebook
  ];

}
