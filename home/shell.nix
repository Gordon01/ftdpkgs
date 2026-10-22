# Define the shared interactive command-line environment; add shell behavior and
# everyday CLI integrations here, not desktop applications.
{ ... }:
{
  flake.homeModules = {
    shell = { pkgs, ... }: {
      home.packages = [ pkgs.nix-output-monitor ];

      programs = {
        direnv = {
          enable = true;
        };
        starship = {
          enable = true;
        };
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
      };
    };
  };
}
