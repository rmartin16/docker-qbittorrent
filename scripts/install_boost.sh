#!/bin/sh

set -e

BASE_PATH="${1}"
BOOST_VERSION="${2}"

cd "${BASE_PATH}"

if [ ! -f "downloads/boost_${BOOST_VERSION}.tar.gz" ]; then
  BOOST_VERSION_URL=$(echo "${BOOST_VERSION}" | sed 's/_/\./g')
  BOOST_RELEASE_URL="https://boostorg.jfrog.io/artifactory/main/release/${BOOST_VERSION_URL}/source/boost_${BOOST_VERSION}.tar.gz"
  curl -NLk "${BOOST_RELEASE_URL}" -o "downloads/boost_${BOOST_VERSION}.tar.gz"
fi

tar zxf "downloads/boost_${BOOST_VERSION}.tar.gz" -C "${BASE_PATH}"
mv "boost_${BOOST_VERSION}" "${BASE_PATH}/boost"
