#!/bin/sh
# platform: host-agnostic
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
T="$ROOT/build/rust-toolchain.sh"
fail() { echo "FAIL: $1"; exit 1; }
[ "$(sh "$T" Linux x86_64)" = cargo-env ] || fail "on x86_64 Linux shipyard's cargo-env.sh gives the pinned rust's Linux toolchain"
[ "$(sh "$T" Darwin x86_64)" = cargo-env ] || fail "on 10.9 and an Intel Mac cargo-env.sh gives the pinned rust, which targets 10.9 natively"
[ "$(sh "$T" Darwin arm64)" = rust-cross ] || fail "Apple Silicon builds with rust-cross, never the x86_64 toolchain under Rosetta"
if sh "$T" Linux aarch64 2>/dev/null; then fail "the rust release has no arm64 Linux toolchain"; fi
if sh "$T" "" "" 2>/dev/null; then fail "an unknown host must fail, never guess a toolchain"; fi
echo "PASS: rust-toolchain"
