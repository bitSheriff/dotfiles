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
    ./opencode
    ./antigravity-cli.nix
    ./claude-code.nix
  ];

  environment.systemPackages =
    with pkgs;
    [
      mcp-nixos # mcp server so agents can access Nix and NixOS resources
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
