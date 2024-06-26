#!/bin/sh

set -e

BASE_PATH="${1}"
LIBTORRENT_VERSION="${2}"

LIBTORRENT_DIR="libtorrent"
LIBTORRENT_REPO_URL="https://github.com/arvidn/libtorrent.git"

cd "${BASE_PATH}"
git clone --shallow-submodules --recurse-submodules ${LIBTORRENT_REPO_URL} ${LIBTORRENT_DIR}

cd "${BASE_PATH}/${LIBTORRENT_DIR}"
if [ "${LIBTORRENT_VERSION}" = "v2-latest" ]; then
  git checkout "$(git tag -l --sort=-v:refname "v2*" | head -n 1)"
elif [ "${LIBTORRENT_VERSION}" = "v1-latest" ]; then
  git checkout "$(git tag -l --sort=-v:refname "v1*" | head -n 1)"
else
  git checkout v"${LIBTORRENT_VERSION}"
fi

git rev-parse HEAD > /build_commit.libtorrent

cmake -Wno-dev -G Ninja -B build \
  -D CMAKE_BUILD_TYPE="Release" \
  -D CMAKE_CXX_STANDARD=17 \
  -D CMAKE_INSTALL_LIBDIR="lib" \
  -D CMAKE_INSTALL_PREFIX="/usr/local"
cmake --build build --parallel "$(nproc)"
cmake --install build
