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
  config = lib.mkIf (config.cfg.development.agentic.enable && cfg.enable && cfg.backend == "ollama") {
    services.ollama = {
      enable = true;

      # ollama picks ollama-cpu unless told otherwise, which silently ignores
      # the GPU. Pin the CUDA build on NVIDIA hosts.
      package =
        if (config.services.xserver.videoDrivers or [ ]) == [ "nvidia" ] then
          pkgs.ollama-cuda
        else
          pkgs.ollama;

      # loopback unless the API is explicitly shared with the network
      host = if cfg.openFirewall then "0.0.0.0" else "127.0.0.1";
      inherit (cfg) port openFirewall;

      # pulled by ollama-model-loader.service after the server comes up;
      # syncModels removes anything no longer declared in cfg.localAI.models
      loadModels = map (m: m.id) cfg.models;
      syncModels = true;

      environmentVariables = {
        # ollama defaults to a small context and silently truncates beyond it.
        # Use the largest context any declared model asks for, so a model
        # loaded on demand is not capped below what the agents are told.
        OLLAMA_CONTEXT_LENGTH = toString (
          lib.foldl' (acc: m: if m.contextWindow > acc then m.contextWindow else acc) 8192 cfg.models
        );
      };
    };
  };
}
