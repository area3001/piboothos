#!/bin/bash
# shellcheck disable=SC2155

set -u
set -e

for arg in "$@"
do
  case "${arg}" in
    --rpi4)
    BOARD_NAME=rpi4
    ;;
  esac
done

# set compatible string
if [ -e ${TARGET_DIR}/etc/rauc/system.conf ]; then
  sed -i "/compatible=/c\compatible=piboothos_${BOARD_NAME}" ${TARGET_DIR}/etc/rauc/system.conf
fi

# copy rauc keyring
cp "${BR2_EXTERNAL_PIBOOTHOS_PATH}/misc/dev-cert.pem" "${TARGET_DIR}/etc/rauc/keyring.pem"

# Add a console on tty1
if [ -e ${TARGET_DIR}/etc/inittab ]; then
    grep -qE '^tty1::' ${TARGET_DIR}/etc/inittab || \
      sed -i '/GENERIC_SERIAL/a\
tty1::respawn:/sbin/getty -L  tty1 0 vt100 # HDMI console' ${TARGET_DIR}/etc/inittab
fi

# add boot partition mount
if [ -e ${TARGET_DIR}/etc/fstab ]; then
    grep -qE '^/dev/mmcblk0p1' ${TARGET_DIR}/etc/fstab || \
      echo '/dev/mmcblk0p1	/boot	vfat	defaults,ro	0	0' >> ${TARGET_DIR}/etc/fstab
    # add configfs mount
    if [ "${BOARD_NAME}" = "rpi4" ]; then
        echo "adding configfs mount"
        grep -qE '^configfs' ${TARGET_DIR}/etc/fstab || \
          echo 'configfs	/sys/kernel/config	configfs	defaults	0	0' >> ${TARGET_DIR}/etc/fstab
    fi
fi

# configure the SSH security
if [ ! -z "${SECURE_SSH_PUBKEY_PATH:-}" ]; then
    echo "SSH public key specified: ${SECURE_SSH_PUBKEY_PATH}"
    for DIR in /root; do
        install -D -m 0600 ${SECURE_SSH_PUBKEY_PATH} \
          "${TARGET_DIR}${DIR}/.ssh/authorized_keys"
    done
else
    echo ">>>> WARNING: no authorized_keys for SSH set up!"
fi