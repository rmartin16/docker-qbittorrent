########################################################
#
# Builds qBittorrent v4.3.0+
#
########################################################
FROM alpine:3.17.0 AS qbittorrent-base

RUN apk --update-cache add \
      automake \
      build-base \
      cmake \
      curl \
      git \
      icu-dev \
      libtool \
      linux-headers \
      patch \
      perl \
      pkgconf \
      python3 \
      python3-dev \
      qt5-qtbase-dev \
      qt5-qttools-dev \
      qt6-qtbase-dev \
      qt6-qttools-dev \
      openssl-dev \
      re2c \
      tar \
      zlib-dev && \
    apk add  && \
    # Add back to normal install once libexecinfo-dev is available for v3.17
    apk add libexecinfo-dev --repository=http://dl-cdn.alpinelinux.org/alpine/v3.16/main

ENV BASE_PATH="/build"

COPY downloads/* ${BASE_PATH}/downloads/
COPY patches/* ${BASE_PATH}/patches/
COPY scripts/* ${BASE_PATH}/scripts/

ARG BOOST_VERSION="1_76_0"
ENV BOOST_DIR="${BASE_PATH}/boost"
ARG LIBTORRENT_VERSION

RUN ${BASE_PATH}/scripts/install_ninja.sh "${BASE_PATH}"
RUN ${BASE_PATH}/scripts/install_boost.sh "${BASE_PATH}" "${BOOST_VERSION}"
RUN ${BASE_PATH}/scripts/install_libtorrent.sh "${BASE_PATH}" "${LIBTORRENT_VERSION}" "${BOOST_DIR}"

RUN rm -rf ${BASE_PATH}/downloads/


FROM qbittorrent-base AS qbittorrent-build

ARG QBT_VERSION
ARG QBT_BUILD_TYPE

RUN ${BASE_PATH}/scripts/install_qbittorrent.sh "${BASE_PATH}" "${QBT_VERSION}" "${QBT_BUILD_TYPE}" "${BOOST_DIR}"


FROM alpine:3.17.0 AS release

ARG QT_VERSION="qt6"
RUN apk --no-cache add doas python3 tini ${QT_VERSION}-qtbase && \
    adduser -D -H -s /sbin/nologin -u 1000 qbtuser && \
    echo "permit nopass :root" >> "/etc/doas.d/doas.conf"

COPY --from=qbittorrent-build /usr/lib/libexecinfo.so* /usr/lib/
COPY --from=qbittorrent-build /usr/local/lib/libtorrent-rasterbar* /usr/local/lib/
COPY --from=qbittorrent-build /usr/local/bin/qbittorrent-nox /usr/bin/qbittorrent-nox

COPY assets/entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/sbin/tini", "-g", "--", "/entrypoint.sh"]
