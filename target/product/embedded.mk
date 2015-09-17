#
# Copyright (C) 2013 The Yudatun Open Source Project
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation
#

# -----------------------------------------------------------------------
# This is a build configuration for a very minimal build of the
# Open-Source part of the tree.

LIBC_CORE := \
    libc \

PRODUCT_PACKAGES := \
    $(LIBC_CORE) \
    libcutils \
    init \

RC_FILES := \
    init.rc \
    ueventd.rc \

PRODUCT_PACKAGES += $(RC_FILES)

HOST_TOOLS := \
    mkbootfs \
    flash \

PRODUCT_PACKAGES += $(HOST_TOOLS)
