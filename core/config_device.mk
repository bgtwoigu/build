#
# Copyright (C) 2015 The Yudatun Open Source Project
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation
#

#---------------------------------------------------------------------
# kernel
ifneq ($(strip $(TARGET_NO_KERNEL)),true)
  INSTALLED_KERNEL_TARGET := $(PRODUCT_OUT)/kernel
else
  INSTALLED_KERNEL_TARGET :=
endif

#---------------------------------------------------------------------
# bootloader
ifneq ($(strip $(TARGET_NO_BOOTLOADER)),true)
  INSTALLED_BOOTLOADER_TARGET := $(PRODUCT_OUT)/bootloader
else
  INSTALLED_BOOTLOADER_TARGET :=
endif
