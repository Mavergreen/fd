#!/bin/sh
# platform: macOS-only -- pkgutil expands the toolchain pkg
#   usage: fetch-rust.sh     prints the prefix of the pinned Mavergreen/rust toolchain for this host
#          The pkg named by components/rust/version, verified against its release's SHA256SUMS and
#          extracted under $WORK, never installed: no root, and exactly the pinned toolchain.
set -eu
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/build/versions.sh"
. "$REPO_ROOT/build/msc.sh"
. "$SHIPYARD_SCRIPTS/mavericks_fetch.sh"
short="$(sh "$REPO_ROOT/build/rust-toolchain.sh" "$(sh "$SHIPYARD_SCRIPTS/mavericks_mode.sh")" "$(uname -m)")"
base="https://github.com/Mavergreen/rust/releases/download/$RUST_PIN"
pkg="$short-$RUST_PIN.pkg"
dir="$WORK/toolchain/$short-$RUST_PIN"
tc="$dir/root/usr/local/mavergreen/$short"
if [ -f "$dir/extracted" ] && [ -x "$tc/bin/cargo" ]; then echo "$tc"; exit 0; fi

sums="$(shipyard_curl "$base/SHA256SUMS" -)" || { echo "fetch-rust: cannot read $base/SHA256SUMS" >&2; exit 1; }
sha="$(printf '%s\n' "$sums" | awk -v f="$pkg" '$2 == f || $2 == "*" f { print $1 }')"
case "$sha" in
  "") echo "fetch-rust: $pkg is not listed in $base/SHA256SUMS; refusing an unverified toolchain" >&2; exit 1 ;;
  *[!0-9a-f]*) echo "fetch-rust: $pkg is listed more than once in $base/SHA256SUMS" >&2; exit 1 ;;
esac
shipyard_fetch_verified "$base/$pkg" "$sha" "$dir" "$pkg" || { echo "fetch-rust: $pkg did not verify" >&2; exit 1; }

rm -rf "$dir/expanded" "$dir/root" "$dir/extracted"
pkgutil --expand "$dir/$pkg" "$dir/expanded"
payload="$dir/expanded/$short-component.pkg/Payload"
[ -f "$payload" ] || { echo "fetch-rust: $pkg has no $short-component.pkg payload" >&2; exit 1; }
mkdir -p "$dir/root"
tar -xf "$payload" -C "$dir/root"
rm -rf "$dir/expanded"
[ -x "$tc/bin/cargo" ] && [ -x "$tc/bin/rustc" ] || { echo "fetch-rust: $pkg holds no cargo and rustc under usr/local/mavergreen/$short" >&2; exit 1; }
: > "$dir/extracted"
echo "$tc"
