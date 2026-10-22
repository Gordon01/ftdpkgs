# Define shared macOS desktop behavior; add reusable system preferences here,
# keeping user-specific paths in host profiles.
{ ... }: {
  flake.modules.darwin.gui = { ... }: {
    system.defaults.finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = false;
      ShowPathbar = true;
      ShowStatusBar = true;
    };
  };
}
