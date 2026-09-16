#!/bin/bash
# Runs inside emscripten/emsdk. Expects LIBHEIF_SRC and LIBDE265_VERSION;
# writes /work/out/csp/libheif.js and /work/out/std/libheif.js.
set -euo pipefail

export USE_TYPESCRIPT=0
export CORES=$(nproc)
# emcc's JS optimizer splits its output into one chunk per core, which changes
# line breaks and function order. Pin it so every machine emits identical files.
export EMCC_CORES=4

# libde265 1.1.x is CMake-only, but libheif's build-emscripten.sh still drives
# the old autotools layout. It skips its own libde265 step when
# libde265/.libs/libde265.a exists, so pre-build it with CMake and place the
# archive and generated version header where the script looks for them.
build_libde265() {
	local src=libde265-${LIBDE265_VERSION}
	curl -sSfL -o $src.tar.gz \
		https://github.com/strukturag/libde265/releases/download/v${LIBDE265_VERSION}/$src.tar.gz
	tar xf $src.tar.gz
	emcmake cmake -S $src -B $src/cmake-build \
		-DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS=-O3 \
		-DBUILD_SHARED_LIBS=OFF -DENABLE_SIMD=OFF -DENABLE_AVX2=OFF -DENABLE_AVX512=OFF \
		-DENABLE_DECODER=OFF -DENABLE_ENCODER=OFF -DENABLE_SDL=OFF
	emmake make -C $src/cmake-build -j${CORES} de265
	mkdir -p $src/libde265/.libs
	cp "$(find $src/cmake-build -name libde265.a | head -1)" $src/libde265/.libs/libde265.a
	cp $src/cmake-build/libde265/de265-version.h $src/libde265/de265-version.h
}

mkdir -p /work/out/csp && cd /work/out/csp
build_libde265
USE_UNSAFE_EVAL=0 USE_WASM=0 "$LIBHEIF_SRC/build-emscripten.sh" "$LIBHEIF_SRC"

# Standard build reuses the compiled libde265.
mkdir -p /work/out/std && cd /work/out/std
ln -sfn /work/out/csp/libde265-${LIBDE265_VERSION} libde265-${LIBDE265_VERSION}
ln -sfn /work/out/csp/libde265-${LIBDE265_VERSION}.tar.gz libde265-${LIBDE265_VERSION}.tar.gz
USE_WASM=0 "$LIBHEIF_SRC/build-emscripten.sh" "$LIBHEIF_SRC"
