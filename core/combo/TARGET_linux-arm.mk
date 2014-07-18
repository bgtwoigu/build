#
# Copyright (C) 2013 The Yudatun Open Source Project
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation
#

#
# Configuration for Linux on ARM
# Included by combo/select.mk
#

# -----------------------------------------------------------
# You can set TARGET_ARCH_VARIANT to use an arch version other
# than ARMv5TE. Each value should correspond to a file named
# $(BUILD_COMBOS)/arch/<name>.mk which must contain
# makefile variable definitions similar to the preprocessor defines in
# make/core/combo/include/arch/<combo>/YudatunConfig.h. Their
# purpose is to allow module Yudatun.mk files to selectively compile
# difference versions of code based upon the funtionality and
# instructions a available in a given architecture version.
#
# The blocks also define specific arch_variant_cflags, which
# include defines, and platforms settings for the given architecture
# version.
#
ifeq ($(strip $(TARGET_ARCH_VARIANT)),)
TARGET_ARCH_VARIANT := armv5te
endif

ifeq ($(strip $(TARGET_GCC_VERSION_EXP)),)
TARGET_GCC_VERSION := 4.7.3
else
TARGET_GCC_VERSION := $(TARGET_GCC_VERSION_EXP)
endif

# -----------------------------------------------------------

# You can set TARGET_TOOLS_PREFIX to get gcc from somewhere else
ifeq ($(strip $(TARGET_TOOLS_PREFIX)),)
TARGET_TOOLCHAIN_ROOT := devtools/gcc/$(HOST_MACHINE_TAG)/target/arm-none-linux-gnueabi-$(TARGET_GCC_VERSION)
TARGET_TOOLS_PREFIX := $(TARGET_TOOLCHAIN_ROOT)/bin/arm-none-linux-gnueabi-
endif

TARGET_CC := $(TARGET_TOOLS_PREFIX)gcc$(HOST_EXECUTABLE_SUFFIX)
TARGET_CXX := $(TARGET_TOOLS_PREFIX)g++$(HOST_EXECUTABLE_SUFFIX)
TARGET_AR := $(TARGET_TOOLS_PREFIX)ar$(HOST_EXECUTABLE_SUFFIX)
TARGET_OBJCOPY := $(TARGET_TOOLS_PREFIX)objcopy$(HOST_EXECUTABLE_SUFFIX)
TARGET_LD := $(TARGET_TOOLS_PREFIX)ld$(HOST_EXECUTABLE_SUFFIX)
TARGET_STRIP := $(TARGET_TOOLS_PREFIX)strip$(HOST_EXECUTABLE_SUFFIX)
ifeq ($(TARGET_BUILD_VARIANT),user)
    TARGET_STRIP_COMMAND = $(TARGET_STRIP) --strip-all $< -o $@
else
    TARGET_STRIP_COMMAND = $(TARGET_STRIP) --strip-all $< -o $@ && \
        $(TARGET_OBJCOPY) --add-gnu-debuglink=$< $@
endif

# -----------------------------------------------------------
TARGET_arm_CFLAGS := \
    -O2 \
    -fomit-frame-pointer \
    -fstrict-aliasing \
    -funswitch-loops

# Modules can choose to compile some source as thumb.
TARGET_thumb_CFLAGS := \
    -mthumb \
    -Os \
    -fomit-frame-pointer \
    -fno-strict-aliasing

# Set FORCE_ARM_DEBUGGING to "true" in your buildspec.mk
# or in your environment to force a full arm build, even for files that are
# normally built as thumb; this can make gdb debugging easier. Don't forget
# to do a clean build.
#
# NOTE:
# if you try to build a -O0 build with thumb, sereral of the libraries need
# to be built with -mlong-calls. When built at -O0, those libraries are
# too big for a thumb "BL <label>" to go from one end to the other.
ifeq ($(FORCE_ARM_DEBUGGING),true)
  TARGET_arm_CFLAGS += -fno-omit-frame-pointer -fno-strict-aliasing
  TARGET_thumb_CFLAGS += -marm -fno-omit-frame-pointer
endif

# -----------------------------------------------------------
TARGET_GLOBAL_CFLAGS += \
    -msoft-float -fpic -fPIE \
    -ffunction-sections \
    -fdata-sections \
    -funwind-tables \
    -fstack-protector \
    -Wa,--noexecstack \
    -Werror=format-security \
    -D_FORTIFY_SOURCE=2 \
    -fno-short-enums \
    $(arch_variant_cflags)

TARGET_GLOBAL_LDFLAGS += \
    -Wl,-z,noexecstack \
    -Wl,-z,relro \
    -Wl,-z,now \
    -Wl,--warn-shared-textrel \
    -Wl,--fatal-warnings \
    $(arch_variant_ldflags)

# -----------------------------------------------------------

TARGET_GLOBAL_CFLAGS += -mthumb-interwork

# -----------------------------------------------------------
TARGET_C_INCLUDES :=

TARGET_STRIP_MODULE := true

TARGET_DEFAULT_SYSTEM_SHARED_LIBRARIES :=

TARGET_LIBGCC := $(shell $(TARGET_CC) $(TARGET_GLOBAL_CFLAGS) -print-libgcc-file-name)

TARGET_CUSTOM_LD_COMMAND := true

define transform-o-to-executable-inner
$(hide) $(PRIVATE_CXX) -fPIE -pie \
    -Bdynamic \
    -Wl,--gc-sections \
    -Wl,-z,nocopyreloc \
    $(PRIVATE_TARGET_GLOBAL_LD_DIRS) \
    -Wl,-rpath-link=$(TARGET_OUT_INTERMEDIATE_LIBRARIES) \
    $(PRIVATE_ALL_OBJECTS) \
    -Wl,--whole-archive \
    $(call normalize-target-libraries,$(PRIVATE_ALL_WHOLE_STATIC_LIBRARIES)) \
    -Wl,--no-whole-archive \
    $(if $(PRIVATE_GROUP_STATIC_LIBRARIES),-Wl$(comma)--start-group) \
    $(call normalize-target-libraries,$(PRIVATE_ALL_STATIC_LIBRARIES)) \
    $(if $(PRIVATE_GROUP_STATIC_LIBRARIES),-Wl$(comma)--end-group) \
    $(call normalize-target-libraries,$(PRIVATE_ALL_SHARED_LIBRARIES)) \
    -o $@ \
    $(PRIVATE_TARGET_GLOBAL_LDFLAGS) \
    $(PRIVATE_LDFLAGS) \
    $(PRIVATE_TARGET_LIBGCC)
endef

define transform-o-to-static-executable-inner
$(hide) $(PRIVATE_CXX) \
    $(PRIVATE_TARGET_GLOBAL_LDFLAGS) \
    -static \
    -Wl,--gc-sections \
    -o $@ \
    $(PRIVATE_TARGET_GLOBAL_LD_DIRS) \
    $(PRIVATE_LDFLAGS) \
    $(PRIVATE_ALL_OBJECTS) \
    -Wl,--whole-archive \
    $(call normalize-target-libraries,$(PRIVATE_ALL_WHOLE_STATIC_LIBRARIES)) \
    -Wl,--no-whole-archive \
    -Wl,--start-group \
    $(call normalize-target-libraries,$(PRIVATE_ALL_STATIC_LIBRARIES)) \
    $(PRIVATE_TARGET_LIBGCC) \
    -Wl,--end-group
endef

define transform-o-to-shared-lib-inner
$(hide) $(PRIVATE_CXX) \
    -Wl,--gc-sections \
    -shared \
    -Wl,-shared,-Bsymbolic \
    $(PRIVATE_TARGET_GLOBAL_LD_DIRS) \
    $(PRIVATE_ALL_OBJECTS) \
    -Wl,--whole-archive \
    $(call normalize-target-libraries,$(PRIVATE_ALL_WHOLE_STATIC_LIBRARIES)) \
    -Wl,--no-whole-archive \
    $(if $(PRIVATE_GROUP_STATIC_LIBRARIES),-Wl$(comma)--start-group) \
    $(call normalize-target-libraries,$(PRIVATE_ALL_STATIC_LIBRARIES)) \
    $(if $(PRIVATE_GROUP_STATIC_LIBRARIES),-Wl$(comma)--end-group) \
    $(call normalize-target-libraries,$(PRIVATE_ALL_SHARED_LIBRARIES)) \
    -o $@ \
    $(PRIVATE_TARGET_GLOBAL_LDFLAGS) \
    $(PRIVATE_LDFLAGS) \
    $(PRIVATE_TARGET_LIBGCC)
endef
