#
# Copyright (C) 2013 ~ 2015 The Yudatun Open Source Project
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation
#

########################################
# This is a build configuration for a
# very minimal build of the Open-Source
# part of the tree.

PRODUCT_PACKAGES := \
    ld-linux \
    libc \
    libm \
    libpthread \
    init \
    libcutils \
    busybox

# rc
PRODUCT_PACKAGES += \
    init.rc \
    ueventd.rc

# Host tools
PRODUCT_PACKAGES += \
    mkbootfs \
    flash
