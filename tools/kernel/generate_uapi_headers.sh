#!/bin/bash

###  Usage: generate_uapi_headers.sh [<options>]
###
###  This script is used to get a copy of the uapi kernel headers
###  from an linux kernel tree and copies them into an Yudatun source
###  tree without any processing. The script also creates all of the
###  generated headers and copies them into the Yudatun source tree.
###
###  Options:
###   --download-kernel
###     Automatically create a temporary git repository and check out the
###     Android kernel source code.
###
###   --use-kernel-dir <DIR>
###     Do not check out the kernel source, use the kernel directory
###     pointed to by <DIR>.
###
###   --arch <arch>
###     The architecture of the kernel headers.
###

# Terminate the script if any command fails
set -eE

TMPDIR=""
KERNEL_VERSION="kernel_linux-4.3"
KERNEL_DIR="."
KERNEL_DOWNLOAD=0
YUDATUN_KERNEL_DIR="thirdparty/kernel-headers/original/uapi"

arch="arm"

function cleanup () {
    if [[ "${TMPDIR}" =~ /tmp ]] && [[ -d "${TMPDIR}" ]]; then
        echo "Removing temporary directory ${TMPDIR}"
        rm -rf "${TMPDIR}"
        TMPDIR=""
    fi
}

function usage()
{
    grep '^###' $0 | sed -e 's/^###//'
}

function copy_hdrs()
{
    local src_dir=$1
    local tgt_dir=$2
    local dont_copy_dirs=$3

    mkdir -p ${tgt_dir}

    local search_dirs=()

    # This only works if none of the filenames have spaces.
    for file in $(ls -d ${src_dir}/* 2> /dev/null); do
        if [[ -d "${file}" ]]; then
            search_dirs+=("${file}")
        elif [[ -f  "${file}" ]] && [[ "${file}" =~ .h$ ]]; then
            cp ${file} ${tgt_dir}
        fi
    done

    if [[ "${dont_copy_dirs}" == "" ]]; then
        for dir in "${search_dirs[@]}"; do
            copy_hdrs "${dir}" ${tgt_dir}/$(basename ${dir})
        done
    fi
}

trap cleanup EXIT
# This automatically triggers a call to cleanup.
trap "exit 1" HUP INT TERM TSTP

while [ $# -gt 0 ] ; do
    case "$1" in
        "--download-kernel")
            KERNEL_DOWNLOAD=1
            ;;
        "--use-kernel-dir")
            if [[ $# -lt 2 ]]; then
                echo "--use-kernel-dir requires an argument."
                exit 1
            fi
            shift
            KERNEL_DIR="$1"
            KERNEL_DOWNLOAD=0
            ;;
        "--arch")
            if [[ $# -lt 2 ]]; then
                echo "--arch requires an argument."
                exit 1
            fi
            shift
            arch="$1"
            ;;
        "-h" | "--help")
            usage
            exit 1
            ;;
        "-"*)
            echo "Error: Unrecognized option $1"
            usage
            exit 1
            ;;
        *)
            echo "Error: Extra arguments on the command-line."
            usage
            exit 1
            ;;
    esac
    shift
done

YUDATUN_KERNEL_DIR="${YUDATUN_BUILD_TOP}/${YUDATUN_KERNEL_DIR}/${arch}"
mkdir -p ${YUDATUN_KERNEL_DIR}
if [[ "${YUDATUN_BUILD_TOP}" == "" ]]; then
    echo "YUDATUN_BUILD_TOP is not set, did you run lunch?"
    exit 1
elif [[ ! -d "${YUDATUN_KERNEL_DIR}" ]]; then
    echo "${YUDATUN_BUILD_TOP} doesn't appear to be the root of an yudatun tree."
    echo "  ${YUDATUN_KERNEL_DIR} is not a directory."
    exit 1
fi

if [[ ${KERNEL_DOWNLOAD} -eq 1 ]]; then
    TMPDIR=$(mktemp -d /tmp/yudatun_kernelXXXXXXXX)
    echo "Fetching Yudatun kernel source ${KERNEL_VERSION}"
    git clone https://github.com/yudatun/kernel_linux-4.3.git ${TMPDIR}
    KERNEL_DIR="${TMPDIR}"
elif [[ "${KERNEL_DIR}" == "" ]]; then
    echo "Must specify one of --use-kernel-dir or --download-kernel."
    exit 1
elif [[ ! -d "${KERNEL_DIR}" ]]; then
    echo "The kernel directory $KERNEL_DIR does not exist."
    exit 1
fi

# Build all of the generated headers.
echo "Generating headers for arch ${arch}"
make ARCH=${arch} -C ${KERNEL_DIR} O=${YUDATUN_KERNEL_DIR} headers_install

# Delete some not used files
rm -r ${YUDATUN_KERNEL_DIR}/arch
rm -r ${YUDATUN_KERNEL_DIR}/include
rm -r ${YUDATUN_KERNEL_DIR}/scripts

copy_hdrs ${YUDATUN_KERNEL_DIR}/usr/include ${YUDATUN_KERNEL_DIR}

rm -r ${YUDATUN_KERNEL_DIR}/usr

echo "Install kernel headers Done!"
