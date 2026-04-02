{
  config,
  pkgs,
  lib,
  ...
}:

{
  programs.starship = {
    enable = true;

    settings = {
      format = lib.concatStrings [
        "[](#CC16C3)"
        "$status"
        "$username"
        "$os"
        "[](bg:#9600ff fg:#CC16C3)"
        "$directory"
        "[](fg:#9600ff bg:#4900ff)"
        "$git_branch"
        "$git_status"
        "$git_metrics"
        "[](fg:#4900ff bg:#00b8ff)"
        "$c"
        "$golang"
        "$haskell"
        "$java"
        "$julia"
        "$rust"
        "$lua"
        "$python"
        "[](fg:#00b8ff bg:#06969A)"
        "$docker_context"
        "[](fg:#06969A bg:#33658A)"
        "$time"
        "$memory_usage"
        "$battery"
        "[ ](fg:#33658A)"
      ];

      scan_timeout = 30;
      command_timeout = 3600000;
      add_newline = false;

      character = {
        success_symbol = "[>](bold #50fa7b)";
        error_symbol = "[x](bold #ff5555)";
        vimcmd_symbol = "[<](bold #50fa7b)";
      };

      username = {
        show_always = true;
        style_user = "bg:#CC16C3 bold";
        style_root = "bg:#2D2B55 bold";
        format = "[$user ]($style)";
        disabled = false;
      };

      os = {
        style = "bg:#CC16C3";
        disabled = false;
        symbols = {
          Alpaquita = " ";
          Alpine = " ";
          AlmaLinux = " ";
          Amazon = " ";
          Android = " ";
          Arch = " ";
          Artix = " ";
          CentOS = " ";
          Debian = " ";
          DragonFly = " ";
          Emscripten = " ";
          EndeavourOS = " ";
          Fedora = " ";
          FreeBSD = " ";
          Garuda = "󰛓 ";
          Gentoo = " ";
          HardenedBSD = "󰞌 ";
          Illumos = "󰈸 ";
          Kali = " ";
          Linux = " ";
          Mabox = " ";
          Macos = " ";
          Manjaro = " ";
          Mariner = " ";
          MidnightBSD = " ";
          Mint = " ";
          NetBSD = " ";
          NixOS = " ";
          OpenBSD = "󰈺 ";
          openSUSE = " ";
          OracleLinux = "󰌷 ";
          Pop = " ";
          Raspbian = " ";
          Redhat = " ";
          RedHatEnterprise = " ";
          RockyLinux = " ";
          Redox = "󰀘 ";
          Solus = "󰠳 ";
          SUSE = " ";
          Ubuntu = " ";
          Unknown = " ";
          Void = " ";
          Windows = "󰍲 ";
        };
      };

      directory = {
        style = "bg:#9600ff bold";
        format = "[ $path ]($style)";
        truncation_length = 3;
        truncation_symbol = "…/";
        substitutions = {
          "Documents" = "󰈙  ";
          "Downloads" = " ";
          "Music" = " ";
          "Pictures" = " ";
          "notes" = "";
          "code" = "";
          ".config" = "";
          "SatanOS" = "󱙧";
          "blog" = "";
          "Audiobooks" = "󰋋";
          "books" = "";
        };
      };

      c = {
        symbol = " ";
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) ]($style)";
      };

      docker_context = {
        symbol = " ";
        style = "bg:#06969A";
        format = "[ $symbol $context ]($style) $path";
      };

      git_branch = {
        symbol = " ";
        style = "bg:#4900ff bold";
        format = "[ $symbol $branch ]($style)";
      };

      git_status = {
        style = "bg:#4900ff";
        conflicted = "⚔️ ";
        ahead = " ×\${count} ";
        behind = " ×\${count} ";
        diverged = " ×\${ahead_count}  ×\${behind_count} ";
        untracked = "×\${count} ";
        stashed = "📦 ";
        modified = " ×\${count} ";
        staged = " ×\${count} ";
        renamed = "󰑕 ×\${count} ";
        deleted = "🗑️×\${count} ";
        format = "[$all_status$ahead_behind ]($style)";
        ignore_submodules = false;
      };

      git_metrics = {
        added_style = "bg:#4900ff bold #47e99b";
        deleted_style = "bg:#4900ff bold red";
        only_nonzero_diffs = true;
        format = "([+$added]($added_style))([-$deleted]($deleted_style))";
        disabled = false;
        ignore_submodules = false;
      };

      golang = {
        symbol = " ";
        style = "bg:#00b8ff";
        format = "[ $symbol ($version) ]($style)";
      };

      rust = {
        symbol = "🦀 ";
        style = "bg:#00b8ff";
        format = "[ $symbol ($version) ]($style)";
        detect_extensions = [ "rs" ];
        detect_files = [ "Cargo.toml" ];
        detect_folders = [ ];
      };

      lua = {
        symbol = "🌕 ";
        style = "bg:#00b8ff";
        format = "[ $symbol ($version) ]($style)";
      };

      python = {
        symbol = " ";
        pyenv_version_name = true;
        python_binary = "python3";
        style = "bg:#00b8ff";
        format = "[ $symbol ($version) ]($style)";
      };

      time = {
        disabled = false;
        time_format = "%R";
        style = "bg:#33658A";
        format = "[  $time ]($style)";
      };

      battery = {
        disabled = false;
        full_symbol = " ";
        charging_symbol = "⚡️ ";
        discharging_symbol = " ";
        display = [
          { style = "bg:#33658A"; }
          {
            threshold = 15;
            style = "bold red bg:#33658A";
          }
          {
            threshold = 30;
            style = "bold yellow bg:#33658A";
            discharging_symbol = " ";
          }
        ];
      };

      memory_usage = {
        disabled = true;
        threshold = -1;
        format = " $symbol \${ram_pct} ";
        symbol = "󰍛 ";
        style = "bg:#33658A";
      };

      status = {
        style = "bg:blue";
        symbol = " ";
        success_symbol = " ";
        format = "[\\[$symbol$common_meaning$signal_name$maybe_int\\]]($style) ";
        map_symbol = true;
        disabled = true;
      };
    };
  };
}
