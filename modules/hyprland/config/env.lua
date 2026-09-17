hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "Adawita")
hl.env("HYPRSHOT_DIR", "$HOME/Pictures/Screenshots")
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("GTK_THEME", "Adwaita:dark")
hl.env("WEBKIT_DISABLE_DMABUF_RENDERER", "1")
-- Must include /etc/profiles/per-user/$USER/share: that's where
-- home-manager's `useUserPackages = true` writes xdg.desktopEntries
-- (e.g. modules/chromium.nix webapps), so without it launchers like
-- noctalia/fuzzel silently can't see any home-manager-generated .desktop file.
hl.env(
  "XDG_DATA_DIRS",
  "$HOME/.nix-profile/share:$HOME/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:/etc/profiles/per-user/$USER/share:/run/current-system/sw/share:/usr/local/share:/usr/share"
)
hl.env("PATH", "/home/benjamin/.local/share/bin:/home/benjamin/.local/bin:" .. (os.getenv("PATH") or ""))