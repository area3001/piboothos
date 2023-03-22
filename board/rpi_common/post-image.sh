#!/bin/bash

set -u
set -e

COMMON_BOARD_DIR="$(dirname $0)"

# Parse arguments and put into argument list of the script
opts="$(getopt -l "linuxdir:,rpi4" -o "l:34c" -- "$@")" || exit $?
eval set -- "$opts"

while true ; do
	case "$1" in
	--rpi4)
		BOARD_NAME=rpi4
		BOARD_DIR="${COMMON_BOARD_DIR}/../${BOARD_NAME}"
		shift
		;;
	--linuxdir)
		shift
		LINUX_DIR=$1
		shift
		;;
	--) shift ; break ;;
	*)
		die "unknown option '${1}'" ;;
	esac
done

GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"
RAUC_FOLDER="${BINARIES_DIR}/rauc"
VERSION=$(git --git-dir=${BR2_EXTERNAL_PIBOOTHOS_PATH}/.git --work-tree=${BR2_EXTERNAL_PIBOOTHOS_PATH}/ describe --tags --always --dirty --match "[0-9]*.[0-9]*.[0-9]*")
OTA_FILE="${BINARIES_DIR}/ota-${BOARD_NAME}-${VERSION}.raucb"

KEY="${BR2_EXTERNAL_PIBOOTHOS_PATH}/misc/dev-key.pem"
CERT="${BR2_EXTERNAL_PIBOOTHOS_PATH}/misc/dev-cert.pem"

# Adjust the config.txt
if [ -f ${BOARD_DIR}/config.txt ]; then
  cp "${BOARD_DIR}/config.txt" "${BINARIES_DIR}/rpi-firmware"
else
  cp "${COMMON_BOARD_DIR}/config.txt" "${BINARIES_DIR}/rpi-firmware"
fi

# compile and copy self-defined overlays
DTC=${LINUX_DIR}/scripts/dtc/dtc
if ! [ -x $DTC ]; then
    DTC=dtc
else
    echo "Using $DTC"
fi

# for DTS in ${COMMON_BOARD_DIR}/*-overlay.dts ${BOARD_DIR}/*-overlay.dts; do
for DTS in ${BOARD_DIR}/*-overlay.dts; do
    if [ ! -e "$DTS" ]; then continue; fi
    DTSNAME=`basename ${DTS%%-overlay.dts}`
    echo "Compile devicetree: $DTSNAME"
    cpp -nostdinc -I ${LINUX_DIR}/include -I ${LINUX_DIR}/arch -undef -x assembler-with-cpp $DTS ${BINARIES_DIR}/${DTSNAME}.prep
    $DTC -@ -O dtb ${BINARIES_DIR}/${DTSNAME}.prep -o ${BINARIES_DIR}/rpi-firmware/overlays/${DTSNAME}.dtbo
    #echo "dtoverlay=${DTSNAME}" >> ${BINARIES_DIR}/rpi-firmware/config.txt
done

# assemble boot files
BOOTFILES="rpi-firmware/config.txt rpi-firmware/overlays Image u-boot.bin boot.scr"
if [ "${BOARD_NAME}" = "rpi4" ]; then
    BOOTFILES+=" rpi-firmware/fixup4.dat rpi-firmware/start4.elf bcm2711-rpi-4-b.dtb"
fi

# add wpa_supplicant.conf if data is specified
rm -f "${BINARIES_DIR}/wpa_supplicant.conf*"
if [ ! -z "${WIFI_SETTINGS_SSID:-}" ] && [ ! -z "${WIFI_SETTINGS_PASSWORD:-}" ]; then
    echo "Create wpa_supplicant.conf for SSID ${WIFI_SETTINGS_SSID}"
    (
        echo "country=be"
        echo "update_config=1"
        echo "ap_scan=1"
        echo "ctrl_interface=/var/run/wpa_supplicant"
        echo ""
        echo "network={"
        echo "  ssid=\"${WIFI_SETTINGS_SSID}\""
        echo "  psk=\"${WIFI_SETTINGS_PASSWORD}\""
        echo "}"
    ) > "${BINARIES_DIR}/wpa_supplicant.conf"
    BOOTFILES+=" wpa_supplicant.conf"
else
    echo "No wifi credentials specified. Adding template file."
    (
        echo "# Adjust this file and rename it to /boot/wpa_supplicant.conf"
        echo "country=be"
        echo "update_config=1"
        echo "ap_scan=1"
        echo "ctrl_interface=/var/run/wpa_supplicant"
        echo ""
        echo "network={"
        echo "  ssid=\"Your Wifi SSID here\""
        echo "  psk=\"Your Wifi password here\""
        echo "}"
    ) > "${BINARIES_DIR}/wpa_supplicant.conf.template"
    BOOTFILES+=" wpa_supplicant.conf.template"
fi

# cleanup genimage files
rm -rf "${GENIMAGE_TMP}"
rm -f "${BINARIES_DIR}/genimage-*.cfg"

# create a genimage from the boot files
cp "${COMMON_BOARD_DIR}/genimage-template.cfg" "${BINARIES_DIR}/genimage-${BOARD_NAME}.cfg"
for BOOTFILE in ${BOOTFILES}; do
    sed -i "/.*files = {.*/a \      \"${BOOTFILE}\"," "${BINARIES_DIR}/genimage-${BOARD_NAME}.cfg"
done

# create SD card image
genimage                           \
    --rootpath "${TARGET_DIR}"     \
    --tmppath "${GENIMAGE_TMP}"    \
    --inputpath "${BINARIES_DIR}"  \
    --outputpath "${BINARIES_DIR}" \
    --config "${BINARIES_DIR}/genimage-${BOARD_NAME}.cfg"

# create rauc update file
rm -rf "${RAUC_FOLDER}" ${BINARIES_DIR}/ota-*.raucb
mkdir -p "${RAUC_FOLDER}"

# create boot.tar.xz for rauc
tar -C ${BINARIES_DIR} --pax-option=exthdr.name=%%d/PaxHeaders/%%f,atime:=0,ctime:=0 -cf - --null --xattrs-include='\''*'\'' --no-recursion -T - --numeric-owner)\n' --transform='flags=r;s|rpi-firmware/||' ${BOOTFILES} | xz -9 -C crc32 -c -T 13 > ${RAUC_FOLDER}/boot.tar.xz

# copy rootfs image
cp -f "${BINARIES_DIR}/rootfs.tar.xz" "${RAUC_FOLDER}/rootfs.tar.xz"

# copy rauc install hook script
cp -f "${BR2_EXTERNAL_PIBOOTHOS_PATH}/misc/rauc-hook" "${RAUC_FOLDER}/hook"

(
    echo "[update]"
    echo "compatible=piboothos_${BOARD_NAME}"
    echo "version=${VERSION}"
    echo "[hooks]"
    echo "filename=hook"
    echo "[image.boot]"
    echo "filename=boot.tar.xz"
    echo "hooks=install"
    echo "[image.rootfs]"
    echo "filename=rootfs.tar.xz"
) > "${RAUC_FOLDER}/manifest.raucm"

rauc bundle -d --cert="${CERT}" --key="${KEY}" "${RAUC_FOLDER}/" "${OTA_FILE}"
