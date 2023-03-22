# Add piboothos sw version to /etc/os-release
VERSION=$(git --git-dir=../.git --work-tree=../ describe --tags --always --dirty --match "[0-9]*.[0-9]*.[0-9]*")
DATE=$(d="$(git --git-dir=../.git log --date=iso --pretty=%ad -1)"; date --iso-8601=seconds --date="$d")

echo "Building version: ${VERSION} of date ${DATE}"
echo "PIBOOTHOS_VERSION=${VERSION}" >> "$TARGET_DIR/etc/os-release" 2> /dev/null
echo "PIBOOTHOS_DATE=${DATE}" >> "$TARGET_DIR/etc/os-release" 2> /dev/null
