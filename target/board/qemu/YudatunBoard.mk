#
# Copyright (C) 2015 The Yudatun Open Source Project
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation
#

LOCAL_PATH := $(call my-dir)

#-----------------------------------------------------------
# Compile Linux Kernel
#-----------------------------------------------------------

ifeq ($(strip $(KERNEL_DEFCONFIG)),)
ifeq ($(TARGET_BUILD_VARIANT),eng)
  KERNEL_DEFCONFIG := qemu_defconfig
else
  KERNEL_DEFCONFIG := qemu_defconfig
endif # TARGET_BUILD_VARIANT
endif # KERNEL_DEFCONFIG

ifeq ($(strip $(KERNEL_VERSION)),)
  KERNEL_VERSION := 3.18.1
endif

TARGET_KERNEL_CROSS_COMPILE_PREFIX := arm-linux-androideabi-

include kernel/linux-$(KERNEL_VERSION)-qemu/YudatunKernel.mk

$(INSTALLED_KERNEL_TARGET): $(TARGET_PREBUILT_KERNEL)
	$(transform-prebuilt-to-target)
