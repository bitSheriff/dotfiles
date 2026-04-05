{ config, pkgs, ... }:

{
  imports = [
    ../modules/zathura.nix
  ];

  environment.systemPackages = with pkgs; [
    anki
    thunderbird
    typst
    typesetter # minimal typst editor
    lazydocker
    # octave # free alternative to MATLAB (but my not use python then ...)
    jupyter # python jupyter notebook
    # wireshark-qt # network analyzer
  ];

}
