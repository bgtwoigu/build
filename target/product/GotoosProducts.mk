#
# Copyright (C) 2013 The Gotoos Open Source Project
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation
#

# Unbundled apps will be build with the most generic product config.
ifneq ($(TARGET_BUILD_APPS),)
PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/gotoos.mk \
    $(LOCAL_DIR)/gotoos_qemu.mk
else
PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/gotoos.mk \
    $(LOCAL_DIR)/gotoos_qemu.mk \
    $(LOCAL_DIR)/gotoos_qt210.mk
endif