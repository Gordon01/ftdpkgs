# Define the user desktop profile; add graphical applications and desktop-facing
# integrations here, not system-wide macOS preferences.
{ ... }:
{
  flake.homeModules.gui =
    { pkgs, ... }:
    {
      programs = {
        ghostty = {
          enable = true;
          package = pkgs.ghostty-bin;
        };
      };
    };
}
