########################################################
#
# Builds qBittorrent v4.3.0+
#
########################################################
FROM alpine:3.21.5 AS qbittorrent-base

RUN apk --update-cache add \
      automake \
      boost-dev	\
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
      samurai \
      tar \
      zlib-dev

ENV BASE_PATH="/build"

COPY patches/* ${BASE_PATH}/patches/
COPY scripts/* ${BASE_PATH}/scripts/

ARG LIBTORRENT_VERSION
ARG QBT_BUILD_TYPE="release"

RUN ${BASE_PATH}/scripts/install_libtorrent.sh "${BASE_PATH}" "${LIBTORRENT_VERSION}" "${QBT_BUILD_TYPE}"


FROM qbittorrent-base AS qbittorrent-build

ARG QBT_REPO_URL="https://github.com/qbittorrent/qBittorrent"
ARG QBT_REPO_REF=""
ARG QBT_VERSION=""
ARG QBT_BUILD_TYPE="release"

RUN ${BASE_PATH}/scripts/install_qbittorrent.sh \
      "${BASE_PATH}" \
      "${QBT_VERSION}" \
      "${QBT_BUILD_TYPE}" \
      "${QBT_REPO_URL}" \
      "${QBT_REPO_REF}"

FROM alpine:3.21.5 AS release

ARG QT_VERSION="qt6"
ARG QBT_BUILD_TYPE="release"
RUN apk --no-cache add doas python3 tini ${QT_VERSION}-qtbase && \
    # debug images bundle binutils so Boost.Stacktrace's addr2line backend can
    # symbolize crashes; release images have stacktrace disabled and don't need it
    if [ "${QBT_BUILD_TYPE}" = "debug" ]; then apk --no-cache add binutils; fi && \
    adduser -D -H -s /sbin/nologin -u 1000 qbtuser && \
    echo "permit nopass :root" >> "/etc/doas.d/doas.conf"

COPY --from=qbittorrent-build /usr/local/lib/libtorrent-rasterbar* /usr/local/lib/
COPY --from=qbittorrent-build /usr/local/bin/qbittorrent-nox /usr/bin/qbittorrent-nox
COPY --from=qbittorrent-build /build_commit.* /

COPY assets/entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/sbin/tini", "-g", "--", "/entrypoint.sh"]
