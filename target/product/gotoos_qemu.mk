#
# Copyright (C) 2013 The Yudatun Open Source Project
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation
#

$(call inherit-product,$(SRC_TARGET_DIR)/product/gotoos.mk)
$(call inherit-product,$(SRC_TARGET_DIR)/product/gotoos_base.mk)

PRODUCT_NAME := gotoos_qemu
PRODUCT_DEVICE := qemu