{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    anki
    thunderbird
    typst
    typesetter # minimal typst editor
    zathura
    lazydocker
    # octave # free alternative to MATLAB (but my not use python then ...)
    jupyter # python jupyter notebook
    # wireshark-qt # network analyzer
  ];

}
