#!/bin/sh
# platform: host-agnostic -- shipyard's cargo-env.sh on an x86_64 host, the pinned rust-cross on Apple Silicon
#   usage: build.sh     builds fd for x86_64 10.9 with the pinned Mavergreen/rust, gates it, and
#          stages bin/fd, its man page and its completions under $STAGE
set -eu
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/build/versions.sh"
. "$REPO_ROOT/build/msc.sh"
SRC="$(sh "$REPO_ROOT/build/fetch-fd.sh")"
case "$(sh "$REPO_ROOT/build/rust-toolchain.sh" "$(uname -s)" "$(uname -m)")" in
  cargo-env)
    if [ -z "${CARGO:-}" ] || [ "${CARGO_BUILD_TARGET:-}" != "$TARGET_TRIPLE" ]; then
      env="$(sh "$SHIPYARD_SCRIPTS/cargo-env.sh" --sh "$REPO_ROOT/components/rust")"
      eval "$env"
    fi ;;
  rust-cross)
    RUST="$(sh "$REPO_ROOT/build/fetch-rust.sh")"
    SDK="$(sh "$SHIPYARD_SCRIPTS/fetch_sdk.sh" --arch x86_64)"
    CARGO="$RUST/bin/cargo" RUSTC="$RUST/bin/rustc"
    export CARGO RUSTC
    # platform: with --target, cargo applies target.<triple>.rustflags to fd alone, never to build
    #           scripts or proc macros; SDKROOT would reach those too, which on Apple Silicon are arm64
    #           and cannot link against the 10.9 SDK
    unset SDKROOT
    CARGO_TARGET_X86_64_APPLE_DARWIN_RUSTFLAGS="-C link-arg=-isysroot -C link-arg=$SDK"
    export CARGO_TARGET_X86_64_APPLE_DARWIN_RUSTFLAGS ;;
esac
CARGO_HOME="$WORK/cargo-home" CARGO_TARGET_DIR="$WORK/target"
export CARGO_HOME CARGO_TARGET_DIR
"$CARGO" build --release --locked --target "$TARGET_TRIPLE" --manifest-path "$SRC/Cargo.toml" >&2
OUT="$CARGO_TARGET_DIR/$TARGET_TRIPLE/release/fd"
[ -x "$OUT" ] || { echo "build: cargo produced no $OUT" >&2; exit 1; }
sh "$REPO_ROOT/build/compat-gate.sh" "$OUT" >&2

# spec: shipyard SKILL.md "Rosetta" -- no build step runs translated or off macOS, so anywhere but an
#       x86_64 Mac a host fd built from the same source writes the completions
case "$(uname -s):$(uname -m)" in
  Darwin:x86_64) gen="$OUT" ;;
  *) host="$("$RUSTC" -vV | sed -n 's/^host: //p')"
     "$CARGO" build --release --locked --target "$host" --manifest-path "$SRC/Cargo.toml" >&2
     gen="$CARGO_TARGET_DIR/$host/release/fd" ;;
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
