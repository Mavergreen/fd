# Build ingredients

Everything baked into the shipped `fd` `.pkg`, where it is pinned, and how a change reaches a release.
The *own upstream* is fd; an ingredient is anything else the artifact is built with.

| Ingredient | Pinned in | Renovate | On a bump |
|---|---|---|---|
| fd source (own upstream) | `UPSTREAM_VERSION` | ✅ `crate` on `fd-find` | cuts `<ver>-mavericks.1` |
| fd's crate dependencies | upstream's `Cargo.lock`, inside the fd crate | ✅ move with `UPSTREAM_VERSION` | built `--locked`: cargo verifies each against the checksum in that lock file |
| Rust toolchain (`rust` on 10.9, `rust-cross` on a modern Mac) | `components/rust/version` | ✅ `github-releases` on `Mavergreen/rust`, `-mavericks.N` versioning | repackage → `-mavericks.(N+1)` |
| MacOSX10.9 SDK (x86_64) | shipyard `fetch_sdk.sh` (pinned by hash) | ✅ moves with shipyard `@v1` | moving tag |

## fd source verification

The fd source is the crate sharkdp publishes to crates.io, `fd-find-<version>.crate`, not a GitHub
tarball. It is verified against the SHA-256 crates.io's own index publishes for that version, read at
build time, so a Renovate bump moves only `UPSTREAM_VERSION` and no hand-maintained hash exists. A
version the index does not list, or lists without a checksum, fails the fetch. GitHub publishes no
checksums for fd's source, so its tarball would need a hash pinned by hand or by a bot. The crate
carries upstream's `Cargo.lock`, `doc/fd.1` and the shell completions, and its `.cargo_vcs_info.json`
names the git commit it was packaged from.

## Declared state

- upstream: UPSTREAM_VERSION
- rust: components/rust/version

## Conformance deviations
