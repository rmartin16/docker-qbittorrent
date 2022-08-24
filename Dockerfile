FROM alpine:latest AS builder

ARG QT_VERSION="qt6"
RUN apk --update-cache add \
      automake build-base cmake curl git libtool linux-headers perl pkgconf python3 python3-dev re2c tar \
      icu-dev libexecinfo-dev openssl-dev zlib-dev ${QT_VERSION}-qtbase-dev ${QT_VERSION}-qttools-dev

RUN cd $HOME && \
    git clone --shallow-submodules --recurse-submodules https://github.com/ninja-build/ninja.git $HOME/ninja && \
    cd $HOME/ninja && \
    git checkout "$(git tag -l --sort=-v:refname "v*" | head -n 1)" && \
    cmake \
      -Wno-dev \
      -B build \
      -D CMAKE_CXX_COMPILER=/usr/bin/g++ \
      -D CMAKE_C_COMPILER=/usr/bin/gcc \
      -D CMAKE_CXX_STANDARD=17 \
	  -D CMAKE_INSTALL_PREFIX="/usr/local" && \
    cmake --build build --parallel $(nproc) && \
    cmake --install build

ARG BOOST_VERSION="1_76_0"
RUN BOOST_RELEASE_URL="https://boostorg.jfrog.io/artifactory/main/release/$(echo ${BOOST_VERSION} | sed 's/_/\./g')/source/boost_${BOOST_VERSION}.tar.gz" && \
    curl -sNLk ${BOOST_RELEASE_URL} | tar zxf - -C "$HOME"

ARG LIBTORRENT_VERSION
RUN cd $HOME && \
    git clone --shallow-submodules --recurse-submodules https://github.com/arvidn/libtorrent.git $HOME/libtorrent && \
    cd $HOME/libtorrent && \
    if [ "${LIBTORRENT_VERSION}" = "v2-latest" ]; then \
      git checkout "$(git tag -l --sort=-v:refname "v2*" | head -n 1)" ; \
    elif [ "${LIBTORRENT_VERSION}" = "v1-latest" ]; then \
      git checkout "$(git tag -l --sort=-v:refname "v1*" | head -n 1)" ; \
    else \
      git checkout v"${LIBTORRENT_VERSION}" ; \
    fi && \
    cmake \
      -Wno-dev \
      -G Ninja \
      -B build \
      -D CMAKE_BUILD_TYPE="Release" \
      -D CMAKE_CXX_STANDARD=17 \
      -D BOOST_INCLUDEDIR="$HOME/boost_${BOOST_VERSION}/" \
      -D CMAKE_INSTALL_LIBDIR="lib" \
      -D CMAKE_INSTALL_PREFIX="/usr/local" && \
    cmake --build build --parallel $(nproc) && \
    cmake --install build

ARG CACHEBUST=1
ARG QBT_VERSION
RUN cd $HOME && echo ${CACHEBUST} && \
    if [[ "${QBT_VERSION}" = "master" ]] ; then \
      QBT_DIR="qBittorrent-${QBT_VERSION}" && \
      QBT_URL="https://github.com/qbittorrent/qBittorrent/archive/refs/heads/${QBT_VERSION}.tar.gz" ; \
    elif [[ "${QBT_VERSION}" = "v4_4_x" || "${QBT_VERSION}" = "v4_3_x" ]] ; then \
      QBT_DIR="qBittorrent-${QBT_VERSION:1}" && \
      QBT_URL="https://github.com/qbittorrent/qBittorrent/archive/refs/heads/${QBT_VERSION}.tar.gz" ; \
    else \
      QBT_DIR="qBittorrent-release-${QBT_VERSION}" && \
      QBT_URL="https://github.com/qbittorrent/qBittorrent/archive/refs/tags/release-${QBT_VERSION}.tar.gz" ; \
    fi && \
    curl -sNLk ${QBT_URL} | tar -zxf - -C "$HOME" && \
    cd "$HOME/${QBT_DIR}" && \
    cmake \
      -B build \
      -G Ninja \
      -D CMAKE_BUILD_TYPE="release" \
      -D CMAKE_CXX_STANDARD=17 \
      -D CMAKE_BUILD_TYPE=RelWithDebInfo \
      -D BOOST_INCLUDEDIR="$HOME/boost_${BOOST_VERSION}/" \
      -D CMAKE_CXX_STANDARD_LIBRARIES="/usr/lib/libexecinfo.so" \
      -D CMAKE_INSTALL_PREFIX="/usr/local" \
      -D QBT_VER_STATUS= \
      -D GUI=OFF \
      -D QT6=ON \
      -D STACKTRACE=OFF && \
    cmake --build build --parallel $(nproc) && \
    cmake --install build

# image for running
FROM alpine:latest

ARG QT_VERSION="qt6"
RUN apk --no-cache add \
      doas \
      python3 \
      ${QT_VERSION}-qtbase \
      tini

RUN adduser \
      -D \
      -H \
      -s /sbin/nologin \
      -u 1000 \
      qbtUser && \
    echo "permit nopass :root" >> "/etc/doas.d/doas.conf"

COPY --from=builder /usr/local/lib/libtorrent-rasterbar* /usr/local/lib/
COPY --from=builder /usr/local/bin/qbittorrent-nox /usr/bin/qbittorrent-nox

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/sbin/tini", "-g", "--", "/entrypoint.sh"]
