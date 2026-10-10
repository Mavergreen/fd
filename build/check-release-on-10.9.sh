#!/bin/sh
# platform: macOS-only -- installer, sw_vers and the mavergreen helper; meant for real 10.9
#   usage: check-release-on-10.9.sh <version>
#          Run ON Mac OS X 10.9 after a release, before trusting it: downloads fd-<version>.pkg,
#          verifies it against the release's SHA256SUMS, installs it (sudo), uses fd the way a user
#          would from a login shell, and uninstalls it. One PASS/FAIL line per step; exit 1 if any
#          failed. MAVERICKS_RELEASE_BASE replaces the release's download URL (file:///path/to/dist
#          rehearses against a local build).
set -u
V="${1:-}"
[ -n "$V" ] || { echo "usage: check-release-on-10.9.sh <version>   (e.g. 10.5.0-mavericks.1)" >&2; exit 2; }
os="$(sw_vers -productVersion)"
case "$os" in 10.9|10.9.*) : ;; *) echo "check-release-on-10.9.sh: run this on Mac OS X 10.9 (this is $os)" >&2; exit 2 ;; esac
base="${MAVERICKS_RELEASE_BASE:-https://github.com/Mavergreen/fd/releases/download/$V}"
pkg="fd-$V.pkg"
w="$(mktemp -d "${TMPDIR:-/tmp}/fd-release-check.XXXXXX")"
bad=0
step() {
  name="$1"; shift
  if ( "$@" ) > "$w/$name.log" 2>&1; then echo "PASS $name"; else echo "FAIL $name (log: $w/$name.log)"; bad=1; fi
}
fetch() {
  curl -fsSL -o "$w/$pkg" "$base/$pkg" && curl -fsSL -o "$w/SHA256SUMS" "$base/SHA256SUMS" || return 1
  ( cd "$w" && grep " $pkg\$" SHA256SUMS | shasum -a 256 -c - )
}
install_pkg() { sudo installer -pkg "$w/$pkg" -target / && /usr/local/bin/mavergreen check; }
# platform: /usr/local/mavergreen/bin reaches PATH and MANPATH only through a login shell's paths.d
L() { /bin/bash -lc "$1"; }
version() { [ "$(L 'fd --version')" = "fd ${V%-mavericks.*}" ]; }
find_files() {
  mkdir -p "$w/tree/sub" && : > "$w/tree/sub/a.txt" && : > "$w/tree/b.md"
  [ "$(L "cd '$w/tree' && fd -t f -e txt")" = sub/a.txt ]
}
man_page() { L 'man -w fd' | grep -q '/usr/local/mavergreen/'; }
uninstall() { sudo /usr/local/bin/mavergreen uninstall fd && [ ! -e /usr/local/mavergreen/fd ]; }

step fetch fetch
step install install_pkg
step version version
step find find_files
step man man_page
step uninstall uninstall
[ "$bad" = 0 ] && rm -rf "$w"
exit "$bad"
