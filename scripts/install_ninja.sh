#!/bin/sh

set -e

BASE_PATH="${1}"

cd "${BASE_PATH}"
git clone --shallow-submodules --recurse-submodules https://github.com/ninja-build/ninja.git "${BASE_PATH}/ninja"

cd "${BASE_PATH}/ninja"
git checkout "$(git tag -l --sort=-v:refname "v*" | head -n 1)"

cmake -Wno-dev -B build \
  -D CMAKE_CXX_COMPILER=/usr/bin/g++ \
  -D CMAKE_C_COMPILER=/usr/bin/gcc \
  -D CMAKE_CXX_STANDARD=17 \
  -D CMAKE_INSTALL_PREFIX="/usr/local"
cmake --build build --parallel "$(nproc)"
cmake --install build
