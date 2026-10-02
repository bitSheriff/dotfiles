{
  config,
  pkgs,
  lib,
  activeUsers,
  ...
}:
let
  withSecrets = import ../../../nix-lib/with-secrets.nix { inherit pkgs lib; };

  # declared in users/benjamin.nix
  sopsSecrets = config.home-manager.users.benjamin.sops.secrets;
in
{

  config = lib.mkIf config.cfg.development.agentic.enable {
    environment.systemPackages = with pkgs; [
      opencode
    ];

    ##################
    ## HOME MANAGER ##
    ##################
    home-manager.users.benjamin = lib.mkIf (lib.elem "benjamin" activeUsers) {
      programs.opencode = {
        enable = true;

        # The keys are handed to opencode only (see nix-lib/with-secrets.nix)
        # rather than exported in the shell. This also covers the
        # opencode-web service below, which never saw the shell's exports.
        package = withSecrets {
          pkg = pkgs.opencode;
          env.OPENCODE_SERVER_USERNAME = "benjamin";
          secrets = {
            OPENROUTER_API_KEY = sopsSecrets."api/openrouter".path;
            OPENCODE_SERVER_PASSWORD = sopsSecrets."access/opencode".path;
          };
        };

        # pull in the shared MCP servers from `programs.mcp.servers` (../mcp.nix)
        enableMcpIntegration = true;

        # settings in `opencode.json`
        settings = {
          plugin = [
            "@simonwjackson/opencode-direnv"
          ];
          formatter = true;
          permission = {
            read = {
              "*" = "allow";
              "*.env" = "ask";
              "*.env.example" = "allow";
            };
            git = {
              "*" = "ask";
              pull = "allow";
              push = "allow";
              commit = "deny";
            };
            nix = {
              check = "allow";
              develop = "allow";
              "build *" = "allow";
              "run *" = "allow";
            };
          };
        };

        # settings in `tui.json`
        # theme is owned by Stylix (modules/stylix) - do not set tui.theme
        # here, it conflicts.
        tui = {
          keybinds = {
            leader = "alt+b";
          };
          diff_style = "auto";
          mouse = true;
          icons = true;
          sidebar = "left";
        };

        web = {
          enable = true;
          extraArgs = [
            "--port"
            "4096"
          ];
        };

      };

      # the server password is read from a sops secret on start
      systemd.user.services.opencode-web.Unit.After = [ "sops-nix.service" ];

      xdg.configFile = {
        "opencode/agents".source = ../_agents;
        "opencode/skills".source = ../_skills;
      };

    };
  };

}
