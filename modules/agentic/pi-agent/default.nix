{
  config,
  pkgs,
  inputs,
  lib,
  activeUsers,
  ...
}:
let
  localAI = config.cfg.development.agentic.localAI;

  # pi speaks the OpenAI API to whichever backend is configured; the provider is
  # named after the backend so model ids can be qualified with it below.
  localProvider = localAI.backend;

  # Translate cfg.localAI.models into pi model definitions.
  localModels = map (
    m:
    {
      inherit (m)
        id
        contextWindow
        maxTokens
        reasoning
        ;
      name = if m.name != null then m.name else m.id;
    }
    // m.extraConfig
  ) localAI.models;
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

            # Local Models -- every model from cfg.development.agentic.localAI.
            # Qualified with the provider prefix on purpose: a bare id like
            # "qwen/qwen3.8-27b" also exists on openrouter and huggingface, and
            # pi hides an entry that is ambiguous across authenticated
            # providers. Wildcards ("lmstudio/*") are NOT supported here.
          ]
          ++ lib.optionals localAI.enable (map (m: "${localProvider}/${m.id}") localModels);
        };

        # written to ~/.pi/agent/models.json.
        # Only configured when a local backend is enabled for this host.
        models = lib.mkIf localAI.enable {
          providers.${localProvider} = {
            baseUrl = "http://${localAI.host}:${toString localAI.port}/v1";
            api = "openai-completions";
            # Local servers ignore the key, but pi hides models whose provider
            # has no auth configured at all, so a dummy value is required.
            apiKey = localProvider;
            compat = {
              supportsDeveloperRole = false; # llama.cpp/ollama want a `system` role
              supportsReasoningEffort = false;
              maxTokensField = "max_tokens";
            };
            models = localModels;
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
