
{ pkgs, ... }:

{
  fonts = {
    packages = with pkgs; [
      font-awesome
      symbola
      material-icons
      hackgen-nf-font
      nerd-fonts
    ];
  };
}
