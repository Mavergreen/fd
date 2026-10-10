#!/bin/sh
# platform: macOS-only -- lipo reads the Mach-O, and the x86_64 fd runs only on a Mac
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/build/versions.sh"
fail() { echo "FAIL: $1"; exit 1; }
FD="$STAGE/bin/fd"
[ -x "$FD" ] || { echo "not built (no $FD) -- skipping"; exit 77; }

[ "$(lipo -info "$FD" | sed -n 's/.*: //p' | xargs)" = x86_64 ] \
  || fail "fd must be exactly x86_64: the 10.9 target has no other arch (got: $(lipo -info "$FD"))"
for f in share/man/man1/fd.1 share/zsh/site-functions/_fd share/bash-completion/completions/fd \
         share/fish/vendor_completions.d/fd.fish; do
  [ -s "$STAGE/$f" ] || fail "the stage must carry fd's $f, in the path its shell or man searches"
done
grep -q '^\.TH FD 1' "$STAGE/share/man/man1/fd.1" || fail "share/man/man1/fd.1 must be fd's man page"
grep -q 'complete -F _fd' "$STAGE/share/bash-completion/completions/fd" || fail "the bash completion must complete fd"
grep -q 'complete -c fd' "$STAGE/share/fish/vendor_completions.d/fd.fish" || fail "the fish completion must complete fd"
file "$FD" | grep -q 'Mach-O 64-bit executable x86_64' || fail "fd must be an x86_64 Mach-O executable (got: $(file "$FD"))"

# platform: an arm64 Mac runs this x86_64 fd only through Rosetta; oahd is its daemon
if [ "$(uname -m)" = arm64 ] && ! /usr/bin/pgrep -q oahd; then
  echo "x86_64 fd cannot run on this arm64 Mac without Rosetta -- skipping the run half"; exit 77
fi
[ "$("$FD" --version)" = "fd $FD_VERSION" ] || fail "fd --version must print the pinned version (got: $("$FD" --version))"

t="$(mktemp -d "${TMPDIR:-/tmp}/fd-build-test.XXXXXX")"; trap 'rm -rf "$t"' EXIT INT TERM
mkdir -p "$t/a/b"; : > "$t/a/one.txt"; : > "$t/a/b/two.txt"; : > "$t/a/b/three.md"
got="$(cd "$t" && "$FD" -t f -e txt . a | sort | tr '\n' ' ')"
[ "$got" = "a/b/two.txt a/one.txt " ] || fail "fd must find files by extension (got: '$got')"
echo "PASS: build"
