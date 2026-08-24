{
  config,
  pkgs,
  inputs,
  lib,
  activeUsers,
  ...
}:
let
  # nix attrset -> TOML file generator
  tomlFormat = pkgs.formats.toml { };

  herdrConfig = {
    onboarding = false;

    theme = {
      name = "kanagawa";
    };

    terminal = {
      # Executable for new interactive panes. Empty -> $SHELL, then /bin/sh.
      default_shell = "";
      shell_mode = "auto";
      new_cwd = "~/code"; # "follow" has problems with .envrc files which activate a flake -> cannot break out of it even if directory is changed
    };

    update = {
      channel = "stable";
      version_check = true;
      manifest_check = true;
    };

    keys = {
      # Prefix key to enter prefix mode. Examples: "ctrl+b", "f12", "esc", "-".
      prefix = "ctrl+b";

      # Prefix-mode actions (uncomment/edit to override defaults).
      # Custom commands (array of tables). type = shell | pane | popup.
      # command = [
      #   {
      #     key = "prefix+alt+g";
      #     type = "popup";
      #     command = "lazygit";
      #     width = "80%";
      #     height = "80%";
      #   }
      # ];
    };

    ui = {
      sidebar_width = 26;
      sidebar_min_width = 18;
      sidebar_max_width = 36;
      sidebar_collapsed_mode = "compact";
      mobile_width_threshold = 64;
      mouse_capture = true;
      copy_on_select = true;
      host_cursor = "auto";
      redraw_on_focus_gained = true;
      mouse_scroll_lines = 3;
      confirm_close = true;
      prompt_new_tab_name = true;
      pane_borders = true;
      pane_gaps = true;
      show_agent_labels_on_pane_borders = false;
      hide_tab_bar_when_single_tab = false;
      agent_panel_sort = "spaces";
      accent = "cyan";

      toast = {
        delivery = "off";
        delay_seconds = 1;
        herdr.position = "bottom-right";
        clipboard = {
          enabled = true;
          position = "bottom-center";
        };
      };

      sound = {
        enabled = false;
        # Optional custom mp3s (relative paths resolve from this config's dir).
        # path = "sounds/notification.mp3";
        # done_path = "sounds/done.mp3";
        # request_path = "sounds/request.mp3";
        # Per-agent overrides: default | on | off
        # agents.droid = "off";
      };
    };

    session = {
      resume_agents_on_restore = true;
    };

    remote = {
      manage_ssh_config = true;
    };

    experimental = {
      allow_nested = false;
      kitty_graphics = true;
      pane_history = true;
      cjk_ime_cursor_shape = "steady_block";
    };

    advanced = {
      scrollback_limit_bytes = 10000000;
    };
  };
in
{
  imports = [
  ];

  environment.systemPackages = with pkgs; [
    herdr
  ];

  ##################
  ## HOME MANAGER ##
  ##################
  home-manager.users.benjamin = lib.mkIf (lib.elem "benjamin" activeUsers) {
    programs.antigravity-cli = {
      enable = true;
    };

    # Generate ~/.config/herdr/config.toml from the nix attrset above.
    xdg.configFile."herdr/config.toml".source = tomlFormat.generate "herdr-config.toml" herdrConfig;
  };
}
