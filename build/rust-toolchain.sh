#!/bin/sh
# platform: host-agnostic
#   usage: rust-toolchain.sh <mode> <arch>     prints the Mavergreen/rust product that builds fd here
#          <mode> is mavericks_mode.sh's answer, <arch> is `uname -m`
set -eu
case "${1:-}:${2:-}" in
  native:x86_64|cross:x86_64) echo rust ;;
  cross:arm64) echo rust-cross ;;
  *) echo "rust-toolchain: no Mavergreen/rust toolchain for mode '${1:-}' on '${2:-}'" >&2; exit 1 ;;
esac
