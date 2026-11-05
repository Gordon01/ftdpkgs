# Define the baseline shared by all NixOS hosts; add common Nix and system
# settings here, keeping host-specific choices in host profiles.
{
  flake.modules.nixos.base = {
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    time.timeZone = "Europe/Moscow";
    programs.nix-ld.enable = true;
  };
}
