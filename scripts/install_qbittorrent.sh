#!/bin/sh

set -e

BASE_PATH="${1}"
QBT_VERSION="${2}"
QBT_BUILD_TYPE="${3}"
QBT_REPO_URL="${4}"
QBT_REPO_REF="${5}"

echo "BASE_PATH=${BASE_PATH}"
echo "QBT_VERSION=${QBT_VERSION}"
echo "QBT_BUILD_TYPE=${QBT_BUILD_TYPE}"
echo "QBT_REPO_URL=${QBT_REPO_URL}"
echo "QBT_REPO_REF=${QBT_REPO_REF}"

QBT_REPO_DIR="qBittorrent"

if [ -n "${QBT_REPO_URL}" ] && [ -n "${QBT_REPO_REF}" ] && [ -n "${QBT_VERSION}" ]; then
  echo "Only set QBT_REPO_URL and QBT_REPO_REF _or_ QBT_VERSION...not both"
  exit 1
fi

if [ -n "${QBT_VERSION}" ]; then
  case "${QBT_VERSION}" in
    # check known dev branches
    master | v[456789]_[0123456789]_x)
      QBT_REPO_REF="${QBT_VERSION}"
      PATCH_VER_STATUS=1 ;;
    # otherwise assume the version is a release
    *)
      QBT_REPO_REF="release-${QBT_VERSION}" ;;
  esac
fi

cd "${BASE_PATH}"
git clone "${QBT_REPO_URL}" "${QBT_REPO_DIR}"
cd "${BASE_PATH}/${QBT_REPO_DIR}"
git checkout "${QBT_REPO_REF}"

git rev-parse HEAD > /build_commit.qBittorrent

# https://github.com/qbittorrent/qBittorrent/issues/13981#issuecomment-746836281
if [ "${QBT_VERSION}" = "4.3.0" ] || [ "${QBT_VERSION}" = "4.3.0.1" ] || [ "${QBT_VERSION}" = "4.3.1" ]; then
  patch "src/base/bittorrent/session.cpp" "${BASE_PATH}/patches/libtorrent_2_compat_early_4.3.0.patch"
fi

if [ "${PATCH_VER_STATUS:-0}" = 1 ]; then
  echo "Setting QBT_VERSION_STATUS to dev"
  sed -i 's/QBT_VERSION_STATUS ""/QBT_VERSION_STATUS "dev"/' src/base/version.h.in
fi

# qBittorrent < 5.0 relies on Qt transitively including the container headers used
# for the struct fields in src/base/http/types.h (QMap/QHash/QByteArray). Newer Qt6
# (Alpine 3.24+) no longer pulls these in, leaving them as incomplete types and
# breaking the build. Upstream added the explicit includes in 5.0; backport them
# when missing so the older maintenance branches (v4_4_x/v4_5_x/v4_6_x) still build.
if ! grep -q '#include <QHash>' src/base/http/types.h; then
  echo "Adding missing container includes to src/base/http/types.h"
  sed -i 's|#include <QHostAddress>|#include <QByteArray>\n#include <QHash>\n#include <QHostAddress>\n#include <QMap>|' src/base/http/types.h
fi

# Stacktrace support is only built into debug images. It uses Boost.Stacktrace's
# addr2line backend (which needs `addr2line` from binutils at runtime) so we avoid
# the execinfo/libexecinfo dependency that musl does not provide.
#
# qBittorrent only adopted Boost.Stacktrace in 4.5.0. Earlier versions implement
# stacktraces via `src/app/stacktrace.h`, which includes execinfo.h directly and
# fails to compile without it. Since libexecinfo is no longer installed (musl lacks
# execinfo.h), leave stacktrace disabled for those versions.
STACKTRACE=OFF
STACKTRACE_CXX_FLAGS=""
if [ "${QBT_BUILD_TYPE}" = "debug" ] && ! grep -q "execinfo.h" src/app/stacktrace.h 2>/dev/null; then
  STACKTRACE=ON
  STACKTRACE_CXX_FLAGS="-DBOOST_STACKTRACE_USE_ADDR2LINE"
fi

cmake -Wno-dev -Wno-deprecated -B build -G Ninja \
  -D CMAKE_BUILD_TYPE="${QBT_BUILD_TYPE}" \
  -D CMAKE_CXX_STANDARD=17 \
  -D CMAKE_CXX_FLAGS="${STACKTRACE_CXX_FLAGS}" \
  -D CMAKE_INSTALL_PREFIX="/usr/local" \
  -D QT_FIND_PRIVATE_MODULES=ON \
  -D QBT_VER_STATUS= \
  -D GUI=OFF \
  -D WEBUI=ON \
  -D QT6=ON \
  -D STACKTRACE="${STACKTRACE}" \
  -D DBUS=ON \
  -D SYSTEMD=OFF \
  -D VERBOSE_CONFIGURE=ON \
  -D TESTING=OFF
cmake --build build --parallel "$(nproc)"
cmake --install build
