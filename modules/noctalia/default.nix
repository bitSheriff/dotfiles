{
  config,
  pkgs,
  inputs,
  lib,
  activeUsers,
  dotfiles_path,
  ...
}:

{

  imports = [
  ];

  environment.systemPackages = with pkgs; [
    # noctalia itself is installed by the home-manager module below
    # (programs.noctalia, pointed at pkgs.noctalia via `package`)

    # needed for some plugins / screenshot & clipboard helpers
    cliphist
    curl
    ffmpeg
    gifski
    grim
    imagemagick
    jq
    slurp
    tesseract
    translate-shell
    wl-clipboard
    wl-screenrec
    gpu-screen-recorder
    zbar
  ];

  home-manager.users.benjamin =
    { config, lib, ... }:
    {
      imports = [
        inputs.noctalia.homeModules.default
      ];

      config = lib.mkIf (lib.elem "benjamin" activeUsers) {
        programs.noctalia = {
          enable = true;
          # Reuse the already-cached nixpkgs build instead of compiling from
          # the noctalia flake (same version is in nixpkgs unstable).
          package = pkgs.noctalia;

          # Theme (mode/source/custom_palette), wallpaper path, fonts and
          # opacity are injected by Stylix (stylix.targets.noctalia, see
          # modules/stylix). Keep this minimal - it's the v5 TOML schema,
          # not the old v4 settings.json, so prior customization (bar
          # widgets, plugins, launcher tweaks) was NOT ported and needs to
          # be redone through the in-app Settings UI, which writes to
          # ~/.local/state/noctalia/settings.toml.
          settings = { };
        };
      };
    };

}
