# Define the shared development environment; add developer tools and workflow
# preferences here, not host provisioning.
{ ... }:
{
  flake.homeModules.dev = { pkgs, ... }: {
    home.packages = with pkgs; [
      nixd
      nixfmt
    ];

    programs = {
      git.enable = true;
      git.settings.user = {
        name = "Alexander Sergeev";
        email = "etc9053@gmail.com";
      };
      tmux = {
        enable = true;
        mouse = true;
        newSession = true;
        secureSocket = true;
      };
    };
  };
}
