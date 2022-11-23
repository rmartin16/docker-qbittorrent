########################################################
#
# Builds qBittorrent v4.3.0+
#
########################################################
FROM alpine:3.16.3 AS builder

ENV BASEPATH="/build"

RUN apk --update-cache add \
      automake \
      build-base \
      cmake \
      curl \
      git \
      icu-dev \
      libexecinfo-dev \
      libtool \
      linux-headers \
      patch \
      perl \
      pkgconf \
      python3 \
      python3-dev \
      openssl-dev \
      re2c \
      tar \
      zlib-dev

ARG QT_VERSION="qt6"
RUN apk add ${QT_VERSION}-qtbase-dev ${QT_VERSION}-qttools-dev

WORKDIR "${BASEPATH}"
COPY ./downloads/* ./
COPY ./patches/* ./patches/

WORKDIR "${BASEPATH}"
RUN git clone --shallow-submodules --recurse-submodules https://github.com/ninja-build/ninja.git "${BASEPATH}/ninja"
WORKDIR "${BASEPATH}/ninja"
RUN git checkout "$(git tag -l --sort=-v:refname "v*" | head -n 1)" && \
    cmake -Wno-dev -B build \
      -D CMAKE_CXX_COMPILER=/usr/bin/g++ \
      -D CMAKE_C_COMPILER=/usr/bin/gcc \
      -D CMAKE_CXX_STANDARD=17 \
	  -D CMAKE_INSTALL_PREFIX="/usr/local" && \
    cmake --build build --parallel $(nproc) && \
    cmake --install build

WORKDIR "${BASEPATH}"
ARG BOOST_VERSION="1_76_0"
RUN if [[ ! -f "boost_${BOOST_VERSION}.tar.gz" ]]; then \
      BOOST_RELEASE_URL="https://boostorg.jfrog.io/artifactory/main/release/$(echo ${BOOST_VERSION} | sed 's/_/\./g')/source/boost_${BOOST_VERSION}.tar.gz" && \
      curl -NLk ${BOOST_RELEASE_URL} -o "boost_${BOOST_VERSION}.tar.gz" ; \
    fi && \
    tar zxf "boost_${BOOST_VERSION}.tar.gz" -C "${BASEPATH}"

WORKDIR "${BASEPATH}"
ARG LIBTORRENT_VERSION
RUN git clone --shallow-submodules --recurse-submodules https://github.com/arvidn/libtorrent.git "${BASEPATH}/libtorrent"
WORKDIR "${BASEPATH}/libtorrent"
RUN if [ "${LIBTORRENT_VERSION}" = "v2-latest" ]; then \
      git checkout "$(git tag -l --sort=-v:refname "v2*" | head -n 1)" ; \
    elif [ "${LIBTORRENT_VERSION}" = "v1-latest" ]; then \
      git checkout "$(git tag -l --sort=-v:refname "v1*" | head -n 1)" ; \
    else \
      git checkout v"${LIBTORRENT_VERSION}" ; \
    fi && \
    cmake -Wno-dev -G Ninja -B build \
      -D CMAKE_BUILD_TYPE="Release" \
      -D CMAKE_CXX_STANDARD=17 \
      -D BOOST_INCLUDEDIR="${BASEPATH}/boost_${BOOST_VERSION}/" \
      -D CMAKE_INSTALL_LIBDIR="lib" \
      -D CMAKE_INSTALL_PREFIX="/usr/local" && \
    cmake --build build --parallel $(nproc) && \
    cmake --install build

WORKDIR "${BASEPATH}"
ARG CACHEBUST=1
ARG QBT_VERSION
RUN echo ${CACHEBUST} && \
    case ${QBT_VERSION} in \
      master) \
        QBT_DIR="qBittorrent-${QBT_VERSION}" && \
        QBT_URL="https://github.com/qbittorrent/qBittorrent/archive/refs/heads/${QBT_VERSION}.tar.gz" ;; \
      v4_5_x | v4_4_x | v4_3_x) \
        QBT_DIR="qBittorrent-${QBT_VERSION:1}" && \
        QBT_URL="https://github.com/qbittorrent/qBittorrent/archive/refs/heads/${QBT_VERSION}.tar.gz" ;; \
      *) \
        QBT_DIR="qBittorrent-release-${QBT_VERSION}" && \
        QBT_URL="https://github.com/qbittorrent/qBittorrent/archive/refs/tags/release-${QBT_VERSION}.tar.gz" ;; \
    esac && \
    curl -sNLk ${QBT_URL} | tar -zxf - -C "${BASEPATH}" && \
    mv "${BASEPATH}/${QBT_DIR}" "${BASEPATH}/qBittorrent"
# https://github.com/qbittorrent/qBittorrent/issues/13981#issuecomment-746836281
RUN if [[ "${QBT_VERSION}" = "4.3.0" || "${QBT_VERSION}" = "4.3.0.1" || "${QBT_VERSION}" = "4.3.1" ]] ; then \
        patch "${BASEPATH}/qBittorrent/src/base/bittorrent/session.cpp" "${BASEPATH}/patches/libtorrent_2_compat_early_4.3.0.patch" ; \
    fi
WORKDIR "${BASEPATH}/qBittorrent"
ARG QBT_BUILD_TYPE="release"
RUN cmake -Wno-dev -Wno-deprecated -B build -G Ninja \
      -D CMAKE_BUILD_TYPE=${QBT_BUILD_TYPE} \
      -D CMAKE_CXX_STANDARD=17 \
      -D BOOST_INCLUDEDIR="${BASEPATH}/boost_${BOOST_VERSION}/" \
      -D Boost_NO_BOOST_CMAKE=TRUE \
      -D CMAKE_CXX_STANDARD_LIBRARIES="/usr/lib/libexecinfo.so" \
      -D CMAKE_INSTALL_PREFIX="/usr/local" \
      -D QBT_VER_STATUS= \
      -D GUI=OFF \
      -D QT6=ON \
      -D STACKTRACE=OFF \
      -D VERBOSE_CONFIGURE=ON && \
    cmake --build build --parallel $(nproc) && \
    cmake --install build


FROM alpine:3.16.3

ARG QT_VERSION="qt6"
RUN apk --no-cache add doas python3 tini ${QT_VERSION}-qtbase && \
    adduser -D -H -s /sbin/nologin -u 1000 qbtUser && \
    echo "permit nopass :root" >> "/etc/doas.d/doas.conf"

COPY --from=builder /usr/local/lib/libtorrent-rasterbar* /usr/local/lib/
COPY --from=builder /usr/local/bin/qbittorrent-nox /usr/bin/qbittorrent-nox

COPY assets/entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/sbin/tini", "-g", "--", "/entrypoint.sh"]
