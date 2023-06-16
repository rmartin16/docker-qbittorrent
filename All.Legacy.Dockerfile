########################################################
#
# Builds qBittorrent v4.1.0 thru v4.2.5
#
########################################################
FROM ubuntu:23.10 AS qbittorrent-base

ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && \
    apt install --no-install-recommends -y \
      automake \
      build-essential \
      ca-certificates \
      cmake \
      curl \
      git \
      libssl-dev \
      libgeoip-dev\
      libtool \
      libboost-dev \
      libboost-system-dev \
      libboost-chrono-dev \
      libboost-random-dev \
      ninja-build \
      pkg-config \
      qtbase5-dev \
      qttools5-dev \
      libqt5svg5-dev \
      zlib1g-dev

ENV BASE_PATH="/build"

COPY patches/* ${BASE_PATH}/patches/
COPY scripts/* ${BASE_PATH}/scripts/

ARG LIBTORRENT_VERSION

RUN ${BASE_PATH}/scripts/install_libtorrent_legacy.sh "${BASE_PATH}" "${LIBTORRENT_VERSION}"


FROM qbittorrent-base AS qbittorrent-build

ARG QBT_VERSION
ARG QBT_BUILD_TYPE="release"

RUN ${BASE_PATH}/scripts/install_qbittorrent_legacy.sh "${BASE_PATH}" "${QBT_VERSION}" "${QBT_BUILD_TYPE}"


FROM ubuntu:23.10 AS release

ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && \
    apt install --no-install-recommends -y \
      doas \
      python3 \
      qtbase5-dev \
      tini && \
    addgroup qbtuser --force-badname && \
    adduser \
      --quiet \
      --system \
      --disabled-password \
      --force-badname \
      --no-create-home \
      --shell /usr/sbin/nologin \
      -u 1000 \
      qbtuser && \
    echo "permit nopass :root" >> "/etc/doas.conf"

COPY --from=qbittorrent-build /usr/local/lib/libtorrent-rasterbar* /usr/local/lib/
COPY --from=qbittorrent-build /usr/local/bin/qbittorrent-nox /usr/bin/qbittorrent-nox
COPY --from=qbittorrent-build /build_commit.* /

COPY assets/entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/usr/bin/tini", "-g", "--", "/entrypoint.sh"]
