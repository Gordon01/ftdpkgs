set -eu
setopt pipefail

fallback=$2
setup=$3
real_tools="$TMPDIR/real tools"

# Both startup hooks must leave exactly one blocker before the first /usr/bin.
(( ${path[(Ie)$fallback]} + 1 == ${path[(ie)/usr/bin]} ))
matches=("${(@M)path:#$fallback}")
(( ${#matches} == 1 ))

path=("$real_tools" /usr/local/bin /usr/bin /bin /usr/bin)
source "$setup"
expected=("$real_tools" /usr/local/bin "$fallback" /usr/bin /bin /usr/bin)
[[ "${(j.:.)path}" == "${(j.:.)expected}" ]]
source "$setup"
[[ "${(j.:.)path}" == "${(j.:.)expected}" ]]

[[ "$(git)" == real-git ]]
[[ "$(gcc)" == real-gcc ]]
[[ "$(/bin/sh -c gcc)" == real-gcc ]]

path=("$NIX_GIT_BIN" "$fallback" /usr/bin /bin)
[[ "$(command -v git)" == "$NIX_GIT_BIN/git" ]]
[[ "$(git --version)" == 'git version '* ]]

# A development shell can prepend a real tool after startup as well.
path=("$fallback" /usr/bin /bin)
path=("$real_tools" "${path[@]}")
[[ "$(git)" == real-git ]]
[[ "$(gcc)" == real-gcc ]]

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
xcode-select --install >"$TMPDIR/stdout" 2>"$TMPDIR/stderr" || result=$?
(( result == 127 ))
[[ "$(<"$TMPDIR/stderr")" == 'xcode-select: macOS developer-tool shim blocked;'* ]]

path=("$real_tools" /bin "$fallback" "$fallback")
source "$setup"
[[ "${(j.:.)path}" == "$real_tools:/bin" ]]

path=()
source "$setup"
(( ${#path} == 0 ))
