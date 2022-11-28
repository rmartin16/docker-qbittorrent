########################################################
#
# Builds qBittorrent v4.3.0+ from base image
#
########################################################
ARG LIBTORRENT_TAG="v2"
FROM ghcr.io/rmartin16/qbittorrent-base:libtorrent-${LIBTORRENT_TAG} AS qbittorrent-build

ENV BASE_PATH="/build"

ARG QBT_VERSION
ARG QBT_BUILD_TYPE
ENV BOOST_DIR="${BASE_PATH}/boost"

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
