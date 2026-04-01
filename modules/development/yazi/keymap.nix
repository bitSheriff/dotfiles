{ config, pkgs, ... }:

{
  imports = [
  ];

  programs.yazi.settings.keymap = {
    mgr = {
      keymap = [
        # General
        {
          on = [ "<Esc>" ];
          run = "escape";
          desc = "Exit visual mode, clear selected, or cancel search";
        }
        {
          on = [ "<C-[" ];
          run = "escape";
          desc = "Exit visual mode, clear selected, or cancel search";
        }
        {
          on = [ "q" ];
          run = "quit";
          desc = "Exit the process";
        }
        {
          on = [ "Q" ];
          run = "quit --no-cwd-file";
          desc = "Exit the process without writing cwd-file";
        }
        {
          on = [ "<C-q>" ];
          run = "close";
          desc = "Close the current tab, or quit if it is last tab";
        }
        {
          on = [ "<C-z>" ];
          run = "suspend";
          desc = "Suspend the process";
        }

        # Navigation
        {
          on = [ "k" ];
          run = "arrow -1";
          desc = "Move cursor up";
        }
        {
          on = [ "j" ];
          run = "arrow 1";
          desc = "Move cursor down";
        }
        {
          on = [ "K" ];
          run = "arrow -5";
          desc = "Move cursor up 5 lines";
        }
        {
          on = [ "J" ];
          run = "arrow 5";
          desc = "Move cursor down 5 lines";
        }
        {
          on = [ "<S-Up>" ];
          run = "arrow -5";
          desc = "Move cursor up 5 lines";
        }
        {
          on = [ "<S-Down>" ];
          run = "arrow 5";
          desc = "Move cursor down 5 lines";
        }
        {
          on = [ "<C-u>" ];
          run = "arrow -50%";
          desc = "Move cursor up half page";
        }
        {
          on = [ "<C-d>" ];
          run = "arrow 50%";
          desc = "Move cursor down half page";
        }
        {
          on = [ "<C-b>" ];
          run = "arrow -100%";
          desc = "Move cursor up one page";
        }
        {
          on = [ "<C-f>" ];
          run = "arrow 100%";
          desc = "Move cursor down one page";
        }
        {
          on = [ "<C-PageUp>" ];
          run = "arrow -50%";
          desc = "Move cursor up half page";
        }
        {
          on = [ "<C-PageDown>" ];
          run = "arrow 50%";
          desc = "Move cursor down half page";
        }
        {
          on = [ "<PageUp>" ];
          run = "arrow -100%";
          desc = "Move cursor up one page";
        }
        {
          on = [ "<PageDown>" ];
          run = "arrow 100%";
          desc = "Move cursor down one page";
        }
        {
          on = [ "h" ];
          run = "leave";
          desc = "Go back to the parent directory";
        }
        {
          on = [ "l" ];
          run = "enter";
          desc = "Enter the child directory";
        }
        {
          on = [ "H" ];
          run = "back";
          desc = "Go back to the previous directory";
        }
        {
          on = [ "L" ];
          run = "forward";
          desc = "Go forward to the next directory";
        }

        # Seek
        {
          on = [ "<A-k>" ];
          run = "seek -5";
          desc = "Seek up 5 units in the preview";
        }
        {
          on = [ "<A-j>" ];
          run = "seek 5";
          desc = "Seek down 5 units in the preview";
        }
        {
          on = [ "<A-PageUp>" ];
          run = "seek -5";
          desc = "Seek up 5 units in the preview";
        }
        {
          on = [ "<A-PageDown>" ];
          run = "seek 5";
          desc = "Seek down 5 units in the preview";
        }
        {
          on = [ "<A-Down>" ];
          run = "seek 5";
          desc = "Seek down 5 units in the preview";
        }
        {
          on = [ "<A-Up>" ];
          run = "seek -5";
          desc = "Seek up 5 units in the preview";
        }

        # Arrows
        {
          on = [ "<Up>" ];
          run = "arrow -1";
          desc = "Move cursor up";
        }
        {
          on = [ "<Down>" ];
          run = "arrow 1";
          desc = "Move cursor down";
        }
        {
          on = [ "<Left>" ];
          run = "leave";
          desc = "Go back to the parent directory";
        }
        {
          on = [ "<Right>" ];
          run = "enter";
          desc = "Enter the child directory";
        }
        {
          on = [
            "g"
            "g"
          ];
          run = "arrow top";
          desc = "Move cursor to the top";
        }
        {
          on = [ "G" ];
          run = "arrow bot";
          desc = "Move cursor to the bottom";
        }

        # Selection
        {
          on = [ "<Space>" ];
          run = [
            "toggle --state=none"
            "arrow 1"
          ];
          desc = "Toggle the current selection state";
        }
        {
          on = [ "v" ];
          run = "visual_mode";
          desc = "Enter visual mode (selection mode)";
        }
        {
          on = [ "V" ];
          run = "visual_mode --unset";
          desc = "Enter visual mode (unset mode)";
        }
        {
          on = [ "<C-a>" ];
          run = "toggle_all --state=true";
          desc = "Select all files";
        }
        {
          on = [ "<C-r>" ];
          run = "toggle_all --state=none";
          desc = "Inverse selection of all files";
        }

        # Operation
        {
          on = [ "o" ];
          run = "open";
          desc = "Open the selected files";
        }
        {
          on = [ "O" ];
          run = "open --interactive";
          desc = "Open the selected files interactively";
        }
        {
          on = [ "<Enter>" ];
          run = "open";
          desc = "Open the selected files";
        }
        {
          on = [ "<S-Enter>" ];
          run = "open --interactive";
          desc = "Open the selected files interactively";
        }
        {
          on = [ "y" ];
          run = "yank";
          desc = "Copy the selected files";
        }
        {
          on = [ "Y" ];
          run = "unyank";
          desc = "Cancel the yank status of files";
        }
        {
          on = [ "x" ];
          run = "yank --cut";
          desc = "Cut the selected files";
        }
        {
          on = [ "X" ];
          run = "unyank";
          desc = "Cancel the yank status of files";
        }
        {
          on = [ "p" ];
          run = "paste";
          desc = "Paste the files";
        }
        {
          on = [ "P" ];
          run = "paste --force";
          desc = "Paste the files (overwrite if the destination exists)";
        }
        {
          on = [ "-" ];
          run = "link";
          desc = "Symlink the absolute path of files";
        }
        {
          on = [ "_" ];
          run = "link --relative";
          desc = "Symlink the relative path of files";
        }
        {
          on = [ "d" ];
          run = "remove";
          desc = "Move the files to the trash";
        }
        {
          on = [ "D" ];
          run = "remove --permanently";
          desc = "Permanently delete the files";
        }
        {
          on = [ "a" ];
          run = "create";
          desc = "Create a file or directory (ends with / for directories)";
        }
        {
          on = [ "r" ];
          run = "rename --cursor=before_ext";
          desc = "Rename a file or directory";
        }
        {
          on = [ ";" ];
          run = "shell --interactive";
          desc = "Run a shell command";
        }
        {
          on = [ ":" ];
          run = "shell --confirm --block";
          desc = "Run a shell command (block the UI until the command finishes)";
        }
        {
          on = [ "." ];
          run = "hidden toggle";
          desc = "Toggle the visibility of hidden files";
        }
        {
          on = [ "s" ];
          run = "search fd";
          desc = "Search files by name using fd";
        }
        {
          on = [ "S" ];
          run = "search rg";
          desc = "Search files by content using ripgrep";
        }
        {
          on = [ "<C-s>" ];
          run = "search none";
          desc = "Cancel the ongoing search";
        }
        {
          on = [ "z" ];
          run = "plugin zoxide";
          desc = "Jump to a directory using zoxide";
        }
        {
          on = [ "Z" ];
          run = "plugin fzf";
          desc = "Jump to a directory, or reveal a file using fzf";
        }

        # Linemode
        {
          on = [
            "m"
            "s"
          ];
          run = "linemode size";
          desc = "Set linemode to size";
        }
        {
          on = [
            "m"
            "p"
          ];
          run = "linemode permissions";
          desc = "Set linemode to permissions";
        }
        {
          on = [
            "m"
            "m"
          ];
          run = "linemode mtime";
          desc = "Set linemode to mtime";
        }
        {
          on = [
            "m"
            "n"
          ];
          run = "linemode none";
          desc = "Set linemode to none";
        }

        # Copy Path
        {
          on = [
            "c"
            "c"
          ];
          run = "copy path";
          desc = "Copy the absolute path";
        }
        {
          on = [
            "c"
            "d"
          ];
          run = "copy dirname";
          desc = "Copy the path of the parent directory";
        }
        {
          on = [
            "c"
            "f"
          ];
          run = "copy filename";
          desc = "Copy the name of the file";
        }
        {
          on = [
            "c"
            "n"
          ];
          run = "copy name_without_ext";
          desc = "Copy the name of the file without the extension";
        }

        # Filter & Find
        {
          on = [ "f" ];
          run = "filter --smart";
          desc = "Filter the files";
        }
        {
          on = [ "/" ];
          run = "find --smart";
          desc = "Find next file";
        }
        {
          on = [ "?" ];
          run = "find --previous --smart";
          desc = "Find previous file";
        }
        {
          on = [ "n" ];
          run = "find_arrow";
          desc = "Go to next found file";
        }
        {
          on = [ "N" ];
          run = "find_arrow --previous";
          desc = "Go to previous found file";
        }

        # Sorting
        {
          on = [
            ","
            "m"
          ];
          run = "sort modified --dir-first";
          desc = "Sort by modified time";
        }
        {
          on = [
            ","
            "M"
          ];
          run = "sort modified --reverse --dir-first";
          desc = "Sort by modified time (reverse)";
        }
        {
          on = [
            ","
            "c"
          ];
          run = "sort created --dir-first";
          desc = "Sort by created time";
        }
        {
          on = [
            ","
            "C"
          ];
          run = "sort created --reverse --dir-first";
          desc = "Sort by created time (reverse)";
        }
        {
          on = [
            ","
            "e"
          ];
          run = "sort extension --dir-first";
          desc = "Sort by extension";
        }
        {
          on = [
            ","
            "E"
          ];
          run = "sort extension --reverse --dir-first";
          desc = "Sort by extension (reverse)";
        }
        {
          on = [
            ","
            "a"
          ];
          run = "sort alphabetical --dir-first";
          desc = "Sort alphabetically";
        }
        {
          on = [
            ","
            "A"
          ];
          run = "sort alphabetical --reverse --dir-first";
          desc = "Sort alphabetically (reverse)";
        }
        {
          on = [
            ","
            "n"
          ];
          run = "sort natural --dir-first";
          desc = "Sort naturally";
        }
        {
          on = [
            ","
            "N"
          ];
          run = "sort natural --reverse --dir-first";
          desc = "Sort naturally (reverse)";
        }
        {
          on = [
            ","
            "s"
          ];
          run = "sort size --dir-first";
          desc = "Sort by size";
        }
        {
          on = [
            ","
            "S"
          ];
          run = "sort size --reverse --dir-first";
          desc = "Sort by size (reverse)";
        }

        # Tabs
        {
          on = [ "t" ];
          run = "tab_create --current";
          desc = "Create a new tab using the current path";
        }
        {
          on = [ "1" ];
          run = "tab_switch 0";
          desc = "Switch to the first tab";
        }
        {
          on = [ "2" ];
          run = "tab_switch 1";
          desc = "Switch to the second tab";
        }
        {
          on = [ "3" ];
          run = "tab_switch 2";
          desc = "Switch to the third tab";
        }
        {
          on = [ "4" ];
          run = "tab_switch 3";
          desc = "Switch to the fourth tab";
        }
        {
          on = [ "5" ];
          run = "tab_switch 4";
          desc = "Switch to the fifth tab";
        }
        {
          on = [ "6" ];
          run = "tab_switch 5";
          desc = "Switch to the sixth tab";
        }
        {
          on = [ "7" ];
          run = "tab_switch 6";
          desc = "Switch to the seventh tab";
        }
        {
          on = [ "8" ];
          run = "tab_switch 7";
          desc = "Switch to the eighth tab";
        }
        {
          on = [ "9" ];
          run = "tab_switch 8";
          desc = "Switch to the ninth tab";
        }
        {
          on = [ "[" ];
          run = "tab_switch -1 --relative";
          desc = "Switch to the previous tab";
        }
        {
          on = [ "]" ];
          run = "tab_switch 1 --relative";
          desc = "Switch to the next tab";
        }
        {
          on = [ "{" ];
          run = "tab_swap -1";
          desc = "Swap the current tab with the previous tab";
        }
        {
          on = [ "}" ];
          run = "tab_swap 1";
          desc = "Swap the current tab with the next tab";
        }

        # Tasks & Help
        {
          on = [ "w" ];
          run = "tasks_show";
          desc = "Show the tasks manager";
        }
        {
          on = [ "~" ];
          run = "help";
          desc = "Open help";
        }

        # Goto
        {
          on = [
            "g"
            "h"
          ];
          run = "cd ~";
          desc = "Go to the home directory";
        }
        {
          on = [
            "g"
            "c"
          ];
          run = "cd ~/.config";
          desc = "Go to the config directory";
        }
        {
          on = [
            "g"
            "C"
          ];
          run = "cd ~/code";
          desc = "Go to the code directory";
        }
        {
          on = [
            "g"
            "d"
          ];
          run = "cd ~/Downloads";
          desc = "Go to the downloads directory";
        }
        {
          on = [
            "g"
            "w"
          ];
          run = "cd $WALLPAPER_DIR";
          desc = "Go to the wallpaper directory";
        }
        {
          on = [
            "g"
            "t"
          ];
          run = "cd /tmp";
          desc = "Go to the temporary directory";
        }
        {
          on = [
            "g"
            "<Space>"
          ];
          run = "cd --interactive";
          desc = "Go to a directory interactively";
        }
      ];
      prepend_keymap = [
        {
          on = "R";
          run = "plugin rsync";
          desc = "Copy files using rsync";
        }
        {
          on = "L";
          run = "plugin lazygit";
          desc = "Open lazygit";
        }
        {
          on = "l";
          run = "plugin smart-enter";
          desc = "Enter the child directory, or open the file";
        }
        {
          on = "<Right>";
          run = "plugin smart-enter";
          desc = "Enter the child directory, or open the file";
        }
      ];
    };
  };

}
