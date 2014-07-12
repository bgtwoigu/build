#
# Copyright (C) 2013 The Yudatun Open Source Project
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation
#

# Unbundled apps will be build with the most generic product config.
ifneq ($(TARGET_BUILD_APPS),)
PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/yudatun.mk \
    $(LOCAL_DIR)/yudatun_qemu.mk
else
PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/yudatun.mk \
    $(LOCAL_DIR)/yudatun_qemu.mk \
    $(LOCAL_DIR)/yudatun_qt210.mk
endif