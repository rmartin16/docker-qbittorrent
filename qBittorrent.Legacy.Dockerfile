########################################################
#
# Builds qBittorrent v4.1.0 thru v4.2.5 from existing base image
#
########################################################
ARG LIBTORRENT_TAG="v1"
FROM ghcr.io/rmartin16/qbittorrent-base:legacy-libtorrent-${LIBTORRENT_TAG} AS qbittorrent-build

ENV BASE_PATH="/build"

ARG QBT_VERSION
ARG QBT_BUILD_TYPE="release"

RUN ${BASE_PATH}/scripts/install_qbittorrent_legacy.sh "${BASE_PATH}" "${QBT_VERSION}" "${QBT_BUILD_TYPE}"


FROM ubuntu:22.04 AS release

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

COPY assets/entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/usr/bin/tini", "-g", "--", "/entrypoint.sh"]
