#
# Copyright (C) 2015 The Yudatun Open Source Project
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation
#

include $(BUILD_SYSTEM)/clang/arm.mk

CLANG_CONFIG_arm_TARGET_TRIPLE := arm-linux-androideabi
CLANG_CONFIG_arm_TARGET_TOOLCHAIN_PREFIX := \
  $(TARGET_TOOLCHAIN_ROOT)/$(CLANG_CONFIG_arm_TARGET_TRIPLE)/bin

CLANG_CONFIG_arm_TARGET_EXTRA_ASFLAGS := \
  $(CLANG_CONFIG_EXTRA_ASFLAGS) \
  $(CLANG_CONFIG_TARGET_EXTRA_ASFLAGS) \
  $(CLANG_CONFIG_arm_EXTRA_ASFLAGS) \
  -target $(CLANG_CONFIG_arm_TARGET_TRIPLE) \
  -B$(CLANG_CONFIG_arm_TARGET_TOOLCHAIN_PREFIX)

CLANG_CONFIG_arm_TARGET_EXTRA_CFLAGS := \
  $(CLANG_CONFIG_EXTRA_CFLAGS) \
  $(CLANG_CONFIG_TARGET_EXTRA_CFLAGS) \
  $(CLANG_CONFIG_arm_EXTRA_CFLAGS) \
  -target $(CLANG_CONFIG_arm_TARGET_TRIPLE) \
  $(CLANG_CONFIG_arm_TARGET_EXTRA_ASFLAGS)

CLANG_CONFIG_arm_TARGET_EXTRA_CPPFLAGS := \
  $(CLANG_CONFIG_EXTRA_CPPFLAGS) \
  $(CLANG_CONFIG_TARGET_EXTRA_CPPFLAGS) \
  $(CLANG_CONFIG_arm_EXTRA_CPPFLAGS) \
  -target $(CLANG_CONFIG_arm_TARGET_TRIPLE)

CLANG_CONFIG_arm_TARGET_EXTRA_LDFLAGS := \
  $(CLANG_CONFIG_EXTRA_LDFLAGS) \
  $(CLANG_CONFIG_TARGET_EXTRA_LDFLAGS) \
  $(CLANG_CONFIG_arm_EXTRA_LDFLAGS) \
  -target $(CLANG_CONFIG_arm_TARGET_TRIPLE) \
  -B$(CLANG_CONFIG_arm_TARGET_TOOLCHAIN_PREFIX)


define convert-to-clang-flags
  $(strip \
  $(call subst-clang-incompatible-arm-flags,\
  $(filter-out $(CLANG_CONFIG_arm_UNKNOWN_CFLAGS),\
  $(1))))
endef

CLANG_TARGET_GLOBAL_CFLAGS := \
  $(call convert-to-clang-flags,$(TARGET_GLOBAL_CFLAGS)) \
  $(CLANG_CONFIG_arm_TARGET_EXTRA_CFLAGS)

CLANG_TARGET_GLOBAL_CPPFLAGS := \
  $(call convert-to-clang-flags,$(TARGET_GLOBAL_CPPFLAGS)) \
  $(CLANG_CONFIG_arm_TARGET_EXTRA_CPPFLAGS)

CLANG_TARGET_GLOBAL_LDFLAGS := \
  $(call convert-to-clang-flags,$(TARGET_GLOBAL_LDFLAGS)) \
  $(CLANG_CONFIG_arm_TARGET_EXTRA_LDFLAGS)
