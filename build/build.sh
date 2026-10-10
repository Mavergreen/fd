#!/bin/sh
# platform: macOS-only -- links with Apple's linker against the pinned MacOSX10.9 SDK
#   usage: build.sh     builds fd for x86_64 10.9 with the pinned Mavergreen/rust, gates it, and
#          stages bin/fd, its man page and its completions under $STAGE
set -eu
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/build/versions.sh"
. "$REPO_ROOT/build/msc.sh"
RUST="$(sh "$REPO_ROOT/build/fetch-rust.sh")"
SRC="$(sh "$REPO_ROOT/build/fetch-fd.sh")"
SDK="$(sh "$SHIPYARD_SCRIPTS/fetch_sdk.sh" --arch x86_64)"

CARGO_HOME="$WORK/cargo-home" CARGO_TARGET_DIR="$WORK/target" RUSTC="$RUST/bin/rustc"
export CARGO_HOME CARGO_TARGET_DIR RUSTC
# platform: with --target, cargo applies target.<triple>.rustflags to fd alone, never to build
#           scripts or proc macros; SDKROOT would reach those too, which on Apple Silicon are arm64
#           and cannot link against the 10.9 SDK
unset SDKROOT
CARGO_TARGET_X86_64_APPLE_DARWIN_RUSTFLAGS="-C link-arg=-isysroot -C link-arg=$SDK"
export CARGO_TARGET_X86_64_APPLE_DARWIN_RUSTFLAGS
"$RUST/bin/cargo" build --release --locked --target "$TARGET_TRIPLE" --manifest-path "$SRC/Cargo.toml" >&2
OUT="$CARGO_TARGET_DIR/$TARGET_TRIPLE/release/fd"
[ -x "$OUT" ] || { echo "build: cargo produced no $OUT" >&2; exit 1; }
sh "$REPO_ROOT/build/compat-gate.sh" "$OUT" >&2

# spec: shipyard SKILL.md "Rosetta" -- no build step runs translated, so off x86_64 a host-arch fd
#       built from the same source writes the completions
case "$(uname -m)" in
  x86_64) gen="$OUT" ;;
  *) "$RUST/bin/cargo" build --release --locked --manifest-path "$SRC/Cargo.toml" >&2
     gen="$CARGO_TARGET_DIR/release/fd" ;;
esac

rm -rf "$STAGE_ROOT"
mkdir -p "$STAGE/bin" "$STAGE/share/man/man1" "$STAGE/share/zsh/site-functions" \
  "$STAGE/share/bash-completion/completions" "$STAGE/share/fish/vendor_completions.d"
cp "$OUT" "$STAGE/bin/fd"
cp "$SRC/doc/fd.1" "$STAGE/share/man/man1/fd.1"
cp "$SRC/contrib/completion/_fd" "$STAGE/share/zsh/site-functions/_fd"
"$gen" --gen-completions bash > "$STAGE/share/bash-completion/completions/fd"
"$gen" --gen-completions fish > "$STAGE/share/fish/vendor_completions.d/fd.fish"
echo "$STAGE/bin/fd"
