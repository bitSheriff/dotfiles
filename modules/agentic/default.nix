{
  config,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./opencode
  ];

  environment.systemPackages = with pkgs; [
    gemini-cli
    antigravity-cli
  ];

}
