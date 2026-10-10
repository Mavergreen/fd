#!/bin/sh
# platform: macOS-only -- assert_binary_compatible.sh reads Mach-O with otool and nm
#   usage: compat-gate.sh <binary>...     fails unless every binary is 10.9-safe
set -eu
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/build/msc.sh"
# spec: INGREDIENTS.md "The 10.9 compat gate" -- the 10.10 symbols fd's std calls, which only the
#       force-loaded shim defines; fd ships stripped, so REQUIRE_DEFINED cannot see them
MAVERICKS_POST_10_9_SYMBOLS='_CCRandomGenerateBytes|_fstatat.*' \
MAVERICKS_DEVIATIONS_ROOT="$REPO_ROOT" MAVERICKS_ALLOW_ARCHS=x86_64 \
  exec sh "$SHIPYARD_SCRIPTS/assert_binary_compatible.sh" "$@"
