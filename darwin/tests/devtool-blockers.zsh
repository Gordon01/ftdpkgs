set -eu
setopt pipefail

fallback=$2
bash=$3
real_tools="$TMPDIR/real tools"

# nix-darwin initializes profiles first, then blockers, then its macOS paths.
[[ "$__NIX_DARWIN_SET_ENVIRONMENT_DONE" == 1 ]]
[[ "${(j.:.)path[-6,-1]}" == "$fallback:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin" ]]
(( ${path[(ie)$fallback]} > 1 ))
matches=("${(@M)path:#$fallback}")
(( ${#matches} == 1 ))

# A real Nix package takes precedence over its blocker.
path=("$NIX_GIT_BIN" "$fallback" /usr/bin /bin)
[[ "$(command -v git)" == "$NIX_GIT_BIN/git" ]]
[[ "$(git --version)" == 'git version '* ]]

# A development shell can prepend a real tool after startup as well.
path=("$fallback" /usr/bin /bin)
path=("$real_tools" "${path[@]}")
[[ "$(git)" == real-git ]]
[[ "$(gcc)" == real-gcc ]]
[[ "$(/bin/sh -c gcc)" == real-gcc ]]
[[ "$("$bash" --noprofile --norc -c gcc)" == real-gcc ]]

# Already-initialized child shells preserve development-shell precedence.
export TEST_FRESH_ENVIRONMENT=0
for mode in c lc ic lic; do
  [[ "$("$NIX_ZSH" -d$mode 'gcc')" == real-gcc ]]
done

path=("$fallback" /usr/bin /bin)
[[ "$(command -v gcc)" == "$fallback/gcc" ]]
result=0
gcc >"$TMPDIR/stdout" 2>"$TMPDIR/stderr" || result=$?
(( result == 127 ))
[[ ! -s "$TMPDIR/stdout" ]]
[[ "$(<"$TMPDIR/stderr")" == 'gcc: macOS developer-tool shim blocked;'* ]]
result=0
/bin/sh -c gcc >"$TMPDIR/stdout" 2>"$TMPDIR/stderr" || result=$?
(( result == 127 ))
result=0
"$bash" --noprofile --norc -c gcc >"$TMPDIR/stdout" 2>"$TMPDIR/stderr" || result=$?
(( result == 127 ))

result=0
xcode-select --install >"$TMPDIR/stdout" 2>"$TMPDIR/stderr" || result=$?
(( result == 127 ))
[[ "$(<"$TMPDIR/stderr")" == 'xcode-select: macOS developer-tool shim blocked;'* ]]
