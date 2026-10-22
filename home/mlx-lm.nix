# Provide the reusable MLX inference service; add service options and lifecycle
# support here, keeping client settings and enablement in profiles.
{ ... }:
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
}
