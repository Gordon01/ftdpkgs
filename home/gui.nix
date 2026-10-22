# Define the user desktop profile; add graphical applications and desktop-facing
# integrations here, not system-wide macOS preferences.
{ inputs, ... }:
{
  flake.homeModules.gui =
    { pkgs, ... }:
    {
      imports = [ inputs.nix-index-database.homeModules.nix-index ];

      programs = {
        ghostty = {
          enable = true;
          package = pkgs.ghostty-bin;
        };
        nix-index-database.comma.enable = true;
      };
    };
}
