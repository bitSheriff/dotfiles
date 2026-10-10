{
  config,
  pkgs,
  inputs,
  lib,
  activeUsers,
  ...
}:
{
  imports = [
    ./mcp.nix
    ./opencode
    ./claude-code
    ./pi-agent
    ./localAI
    ./herdr.nix
    ./antigravity.nix
  ];

  config = lib.mkIf config.cfg.development.agentic.enable {
    environment.systemPackages = with pkgs; [
      # mistral-vibe # needs a build!!!
      openspec # spec driven development
    ];

    ##################
    ## HOME MANAGER ##
    ##################
    home-manager.users.benjamin = lib.mkIf (lib.elem "benjamin" activeUsers) {

    };
  };
}
