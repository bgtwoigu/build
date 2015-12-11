#
# Copyright (C) 2014 The Yudatun Open Source Project
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation
#

# Configuration for Linux on ARM.
# Included by combo/select.mk

# You can set TARGET_ARCH_VARIANT to use an arch version other
# than ARMv5TE. Each value should correspond to a file named
# $(BUILD_COMBOS)/arch/<name>.mk which must contain
# makefile variable definitions similar to the preprocessor
# defines in build/core/combo/include/arch/<combo>/AndroidConfig.h. Their
# purpose is to allow module Android.mk files to selectively compile
# different versions of code based upon the funtionality and
# instructions available in a given architecture version.
#
# The blocks also define specific arch_variant_cflags, which
# include defines, and compiler settings for the given architecture
# version.
#

ifeq ($(strip $(TARGET_ARCH_VARIANT)),)
TARGET_ARCH_VARIANT := armv5te
endif

ifeq ($(strip $(TARGET_GCC_VERSION_EXP)),)
TARGET_GCC_VERSION := 5.1.0
else
TARGET_GCC_VERSION := $(TARGET_GCC_VERSION_EXP)
endif

ifeq ($(strip $(TARGET_GLIBC_VERSION_EXP)),)
TARGET_GLIBC_VERSION := 2.21
else
TARGET_GLIBC_VERSION := $(TARGET_GLIBC_VERSION_EXP)
endif

ifeq ($(strip $(TARGET_LINUX_EABI_PREFIX_EXP)),)
TARGET_LINUX_EABI_PREFIX := arm-linux-gnueabi
else
TARGET_LINUX_EABI_PREFIX := $(TARGET_LINUX_EABI_PREFIX_EXP)
endif # TARGET_LINUX_EABI_PREFIX_EXP

ifeq ($(strip $(TARGET_EABI_PREFIX_EXP)),)
TARGET_EABI_PREFIX := arm-eabi
else
TARGET_EABI_PREFIX := $(TARGET_EABI_PREFIX_EXP)
endif # TARGET_EABI_PREFIX_EXP

TARGET_ARCH_VARIANT := $(strip $(TARGET_ARCH_VARIANT))
TARGET_ARCH_SPECIFIC_MAKEFILE := $(BUILD_COMBOS)/arch/$(TARGET_ARCH)/$(TARGET_ARCH_VARIANT).mk

ifeq ($(strip $(wildcard $(TARGET_ARCH_SPECIFIC_MAKEFILE))),)
$(error Unknown ARM architecture version: $(TARGET_ARCH_VARIANT))
endif

include $(TARGET_ARCH_SPECIFIC_MAKEFILE)

# You can set TARGET_TOOLS_PREFIX to get gcc from somewhere else
ifeq ($(strip $(TARGET_TOOLS_PREFIX)),)
TARGET_TOOLCHAIN_ROOT := devtools/gcc/$(HOST_MACHINE_TAG)/arm/$(TARGET_LINUX_EABI_PREFIX)-$(TARGET_GCC_VERSION)
TARGET_TOOLS_PREFIX := $(TARGET_TOOLCHAIN_ROOT)/bin/$(TARGET_LINUX_EABI_PREFIX)-
endif

TARGET_CC := $(TARGET_TOOLS_PREFIX)gcc$(HOST_EXECUTABLE_SUFFIX)
TARGET_CXX := $(TARGET_TOOLS_PREFIX)g++$(HOST_EXECUTABLE_SUFFIX)
TARGET_AR := $(TARGET_TOOLS_PREFIX)ar$(HOST_EXECUTABLE_SUFFIX)
TARGET_OBJCOPY := $(TARGET_TOOLS_PREFIX)objcopy$(HOST_EXECUTABLE_SUFFIX)
TARGET_LD := $(TARGET_TOOLS_PREFIX)ld$(HOST_EXECUTABLE_SUFFIX)
TARGET_READELF := $(TARGET_TOOLS_PREFIX)readelf$(HOST_EXECUTABLE_SUFFIX)
TARGET_STRIP := $(TARGET_TOOLS_PREFIX)strip$(HOST_EXECUTABLE_SUFFIX)
ifeq ($(TARGET_BUILD_VARIANT),user)
    TARGET_STRIP_COMMAND = $(TARGET_STRIP) --strip-all $< -o $@
else
    TARGET_STRIP_COMMAND = $(TARGET_STRIP) --strip-all $< -o $@ && \
        $(TARGET_OBJCOPY) --add-gnu-debuglink=$< $@
endif

TARGET_NO_UNDEFINED_LDFLAGS := -Wl,--no-undefined

TARGET_arm_CFLAGS :=    -O2 \
                        -fomit-frame-pointer \
                        -fstrict-aliasing    \
                        -funswitch-loops

# Modules can choose to compile some source as thumb.
TARGET_thumb_CFLAGS :=  -mthumb \
                        -Os \
                        -fomit-frame-pointer \
                        -fno-strict-aliasing

# Set FORCE_ARM_DEBUGGING to "true" in your buildspec.mk
# or in your environment to force a full arm build, even for
# files that are normally built as thumb; this can make
# gdb debugging easier.  Don't forget to do a clean build.
#
# NOTE: if you try to build a -O0 build with thumb, several
# of the libraries (libpv, libwebcore, libkjs) need to be built
# with -mlong-calls.  When built at -O0, those libraries are
# too big for a thumb "BL <label>" to go from one end to the other.
ifeq ($(FORCE_ARM_DEBUGGING),true)
  TARGET_arm_CFLAGS += -fno-omit-frame-pointer -fno-strict-aliasing
  TARGET_thumb_CFLAGS += -marm -fno-omit-frame-pointer
endif

yudatun_config_h := $(call select-yudatun-config-h,linux-arm)

TARGET_GLOBAL_CFLAGS += \
    -Wall \
    -Winline \
    -Wundef \
    -Wwrite-strings \
    -fmerge-all-constants \
    -frounding-math \
    -Wstrict-prototypes  \
    -msoft-float \
    -fPIC \
    -fexceptions \
    -ffunction-sections \
    -fdata-sections \
    -funwind-tables \
    -fstack-protector \
    -Wa,--noexecstack \
    -Werror=format-security \
    -D_FORTIFY_SOURCE=2 \
    -fno-short-enums \
    $(arch_variant_cflags) \

# The "-Wunused-but-set-variable" option often breaks projects that enable
# "-Wall -Werror" due to a commom idiom "ALOGV(mesg)" where ALOGV is turned
# into no-op in some builds while mesg is defined earlier. So we explicitly
# disable "-Wunused-but-set-variable" here.
ifneq ($(filter 4.6 4.6.% 4.7 4.7.% 4.8, 5.1.% $(TARGET_GCC_VERSION)),)
TARGET_GLOBAL_CFLAGS += \
    -Wno-unused-but-set-variable \
    -fno-builtin-sin \
    -fno-strict-volatile-bitfields
endif

# This is to avoid the dreaded warning compiler message:
#   note: the mangling of 'va_list' has changed in GCC 4.4
#
# The fact that the mangling changed does not affect the NDK ABI
# very fortunately (since none of the exposed APIs used va_list
# in their exported C++ functions). Also, GCC 4.5 has already
# removed the warning from the compiler.
#
TARGET_GLOBAL_CFLAGS += -Wno-psabi

TARGET_GLOBAL_LDFLAGS += \
    -Wl,-z,noexecstack \
    -Wl,-z,relro \
    -Wl,-z,now \
    -Wl,--warn-shared-textrel \
    -Wl,--fatal-warnings \
    $(arch_variant_ldflags)

TARGET_GLOBAL_CFLAGS += -mthumb-interwork

TARGET_GLOBAL_CPPFLAGS += -fvisibility-inlines-hidden

# More flags/options can be added here
TARGET_RELEASE_CFLAGS := \
    -DNDEBUG \
    -Wstrict-aliasing=2 \
    -fgcse-after-reload \
    -frerun-cse-after-loop \
    -frename-registers

#-----------------------------------------------------------
# Target c includes
kernel_headers := thirdparty/kernel-headers/original/uapi/$(TARGET_ARCH)
libc_headers := thirdparty/glibc/glibc-headers/$(TARGET_ARCH)

TARGET_C_INCLUDES := \
    $(kernel_headers) \
    $(libc_headers)

# crt1.o crti.o
TARGET_CRTBEGIN_STATIC_O := \
  $(TARGET_OUT_INTERMEDIATE_LIBRARIES)/crt1.o \
  $(TARGET_OUT_INTERMEDIATE_LIBRARIES)/crti.o
TARGET_CRTBEGIN_DYNAMIC_O := \
  $(TARGET_OUT_INTERMEDIATE_LIBRARIES)/crt1.o \
  $(TARGET_OUT_INTERMEDIATE_LIBRARIES)/crti.o
# crtn.o
TARGET_CRTEND_O := \
  $(TARGET_OUT_INTERMEDIATE_LIBRARIES)/crtn.o

TARGET_LD-LINUX_SO := $(TARGET_OUT_INTERMEDIATE_LIBRARIES)/ld-linux.so

########################################
# on some hosts, the target cross-compiler
# is not available so do not run this command
ifneq ($(wildcard $(TARGET_CC)),)
# We compile with the global cflags to ensure that
# any flags which affect libgcc are correctly taken
# into account.
TARGET_LIBGCC := \
  $(shell $(TARGET_CC) $(TARGET_GLOBAL_CFLAGS) -print-file-name=libgcc.a)
TARGET_LIBGCC_EH := \
  $(shell $(TARGET_CC) $(TARGET_GLOBAL_CFLAGS) -print-file-name=libgcc_eh.a)
endif

TARGET_STRIP_MODULE := true

TARGET_DEFAULT_SYSTEM_SHARED_LIBRARIES := libc
TARGET_DEFAULT_SYSTEM_STATIC_LIBRARIES := libc_nonshared libpthread_nonshared

########################################
define transform-o-to-static-executable-inner
$(hide) $(PRIVATE_CXX) \
    -nostdlib -Bstatic \
    -Wl,--gc-sections \
    -o $@ \
    $(PRIVATE_TARGET_GLOBAL_LD_DIRS) \
    $(if $(filter true,$(PRIVATE_NO_CRT)),,$(PRIVATE_TARGET_CRTBEGIN_STATIC_O)) \
    $(PRIVATE_TARGET_GLOBAL_LDFLAGS) \
    $(PRIVATE_LDFLAGS) \
    $(PRIVATE_ALL_OBJECTS) \
    -Wl,--whole-archive \
    $(call normalize-target-libraries,$(PRIVATE_ALL_WHOLE_STATIC_LIBRARIES)) \
    -Wl,--no-whole-archive \
    $(call normalize-target-libraries,$(filter-out %libc.a,$(PRIVATE_ALL_STATIC_LIBRARIES))) \
    -Wl,--start-group \
    $(call normalize-target-libraries,$(filter %libc.a,$(PRIVATE_ALL_STATIC_LIBRARIES))) \
    $(if $(PRIVATE_LIBCXX),,$(PRIVATE_TARGET_LIBGCC)) \
    -Wl,--end-group \
    $(if $(filter true,$(PRIVATE_NO_CRT)),,$(PRIVATE_TARGET_CRTEND_O))
endef

define transform-o-to-executable-inner
$(hide) $(PRIVATE_CXX) -nostdlib -Bdynamic \
    -Wl,-dynamic-linker,/lib/ld-linux.so \
    -Wl,--gc-sections \
    -Wl,-z,nocopyreloc \
    $(PRIVATE_TARGET_GLOBAL_LD_DIRS) \
    -Wl,-rpath-link=$(PRIVATE_TARGET_OUT_INTERMEDIATE_LIBRARIES) \
    $(if $(filter true,$(PRIVATE_NO_CRT)),,$(PRIVATE_TARGET_CRTBEGIN_DYNAMIC_O)) \
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
    $(if $(PRIVATE_LIBCXX),,$(PRIVATE_TARGET_LIBGCC)) \
    $(if $(filter true,$(PRIVATE_NO_CRT)),,$(PRIVATE_TARGET_CRTEND_O)) \
    $(PRIVATE_LDLIBS)
endef

define transform-o-to-shared-lib-inner
$(hide) $(PRIVATE_CXX) \
    -nostdlib -Wl,-soname,$(notdir $@) \
    -Wl,--gc-sections \
    -Wl,-shared,-Bsymbolic \
    -shared \
    $(PRIVATE_TARGET_GLOBAL_LD_DIRS) \
    $(if $(filter true,$(PRIVATE_NO_CRT)),,$(PRIVATE_TARGET_CRTBEGIN_SO_O)) \
    $(PRIVATE_ALL_OBJECTS) \
    -Wl,-d -Wl,--whole-archive \
    $(call normalize-target-libraries,$(PRIVATE_ALL_WHOLE_STATIC_LIBRARIES)) \
    -Wl,--no-whole-archive \
    $(if $(PRIVATE_GROUP_STATIC_LIBRARIES),-Wl$(comma)--start-group) \
    $(call normalize-target-libraries,$(PRIVATE_ALL_STATIC_LIBRARIES)) \
    $(if $(PRIVATE_GROUP_STATIC_LIBRARIES),-Wl$(comma)--end-group) \
    $(call normalize-target-libraries,$(PRIVATE_ALL_SHARED_LIBRARIES)) \
    -o $@ \
    $(PRIVATE_TARGET_GLOBAL_LDFLAGS) \
    $(PRIVATE_LDFLAGS) \
    $(if $(PRIVATE_LIBCXX),,$(PRIVATE_TARGET_LIBGCC)) \
    $(if $(filter true,$(PRIVATE_NO_CRT)),,$(PRIVATE_TARGET_CRTEND_SO_O)) \
    $(PRIVATE_LDLIBS)
endef
