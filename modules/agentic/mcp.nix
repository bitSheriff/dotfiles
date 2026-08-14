{
  pkgs,
  lib,
  activeUsers,
  ...
}:
{
  ##################
  ## HOME MANAGER ##
  ##################
  # Client-agnostic MCP server registry, written to ~/.config/mcp/mcp.json.
  # Each client pulls these in via its own `enableMcpIntegration = true;`.
  home-manager.users.benjamin = lib.mkIf (lib.elem "benjamin" activeUsers) {
    programs.mcp = {
      enable = true;

      servers = {
        # https://github.com/iiAtlas/hledger-mcp
        # Fetched from npm on first run, so it needs network once and is not pinned.
        hledger = {
          command = "${pkgs.nodejs}/bin/npx";
          args = [
            "-y"
            "@iiatlas/hledger-mcp"
            "/home/benjamin/notes/Journal/_finance/all.hledger"
          ];
          env = {
            # the clients spawn the server without the zsh env, so use store paths
            HLEDGER_EXECUTABLE_PATH = "${pkgs.hledger}/bin/hledger";
            HLEDGER_WEB_EXECUTABLE_PATH = "${pkgs.hledger-web}/bin/hledger-web";
          };
        };

        # query Nix and NixOS packages, options and Home Manager options
        nixos.command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
      };
    };
  };
}
