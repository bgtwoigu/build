#!/bin/bash
#
# Copyright (C) 2013 The Gotoos Open Source Project
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation
###########################################

DEV_SDB="/dev/sdb"
DEV_SDC="/dev/sdc"
DEV_MMCBLK0="/dev/mmcblk0"

function check_argv()
{
    if [ -z $1 ] ; then
        echo "usage: [sudo] ./sd_fusing.sh <SD Reader's device file>"
        return
    fi

    if [ $1 = $DEV_SDB ] ; then
        echo "fusing $1"
    elif [ $1 = $DEV_SDC ] ; then
        echo "fusing $1"
    elif [ $1 = $DEV_MMCBLK0 ] ; then
        echo "fusing $1"
    else
        echo "Unsupported SD reader"
        return
    fi

    if [ -b $1 ] ; then
        echo "$1 reader is identified."
    else
        echo "$1 is not identified."
        return
    fi
}

function main()
{
    check_argv $1
}

main $1