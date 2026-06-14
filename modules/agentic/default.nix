{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:
{
  imports = [
    ./opencode
  ];

  environment.systemPackages =
    with pkgs;
    [
      gemini-cli
      antigravity-cli
      mistral-vibe
    ]
    # Host Specifics (strong gaming PC with dedicated GPU)
    ++ lib.optionals (config.networking.hostName == "rhodos") [
      (alpaca.override { ollama = ollama-cuda; }) # GUI chat app for ollama
    ];

  services.ollama = lib.mkIf (config.networking.hostName == "rhodos") {
    enable = true;
    package = pkgs.ollama-cuda;
  };
}
