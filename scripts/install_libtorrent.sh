#!/bin/sh

set -e

BASE_PATH="${1}"
LIBTORRENT_VERSION="${2}"
# libtorrent must be built with the same build type as qBittorrent. Mixing a
# Release libtorrent with a Debug qBittorrent (or vice versa) changes the layout
# of libtorrent's public structs via TORRENT_USE_ASSERTS/NDEBUG, producing an
# ABI mismatch that crashes qBittorrent (std::bad_alloc) when reading trackers.
BUILD_TYPE="${3:-release}"

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

# libtorrent enables its own internal invariant assertions in Debug builds via a
# PUBLIC `$<$<CONFIG:Debug>:TORRENT_USE_ASSERTS>` in its CMakeLists. These are
# libtorrent-development checks that abort the process on internal invariants
# (e.g. libtorrent 2.1's disk_cache), which is not what our debug images are for --
# there we want qBittorrent's own Q_ASSERT + stacktrace, not libtorrent's. Because
# the definition is PUBLIC it also propagates to qBittorrent (a Debug consumer),
# so we must strip it here rather than override the build type: removing it leaves
# the macro undefined, which libtorrent's config.hpp defaults to 0 for both the
# library and its consumers, keeping TORRENT_USE_ASSERTS (and thus the struct ABI)
# consistent. Release builds are unaffected (the generator expression is inactive).
sed -i '/\$<\$<CONFIG:Debug>:TORRENT_USE_ASSERTS>/d' CMakeLists.txt

# qBittorrent 5.3+ requires libtorrent 2.1 to be built with deprecated functions
# disabled; see https://github.com/qbittorrent/qBittorrent/issues/24663
case "${LIBTORRENT_VERSION}" in
  2.1*) DEPRECATED_FUNCTIONS="OFF" ;;
  *)    DEPRECATED_FUNCTIONS="ON" ;;
esac

cmake -Wno-dev -G Ninja -B build \
  -D CMAKE_BUILD_TYPE="${BUILD_TYPE}" \
  -D CMAKE_CXX_STANDARD=17 \
  -D CMAKE_INSTALL_LIBDIR="lib" \
  -D CMAKE_INSTALL_PREFIX="/usr/local" \
  -D deprecated-functions="${DEPRECATED_FUNCTIONS}"
cmake --build build --parallel "$(nproc)"
cmake --install build
