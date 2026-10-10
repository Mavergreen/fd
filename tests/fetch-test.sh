#!/bin/sh
# platform: host-agnostic
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
F="$ROOT/build/fetch-fd.sh"
fail() { echo "FAIL: $1"; exit 1; }
T="$(mktemp -d "${TMPDIR:-/tmp}/fd-fetch-test.XXXXXX")"
trap 'rm -rf "$T"' EXIT INT TERM

mkdir -p "$T/crate/fd-find-9.9.9" "$T/dl/fd-find" "$T/idx/fd/-f"
printf '[package]\nname = "fd-find"\nversion = "9.9.9"\n' > "$T/crate/fd-find-9.9.9/Cargo.toml"
(cd "$T/crate" && tar czf "$T/dl/fd-find/fd-find-9.9.9.crate" fd-find-9.9.9)
good="$(shasum -a 256 < "$T/dl/fd-find/fd-find-9.9.9.crate" | cut -c1-64)"
bad="$(printf '%s' "$good" | tr 0-9a-f 1-9a-f0)"
index_with() {  # $1 = the cksum the index publishes for 9.9.9 ("" = the field is absent)
  {
    printf '{"name":"fd-find","vers":"9.9.8","deps":[],"cksum":"%s","features":{},"yanked":false}\n' "$bad"
    if [ -n "$1" ]; then
      printf '{"name":"fd-find","vers":"9.9.9","deps":[],"cksum":"%s","features":{},"yanked":false}\n' "$1"
    else
      printf '{"name":"fd-find","vers":"9.9.9","deps":[],"features":{},"yanked":false}\n'
    fi
  } > "$T/idx/fd/-f/fd-find"
}
fetch() {  # $1 = version; prints the source dir
  MAVERICKS_BUILD_ROOT="$T/build" FD_CRATES_INDEX="file://$T/idx" FD_CRATES_DL="file://$T/dl" \
    sh "$F" "$1"
}

index_with "$good"
src="$(fetch 9.9.9)" || fail "a crate matching the index's published checksum must fetch"
grep -q '^version = "9.9.9"' "$src/Cargo.toml" || fail "the fetched tree must be the requested version (got $src)"
echo stale > "$src/stale"
src="$(fetch 9.9.9)" || fail "a second fetch must succeed from the verified cache"
[ ! -e "$src/stale" ] || fail "every fetch must extract afresh, so a patched or built tree never leaks into the next"

index_with "$bad"
rm -rf "$T/build"
if out="$(fetch 9.9.9 2>&1)"; then fail "unverified_fails: a crate whose bytes differ from the published checksum must fail"; fi
printf '%s\n' "$out" | grep -q "$good" || fail "unverified_fails: the failure must name the SHA-256 it got (got: $out)"

index_with ""
if out="$(fetch 9.9.9 2>&1)"; then fail "a version listed with no checksum must fail, never verify against nothing"; fi
printf '%s\n' "$out" | grep -q 'no checksum' || fail "an absent checksum must say so (got: $out)"

index_with "$good"
if out="$(fetch 9.9.7 2>&1)"; then fail "a version the index does not list must fail"; fi
printf '%s\n' "$out" | grep -q 'not listed' || fail "an unlisted version must say so (got: $out)"

want="$(tr -d ' \t\n' < "$ROOT/UPSTREAM_VERSION")"
src="$(MAVERICKS_BUILD_ROOT="$T/real" sh "$F")" || fail "the pinned fd $want must fetch from crates.io"
grep -q "^version = \"$want\"" "$src/Cargo.toml" || fail "the fetched fd must be UPSTREAM_VERSION ($want)"
for f in Cargo.lock doc/fd.1 contrib/completion/_fd; do
  [ -f "$src/$f" ] || fail "the fd crate must carry $f: the build is --locked, and the pkg ships the man page and completions"
done
echo "PASS: fetch"
