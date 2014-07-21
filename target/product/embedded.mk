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

PRODUCT_PACKAGES += \
    sshd \
    init \
    libcutils \
    liblua \
    libclua \
    libssh \
    libssl \
    libcrypto \
    libz \
    bash \
    busybox

CORE_LUA_FILES += \
    init.lua \
    services.lua \
    actions.lua

PRODUCT_PACKAGES += $(CORE_LUA_FILES)


ifeq (arm-none-linux-gnueabi, $(strip $(TARGET_LINUX_EABI_PREFIX)))

PRODUCT_PACKAGES += \
    ld-linux.so.3 \
    libm.so.6 \
    libc.so.6 \
    libgcc_s.so.1 \
    libstdc++.so.6

endif # TARGET_LINUX_EABI_PREFIX
