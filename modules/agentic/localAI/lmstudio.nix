{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.cfg.development.agentic.localAI;
in
{
  config =
    lib.mkIf (config.cfg.development.agentic.enable && cfg.enable && cfg.backend == "lmstudio")
      {
        # LM Studio is a GUI app (unfree). Only the package is declarative - the
        # HTTP server, the loaded model, its context length and the bind address
        # are all app state in ~/.lmstudio, so cfg.localAI.models cannot be
        # enforced here. It only tells the agents which models to offer.
        #
        # After installing, in the app:
        #   - Developer tab -> enable "start server on launch", otherwise every
        #     reboot leaves the agents with a connection error
        #   - load each model in cfg.localAI.models with a context length that
        #     matches the `contextWindow` declared there
        environment.systemPackages = with pkgs; [ lmstudio ];
      };
}
