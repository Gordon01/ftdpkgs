{ lib, self, ... }:
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
    pkgs.runCommand "darwin-devtool-blockers" { } ''
      mkdir -p "$out/bin"
      for name in ${lib.escapeShellArgs commands}; do
        ln -s ${blocker} "$out/bin/$name"
      done
    '';

in
{
  flake.modules.darwin.devtool-blockers = { pkgs, ... }: {
    # Nix profiles have order 1000; nix-darwin's macOS paths have order 1200.
    environment.systemPath = lib.mkOrder 1100 [ "${mkBlockers pkgs}/bin" ];
  };

  perSystem = { pkgs, ... }: {
    checks = lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
      darwin-devtool-blockers =
        let
          blockers = mkBlockers pkgs;
          darwin = self.darwinConfigurations."Gordon01-MB".config;
          systemPaths = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
          profilePaths = lib.concatMapStringsSep ":" (profile: "${profile}/bin") darwin.environment.profiles;
        in
        assert darwin.environment.systemPath == "${profilePaths}:${blockers}/bin:${systemPaths}";
        pkgs.runCommand "check-darwin-devtool-blockers"
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
            export USER=devtool-test
            mkdir -p "$HOME" "$TMPDIR/real tools"
            for name in git gcc; do
              printf '#!${pkgs.runtimeShell}\nprintf "real-%s\\n"\n' "$name" > "$TMPDIR/real tools/$name"
              chmod +x "$TMPDIR/real tools/$name"
            done
            # Exercise generated global startup files without activating the system.
            cat > "$HOME/.zshenv" <<'EOF'
            unset __ETC_ZSHENV_SOURCED
            if [[ "$TEST_FRESH_ENVIRONMENT" == 1 ]]; then
              unset __NIX_DARWIN_SET_ENVIRONMENT_DONE
            fi
            source ${darwin.environment.etc."zshenv".source}
            EOF
            cat > "$HOME/.zprofile" <<'EOF'
            unset __ETC_ZPROFILE_SOURCED
            source ${darwin.environment.etc."zprofile".source}
            EOF
            export NIX_GIT_BIN=${pkgs.git}/bin
            export NIX_ZSH=${pkgs.zsh}/bin/zsh
            export TEST_FRESH_ENVIRONMENT=1
            for mode in c lc ic lic; do
              PATH=/usr/local/bin:/usr/bin:/bin "$NIX_ZSH" -d$mode 'source "$1"' -- \
                ${./tests/devtool-blockers.zsh} ${blockers}/bin ${pkgs.bash}/bin/bash
            done
            touch "$out"
          '';
    };
  };
}
