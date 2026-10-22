# Define the user's AI client workflow; add clients and provider connections here,
# keeping service implementations in their own modules.
{ inputs, ... }:
{
  flake.homeModules.ai =
    { pkgs, ... }:
    {
      home.packages = [ inputs.llm-agents.packages.${pkgs.system}.opencode2 ];

      programs.opencode = {
        enable = true;
        settings = {
          model = "github-copilot/claude-opus-4.8";
          provider.mlx = {
            npm = "@ai-sdk/openai-compatible";
            name = "MacBook";
            options.baseURL = "http://127.0.0.1:8080/v1";
            models = {
              "mlx-community/Qwen3-Coder-Next-4bit".name = "Qwen3-Coder-Next";
              "mlx-community/Qwen3.5-REAP-97B-A10B-4bit".name = "Qwen3.5-REAP-97B";
              "mlx-community/Laguna-S-2.1-OptiQ-2bit".name = "Laguna-S-2.1-OptiQ";
            };
          };
        };
      };
    };
}
