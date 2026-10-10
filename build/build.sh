#!/bin/sh
# platform: macOS-only -- links with Apple's linker against the pinned MacOSX10.9 SDK
#   usage: build.sh     builds fd for x86_64 10.9 with Mavergreen/rust and stages $STAGE/bin/fd
#          RUST_BIN names the toolchain's bin/ (default: rust-cross on an arm64 Mac, else rust,
#          both under /usr/local/mavergreen).
set -eu
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/build/versions.sh"
. "$REPO_ROOT/build/msc.sh"

if [ -z "${RUST_BIN:-}" ]; then
  case "$(uname -m)" in arm64) RUST_BIN=/usr/local/mavergreen/rust-cross/bin ;; *) RUST_BIN=/usr/local/mavergreen/rust/bin ;; esac
fi
[ -x "$RUST_BIN/cargo" ] && [ -x "$RUST_BIN/rustc" ] \
  || { echo "build: no Mavergreen Rust toolchain at $RUST_BIN -- install the rust (10.9) or rust-cross (modern Mac) pkg $RUST_PIN" >&2; exit 1; }

SRC="$(sh "$REPO_ROOT/build/fetch-fd.sh")"
SDKROOT="$(sh "$SHIPYARD_SCRIPTS/fetch_sdk.sh" --arch x86_64)"
export SDKROOT
CARGO_HOME="$WORK/cargo-home" CARGO_TARGET_DIR="$WORK/target" RUSTC="$RUST_BIN/rustc" \
  "$RUST_BIN/cargo" build --release --locked --target "$TARGET_TRIPLE" --manifest-path "$SRC/Cargo.toml" >&2
OUT="$WORK/target/$TARGET_TRIPLE/release/fd"
[ -x "$OUT" ] || { echo "build: cargo produced no $OUT" >&2; exit 1; }
sh "$REPO_ROOT/build/compat-gate.sh" "$OUT" >&2

rm -rf "$STAGE_ROOT"; mkdir -p "$STAGE/bin"
cp "$OUT" "$STAGE/bin/fd"
echo "$STAGE/bin/fd"
