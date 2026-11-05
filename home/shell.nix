# Define the shared interactive command-line environment; add shell behavior and
# everyday CLI integrations here, not desktop applications.
{ inputs, ... }:
{
  flake.modules.homeManager.shell = { pkgs, ... }: {
    imports = [ inputs.nix-index-database.homeModules.nix-index ];

    home.packages = with pkgs; [
      htop
      nix-output-monitor
    ];

    programs = {
      direnv.enable = true;
      starship.enable = true;
      zsh = {
        enable = true;
        enableCompletion = true;
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;
      };
      fzf = {
        enable = true;
        defaultOptions = [
          "--height 40%"
          "--border rounded"
        ];
      };
      nix-index-database.comma.enable = true;
    };
  };
}
