# Provide one entry point for applying configurations; add deployment targets
# here, keeping machine definitions in their host profiles.
{ lib, self, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      darwin = self.darwinConfigurations."Gordon01-MB".config;

      # NixOS hosts build on themselves; the SSH aliases supply the login user.
      targets =
        lib.mapAttrs (
          name: host:
          let
            h = host.config.networking.hostName;
          in
          ''nixos-rebuild switch --flake ".#${name}" --target-host ${h} --build-host ${h} --elevate sudo''
        ) self.nixosConfigurations
        // {
          mac = ''sudo ${darwin.system.build.darwin-rebuild}/bin/darwin-rebuild switch --flake ".#Gordon01-MB"'';
        };
      names = lib.attrNames targets;
    in
    {
      apps.deploy = {
        type = "app";
        meta.description = "Apply configurations: deploy [${lib.concatStringsSep "|" names}]...";
        program = lib.getExe (
          pkgs.writeShellApplication {
            name = "deploy";
            runtimeInputs = [ pkgs.nixos-rebuild ];
            text = ''
              [ "$#" -gt 0 ] || set -- ${toString names}
              for target; do
                echo "==> $target"
                case "$target" in
                ${lib.concatMapAttrsStringSep "\n  " (name: cmd: "${name}) ${cmd} ;;") targets}
                *) echo "unknown target: $target (expected: ${lib.concatStringsSep ", " names})" >&2; exit 1 ;;
                esac
              done
            '';
          }
        );
      };
    };
}
