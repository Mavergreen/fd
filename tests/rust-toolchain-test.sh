#!/bin/sh
# platform: host-agnostic
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
T="$ROOT/build/rust-toolchain.sh"
fail() { echo "FAIL: $1"; exit 1; }
[ "$(sh "$T" native x86_64)" = rust ] || fail "on 10.9 the native rust toolchain builds fd"
[ "$(sh "$T" cross x86_64)" = rust ] || fail "an Intel modern Mac runs the native rust toolchain, which targets 10.9"
[ "$(sh "$T" cross arm64)" = rust-cross ] || fail "Apple Silicon builds with rust-cross, never the x86_64 toolchain under Rosetta"
if sh "$T" native arm64 2>/dev/null; then fail "no toolchain is native on arm64: 10.9 has no arm64"; fi
if sh "$T" "" "" 2>/dev/null; then fail "an unknown host must fail, never guess a toolchain"; fi
echo "PASS: rust-toolchain"
