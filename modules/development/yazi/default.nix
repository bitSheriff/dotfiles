{ config, pkgs, ... }:

{
  imports = [
    ./keymap.nix
  ];

  environment.systemPackages = with pkgs; [
    glow # view markdown
    rsync
    lazygit
  ];

  programs.yazi = {
    enable = true;
    plugins = {
      inherit (pkgs.yaziPlugins) mount;
      inherit (pkgs.yaziPlugins) smart-enter;
      inherit (pkgs.yaziPlugins) git;
      inherit (pkgs.yaziPlugins) piper;
      inherit (pkgs.yaziPlugins) lazygit;
      inherit (pkgs.yaziPlugins) rsync;
    };
    settings = {
      yazi = {
        mgr = {
          ratio = [
            1
            4
            3
          ];
          sort_by = "alphabetical";
          sort_sensitive = false;
          sort_reverse = false;
          sort_dir_first = true;
          linemode = "none";
          show_hidden = true;
          show_symlink = true;
          scrolloff = 5;
        };

        preview = {
          tab_size = 2;
          max_width = 600;
          max_height = 900;
          cache_dir = "";
        };

        opener = {
          edit = [
            {
              run = ''nvim "$@"'';
              desc = "neovim";
              block = true;
              for = "unix";
            }
            {
              run = ''zed "$@"'';
              desc = "zed";
              block = false;
              for = "unix";
            }
            {
              run = ''zed -n "$@"'';
              desc = "zed (new workspace)";
              block = false;
              for = "unix";
            }
          ];
          open = [
            {
              run = ''xdg-open "$@"'';
              desc = "Open";
              for = "linux";
            }
            {
              run = ''open "$@"'';
              desc = "Open";
              for = "macos";
            }
          ];
          reveal = [
            {
              run = ''xdg-open "$(dirname "$0")"'';
              desc = "Reveal";
              for = "linux";
            }
            {
              run = ''exiftool "$1"u echo "Press enter to exit"; read _'';
              block = true;
              desc = "Show EXIF";
              for = "unix";
            }
          ];
          extract = [
            {
              run = ''file-roller "$1"'';
              desc = "Open with File-Roller";
              for = "unix";
            }
            {
              run = ''unrar x "$1"'';
              desc = "(unrar) Extract here";
              for = "unix";
            }
            {
              run = ''unzip "$1"'';
              desc = "(unzip) Extract here";
              for = "unix";
            }
          ];
          play = [
            {
              run = ''mpv "$@"'';
              orphan = true;
              for = "unix";
            }
            {
              run = ''mediainfo "$1"; echo "Press enter to exit"; read _'';
              block = true;
              desc = "Show media info";
              for = "unix";
            }
          ];
          viewPDF = [
            {
              run = ''zathura "$@"'';
              orphan = true;
              for = "unix";
            }
            {
              run = ''okular "$@"'';
              orphan = true;
              for = "unix";
            }
          ];
          viewImage = [
            {
              run = ''qview "$@"'';
              orphan = true;
              for = "unix";
            }
          ];
          viewEpub = [
            {
              run = ''foliate "$@"'';
              orphan = true;
              for = "unix";
              desc = "Open with Foliate";
            }
            {
              run = ''okular "$@"'';
              orphan = true;
              for = "unix";
              desc = "Open with Okular";
            }
          ];
          openMarkdown = [
            {
              run = ''nvim "$@"'';
              desc = "neovim";
              block = true;
              for = "unix";
            }
            {
              run = ''zed "$@"'';
              desc = "Zed";
              block = false;
              for = "unix";
            }
            {
              run = ''typora "$@"'';
              desc = "Typora";
              block = false;
              for = "unix";
            }
          ];
          openMusic = [
            {
              run = ''kew play "$@"'';
              desc = "Open with Kew";
              block = true;
              for = "unix";
            }
            {
              run = ''picard "$@"'';
              desc = "Open with MuiscBrainz Picard";
              block = false;
              for = "unix";
            }
          ];
          openVideo = [
            {
              run = ''mpv "$@"'';
              orphan = true;
              for = "unix";
              block = false;
            }
            {
              run = ''haruna "$@"'';
              orphan = true;
              for = "unix";
              block = false;
            }
          ];
          openDiffMerger = [
            {
              run = ''meld "$@"'';
              desc = "Open with Meld";
              block = false;
            }
          ];
        };
        open = {
          rules = [
            {
              name = "*/";
              use = [
                "edit"
                "open"
                "reveal"
              ];
            }
            {
              mime = "application/epub+zip";
              use = [ "viewEpub" ];
            }
            {
              mime = "text/plain";
              use = [
                "openMarkdown"
                "openDiffMerger"
              ];
            }
            {
              mime = "text/*";
              use = [
                "edit"
                "reveal"
                "openMarkdown"
                "openDiffMerger"
              ];
            }
            {
              mime = "image/*";
              use = [
                "viewImage"
                "open"
                "reveal"
              ];
            }
            {
              mime = "audio/*";
              use = [
                "openMusic"
                "reveal"
              ];
            }
            {
              mime = "video/*";
              use = [
                "openVideo"
                "reveal"
              ];
            }
            {
              mime = "inode/x-empty";
              use = [
                "edit"
                "reveal"
              ];
            }
            {
              mime = "application/*zip";
              use = [
                "extract"
                "reveal"
              ];
            }
            {
              mime = "application/x-{tar,bzip*,7z-compressed,xz,rar}";
              use = [
                "extract"
                "reveal"
              ];
            }
            {
              mime = "application/*pdf";
              use = [
                "viewPDF"
                "reveal"
              ];
            }
            {
              mime = "application/json";
              use = [
                "edit"
                "reveal"
              ];
            }
            {
              mime = "*/javascript";
              use = [
                "edit"
                "reveal"
              ];
            }
            {
              mime = "*";
              use = [
                "open"
                "reveal"
              ];
            }
          ];
        };
      };

    };
  };

}
