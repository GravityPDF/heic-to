#!/bin/bash
# Compare scripts/libheif-versions.env with the latest libheif and libde265
# releases. When either is newer, rewrite the versions file and the README's
# version line, and emit the details as GitHub Actions step outputs.
#
# Skips a version pair that already has a pull request in any state (a closed
# one means someone decided against it) or an open build-failure issue, so a
# daily run doesn't repeat work.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSIONS="$ROOT/scripts/libheif-versions.env"
OUTPUT="${GITHUB_OUTPUT:-/dev/stdout}"

pinned() { sed -n "s/^$1=//p" "$VERSIONS"; }
latest() { gh release view --repo "$1" --json tagName --jq '.tagName | ltrimstr("v")'; }
# True when $2 is a later version than $1.
is_newer() { [ "$1" != "$2" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -1)" = "$2" ]; }

current_libheif=$(pinned LIBHEIF_VERSION)
current_libde265=$(pinned LIBDE265_VERSION)
current_emsdk=$(pinned EMSDK_VERSION)

libheif=$current_libheif
libde265=$current_libde265
latest_libheif=$(latest strukturag/libheif)
latest_libde265=$(latest strukturag/libde265)
is_newer "$current_libheif" "$latest_libheif" && libheif=$latest_libheif
is_newer "$current_libde265" "$latest_libde265" && libde265=$latest_libde265

echo "libheif: pinned $current_libheif, latest $latest_libheif"
echo "libde265: pinned $current_libde265, latest $latest_libde265"

if [ "$libheif" = "$current_libheif" ] && [ "$libde265" = "$current_libde265" ]; then
	echo "Up to date."
	echo "update=false" >> "$OUTPUT"
	exit 0
fi

branch="libheif/$libheif-libde265-$libde265"
title="Upgrade to libheif v$libheif and libde265 v$libde265"
failure_title="Build failed: libheif v$libheif with libde265 v$libde265"

if [ "$(gh pr list --head "$branch" --state all --json number --jq length)" != "0" ]; then
	echo "A pull request for $branch already exists; skipping."
	echo "update=false" >> "$OUTPUT"
	exit 0
fi
if [ "$(gh issue list --state open --search "\"$failure_title\" in:title" --json number --jq length)" != "0" ]; then
	echo "An open issue already reports that $failure_title; skipping."
	echo "update=false" >> "$OUTPUT"
	exit 0
fi

# Follow the Emscripten version libheif's own CI builds that release with.
emsdk=$(gh api "repos/strukturag/libheif/contents/.github/workflows/emscripten.yml?ref=v$libheif" --jq .content \
	| base64 -d | sed -n 's/^ *EMSCRIPTEN_VERSION: *//p' | head -1)
emsdk=${emsdk:-$current_emsdk}

printf 'LIBHEIF_VERSION=%s\nLIBDE265_VERSION=%s\nEMSDK_VERSION=%s\n' "$libheif" "$libde265" "$emsdk" > "$VERSIONS"
sed -i.bak -E "s#^Currently, heic-to is using .*#Currently, heic-to is using [libheif $libheif](https://github.com/strukturag/libheif/releases/tag/v$libheif) and [libde265 $libde265](https://github.com/strukturag/libde265/releases/tag/v$libde265) under the hood.#" "$ROOT/README.md"
rm "$ROOT/README.md.bak"

{
	echo "update=true"
	echo "branch=$branch"
	echo "title=$title"
	echo "failure_title=$failure_title"
	echo "libheif=$libheif"
	echo "libde265=$libde265"
	echo "emsdk=$emsdk"
	echo "previous_libheif=$current_libheif"
	echo "previous_libde265=$current_libde265"
	echo "previous_emsdk=$current_emsdk"
} >> "$OUTPUT"
