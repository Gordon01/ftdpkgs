{ inputs, ... }:
{
  flake.homeModules = {
    shell = { pkgs, ... }: {
      home.packages = [ pkgs.nix-output-monitor ];

      programs = {
        direnv = {
          enable = true;
          enableZshIntegration = true;
        };
        starship = {
          enable = true;
          enableZshIntegration = true;
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

    gui =
      { pkgs, ... }:
      {
        imports = [ inputs.nix-index-database.homeModules.nix-index ];

        programs = {
          ghostty = {
            enable = true;
            package = pkgs.ghostty-bin;
            enableZshIntegration = true;
          };
          nix-index-database.comma.enable = true;
        };
      };
  };
}
