# make real directories
# Should be run after board/common/real-dirs.sh
function make_real_dir
{
  DIR="$1"

  if [ -h "${TARGET_DIR}${DIR}" ]; then
    echo "TARGET: replace ${TARGET_DIR}${DIR} as dir"
    rm -f "${TARGET_DIR}${DIR}"
    mkdir -p "${TARGET_DIR}${DIR}"
  fi

  if [ ! -d "${TARGET_DIR}${DIR}" ]; then
    echo "TARGET: create dir ${TARGET_DIR}${DIR}"
    mkdir -p "${TARGET_DIR}${DIR}"
  fi
}

make_real_dir /etc/dropbear
make_real_dir /etc/docker
make_real_dir /var/log
make_real_dir /var/lock
make_real_dir /boot
