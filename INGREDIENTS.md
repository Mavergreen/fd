# Build ingredients

Everything baked into the shipped `fd` `.pkg`, where it is pinned, and how a change reaches a release.
The *own upstream* is fd; an ingredient is anything else the artifact is built with.

| Ingredient | Pinned in | Renovate | On a bump |
|---|---|---|---|
| fd source (own upstream) | `UPSTREAM_VERSION` | ✅ `crate` on `fd-find` | cuts `<ver>-mavericks.1` |
| fd's crate dependencies | upstream's `Cargo.lock`, inside the fd crate | ✅ move with `UPSTREAM_VERSION` | built `--locked`: cargo verifies each against the checksum in that lock file |
| Rust toolchain (`rust` on 10.9, `rust-cross` on a modern Mac) | `components/rust/version` | ✅ `github-releases` on `Mavergreen/rust`, `-mavericks.N` versioning | repackage → `-mavericks.(N+1)`. `build/fetch-rust.sh` verifies the pkg against its release's `SHA256SUMS` and extracts it under the build root; nothing is installed |
| MacOSX10.9 SDK (x86_64) | shipyard `fetch_sdk.sh` (pinned by hash) | ✅ moves with shipyard `@v1` | moving tag |

## fd source verification

The fd source is the crate sharkdp publishes to crates.io, `fd-find-<version>.crate`, not a GitHub
tarball. It is verified against the SHA-256 crates.io's own index publishes for that version, read at
build time, so a Renovate bump moves only `UPSTREAM_VERSION` and no hand-maintained hash exists. A
version the index does not list, or lists without a checksum, fails the fetch. GitHub publishes no
checksums for fd's source, so its tarball would need a hash pinned by hand or by a bot. The crate
carries upstream's `Cargo.lock`, `doc/fd.1` and the shell completions, and its `.cargo_vcs_info.json`
names the git commit it was packaged from.

## Man page and completions

`doc/fd.1` and the zsh completion `contrib/completion/_fd` ship as upstream wrote them. The bash and
fish completions are what `fd --gen-completions` prints, as upstream's own Makefile makes them. On an
arm64 Mac a host-arch `fd`, built from the same source, prints them, so no build step runs under
Rosetta. They install under `share/zsh/site-functions`, `share/bash-completion/completions` and
`share/fish/vendor_completions.d` in fd's own tree; the link farm exports only `bin/` and the man
page, so a shell finds them once pointed there.

## The 10.9 compat gate

`build/compat-gate.sh` runs shipyard's compat guard on the linked `fd` before it is staged: x86_64
only, minos and SDK 10.9, and no post-10.9 undefined import. Mavergreen/rust's `rustc` force-loads
macports-legacy-support, which defines the 10.10 functions fd's std calls (`clock_gettime`,
`CCRandomGenerateBytes`, `fstatat`). fd's release profile strips symbols, so the shipped binary
records none of them as defined and `MAVERICKS_REQUIRE_DEFINED_SYMBOLS` stays empty. Instead the
gate denies all three as imports: a build that lost the shim would import them, and fail.

## Declared state

- upstream: UPSTREAM_VERSION
- rust: components/rust/version

## Conformance deviations

- rosetta:tests/build-test.sh: on an arm64 CI runner the test executes the shipped x86_64 `fd` (`--version`, a find by extension) under Rosetta. It cannot run natively: the binary under test is the x86_64 one, and the release runner is arm64. CI primes Rosetta and runs it; it exits 77 only on a developer's arm64 Mac without Rosetta. On 10.9 it runs natively. Exit: move the run half to an x86_64 host (the 10.9 box or an Intel runner) before macOS 28 removes Rosetta.
