#!/bin/sh
# platform: host-agnostic
#   usage: rust-toolchain.sh <os> <arch>     prints how fd's cargo environment is made here
#          <os> and <arch> are `uname -s` and `uname -m`. cargo-env: shipyard's cargo-env.sh with the
#          pinned rust, on any x86_64 host; rust-cross: the pinned rust-cross pkg, on Apple Silicon
set -eu
case "${1:-}:${2:-}" in
  Linux:x86_64|Darwin:x86_64) echo cargo-env ;;
  Darwin:arm64) echo rust-cross ;;
  *) echo "rust-toolchain: no Mavergreen/rust toolchain for '${1:-}' on '${2:-}'" >&2; exit 1 ;;
esac
