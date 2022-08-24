# docker-qbittorrent
Build images for qBittorrent `v4.3.0+`. Uses `qt6` for `v4.4.0+`.

## Build
    docker buildx build \
        --load \
        --tag qbittorrent-nox:v4.4.4-2.0.7 \
        --build-arg BOOST_VERSION=1_76_0 \
        --build-arg LIBTORRENT_VERSION=2.0.7 \
        --build-arg QBT_VERSION=4.4.4 \
        $(pwd)

## Run
    docker run \
        --name qbittorrent-nox-4.4.4-2.0.7 \
        --detach \
        --publish 8080:8080 \
        --publish 6881:6881/tcp \
        --publish 6881:6881/udp \
        --env QBT_EULA=accept \
        --volume "$(pwd)/config:/config" \
        --volume "$(pwd)/downloads:/downloads" \
        qbittorrent-nox:v4.4.4-2.0.7
