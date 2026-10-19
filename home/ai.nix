{ ... }:
{
  flake.homeModules.ai =
    {
      config,
      pkgs,
      ...
    }:
    let
      openWebui = pkgs.writeShellApplication {
        name = "open-webui";
        runtimeInputs = [ pkgs.open-webui ];
        runtimeEnv = {
          HOME = "${config.home.homeDirectory}/.local/share/open-webui";
          DATA_DIR = "${config.home.homeDirectory}/.local/share/open-webui/data";
          STATIC_DIR = "${config.home.homeDirectory}/.local/share/open-webui/static";
          HF_HOME = "${config.home.homeDirectory}/.local/share/open-webui/hf_home";
          SENTENCE_TRANSFORMERS_HOME = "${config.home.homeDirectory}/.local/share/open-webui/transformers_home";
          WEBUI_URL = "http://localhost:3000";
        };
        text = ''
          mkdir -p "$DATA_DIR" "$STATIC_DIR"
          cd "$HOME"
          exec ${pkgs.open-webui}/bin/open-webui "$@"
        '';
      };
      pythonMlx = pkgs.writeShellApplication {
        name = "python-mlx";
        runtimeInputs = [
          pkgs.uv
          pkgs.zsh
        ];
        text = ''
          uv_args=(run --no-project --with mlx-lm --python 3.14 --managed-python)

          if (( $# > 0 )); then
            exec uv "''${uv_args[@]}" "$@"
          fi

          exec uv "''${uv_args[@]}" zsh -i
        '';
      };
      mlxLmServer = pkgs.writeShellApplication {
        name = "mlx-lm-server";
        runtimeInputs = [ pythonMlx ];
        text = ''
          exec python-mlx -m mlx_lm server "$@"
        '';
      };
    in
    {
      home.packages = [
        openWebui
        pythonMlx
        mlxLmServer
      ];

      home.shellAliases = {
        open-webui-server = "open-webui serve --host 127.0.0.1 --port 3000";
        open-webui-start = "launchctl kickstart gui/$(id -u)/com.alex.open-webui";
        open-webui-stop = "launchctl kill SIGTERM gui/$(id -u)/com.alex.open-webui";
        mlx-lm-start = "launchctl kickstart gui/$(id -u)/com.alex.mlx-lm-server";
        mlx-lm-stop = "launchctl kill SIGTERM gui/$(id -u)/com.alex.mlx-lm-server";
      };

      launchd.agents.open-webui = {
        enable = true;
        config = {
          Label = "com.alex.open-webui";
          ProgramArguments = [
            "${openWebui}/bin/open-webui"
            "serve"
            "--host"
            "127.0.0.1"
            "--port"
            "3000"
          ];
          RunAtLoad = true;
          KeepAlive = false;
          StandardOutPath = "${config.home.homeDirectory}/Library/Logs/open-webui.log";
          StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/open-webui.log";
        };
      };

      launchd.agents.mlx-lm-server = {
        enable = true;
        config = {
          Label = "com.alex.mlx-lm-server";
          ProgramArguments = [
            "${mlxLmServer}/bin/mlx-lm-server"
          ];
          RunAtLoad = false;
          KeepAlive = false;
          StandardOutPath = "${config.home.homeDirectory}/Library/Logs/mlx-lm-server.log";
          StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/mlx-lm-server.log";
        };
      };

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
