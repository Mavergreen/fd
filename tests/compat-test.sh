#!/bin/sh
# platform: macOS-only -- otool and nm read Mach-O, and clang links the fixtures
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/build/versions.sh"
. "$ROOT/build/msc.sh"
G="$ROOT/build/compat-gate.sh"
fail() { echo "FAIL: $1"; exit 1; }
t="$(mktemp -d "${TMPDIR:-/tmp}/fd-compat-test.XXXXXX")"; trap 'rm -rf "$t"' EXIT INT TERM
SDK="$(sh "$SHIPYARD_SCRIPTS/fetch_sdk.sh" --arch x86_64)"

fixture() {  # $1 = a symbol 10.9 lacks; links a binary that imports it
  printf 'extern void %s(void);\nint main(void) { %s(); return 0; }\n' "$1" "$1" > "$t/$1.c"
  /usr/bin/clang -arch x86_64 -isysroot "$SDK" -mmacosx-version-min=10.9 -Wl,-U,"_$1" \
    "$t/$1.c" -o "$t/$1"
}
for s in os_unfair_lock_lock clock_gettime CCRandomGenerateBytes 'fstatat$INODE64'; do
  fixture "$s"
  if sh "$G" "$t/$s" >"$t/out" 2>&1; then
    fail "rejects_post_10_9_symbol: a binary importing _$s must fail the gate (it is what fd's std reaches for when the 10.9 shim is missing)"
  fi
  grep -qF "_$s" "$t/out" || fail "rejects_post_10_9_symbol: the gate must reject _$s by name (got: $(cat "$t/out"))"
done

FD="$STAGE/bin/fd"
[ -x "$FD" ] || { echo "not built (no $FD) -- skipping the shipped-binary half"; exit 77; }
minos="$(otool -l "$FD" | awk '/LC_VERSION_MIN_MACOSX/{f=1} f && $1=="version"{print $2; exit} /LC_BUILD_VERSION/{b=1} b && $1=="minos"{print $2; exit}')"
[ "$minos" = 10.9 ] || fail "floor_is_10_9: the linked fd must record minos 10.9, not the 10.12 rustc stamps on its objects (got '$minos')"
sh "$G" "$FD" || fail "the shipped fd must pass the compat gate"
echo "PASS: compat"
