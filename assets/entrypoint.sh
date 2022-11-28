#!/bin/sh

DOWNLOADS_PATH="/downloads"
PROFILE_PATH="/config"
QBT_CONFIG_FILE="${PROFILE_PATH}/qBittorrent/config/qBittorrent.conf"

if [ ! -f "${QBT_CONFIG_FILE}" ]; then
    mkdir -p "$(dirname ${QBT_CONFIG_FILE})"
    cat << EOF > "${QBT_CONFIG_FILE}"
[BitTorrent]
Session\DefaultSavePath=${DOWNLOADS_PATH}
Session\Port=6881
Session\TempPath=${DOWNLOADS_PATH}/temp
[LegalNotice]
Accepted=false
EOF

    if [ "$QBT_EULA" = "accept" ]; then
        sed -i '/^\[LegalNotice\]$/{$!{N;s|\(\[LegalNotice\]\nAccepted=\).*|\1true|}}' "${QBT_CONFIG_FILE}"
    else
        sed -i '/^\[LegalNotice\]$/{$!{N;s|\(\[LegalNotice\]\nAccepted=\).*|\1false|}}' "${QBT_CONFIG_FILE}"
    fi
fi

# those are owned by root by default
# don't change existing files owner in `$DOWNLOADS_PATH`
mkdir -p "${DOWNLOADS_PATH}"
mkdir -p "${PROFILE_PATH}"
chown qbtuser:qbtuser "${DOWNLOADS_PATH}"
chown qbtuser:qbtuser -R "${PROFILE_PATH}"

doas -u qbtuser \
    qbittorrent-nox \
        --profile="${PROFILE_PATH}" \
        --webui-port="${QBT_WEBUI_PORT:=8080}" \
        "$@"
