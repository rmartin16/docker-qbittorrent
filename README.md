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
    [ same for v4_5_x, v4_4_x, and v4_3_x ]

## Build

### Build Arguments

- `LIBTORRENT_VERSION`
  - Use `v1-latest` or `v2-latest` for the latest respective `libtorrent` version.
  - Or use a specific release name, e.g. `2.0.8` or `1.2.18`.
- `QBT_VERSION`
  - Version of qBittorrent to build, e.g. `4.5.0` or a dev branch like `v4_5_x` or `master`.
  - Alternatively, specify an arbitrary qBittorrent repo and ref.
- `QBT_REPO_URL`
  - Repo to use via `git clone`, e.g. `https://github.com/qbittorrent/qBittorrent`.
- `QBT_REPO_REF`
  - Repo reference to use via `git checkout` such as branch or tag name.
- `QBT_BUILD_TYPE`
  - Build type `release` or `debug`.

From an official qBittorrent release:

    docker buildx build \
        --load \
        --tag qbittorrent-nox:v4.5.0 \
        --build-arg LIBTORRENT_VERSION=v2-latest \
        --build-arg QT_VERSION=qt6 \
        --build-arg QBT_BUILD_TYPE=debug \
        --build-arg QBT_VERSION=4.5.0 \
        --file All.Dockerfile \
        $(pwd)

From an official qBittorrent dev branch:

    docker buildx build \
        --load \
        --tag qbittorrent-nox:v4.5.0 \
        --build-arg LIBTORRENT_VERSION=v2-latest \
        --build-arg QT_VERSION=qt6 \
        --build-arg QBT_BUILD_TYPE=debug \
        --build-arg QBT_VERSION=v4_5_x \
        --file All.Dockerfile \
        $(pwd)

From an arbitrary repo:

    docker buildx build \
        --load \
        --tag qbittorrent-nox:v4.5.0 \
        --build-arg LIBTORRENT_VERSION=v2-latest \
        --build-arg QT_VERSION=qt6 \
        --build-arg QBT_BUILD_TYPE=debug \
        --build-arg QBT_REPO_URL=https://github.com/user/repo \
        --build-arg QBT_REPO_REF=branch-name \
        --file All.Dockerfile \
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
        qbittorrent-nox:v4.5.0

<sub>Created primarily to facilitate automated testing for [qbittorrent-api](https://github.com/rmartin16/qbittorrent-api). Zero guarantees. Use at own risk.</sub>
