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
          "XCURSOR_SIZE,24"
          "HYPRCURSOR_SIZE,24"
          "HYPRCURSOR_THEME,Adawita"
          "HYPRSHOT_DIR,$HOME/Pictures/Screenshots"
          "LIBVA_DRIVER_NAME,nvidia"
          "XDG_CURRENT_DESKTOP,Hyprland"
          "XDG_SESSION_TYPE,wayland"
          "GBM_BACKEND,nvidia-drm"
          "__GLX_VENDOR_LIBRARY_NAME,nvidia"
          "QT_QPA_PLATFORMTHEME,qt6ct"
          "QT_QPA_PLATFORM,wayland;xcb"
          "GDK_BACKEND,wayland,x11,*"
          "GTK_THEME,Adwaita:dark"
          "WEBKIT_DISABLE_DMABUF_RENDERER,1"
          "XDG_DATA_DIRS,/home/benjamin/.nix-profile/share:/home/benjamin/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:/run/current-system/sw/share:/usr/local/share:/usr/share"
          "PATH,/home/benjamin/.local/share/bin:/home/benjamin/.local/bin:$PATH"
        ];

      };
    };
}
