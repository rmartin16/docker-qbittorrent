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

if [[ ! -z "${QBT_REPO_URL}" && ! -z "${QBT_REPO_REF}" && ! -z ${QBT_VERSION} ]]; then
  echo "Only set QBT_REPO_URL and QBT_REPO_REF _or_ QBT_VERSION...not both"
  exit 1
fi

if [[ ! -z "${QBT_VERSION}" ]]; then
  case "${QBT_VERSION}" in
    # check known dev branches
    master | v4_5_x | v4_4_x | v4_3_x)
      QBT_REPO_REF="${QBT_VERSION}" ;;
    # otherwise assume the version is a release
    *)
      QBT_REPO_REF="release-${QBT_VERSION}" ;;
  esac
fi

cd "${BASE_PATH}"
git clone "${QBT_REPO_URL}"
cd "${BASE_PATH}/qBittorrent"
git checkout "${QBT_REPO_REF}"

git rev-parse HEAD > /build_commit.qBittorrent

# https://github.com/qbittorrent/qBittorrent/issues/13981#issuecomment-746836281
if [[ "${QBT_VERSION}" = "4.3.0" || "${QBT_VERSION}" = "4.3.0.1" || "${QBT_VERSION}" = "4.3.1" ]] ; then
  patch "src/base/bittorrent/session.cpp" "${BASE_PATH}/patches/libtorrent_2_compat_early_4.3.0.patch"
fi

cmake -Wno-dev -Wno-deprecated -B build -G Ninja \
  -D CMAKE_BUILD_TYPE="${QBT_BUILD_TYPE}" \
  -D CMAKE_CXX_STANDARD=17 \
  -D CMAKE_CXX_STANDARD_LIBRARIES="/usr/lib/libexecinfo.so" \
  -D CMAKE_INSTALL_PREFIX="/usr/local" \
  -D QBT_VER_STATUS= \
  -D GUI=OFF \
  -D QT6=ON \
  -D STACKTRACE=ON \
  -D VERBOSE_CONFIGURE=ON
cmake --build build --parallel "$(nproc)"
cmake --install build
