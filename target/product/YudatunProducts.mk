#
# Copyright (C) 2013 The Yudatun Open Source Project
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation
#

# qemu
ifeq (yudatun_qemu, $(strip $(TARGET_PRODUCT)))
PRODUCT_MAKEFILES := \
    device/qemu/yudatun_qemu.mk
endif # yudatun_qemu

# raspberrypi
ifeq (yudatun_raspberrypi, $(strip $(TARGET_PRODUCT)))
PRODUCT_MAKEFILES := \
    device/raspberrypi/yudatun_raspberrypi.mk
endif # yudatun_raspberrypi
