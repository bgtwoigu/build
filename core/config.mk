#
# Copyright (C) 2013 The Yudatun Open Source Project
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation
#

# -------------------------------------------------------------
# This is included by the top-level Makefile.
# It sets up standard variables based on the
# current configuration and platform, which
# are not specific to what is being build.

# Use bash, not whatever shell somebody has installed as /bin/sh
# This is repeated from main.mk, since envsetup.sh runs this file
# directly.
SHELL := /bin/bash

# Utility variables.
empty :=
space := $(empty) $(empty)
comma := ,

# -------------------------------------------------------------
# TODO: Enforce some kind of layering; only add include paths
# when a module links against a particular library.
# TODO: See if we can remove most of these from the global list.
SRC_HEADERS := \
    $(TOPDIR)system/libraries/include \
    $(TOPDIR)system/private/include \

SRC_TARGET_DIR := $(TOPDIR)build/target

BUILD_TARGET_BOARD := $(SRC_TARGET_DIR)/board
BUILD_TARGET_PRODUCT := $(SRC_TARGET_DIR)/product

# -------------------------------------------------------------
# Build system internal files
#
BUILD_COMBOS := $(BUILD_SYSTEM)/combo

CLEAR_VARS := $(BUILD_SYSTEM)/clear_vars.mk

BUILD_COPY_HEADERS := $(BUILD_SYSTEM)/copy_headers.mk

BUILD_EXECUTABLE := $(BUILD_SYSTEM)/executable.mk
BUILD_STATIC_LIBRARY := $(BUILD_SYSTEM)/static_library.mk
BUILD_SHARED_LIBRARY := $(BUILD_SYSTEM)/shared_library.mk
BUILD_PREBUILT := $(BUILD_SYSTEM)/prebuilt.mk

BUILD_HOST_EXECUTABLE := $(BUILD_SYSTEM)/host_executable.mk
BUILD_HOST_STATIC_LIBRARY := $(BUILD_SYSTEM)/host_static_library.mk
BUILD_HOST_SHARED_LIBRARY := $(BUILD_SYSTEM)/host_shared_library.mk

# ------------------------------------------------------------
# Set common values
#

# These can be changed to modify both host and device modules.
COMMON_GLOBAL_CFLAGS := -DYUDATUN -fmessage-length=0 -W -Wall -Wno-unused -Winit-self -Wpointer-arith
COMMON_RELEASE_CFLAGS := -DNDEBUG -UDEBUG

# list of flags to turn specific warnings in to errors
TARGET_ERROR_FLAGS := -Werror=return-type -Werror=non-virtual-dtor -Werror=address -Werror=sequence-point

# TODO: do symbol compression
TARGET_COMPRESS_MODULE_SYMBOLS := false

# Default shell is bash.
TARGET_SHELL := bash

#----------------------------------------------------------------------
# Define most of the global variables. These are the ones that
# are specifice to the user's build configuration.
#
include $(BUILD_SYSTEM)/envsetup.mk

#---------------------------------------------------------------------
TARGET_CPU_ABI := $(strip $(TARGET_CPU_ABI))
ifeq ($(TARGET_CPU_ABI),)
  $(error No TARGET_CPU_ABI defined by board config: $(board_config_mk))
endif
TARGET_CPU_ABI2 := $(strip $(TARGET_CPU_ABI2))

# $(1): os/arch
define select-yudatun-config-h
build/core/combo/include/arch/$(1)/YudatunConfig.h
endef

#---------------------------------------------------------------------
# Select the platform compiler.
combo_target := HOST_
include $(BUILD_SYSTEM)/combo/select.mk

combo_target := TARGET_
include $(BUILD_SYSTEM)/combo/select.mk

#---------------------------------------------------------------------
# General tools.
# cpio
MKBOOTFS := $(HOST_OUT_EXECUTABLES)/mkbootfs$(HOST_EXECUTABLE_SUFFIX)
# bootimage
MKBOOTIMG := $(HOST_OUT_EXECUTABLES)/mkbootimg$(HOST_EXECUTABLE_SUFFIX)
# vfat
MKDOSFS := $(HOST_OUT_EXECUTABLES)/mkdosfs$(HOST_EXECUTABLE_SUFFIX)
MCOPY := $(HOST_OUT_EXECUTABLES)/mcopy$(HOST_EXECUTABLE_SUFFIX)
# ext4
MKEXT4FS := $(HOST_OUT_EXECUTABLES)/mkext4fs$(HOST_EXECUTABLE_SUFFIX)
SIMG2IMG := $(HOST_OUT_EXECUTABLES)/simg2img$(HOST_EXECUTABLE_SUFFIX)
# u-boot
UBOOT-MKIMAGE := $(HOST_OUT_EXECUTABLES)/uboot-mkimage$(HOST_EXECUTABLE_SUFFIX)

#---------------------------------------------------------------------
# Set up final options for host module
HOST_PROJECT_INCLUDES := $(SRC_HEADERS) $(HOST_OUT_INTERMEDIATE_HEADERS)

HOST_GLOBAL_CFLAGS += $(COMMON_GLOBAL_CFLAGS)
HOST_RELEASE_CFLAGS += $(COMMON_RELEASE_CFLAGS)

HOST_GLOBAL_CFLAGS += $(HOST_RELEASE_CFLAGS)

HOST_GLOBAL_LD_DIRS += -L$(HOST_OUT_INTERMEDIATE_LIBRARIES)

# -----------------------------------------------------------
# Set up final options for target module
TARGET_PROJECT_INCLUDES := $(SRC_HEADERS) $(TARGET_OUT_INTERMEDIATE_HEADERS)

TARGET_GLOBAL_CFLAGS += $(COMMON_GLOBAL_CFLAGS)
TARGET_RELEASE_CFLAGS += $(COMMON_RELEASE_CFLAGS)

# Many host platformss don't support these flags, so we have to make sure to only
# specify them for the target platformss checked in to the source tree.
TARGET_GLOBAL_CFLAGS += $(TARGET_ERROR_FLAGS)

TARGET_GLOBAL_CFLAGS += $(TARGET_RELEASE_CFLAGS)

TARGET_GLOBAL_LD_DIRS += -L$(TARGET_OUT_INTERMEDIATE_LIBRARIES)

#------------------------------------------------------------
# define clang/llvm tools and global flags
include $(BUILD_SYSTEM)/clang/config.mk

#------------------------------------------------------------
include $(BUILD_SYSTEM)/dumpvar.mk
