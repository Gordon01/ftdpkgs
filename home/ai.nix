{ inputs, ... }:
{
  flake.homeModules.ai =
    {
      config,
      pkgs,
      ...
    }:
    let
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
        pythonMlx
        mlxLmServer
        inputs.llm-agents.packages.${pkgs.system}.opencode2
      ];

      home.shellAliases = {
        mlx-lm-start = "launchctl kickstart gui/$(id -u)/com.alex.mlx-lm-server";
        mlx-lm-stop = "launchctl kill SIGTERM gui/$(id -u)/com.alex.mlx-lm-server";
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

  flake.homeModules.open-webui =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.open-webui;
      webuiHome = "${config.home.homeDirectory}/.local/share/open-webui";
      openWebui = pkgs.writeShellApplication {
        name = "open-webui";
        runtimeInputs = [ pkgs.open-webui ];
        runtimeEnv = {
          HOME = webuiHome;
          DATA_DIR = "${webuiHome}/data";
          STATIC_DIR = "${webuiHome}/static";
          HF_HOME = "${webuiHome}/hf_home";
          SENTENCE_TRANSFORMERS_HOME = "${webuiHome}/transformers_home";
          WEBUI_URL = "http://localhost:${toString cfg.port}";
        };
        text = ''
          mkdir -p "$DATA_DIR" "$STATIC_DIR"
          cd "$HOME"
          exec open-webui "$@"
        '';
      };
    in
    {
      options.services.open-webui = {
        enable = lib.mkEnableOption "Open WebUI";

        host = lib.mkOption {
          type = lib.types.str;
          default = "127.0.0.1";
          description = "Address on which the Open WebUI server listens.";
        };

        port = lib.mkOption {
          type = lib.types.ints.between 1 65535;
          default = 3000;
          description = "Port on which the Open WebUI server listens.";
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = [ openWebui ];

        home.shellAliases = {
          open-webui-start = "launchctl kickstart gui/$(id -u)/${config.launchd.agents.open-webui.config.Label}";
          open-webui-stop = "launchctl kill SIGTERM gui/$(id -u)/${config.launchd.agents.open-webui.config.Label}";
        };

        launchd.agents.open-webui = {
          enable = true;
          config = {
            ProgramArguments = [
              "${openWebui}/bin/open-webui"
              "serve"
              "--host"
              cfg.host
              "--port"
              (toString cfg.port)
            ];
            RunAtLoad = true;
            KeepAlive = false;
            StandardOutPath = "${config.home.homeDirectory}/Library/Logs/open-webui.log";
            StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/open-webui.log";
          };
        };
      };
    };
}
