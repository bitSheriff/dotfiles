{
  config,
  pkgs,
  inputs,
  lib,
  activeUsers,
  ...
}:
let
  # Where the local OpenAI-compatible server lives.
  # rhodos runs LM Studio itself; other hosts talk to rhodos over the LAN
  # (LM Studio: Developer tab -> "Serve on local network").
  localAiHost = if config.networking.hostName == "rhodos" then "localhost" else "rhodos";

  # Single source of truth for the local LM Studio models: registered as a
  # provider below AND expanded into `enabledModels`, so adding one here is
  # enough to make it selectable in pi.
  # NOTE: `id` must match what the server reports:
  #   curl http://localhost:1234/v1/models | jq -r '.data[].id'
  # Embedding models (nomic-embed-text) are deliberately left out, they cannot chat.
  lmstudioModels = [
    {
      id = "qwen/qwen3.8-27b";
      name = "Qwen3.8 27B (local)";
      reasoning = true;
      # thinking cannot be switched off on this model
      thinkingLevelMap.off = null;
      # must match the context the model is LOADED with in LM Studio,
      # not the 262144 the model could do -- check with `lms ps`
      contextWindow = 32768;
      maxTokens = 8192;
    }
    {
      id = "google/gemma-4-e4b";
      name = "Gemma 4 E4B (local)";
      contextWindow = 32768;
      maxTokens = 8192;
    }
  ];
in
{
  imports = [
  ];

  config = lib.mkIf config.cfg.development.agentic.pi-coding-agent.enable {
    environment.systemPackages = with pkgs; [
    ];

    ##################
    ## HOME MANAGER ##
    ##################
    home-manager.users.benjamin = lib.mkIf (lib.elem "benjamin" activeUsers) {
      programs.pi-coding-agent = {
        enable = true;
        extraPackages = with pkgs; [ nodejs ];
        settings = {
          theme = "synthwave-84";
          enableInstallTelemetry = false;
          quietStartup = true;
          npmCommand = [ "${lib.getExe' pkgs.nodejs "npm"}" ];
          defaultProjectTrust = "always"; # always trust new projects
          tuiMode = "fullscreen";
          externalEditor = "zeditor";
          compaction = {
            enabled = true;
            keepRecentTokens = 20000;
            reserveTokens = 16384;
            defaultThinkingLevel = "medium";
          };
          packages = [
            "npm:pi-mcp-adapter" # enable mcp
            "npm:pi-web-access" # enable web search with multiple tools
            "npm:@juicesharp/rpiv-ask-user-question" # ask the user questions
            "npm:context-mode"
            "npm:@juicesharp/rpiv-todo" # work with todos

            # Providers and Login
            "npm:pi-claude-auth" # use Claude Code Subscription (uses claude instance for login, so i guess you need it installed)

            # Themes
            "npm:pi-theme-synthwave-84"
          ];

          # default Provider and Setting
          defaultProvider = "anthropic";
          defaultModel = "claude-sonnet-5";
          # other models are not displayed
          enabledModels = [
            # Claude Models
            "claude-haiku-4-5" # fast
            "claude-sonnet-5" # normal tasks
            "claude-opus-5" # hard tasks, debugging

            # OpenRouter Models
            "deepseek/deepseek-v4-flash"
            "deepseek/deepseek-v4-pro"

            # Local Models -- every model from `lmstudioModels` above.
            # Qualified with the "lmstudio/" prefix on purpose: bare ids like
            # "qwen/qwen3.8-27b" also exist on openrouter and huggingface, and pi
            # hides an entry that is ambiguous across authenticated providers.
            # Wildcards such as "lmstudio/*" are NOT supported here.
          ]
          ++ (map (m: "lmstudio/${m.id}") lmstudioModels);
        };

        # written to ~/.pi/agent/models.json
        models = {
          providers = {
            lmstudio = {
              baseUrl = "http://${localAiHost}:1234/v1";
              api = "openai-completions";
              apiKey = "lmstudio"; # dummy, the server ignores it, but pi wants auth to be present
              compat = {
                supportsDeveloperRole = false; # llama.cpp/LM Studio want a `system` role
                supportsReasoningEffort = false;
                maxTokensField = "max_tokens";
              };
              models = lmstudioModels;
            };

            # ollama = {
            #   baseUrl = "http://${localAiHost}:11434/v1";
            #   api = "openai-completions";
            #   apiKey = "ollama";
            #   compat = {
            #     supportsDeveloperRole = false;
            #     supportsReasoningEffort = false;
            #   };
            #   models = [ { id = "qwen2.5-coder:7b"; } ];
            # };
          };
        };
      };

      home.file = {
        ".pi/agent/skills".source = ../_skills;
        ".pi/agent/extensions".source = ./extensions; # exclusive to pi-coding-agent
      };

    };
  };
}
