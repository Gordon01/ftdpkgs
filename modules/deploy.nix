# Provide one entry point for applying configurations; add deployment targets
# here, keeping machine definitions in their host profiles.
{ lib, self, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      darwin = self.darwinConfigurations."Gordon01-MB";

      # NixOS hosts build on themselves; the SSH aliases supply the login user.
      nixosTargets = lib.mapAttrs (name: host: ''
        nixos-rebuild switch --flake ".#${name}" \
          --target-host ${host.config.networking.hostName} \
          --build-host ${host.config.networking.hostName} \
          --elevate sudo
      '') self.nixosConfigurations;

      targets = nixosTargets // {
        mac = ''
          sudo ${darwin.config.system.build.darwin-rebuild}/bin/darwin-rebuild switch --flake ".#Gordon01-MB"
        '';
      };
    in
    {
      apps.deploy = {
        type = "app";
        meta.description = "Apply configurations: deploy [${lib.concatStringsSep "|" (lib.attrNames targets)}]...";
        program = lib.getExe (
          pkgs.writeShellApplication {
            name = "deploy";
            runtimeInputs = [ pkgs.nixos-rebuild ];
            text = ''
              if [ "$#" -eq 0 ]; then
                set -- ${lib.concatStringsSep " " (lib.attrNames targets)}
              fi
              for target in "$@"; do
                echo "==> $target"
                case "$target" in
                ${lib.concatStrings (
                  lib.mapAttrsToList (name: cmd: ''
                    ${name})
                      ${cmd}
                      ;;
                  '') targets
                )}
                  *)
                    echo "unknown target: $target (expected: ${lib.concatStringsSep ", " (lib.attrNames targets)})" >&2
                    exit 1
                    ;;
                esac
              done
            '';
          }
        );
      };
    };
}
