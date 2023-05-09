#!/bin/sh

set -e

BASE_PATH="${1}"
LIBTORRENT_VERSION="${2}"

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

cmake -Wno-dev -B cmake-build-dir/Release \
  -D CMAKE_BUILD_TYPE=Release \
  -D CMAKE_INSTALL_PREFIX="/usr/local"
cmake --build cmake-build-dir/Release --parallel "$(nproc)"
cmake --install cmake-build-dir/Release
