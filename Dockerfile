FROM alpine:latest AS builder

RUN apk --no-cache add \
      automake build-base cmake curl git libtool linux-headers perl pkgconf python3 python3-dev re2c tar \
      icu-dev libexecinfo-dev openssl-dev zlib-dev qt6-qtbase-dev qt6-qttools-dev qt5-qtbase-dev qt5-qttools-dev

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
RUN BOOST_RELEASE_URL="https://boostorg.jfrog.io/artifactory/main/release/$(echo $BOOST_VERSION | sed 's/_/\./g')/source/boost_$BOOST_VERSION.tar.gz" && \
    curl -sNLk $BOOST_RELEASE_URL | tar zxf - -C "$HOME"

ARG LIBTORRENT_VERSION
RUN cd $HOME && \
    git clone --shallow-submodules --recurse-submodules https://github.com/arvidn/libtorrent.git $HOME/libtorrent && \
    cd $HOME/libtorrent && \
    if [ "$LIBTORRENT_VERSION" = "v2-latest" ]; then \
      git checkout "$(git tag -l --sort=-v:refname "v2*" | head -n 1)" ; \
    elif [ "$LIBTORRENT_VERSION" = "v1-latest" ]; then \
      git checkout "$(git tag -l --sort=-v:refname "v1*" | head -n 1)" ; \
    else \
      git checkout v"$LIBTORRENT_VERSION" ; \
    fi && \
    cmake \
      -Wno-dev \
      -G Ninja \
      -B build \
      -D CMAKE_BUILD_TYPE="Release" \
      -D CMAKE_CXX_STANDARD=17 \
      -D BOOST_INCLUDEDIR="$HOME/boost_$BOOST_VERSION/" \
      -D CMAKE_INSTALL_LIBDIR="lib" \
      -D CMAKE_INSTALL_PREFIX="/usr/local" && \
    cmake --build build --parallel $(nproc) && \
    cmake --install build

ARG QBT_VERSION
RUN cd $HOME && \
    if [ "$QBT_VERSION" = "master" ]; then \
      QBT_URL="https://github.com/qbittorrent/qBittorrent/archive/refs/heads/master.tar.gz" && \
      curl -sNLK $QBT_URL | tar -zxf - -C "$HOME" && \
      cd qBittorrent-master ; \
    else \
      QBT_URL="https://github.com/qbittorrent/qBittorrent/archive/refs/tags/release-${QBT_VERSION}.tar.gz" && \
      curl -sNLk $QBT_URL | tar -zxf - -C "$HOME" && \
      cd "$HOME/qBittorrent-release-${QBT_VERSION}" ; \
    fi && \
    cmake \
      -B build \
      -G Ninja \
      -D CMAKE_BUILD_TYPE="release" \
      -D CMAKE_CXX_STANDARD=17 \
      -D CMAKE_BUILD_TYPE=RelWithDebInfo \
      -D BOOST_INCLUDEDIR="$HOME/boost_$BOOST_VERSION/" \
      -D CMAKE_CXX_STANDARD_LIBRARIES="/usr/lib/libexecinfo.so" \
      -D CMAKE_INSTALL_PREFIX="/usr/local" \
      -D QBT_VER_STATUS= \
      -DGUI=OFF \
      -DQT6=ON \
      -DSTACKTRACE=OFF && \
    cmake --build build --parallel $(nproc) && \
    cmake --install build

# image for running
FROM alpine:latest

RUN apk --no-cache add \
      doas \
      python3 \
      qt5-qtbase \
      qt6-qtbase \
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
