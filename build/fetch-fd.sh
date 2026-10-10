#!/bin/sh
# platform: host-agnostic
#   usage: fetch-fd.sh [version]     prints a fresh fd source tree (default: UPSTREAM_VERSION)
#          The fd-find crate from crates.io, verified against the SHA-256 crates.io's index
#          publishes for that version; fails closed when the index does not list it, lists it
#          without a checksum, or the bytes differ. FD_CRATES_INDEX and FD_CRATES_DL replace
#          https://index.crates.io and https://static.crates.io/crates (the tests serve file://).
set -eu
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/build/versions.sh"
. "$REPO_ROOT/build/msc.sh"
. "$SHIPYARD_SCRIPTS/mavericks_fetch.sh"
V="${1:-$FD_VERSION}"
INDEX="${FD_CRATES_INDEX:-https://index.crates.io}/fd/-f/fd-find"
CRATE="fd-find-$V.crate"
URL="${FD_CRATES_DL:-https://static.crates.io/crates}/fd-find/$CRATE"

idx="$(curl -fsSL "$INDEX")" || { echo "fetch-fd: cannot read the crates.io index at $INDEX" >&2; exit 1; }
line="$(printf '%s\n' "$idx" | grep "\"vers\":\"$V\"" || true)"
[ -n "$line" ] || { echo "fetch-fd: fd-find $V is not listed in $INDEX" >&2; exit 1; }
sha="$(printf '%s\n' "$line" | sed -n 's/.*"cksum":"\([0-9a-f]\{64\}\)".*/\1/p')"
[ -n "$sha" ] || { echo "fetch-fd: $INDEX lists fd-find $V with no checksum; refusing to verify against nothing" >&2; exit 1; }

SRC="$WORK/src"
# spec: shipyard scripts/mavericks_fetch.sh usage -- mav_fetch_pinned keeps an existing entry, so the
#       caller removes the old tree to extract afresh
rm -rf "$SRC/fd-find-$V"
mav_fetch_pinned "$URL" "$sha" "$SRC" "$CRATE" \
  || { echo "fetch-fd: $URL did not verify against crates.io's published sha256 $sha" >&2; exit 1; }
[ -f "$SRC/fd-find-$V/Cargo.toml" ] || { echo "fetch-fd: $CRATE holds no fd-find-$V/Cargo.toml" >&2; exit 1; }
echo "$SRC/fd-find-$V"
