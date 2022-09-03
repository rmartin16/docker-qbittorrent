# docker-qbittorrent
Build images for qBittorrent `v4.1.0+`. Uses `qt6` for `v4.4.0+`.

## tl;dr
    docker run \
        --name qbittorrent-nox \
        --detach \
        --publish 8080:8080 \
        --publish 6881:6881/tcp \
        --publish 6881:6881/udp \
        --env QBT_EULA=accept \
        --volume "$(pwd)/config:/config" \
        --volume "$(pwd)/downloads:/downloads" \
        ghcr.io/rmartin16/qbittorrent-nox

Open qBittorrent WebUI at http://localhost:8080

## Release Images
Latest qBittorrent Release

    docker pull ghcr.io/rmartin16/qbittorrent-nox:latest     # latest libtorrent v2.x.x
    docker pull ghcr.io/rmartin16/qbittorrent-nox:latest-v1  # latest libtorrent v1.x.x

Arbitrary qBittorrent Release

    docker pull ghcr.io/rmartin16/qbittorrent-nox:v4.x.x     # latest libtorrent v2.x.x
    docker pull ghcr.io/rmartin16/qbittorrent-nox:v4.x.x-v1  # latest libtorrent v1.x.x

Arbitrary Debug qBittorrent Release

    docker pull ghcr.io/rmartin16/qbittorrent-nox:latest-debug     # latest libtorrent v2.x.x
    docker pull ghcr.io/rmartin16/qbittorrent-nox:latest-v1-debug  # latest libtorrent v1.x.x
    docker pull ghcr.io/rmartin16/qbittorrent-nox:v4.x.x-debug     # latest libtorrent v2.x.x
    docker pull ghcr.io/rmartin16/qbittorrent-nox:v4.x.x-v1-debug  # latest libtorrent v1.x.x

qBittorrent dev branches

    docker pull ghcr.io/rmartin16/qbittorrent-nox:master
    docker pull ghcr.io/rmartin16/qbittorrent-nox:master-v2
    docker pull ghcr.io/rmartin16/qbittorrent-nox:master-v2-debug
    docker pull ghcr.io/rmartin16/qbittorrent-nox:master-v1
    docker pull ghcr.io/rmartin16/qbittorrent-nox:master-v1-debug
    [ same for v4_4_x and v4_3_x ]

## Build
    docker buildx build \
        --load \
        --tag qbittorrent-nox:v4.4.5 \
        --build-arg BOOST_VERSION=1_76_0 \
        --build-arg LIBTORRENT_VERSION=v2-latest \
        --build-arg QT_VERSION=qt6 \
        --build-arg QBT_VERSION=4.4.5 \
        --build-arg QBT_RELEASE_TYPE=debug \
        $(pwd)

## Run
    docker run \
        --name qbittorrent-nox \
        --detach \
        --publish 8080:8080 \
        --publish 6881:6881/tcp \
        --publish 6881:6881/udp \
        --env QBT_EULA=accept \
        --volume "$(pwd)/config:/config" \
        --volume "$(pwd)/downloads:/downloads" \
        qbittorrent-nox:v4.4.5

<sub>Created primarily to facilitate automated testing for [qbittorrent-api](https://github.com/rmartin16/qbittorrent-api). Zero guarantees. Use at own risk.</sub>
