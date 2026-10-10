# platform: host-agnostic
#   usage: . build/versions.sh     sets REPO_ROOT, FD_VERSION, RUST_PIN, WORK, TARGET_TRIPLE
: "${REPO_ROOT:=$(cd "$(dirname "$0")/.." && pwd)}"
export REPO_ROOT
FD_VERSION="$(tr -d ' \t\n' < "$REPO_ROOT/UPSTREAM_VERSION")"
RUST_PIN="$(tr -d ' \t\n' < "$REPO_ROOT/components/rust/version")"
# spec: SKILL.md "Build OUT of the source tree" -- a checkout may live on NFS
WORK="${MAVERICKS_BUILD_ROOT:-${TMPDIR:-/tmp}/mm-build}/mavergreen-fd"
TARGET_TRIPLE=x86_64-apple-darwin
export FD_VERSION RUST_PIN WORK TARGET_TRIPLE
PREFIX=/usr/local/mavergreen/fd
STAGE_ROOT="$WORK/stage"
STAGE="$STAGE_ROOT$PREFIX"
export PREFIX STAGE_ROOT STAGE
