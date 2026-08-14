{
  pkgs,
  lib,
  activeUsers,
  ...
}:
let
  # the npm package has a `#!/usr/bin/env node` shebang, so `node` itself must be
  # on PATH - calling npx by its store path is not enough
  hledger-mcp = pkgs.writeShellScriptBin "hledger-mcp" ''
    # hledger fails to read journals containing umlauts without a UTF-8 locale,
    # which GUI-launched clients do not necessarily pass on
    export LANG="''${LANG:-C.UTF-8}"
    export PATH="${pkgs.nodejs}/bin:$PATH"
    exec ${pkgs.nodejs}/bin/npx -y @iiatlas/hledger-mcp "$@"
  '';
in
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
          command = "${hledger-mcp}/bin/hledger-mcp";
          args = [
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
