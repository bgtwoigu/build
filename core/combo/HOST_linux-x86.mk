#
# Copyright (C) 2015 The Yudatun Open Source Project
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation
#

# Configuration for builds hosted on linux-x86.
# Included by combo/select.mk

ifeq ($(strip $(HOST_TOOLCHAIN_PREFIX)),)
HOST_TOOLCHAIN_PREFIX := devtools/gcc/linux-x86/host/x86_64-linux-glibc2.15-4.8/bin/x86_64-linux-
endif
HOST_CC  := $(HOST_TOOLCHAIN_PREFIX)gcc
HOST_CXX := $(HOST_TOOLCHAIN_PREFIX)g++
HOST_AR  := $(HOST_TOOLCHAIN_PREFIX)ar

# gcc location for clang; to be updated when clang is updated
HOST_TOOLCHAIN_FOR_CLANG := devtools/gcc/linux-x86/host/x86_64-linux-glibc2.15-4.8/

# We expect SSE3 floating point math.
HOST_GLOBAL_CFLAGS += -msse3 -mfpmath=sse -m32 -Wa,--noexecstack -march=prescott
HOST_GLOBAL_LDFLAGS += -m32 -Wl,-z,noexecstack

ifneq ($(strip $(BUILD_HOST_static)),)
# Statically-linked binaries are desirable for sandboxed environment
HOST_GLOBAL_LDFLAGS += -static
endif # BUILD_HOST_static

HOST_GLOBAL_CFLAGS += -fPIC \
  -no-canonical-prefixes \
  -include $(call select-yudatun-config-h,linux-x86)

# Disable new longjmp in glibc 2.11 and later. See bug 2967937. Same for 2.15?
HOST_GLOBAL_CFLAGS += -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0

# Workaround differences in inttypes.h between host and target.
# See bug 12708004.
HOST_GLOBAL_CFLAGS += -D__STDC_FORMAT_MACROS -D__STDC_CONSTANT_MACROS

HOST_NO_UNDEFINED_LDFLAGS := -Wl,--no-undefined


############################################################
## Macros after this line are shared by the 64-bit config.

# $(1): The file to check
define get-file-size
stat --format "%s" "$(1)" | tr -d '\n'
endef
