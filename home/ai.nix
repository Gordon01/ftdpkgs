# Define the user's AI client workflow; add clients and provider connections here,
# keeping service implementations in their own modules.
{ self, ... }:
{
  flake.modules.homeManager.ai =
    { config, ... }:
    let
      mlx = config.services.mlx-lm;
      mlxUrl = "http://${mlx.host}:${toString mlx.port}/v1";
    in
    {
      imports = [
        self.modules.homeManager.mlx-lm
        self.modules.homeManager.open-webui
      ];

      services.open-webui.openai.baseUrls = [ mlxUrl ];

      programs.opencode = {
        enable = true;
        context = ./agent-instructions.md;
        settings = {
          model = "github-copilot/claude-opus-4.8";
          provider.mlx = {
            npm = "@ai-sdk/openai-compatible";
            name = "MacBook";
            options.baseURL = mlxUrl;
            models = {
              "mlx-community/Qwen3-Coder-Next-4bit".name = "Qwen3-Coder-Next";
              "mlx-community/Qwen3.5-REAP-97B-A10B-4bit".name = "Qwen3.5-REAP-97B";
              "mlx-community/Laguna-S-2.1-OptiQ-2bit".name = "Laguna-S-2.1-OptiQ";
            };
          };
        };
      };

      home.file.".copilot/copilot-instructions.md".source = ./agent-instructions.md;
    };
}
