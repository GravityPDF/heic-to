#!/bin/bash
# Build src/lib/libheif.js and src/lib/libheif-without-unsafe-eval.js from
# source inside the emscripten/emsdk Docker image, then wrap them as ES modules.
# Versions come from scripts/libheif-versions.env unless set in the environment:
#
#   LIBHEIF_VERSION=1.23.5 npm run build:libheif
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

for var in LIBHEIF_VERSION LIBDE265_VERSION EMSDK_VERSION; do
	[ -n "${!var:-}" ] || declare "$var=$(sed -n "s/^$var=//p" "$ROOT/scripts/libheif-versions.env")"
done

WORK="$ROOT/tmp/libheif-build"

rm -rf "$WORK/out"
mkdir -p "$WORK"
if [ ! -d "$WORK/libheif-$LIBHEIF_VERSION" ]; then
	git clone --quiet --depth 1 --branch "v$LIBHEIF_VERSION" \
		https://github.com/strukturag/libheif.git "$WORK/libheif-$LIBHEIF_VERSION"
fi

# The image is amd64-only; on Apple Silicon it runs under emulation.
docker run --rm --platform linux/amd64 \
	-v "$WORK:/work" \
	-v "$ROOT/scripts:/scripts:ro" \
	-e LIBHEIF_SRC="/work/libheif-$LIBHEIF_VERSION" \
	-e LIBDE265_VERSION="$LIBDE265_VERSION" \
	"emscripten/emsdk:$EMSDK_VERSION" \
	bash /scripts/build-in-docker.sh

node "$ROOT/scripts/to-esm.cjs" "$WORK/out/std/libheif.js" "$ROOT/src/lib/libheif.js" \
	"Build from libheif $LIBHEIF_VERSION with LIBDE265_VERSION=$LIBDE265_VERSION"
node "$ROOT/scripts/to-esm.cjs" "$WORK/out/csp/libheif.js" "$ROOT/src/lib/libheif-without-unsafe-eval.js" \
	"Build from libheif $LIBHEIF_VERSION with USE_UNSAFE_EVAL=0 and LIBDE265_VERSION=$LIBDE265_VERSION"
