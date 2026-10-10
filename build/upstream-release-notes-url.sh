#!/bin/sh
# platform: host-agnostic
#   usage: upstream-release-notes-url.sh <upstream-version>     prints fd's notes URL for it
set -eu
printf 'https://github.com/sharkdp/fd/releases/tag/v%s\n' "${1:?usage: upstream-release-notes-url.sh <upstream-version>}"
