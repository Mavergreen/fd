#!/bin/sh
# platform: macOS-only -- clang links the stand-in x86_64 fd, and build-test.sh reads it with lipo
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/build/msc.sh"
fail() { echo "FAIL: $1"; exit 1; }
t="$(mktemp -d "${TMPDIR:-/tmp}/fd-arm64-test.XXXXXX")"; trap 'rm -rf "$t"' EXIT INT TERM
S="$t/root/mavergreen-fd/stage/usr/local/mavergreen/fd"
mkdir -p "$S/bin" "$S/share/man/man1" "$S/share/zsh/site-functions" "$S/share/bash-completion/completions" \
  "$S/share/fish/vendor_completions.d" "$t/bin"
printf '#include <stdio.h>\nint main(void) { FILE *f = fopen("%s/ran", "w"); if (f) fclose(f); return 1; }\n' "$t" > "$t/fd.c"
/usr/bin/clang -arch x86_64 -isysroot "$(sh "$SHIPYARD_SCRIPTS/fetch_sdk.sh" --arch x86_64)" \
  -mmacosx-version-min=10.9 "$t/fd.c" -o "$S/bin/fd"
printf '.TH FD 1\n' > "$S/share/man/man1/fd.1"
printf '#compdef fd\n' > "$S/share/zsh/site-functions/_fd"
printf 'complete -F _fd fd\n' > "$S/share/bash-completion/completions/fd"
printf 'complete -c fd\n' > "$S/share/fish/vendor_completions.d/fd.fish"
host() { printf '#!/bin/sh\necho %s\n' "$1" > "$t/bin/uname"; chmod +x "$t/bin/uname"
  PATH="$t/bin:$PATH" MAVERICKS_BUILD_ROOT="$t/root" sh "$ROOT/tests/build-test.sh" > "$t/out" 2>&1; }

rc=0; host arm64 || rc=$?
[ ! -e "$t/ran" ] || fail "on arm64 build-test must not execute the x86_64 fd: that would be Rosetta, and vm-test runs it on 10.9"
[ "$rc" = 0 ] || fail "on arm64 build-test must pass on the checks it can make (exit $rc: $(cat "$t/out"))"
grep -q 'vm-test' "$t/out" || fail "on arm64 build-test must say where the x86_64 fd runs instead (got: $(cat "$t/out"))"

rc=0; host x86_64 || rc=$?
[ -e "$t/ran" ] || fail "on x86_64 build-test must execute the shipped fd"
[ "$rc" != 0 ] || fail "on x86_64 build-test must fail an fd that prints no version"
echo "PASS: build-test-arm64"
