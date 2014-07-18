#
# Copyright (C) 2013 The Yudatun Open Source Project
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation
#

# -----------------------------------------------------------
# Configuration for builds hosted on linux-x86.
# Included by combo/select.mk

# -----------------------------------------------------------
# Previously the prebuilt host toolchanin is used only for the
# software development kit (sdk) build, that's why we have "sdk"
# in the path name.
ifeq ($(strip $(HOST_TOOLCHAIN_PREFIX)),)
HOST_TOOLCHAIN_PREFIX := devtools/tools/gcc-sdk
endif

# Don't do anything if the toolchain is not there
ifneq (,$(strip $(wildcard $HOST_TOOLCHAIN_PREFIX)/gcc))
HOST_CC := $(HOST_TOOLCHAIN_PREFIX)/gcc
HOST_CXX := $(HOST_TOOLCHAIN_PREFIX)/g++
HOST_AR := $(HOST_TOOLCHAIN_PREFIX)/ar
endif

# -----------------------------------------------------------
ifeq ($(strip $(shell uname -p)),x86_64)
BUILD_HOST_64bit := true
endif

ifneq ($(strip $(BUILD_HOST_64bit)),)
# By default we build everything in 32-bit, because it gives us
# more consistency between the host tools and the target.
# BUILD_HOST_64bit=1 overrides it for tool like emulator
# which can benefit from 64-bit host arch.
HOST_GLOBAL_CFLAGS += -m64
HOST_GLOBAL_LDFLAGS += -m64
else
# We expect SSE3 floating point math.
HOST_GLOBAL_CFLAGS += -mstackrealign -msse3 -mfpmath=sse -m32
HOST_GLOBAL_LDFLAGS += -m32
endif # BUILD_HOST_64bits

# -----------------------------------------------------------
ifneq ($(strip $(BUILD_HOST_static)),)
# Statically-linked binaries are desirable for sandboxed environment
HOST_GLOBAL_LDFLAGS += -static
endif # BUILD_HOST_static

# -----------------------------------------------------------
HOST_GLOBAL_CFLAGS += -fPIC

# Disable new longjmp in glibc 2.11 and later.
HOST_GLOBAL_CFLAGS += -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0

HOST_SHLIB_SUFFIX := .so
