#!/bin/sh
# platform: host-agnostic -- shipyard's pkg_read.sh and stevedore read the pkg, $OTOOL the updater
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/build/versions.sh"
. "$ROOT/build/msc.sh"
fail() { echo "FAIL: $1"; exit 1; }
set -- "$ROOT"/dist/fd-*.pkg
[ -f "$1" ] || { echo "not packaged (no dist/fd-*.pkg) -- run build/build.sh, then build/package-pkg.sh; skipping"; exit 77; }
[ "$#" -eq 1 ] || fail "dist/ holds $# fd pkgs; one build makes one"
PKG="$1"
t="$(mktemp -d "${TMPDIR:-/tmp}/fd-package-test.XXXXXX")"; trap 'rm -rf "$t"' EXIT INT TERM
sh "$SHIPYARD_SCRIPTS/pkg_read.sh" expand "$PKG" "$t/x" || fail "$PKG must expand"
sh "$SHIPYARD_SCRIPTS/pkg_read.sh" payload "$t/x" "$IDENTIFIER" "$t/root" || fail "$PKG holds no fd component"
P="$t/root$PREFIX"

for f in bin/fd share/man/man1/fd.1 share/zsh/site-functions/_fd share/bash-completion/completions/fd \
         share/fish/vendor_completions.d/fd.fish mavergreen.plist; do
  [ -s "$P/$f" ] || fail "the pkg must install $PREFIX/$f"
done
cmp -s "$P/bin/fd" "$STAGE/bin/fd" || fail "the pkg's fd must be the one build.sh gated"

app="$t/root/Library/Application Support/Mavergreen/fd-updater.app"
[ -d "$app" ] || fail "the pkg must install fd-updater.app"
[ -f "$t/root/Library/LaunchAgents/dev.mavergreen.fd-updatecheck.plist" ] || fail "the pkg must install the update-check LaunchAgent"
feed="$("$(sh "$SHIPYARD_SCRIPTS/fetch_stevedore.sh")" plist get "$app/Contents/Info.plist" SUFeedURL)"
[ "$feed" = https://github.com/Mavergreen/fd/releases/latest/download/fd.xml ] || fail "the updater must poll fd's feed (got $feed)"
if "${OTOOL:-otool}" -L "$app/Contents/MacOS/"* | grep -q "$PREFIX"; then fail "the updater must not link the product it updates"; fi
sh "$SHIPYARD_SCRIPTS/assert_sparkle_pristine.sh" "$app/Contents/Frameworks/Sparkle.framework" \
  "$(sh "$SHIPYARD_SCRIPTS/fetch_sparkle_framework.sh")" || fail "the embedded Sparkle.framework must be the pinned one"

sh "$SHIPYARD_SCRIPTS/assert_pkg_installs_in_place.sh" "$PKG" || fail "the pkg must neither relocate nor version-skip a bundle"
d="$t/x/Distribution"
grep -q '<os-version min="10.9.5"' "$d" || fail "the Distribution must declare the 10.9.5 install floor"
first="$(sed -n 's/.*<pkg-ref id="\([^"]*\)".*/\1/p' "$d" | sed -n 1p)"
[ "$first" = dev.mavergreen.base ] || fail "dev.mavergreen.base must be the first component, not $first"
grep -q "id=\"$IDENTIFIER\"" "$d" || fail "the pkg must carry the $IDENTIFIER component"
echo "PASS: package"
