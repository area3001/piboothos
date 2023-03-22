#!/bin/sh
set -e

function mark_good() {
    rauc status mark-good
    exit 0
}

mark_good