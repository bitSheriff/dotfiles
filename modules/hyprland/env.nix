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
  home-manager.users.benjamin =
    { config, lib, ... }:
    lib.mkIf (lib.elem "benjamin" activeUsers) {
      wayland.windowManager.hyprland.settings = {
        env = [
          { _args = [ "XCURSOR_SIZE" "24" ]; }
          { _args = [ "HYPRCURSOR_SIZE" "24" ]; }
          { _args = [ "HYPRCURSOR_THEME" "Adawita" ]; }
          { _args = [ "HYPRSHOT_DIR" "$HOME/Pictures/Screenshots" ]; }
          { _args = [ "LIBVA_DRIVER_NAME" "nvidia" ]; }
          { _args = [ "XDG_CURRENT_DESKTOP" "Hyprland" ]; }
          { _args = [ "XDG_SESSION_TYPE" "wayland" ]; }
          { _args = [ "GBM_BACKEND" "nvidia-drm" ]; }
          { _args = [ "__GLX_VENDOR_LIBRARY_NAME" "nvidia" ]; }
          { _args = [ "QT_QPA_PLATFORMTHEME" "qt6ct" ]; }
          { _args = [ "QT_QPA_PLATFORM" "wayland;xcb" ]; }
          { _args = [ "GDK_BACKEND" "wayland,x11,*" ]; }
          { _args = [ "GTK_THEME" "Adwaita:dark" ]; }
          { _args = [ "WEBKIT_DISABLE_DMABUF_RENDERER" "1" ]; }
          { _args = [ "XDG_DATA_DIRS" "/home/benjamin/.nix-profile/share:/home/benjamin/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:/run/current-system/sw/share:/usr/local/share:/usr/share" ]; }
          { _args = [ "PATH" "/home/benjamin/.local/share/bin:/home/benjamin/.local/bin:$PATH" ]; }
        ];
      };
    };
}
