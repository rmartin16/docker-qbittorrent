#!/bin/sh

set -e

BASE_PATH="${1}"
LIBTORRENT_VERSION="${2}"
# must match the qBittorrent build type to avoid an assert/NDEBUG ABI mismatch
BUILD_TYPE="${3:-Release}"

cd "${BASE_PATH}"

if [ "${LIBTORRENT_VERSION}" = "1_1_14" ]; then
  LIBTORRENT_BRANCH="libtorrent-${LIBTORRENT_VERSION}"
else
  LIBTORRENT_BRANCH="v${LIBTORRENT_VERSION}"
fi

mkdir -p "${BASE_PATH}/libtorrent/src"

cd "${BASE_PATH}/libtorrent/src"
git clone --shallow-submodules --recurse-submodules https://github.com/arvidn/libtorrent.git --branch "${LIBTORRENT_BRANCH}"

cd "${BASE_PATH}/libtorrent/src/libtorrent"
git rev-parse HEAD > /build_commit.libtorrent

# libtorrent 1.1.14's headers rely on transitive <map> includes that newer
# libstdc++ (Ubuntu 24.04+) no longer provides, so add the include explicitly
if [ "${LIBTORRENT_VERSION}" = "1_1_14" ]; then
  patch -p1 < "${BASE_PATH}/patches/libtorrent_map_include_1_1_14.patch"
fi

cmake -Wno-dev -B cmake-build-dir \
  -D CMAKE_BUILD_TYPE="${BUILD_TYPE}" \
  -D CMAKE_INSTALL_PREFIX="/usr/local"
cmake --build cmake-build-dir --parallel "$(nproc)"
cmake --install cmake-build-dir
