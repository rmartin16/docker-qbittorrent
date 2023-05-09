#!/bin/sh

set -e

BASE_PATH="${1}"
QBT_VERSION="${2}"
QBT_BUILD_TYPE="${3}"

cd "${BASE_PATH}"

QBT_URL="https://github.com/qbittorrent/qBittorrent/archive/refs/tags/release-${QBT_VERSION}.tar.gz"
curl -sNLk "${QBT_URL}" | tar -zxf - -C "${BASE_PATH}"
mv "qBittorrent-release-${QBT_VERSION}" "qBittorrent"

cd "${BASE_PATH}/qBittorrent"

echo "${QBT_VERSION}" > /build_commit.qBittorrent

# https://github.com/qbittorrent/qBittorrent/issues/9333
if [ "${QBT_VERSION}" = "4.1.2" ] ; then
  patch "src/base/preferences.cpp" "${BASE_PATH}/patches/implicit_cast_4.1.2.patch"
fi

if [ "${QBT_VERSION}" = "4.1.6" ] ; then
  patch "src/base/rss/rss_feed.cpp" "${BASE_PATH}/patches/rss_assert_4.1.6.patch"
fi

if [ "${QBT_BUILD_TYPE}" = "debug" ]; then
  ENABLE_DEBUG="--enable-debug"
fi
./configure \
  CXXFLAGS="-std=c++14" \
  CFLAGS="-I/usr/local/include/libtorrent" \
  LDFLAGS="-Wl,-rpath,/usr/local/lib/" \
  libtorrent_CFLAGS="/usr/local/include/" \
  libtorrent_LIBS="/usr/local/lib/libtorrent-rasterbar.so" \
  ${ENABLE_DEBUG} \
  --disable-gui
make -j "$(nproc)" install
