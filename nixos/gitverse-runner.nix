{ inputs, ... }:
{
  flake.nixosModules.gitverse-runner =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.gitverse-runner;
      registrationDirectory = builtins.dirOf cfg.settings.tokenFile;
      settingsFormat = pkgs.formats.yaml { };
      runnerPackage = pkgs.stdenvNoCC.mkDerivation {
        pname = "gitverse-runner";
        version = "6.0.2";

        src = inputs.gitverse-runner;

        dontUnpack = true;
        dontStrip = true;
        installPhase = ''
          runHook preInstall
          install -Dm755 "$src" "$out/bin/act_runner"
          runHook postInstall
        '';

        meta = {
          description = "Official GitVerse self-hosted Actions runner";
          homepage = "https://gitverse.ru/docs/cicd/docs/runners/self-hosted";
          mainProgram = "act_runner";
          platforms = [ "x86_64-linux" ];
          sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
        };
      };
    in
    {
      options.services.gitverse-runner = {
        enable = lib.mkEnableOption "the sandboxed GitVerse runner";
        settings = lib.mkOption {
          default = { };
          description = ''
            GitVerse runner configuration and registration settings.
            Registration requires a runtime tokenFile.
            Other settings are passed to the runner's native YAML configuration.
          '';
          type = lib.types.submodule {
            freeformType = settingsFormat.type;
            options = {
              tokenFile = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "Absolute host path to an environment file containing TOKEN.";
              };
              name = lib.mkOption {
                type = lib.types.str;
                default = "cloud-nixos";
                description = "Runner registration name.";
              };
              url = lib.mkOption {
                type = lib.types.str;
                default = "https://gitverse.ru";
                description = "GitVerse instance URL.";
              };
              labels = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [
                  "cloud-nixos:host"
                  "self-hosted:host"
                  "linux:host"
                  "x64:host"
                ];
                description = "Native host-execution registration labels.";
              };
            };
          };
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = cfg.settings.tokenFile != null;
            message = "services.gitverse-runner.settings.tokenFile is required.";
          }
          {
            assertion = !(cfg.settings ? token);
            message = "services.gitverse-runner.settings.token is not supported; use tokenFile.";
          }
          {
            assertion = cfg.settings.tokenFile == null || lib.hasPrefix "/" cfg.settings.tokenFile;
            message = "services.gitverse-runner.settings.tokenFile must be an absolute host path.";
          }
          {
            assertion = cfg.settings.tokenFile == null || registrationDirectory != "/";
            message = "services.gitverse-runner.settings.tokenFile must be in a dedicated directory, not the host root.";
          }
          {
            assertion = cfg.settings.labels != [ ] && lib.all (lib.hasSuffix ":host") cfg.settings.labels;
            message = "services.gitverse-runner.settings.labels must contain only explicit :host labels.";
          }
        ];

        networking.nat = {
          enable = true;
          internalInterfaces = [ "ve-gitverse" ];
        };

        systemd.tmpfiles.rules = lib.optionals (cfg.settings.tokenFile != null) [
          "d ${registrationDirectory} 0700 root root -"
        ];
        systemd.services."container@gitverse".unitConfig.RequiresMountsFor =
          lib.optionals (cfg.settings.tokenFile != null)
            [
              registrationDirectory
            ];

        containers.gitverse = {
          autoStart = true;
          privateNetwork = true;
          privateUsers = "pick";
          hostAddress = "192.168.100.1";
          localAddress = "192.168.100.2";

          # Map host root-owned credentials to container root's private UID.
          extraFlags = lib.optionals (cfg.settings.tokenFile != null) [
            "--bind-ro=${registrationDirectory}:/run/gitverse-registration:idmap"
          ];

          config =
            { ... }:
            {
              system.stateVersion = config.system.stateVersion;
              networking = {
                useHostResolvConf = lib.mkForce false;
                nameservers = [
                  "1.1.1.1"
                  "9.9.9.9"
                ];
              };

              nix.settings.experimental-features = [
                "nix-command"
                "flakes"
              ];
              security.sudo.enable = false;

              services.gitea-actions-runner = {
                package = runnerPackage;
                instances.gitverse = {
                  enable = true;
                  inherit (cfg.settings)
                    name
                    url
                    labels
                    ;
                  tokenFile =
                    if cfg.settings.tokenFile == null then
                      null
                    else
                      "/run/gitverse-registration/${builtins.baseNameOf cfg.settings.tokenFile}";
                  settings =
                    lib.recursiveUpdate
                      {
                        runner = {
                          capacity = 1;
                          envs.NIX_REMOTE = "daemon";
                        };
                      }
                      (
                        builtins.removeAttrs cfg.settings [
                          "name"
                          "url"
                          "labels"
                          "tokenFile"
                        ]
                      );
                };
              };

              systemd.services.gitea-runner-gitverse = {
                path = [
                  pkgs.nix
                  pkgs.findutils
                  pkgs.gnutar
                  pkgs.gzip
                ];
                serviceConfig = {
                  NoNewPrivileges = true;
                  PrivateTmp = true;
                  ProtectHome = true;
                  ProtectSystem = "strict";
                  ProtectKernelTunables = true;
                  ProtectKernelModules = true;
                  ProtectControlGroups = true;
                  RestrictSUIDSGID = true;
                  CapabilityBoundingSet = "";
                };
              };
            };
        };
      };
    };
}
