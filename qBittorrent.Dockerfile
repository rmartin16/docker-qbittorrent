########################################################
#
# Builds qBittorrent v4.3.0+ using existing base image
#
########################################################
ARG LIBTORRENT_TAG="v2"
FROM ghcr.io/rmartin16/qbittorrent-base:libtorrent-${LIBTORRENT_TAG} AS qbittorrent-build

ENV BASE_PATH="/build"

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


FROM alpine:3.21.4 AS release

ARG QT_VERSION="qt6"
RUN apk --no-cache add doas python3 tini ${QT_VERSION}-qtbase && \
    adduser -D -H -s /sbin/nologin -u 1000 qbtuser && \
    echo "permit nopass :root" >> "/etc/doas.d/doas.conf"

COPY --from=qbittorrent-build /usr/lib/libexecinfo.so* /usr/lib/
COPY --from=qbittorrent-build /usr/local/lib/libtorrent-rasterbar* /usr/local/lib/
COPY --from=qbittorrent-build /usr/local/bin/qbittorrent-nox /usr/bin/qbittorrent-nox
COPY --from=qbittorrent-build /build_commit.* /

COPY assets/entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/sbin/tini", "-g", "--", "/entrypoint.sh"]
