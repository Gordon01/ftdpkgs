# Define the user desktop profile; add graphical applications and desktop-facing
# integrations here, not system-wide macOS preferences.
{
  flake.modules.homeManager.gui = { pkgs, ... }: {
    programs.ghostty = {
      enable = true;
      package = pkgs.ghostty-bin;
    };
  };
}
