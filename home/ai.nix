{ inputs, ... }:
{
  flake.homeModules.mlx-lm =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.mlx-lm;
      mlxLmHome = "${config.xdg.dataHome}/mlx-lm";
      mlxLmLogPath = "${mlxLmHome}/mlx-lm-server.log";
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
      options.services.mlx-lm = {
        enable = lib.mkEnableOption "MLX-LM server";

        host = lib.mkOption {
          type = lib.types.str;
          default = "127.0.0.1";
          description = "Address on which the MLX-LM server listens.";
        };

        port = lib.mkOption {
          type = lib.types.ints.between 1 65535;
          default = 8080;
          description = "Port on which the MLX-LM server listens.";
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = [
          pythonMlx
          mlxLmServer
        ];

        home.activation.createMlxLmLogDir =
          lib.hm.dag.entryBetween [ "setupLaunchAgents" ] [ "writeBoundary" ]
            ''
              run mkdir -p $VERBOSE_ARG -- ${lib.escapeShellArg mlxLmHome}
            '';

        home.shellAliases = {
          mlx-lm-start = "launchctl kickstart gui/$(id -u)/com.alex.mlx-lm-server";
          mlx-lm-stop = "launchctl kill SIGTERM gui/$(id -u)/com.alex.mlx-lm-server";
        };

        launchd.agents.mlx-lm-server = {
          enable = true;
          config = {
            Label = "com.alex.mlx-lm-server";
            ProgramArguments = [
              (lib.getExe mlxLmServer)
              "--host"
              cfg.host
              "--port"
              (toString cfg.port)
            ];
            RunAtLoad = false;
            KeepAlive = false;
            StandardOutPath = mlxLmLogPath;
            StandardErrorPath = mlxLmLogPath;
          };
        };
      };
    };

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

  flake.homeModules.open-webui =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.open-webui;
      webuiHome = "${config.xdg.dataHome}/open-webui";
      webuiLogDir = "${webuiHome}/logs";
      environmentVariables = {
        DATA_DIR = "${webuiHome}/data";
        STATIC_DIR = "${webuiHome}/static";
        HF_HOME = "${webuiHome}/hf_home";
        SENTENCE_TRANSFORMERS_HOME = "${webuiHome}/transformers_home";
      }
      // lib.optionalAttrs (cfg.openai.baseUrls != [ ]) {
        OPENAI_API_BASE_URLS = lib.concatStringsSep ";" cfg.openai.baseUrls;
      }
      // lib.optionalAttrs (cfg.webuiUrl != null) {
        WEBUI_URL = cfg.webuiUrl;
      }
      // cfg.environment;
    in
    {
      options.services.open-webui = {
        enable = lib.mkEnableOption "Open WebUI: Self-Hosted AI Platform";

        package = lib.mkPackageOption pkgs "open-webui" { };

        environment = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          example = {
            ENABLE_OLLAMA_API = "False";
          };
          description = ''
            Additional environment variables for the Open WebUI service.
            These override module-provided values.

            See <https://docs.openwebui.com/reference/env-configuration/>.
          '';
        };

        webuiUrl = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "https://chat.example.com";
          description = ''
            Specifies the URL where your Open WebUI installation is reachable.
            Needed for search engine support and OAuth/SSO.
          '';
        };

        host = lib.mkOption {
          type = lib.types.str;
          default = "127.0.0.1";
          description = "Address on which the Open WebUI server listens.";
        };

        port = lib.mkOption {
          type = lib.types.port;
          default = 3000;
          description = "Port on which the Open WebUI server listens.";
        };

        openai.baseUrls = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          example = [ "http://localhost:8080/v1" ];
          description = ''
            Base URLs of OpenAI-compatible API servers, including any required
            path prefix such as /v1.
          '';
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = [ cfg.package ];

        xdg.dataFile."open-webui/home/.keep".text = "";

        launchd.agents.open-webui = {
          enable = true;
          config = {
            ProgramArguments = [
              (lib.getExe cfg.package)
              "serve"
              "--host"
              cfg.host
              "--port"
              (toString cfg.port)
            ];
            EnvironmentVariables = environmentVariables;
            RunAtLoad = true;
            KeepAlive = true;
            WorkingDirectory = "${webuiHome}/home";
            StandardOutPath = "${webuiLogDir}/output.log";
            StandardErrorPath = "${webuiLogDir}/error.log";
          };
        };
      };
    };
}
