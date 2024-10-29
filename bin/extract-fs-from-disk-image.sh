#!/bin/bash
DISK_IMAGE=$1
FS_LOCATION=$2

if [[ ! -f "$DISK_IMAGE" ]]
then
    echo "Cannot find disk image."
    echo "Usage:"
    echo "$0 <full disk image> <[directory for fs image | full path for fs image]>"
    exit 1
fi

if [[ -d "$FS_LOCATION" ]]
then
    FS_LOCATION=${FS_LOCATION}/rootfs-raw.img
fi

dd if=${DISK_IMAGE} of=${FS_LOCATION} skip=2048
