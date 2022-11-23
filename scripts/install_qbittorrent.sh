#!/bin/sh

set -e

BASE_PATH="${1}"
QBT_VERSION="${2}"
QBT_BUILD_TYPE="${3}"
BOOST_DIR="${4}"

cd "${BASE_PATH}"

case "${QBT_VERSION}" in
  master)
    QBT_DIR="qBittorrent-${QBT_VERSION}"
    QBT_URL="https://github.com/qbittorrent/qBittorrent/archive/refs/heads/${QBT_VERSION}.tar.gz" ;;
  v4_5_x | v4_4_x | v4_3_x)
    QBT_DIR="qBittorrent-${QBT_VERSION:1}"
    QBT_URL="https://github.com/qbittorrent/qBittorrent/archive/refs/heads/${QBT_VERSION}.tar.gz" ;;
  *)
    QBT_DIR="qBittorrent-release-${QBT_VERSION}"
    QBT_URL="https://github.com/qbittorrent/qBittorrent/archive/refs/tags/release-${QBT_VERSION}.tar.gz" ;;
esac

curl -sNLk "${QBT_URL}" | tar -zxf - -C "${BASE_PATH}"
mv "${QBT_DIR}" "${BASE_PATH}/qBittorrent"

cd "${BASE_PATH}/qBittorrent"

# https://github.com/qbittorrent/qBittorrent/issues/13981#issuecomment-746836281
if [[ "${QBT_VERSION}" = "4.3.0" || "${QBT_VERSION}" = "4.3.0.1" || "${QBT_VERSION}" = "4.3.1" ]] ; then
  patch "src/base/bittorrent/session.cpp" "${BASE_PATH}/patches/libtorrent_2_compat_early_4.3.0.patch"
fi

cmake -Wno-dev -Wno-deprecated -B build -G Ninja \
  -D CMAKE_BUILD_TYPE="${QBT_BUILD_TYPE}" \
  -D CMAKE_CXX_STANDARD=17 \
  -D BOOST_INCLUDEDIR="${BOOST_DIR}" \
  -D Boost_NO_BOOST_CMAKE=TRUE \
  -D CMAKE_CXX_STANDARD_LIBRARIES="/usr/lib/libexecinfo.so" \
  -D CMAKE_INSTALL_PREFIX="/usr/local" \
  -D QBT_VER_STATUS= \
  -D GUI=OFF \
  -D QT6=ON \
  -D STACKTRACE=ON \
  -D VERBOSE_CONFIGURE=ON
cmake --build build --parallel "$(nproc)"
cmake --install build
