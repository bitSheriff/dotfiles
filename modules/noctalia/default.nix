{
  config,
  pkgs,
  inputs,
  lib,
  activeUsers,
  dotfiles_path,
  ...
}:

let
  module_path = "${dotfiles_path}/modules/noctalia";

  # Per-host noctalia overrides (monitor/output-pinned settings like
  # wallpaper.monitors.* or lockscreen widget placement can't be shared
  # across hosts). Each file pulls in config/common.toml itself via
  # [include] - see modules/noctalia/config/hosts/. Nix dispatches by
  # hostname directly (same pattern as modules/stylix's `themes` attrset),
  # so a missing host fails loudly with a normal Nix "attribute missing"
  # error instead of a filesystem check at eval time.
  hostConfigFiles = {
    delos = "${module_path}/config/hosts/delos.toml";
    rhodos = "${module_path}/config/hosts/rhodos.toml";
  };
in
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
    { config, lib, osConfig, ... }:
    let
      hostConfigFile =
        hostConfigFiles.${osConfig.networking.hostName}
          or (throw "modules/noctalia: no entry in hostConfigFiles for host '${osConfig.networking.hostName}' - add modules/noctalia/config/hosts/${osConfig.networking.hostName}.toml and list it there");
    in
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
          # modules/stylix) through this option, which the module renders
          # into a single immutable ~/.config/noctalia/config.toml. Keep
          # this Stylix-only - hand-edited settings go in config/common.toml
          # and config/hosts/<host>.toml below.
          settings = { };
        };

        # Hand-curated settings, live-symlinked into the dotfiles repo (same
        # workflow as the old v4 settings.json symlink): noctalia merges
        # every *.toml file under ~/.config/noctalia/ alphabetically, so
        # this loads alongside (after) the Stylix-generated config.toml
        # above. The symlink target is picked by hostname - edit
        # modules/noctalia/config/hosts/<host>.toml (or common.toml, which
        # it includes) directly, it's hot-reloaded, no rebuild needed.
        xdg.configFile."noctalia/user.toml".source =
          config.lib.file.mkOutOfStoreSymlink hostConfigFile;
      };
    };

}
