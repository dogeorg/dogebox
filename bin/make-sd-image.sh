#!/bin/bash
WORK_DIR=${1:-nixos-arm64}
CWD=$(pwd)
IMAGE_FILE=${2:-sd-${WORK_DIR}-$(date +%Y%m%d).img}
IMAGE_SIZE=${3:-7617187}

pushd $WORK_DIR

for i in parameter.txt idbloader.img uboot.img
do
    if [[ ! -f $i ]]; then
        echo "Required file $i missing!"
        exit 1
    fi
done

declare -A partition_uuid=( 
    [uboot]='F808D051-1602-4DCD-9452-F9637FEFC49A'
    [misc]='C6D08308-E418-4124-8890-F8411E3D8D87'
    [dtbo]='2A583E58-486A-4BD4-ACE4-8D5454E97F5C'
    [resource]='6115F139-4F47-4BAF-8D23-B6957EAEE4B3'
    [kernel]='A83FBA16-D354-45C5-8B44-3EC50832D363'
    [boot]='500E2214-B72D-4CC3-D7C1-8419260130F5'
    [recovery]='E099DA71-5450-44EA-AA9F-1B771C582805'
    [rootfs]='AF12D156-5D5B-4EE3-B415-8D492CA12EA9'
);

dd if=/dev/zero of=${IMAGE_FILE} count=0 seek=${IMAGE_SIZE}
parted -s ${IMAGE_FILE} mklabel gpt
dd if=./idbloader.img of=${IMAGE_FILE} seek=64 conv=notrunc

PARTITION_NUMBER=1;
IN=$(cat parameter.txt | grep '^CMDLINE:' | cut -d: -f3);
IFS=, read -ra DATA <<< $IN

for i in "${DATA[@]}"; do
    partition_info=($(echo $i | sed -r 's/-/0x0/' | sed -r 's/(.*)\@(.*)\((.*)/\1 \2 \3/' | sed -r 's/\)//'))
    SIZE=$(( ${partition_info[0]} ))
    START=$(( ${partition_info[1]} ))
    NAME=${partition_info[2]}
    echo "${NAME} starting at ${START} with size ${SIZE}"

    if [[ $NAME == 'rootfs' ]]; then
        if [[ ! -f "rootfs-raw.img" ]]; then
            echo "Expanding sparse image for rootfs"
            simg2img rootfs.img rootfs-raw.img
        fi
        SIZE=$(POSIXLY_CORRECT=1 du --apparent-size rootfs-raw.img | cut -f1)
        echo "Actual size $SIZE"
        echo "Writing rootfs"
        dd if=rootfs-raw.img of=${IMAGE_FILE} seek=${START} conv=notrunc
    elif [[ -f "${NAME}.img" ]]; then
        echo "Writing ${NAME}.img to ${IMAGE_FILE}"
        dd if=${NAME}.img of=${IMAGE_FILE} seek=${START} conv=notrunc
    else
        echo "No image for ${NAME}, leaving empty"
    fi

    parted -s ${IMAGE_FILE} mkpart ${NAME} ${START}s $(( ${START} + ${SIZE} - 1 ))s
    parted -s ${IMAGE_FILE} type ${PARTITION_NUMBER} ${partition_uuid[$NAME]}

    PARTITION_NUMBER=$(( $PARTITION_NUMBER + 1 ))
done

popd
