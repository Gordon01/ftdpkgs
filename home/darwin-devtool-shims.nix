{ lib, ... }:
let
  # macOS shim hard-link groups for gcc and xcodebuild, plus their dispatchers.
  commands = [
    "DeRez"
    "GetFileInfo"
    "ResMerger"
    "Rez"
    "SetFile"
    "SplitForks"
    "actool"
    "agvtool"
    "ar"
    "as"
    "asa"
    "bison"
    "bm4"
    "c++"
    "c++filt"
    "c89"
    "c99"
    "cc"
    "clang"
    "clang++"
    "clangd"
    "cmpdylib"
    "codesign_allocate"
    "cpp"
    "ctags"
    "ctf_insert"
    "desdp"
    "dsymutil"
    "dwarfdump"
    "dyld_info"
    "flex"
    "flex++"
    "g++"
    "gatherheaderdoc"
    "gcc"
    "gcov"
    "genstrings"
    "git"
    "git-receive-pack"
    "git-shell"
    "git-upload-archive"
    "git-upload-pack"
    "gm4"
    "gnumake"
    "gperf"
    "hdxml2manxml"
    "headerdoc2html"
    "ibtool"
    "ictool"
    "indent"
    "install_name_tool"
    "ld"
    "lex"
    "libtool"
    "lipo"
    "lldb"
    "llvm-g++"
    "llvm-gcc"
    "lorder"
    "m4"
    "make"
    "mig"
    "nm"
    "nmedit"
    "objdump"
    "opendiff"
    "otool"
    "pagestuff"
    "pip3"
    "python3"
    "ranlib"
    "resolveLinks"
    "rpcgen"
    "sdef"
    "sdp"
    "segedit"
    "size"
    "sourcekit-lsp"
    "stapler"
    "strings"
    "strip"
    "swift"
    "swiftc"
    "unifdef"
    "unifdefall"
    "vtool"
    "xcdebug"
    "xcode-select"
    "xcodebuild"
    "xcrun"
    "xcscontrol"
    "xcsdiagnose"
    "xctrace"
    "xed"
    "xml2man"
    "yacc"
  ];

  mkBlockers =
    pkgs:
    let
      blocker = pkgs.writeShellScript "blocked-apple-devtool" ''
        printf '%s: macOS developer-tool shim blocked; use a Nix package or nix develop/nix shell instead.\n' "''${0##*/}" >&2
        exit 127
      '';
    in
    pkgs.runCommand "darwin-devtool-shims" { } ''
      mkdir -p "$out/bin"
      for name in ${lib.escapeShellArgs commands}; do
        ln -s ${blocker} "$out/bin/$name"
      done
    '';

  pathSetup = blockers: ''
    () {
      local fallback=${lib.escapeShellArg "${blockers}/bin"}
      local entry
      local -a next_path
      local inserted=0
      for entry in "''${path[@]}"; do
        [[ "$entry" == "$fallback" ]] && continue
        if [[ "$entry" == /usr/bin && $inserted == 0 ]]; then
          next_path+=("$fallback")
          inserted=1
        fi
        next_path+=("$entry")
      done
      export PATH
      path=("''${next_path[@]}")
    }
  '';
in
{
  flake.homeModules.darwin-devtool-shims = { pkgs, ... }: {
    config = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      programs.zsh.envExtra = lib.mkAfter (pathSetup (mkBlockers pkgs));
      programs.zsh.profileExtra = lib.mkAfter (pathSetup (mkBlockers pkgs));
    };
  };

  perSystem = { pkgs, ... }: {
    checks = lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
      darwin-devtool-shims =
        let
          blockers = mkBlockers pkgs;
          setup = pkgs.writeText "devtool-path.zsh" (pathSetup blockers);
        in
        pkgs.runCommand "check-darwin-devtool-shims"
          {
            nativeBuildInputs = [ pkgs.zsh ];
          }
          ''
            test ${toString (builtins.length commands)} -eq 96
            test "$(find ${blockers}/bin -type l | wc -l | tr -d ' ')" -eq 96
            for name in ${lib.escapeShellArgs commands}; do
              test -x "${blockers}/bin/$name"
              status=0
              "${blockers}/bin/$name" --version >stdout 2>stderr || status=$?
              test "$status" -eq 127
              test ! -s stdout
              grep -qF "$name: macOS developer-tool shim blocked;" stderr
            done

            export HOME="$TMPDIR/home"
            export ZDOTDIR="$HOME"
            mkdir -p "$HOME" "$TMPDIR/real tools"
            for name in git gcc; do
              printf '#!${pkgs.runtimeShell}\nprintf "real-%s\\n"\n' "$name" > "$TMPDIR/real tools/$name"
              chmod +x "$TMPDIR/real tools/$name"
            done
            printf 'source %s\n' ${setup} > "$HOME/.zshenv"
            # Model login startup reordering the path after .zshenv.
            printf 'path=(/usr/bin "''${path[@]}")\nsource %s\n' ${setup} > "$HOME/.zprofile"
            export NIX_GIT_BIN=${pkgs.git}/bin
            for mode in c lc ic lic; do
              PATH=/usr/local/bin:/usr/bin:/bin ${pkgs.zsh}/bin/zsh -d$mode 'source "$1"' -- \
                ${./tests/darwin-devtool-shims.zsh} ${blockers}/bin ${setup}
            done
            touch "$out"
          '';
    };
  };
}
