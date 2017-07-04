#!/usr/bin/env bash

# This script requires:
#     apt install jq curl git

if [ -f OLD_VERSION ]; then
    source OLD_VERSION
else
    OLD_VERSION=0
fi
REBUILD=0

for TARGET in linux64 linux32; do
    if [ "${TARGET}" == "linux32" ]; then
        LPARCH="i386"
        # 32-bit Intel is not currently accessible via build.snapcraft.io
        # Skip for now.
        continue
    elif [ "${TARGET}" == "linux64" ]; then
        LPARCH="amd64"
    else
        echo "Unknown target, skipping."
        continue
    fi
    HTML="${LPARCH}.html"

    # Get the latest releases json
    curl -s http://update.gitter.im/${TARGET}/latest > "${HTML}"

    # Get the version from the tag_name and the download URL.
    DEB_URL=$(grep window.location.href "${HTML}" | cut -d'"' -f2)
    VERSION=$(echo "${DEB_URL}" | cut -d'_' -f2)
    DEB=$(basename "${DEB_URL}")
    rm -f "${HTML}" 2>/dev/null
    rm -f snap/snapcraft.yaml.new 2>/dev/null

    if [ "${OLD_VERSION}" != "${VERSION}" ] || [ ${REBUILD} -eq 1 ]; then
        echo "Detected ${LPARCH} ${VERSION}, which is different from ${OLD_VERSION}!"
        sed "s/VVV/${VERSION}/" snap/snapcraft.yaml.in > snap/snapcraft.yaml.new
        sed -i "s|UUU|${DEB_URL}|" snap/snapcraft.yaml.new
        sed -i "s|TTT|${TARGET}|" snap/snapcraft.yaml.new
        REBUILD=1
    else
        echo "No version change, still ${OLD_VERSION}. Stopping here."
    fi

    if [ ${REBUILD} -eq 1 ]; then
        mv snap/snapcraft.yaml.new snap/snapcraft.yaml
        echo "OLD_VERSION=${VERSION}" > OLD_VERSION
        git commit -m "${LPARCH} version bumped to ${VERSION}"
        git push
        if  [ "${LPARCH}" == "i386" ]; then
            echo "i386 and amd64 builds need discrete handling in some fashion."
        fi
    fi
done
