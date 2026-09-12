{
  config,
  lib,
  ...
}:
let
  cfg = config.cfg.development.agentic.localAI;
in
{
  imports = [
    ./ollama.nix
    ./lmstudio.nix
  ];

  config = lib.mkIf (config.cfg.development.agentic.enable && cfg.enable) {
    # Every backend speaks the OpenAI API, so consumers (modules/agentic/pi-agent)
    # only need the base URL, which they build from `localAI.host`/`localAI.port`.
    # The backend-specific bits live in ./ollama.nix and ./lmstudio.nix.

    assertions = [
      {
        assertion = cfg.backend != "lmstudio" || !cfg.openFirewall;
        message = ''
          cfg.development.agentic.localAI.openFirewall has no effect with the
          lmstudio backend: LM Studio binds to 127.0.0.1 and the bind address is
          set inside the app (Developer tab), not declaratively.
        '';
      }
    ];
  };
}
