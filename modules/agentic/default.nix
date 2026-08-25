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
    ./antigravity.nix
    ./herdr.nix
  ];

  environment.systemPackages =
    with pkgs;
    [
      # mistral-vibe # needs a build!!!
    ]
    # Host Specifics (strong gaming PC with dedicated GPU)
    ++ lib.optionals (config.networking.hostName == "rhodos") [
      # (alpaca.override { ollama = ollama-cuda; }) # GUI chat app for ollama
      lmstudio # Lm Studio for local AI
    ];

  # services.ollama = lib.mkIf (config.networking.hostName == "rhodos") {
  #   enable = true;
  #   package = pkgs.ollama-cuda;
  # };

  ##################
  ## HOME MANAGER ##
  ##################
  home-manager.users.benjamin = lib.mkIf (lib.elem "benjamin" activeUsers) {

  };
}
