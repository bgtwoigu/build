#
# Copyright (C) 2013 The Yudatun Open Source Project
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation
#

# ----------------------------------------------------------
# Set up version information.
include $(BUILD_SYSTEM)/version_defaults.mk

# the variant -- the set of files that are included for a build
ifeq ($(strip $(TARGET_BUILD_VARIANT)),)
TARGET_BUILD_VARIANT := eng
endif

# ----------------------------------------------------------
# Set up configuration for host machine. We don't do cross-compiles
# except for arm/mips, os the HOST is whatever we are running on
#

UNAME := $(shell uname -sm)

# HOST_OS
ifneq (,$(findstring Linux,$(UNAME)))
HOST_OS := linux
endif

# BUILD_OS is the real host doing the build.
BUILD_OS := $(HOST_OS)

ifeq ($(HOST_OS),)
$(error Unable to determine HOST_OS from uname -sm: $(UNAME)!)
endif

# HOST_ARCH
ifneq (,$(findstring 86,$(UNAME)))
HOST_ARCH := x86
endif

BUILD_ARCH := $(HOST_ARCH)

ifeq ($(HOST_ARCH),)
$(error Unable to determine HOST_ARCH from uname -sm; $(UNAME)!)
endif

# the host build defaults to release, and it must be release or debug
ifeq ($(HOST_BUILD_TYPE),)
HOST_BUILD_TYPE := release
endif

ifneq ($(HOST_BUILD_TYPE),release)
ifneq ($(HOST_BUILD_TYPE),debug)
$(error HOST_BUILD_TYPE must be either release or debug, not '$(HOST_BUILD_TYPE)')
endif
endif

#
# This is the standard way to name a directory containng platforms host
# objects. E.g., platforms/$(HOST_COMPILER_TAG)/arm-gcc
#
ifeq ($(HOST_OS),linux)
HOST_COMPILER_TAG := $(HOST_OS)-$(HOST_ARCH)
endif

# ------------------------------------------------------------
# TARGET_COPY_OUT_* are all relative to the staging directory, ie PRODUCT_OUT.
# Define them here so they can be used in product config files.
TARGET_COPY_OUT_SYSTEM := system
TARGET_COPY_OUT_DATA := data
TARGET_COPY_OUT_ROOT := root

# ------------------------------------------------------------
# Read the product specs so we an get TARGET_DEVICE and other
# variables that we need in order ot locate the output files.
include $(BUILD_SYSTEM)/product_config.mk

build_variant := $(filter-out eng user userdebug,$(TARGET_BUILD_VARIANT))
ifneq ($(build_variant)-$(words $(TARGET_BUILD_VARIANT)),-1)
$(warning bad TARGET_BUILD_VARIANT: $(TARGET_BUILD_VARIANT))
$(error must be empty or one of: eng user userdebug)
endif

# ------------------------------------------------------------
# Set up configuration for target machine.
# The following must be set:
#      TARGET_OS = {linux}
#      TARGET_ARCH = {arm | x86 | mips}
#
TARGET_OS := linux

# TARGET_ARCH should be set by BoardConfig.mk and will be checked later

# the target build type defaults to release
ifneq ($(TARGET_BUILD_TYPE),debug)
TARGET_BUILD_TYPE := release
endif

# ------------------------------------------------------------
# figure out the output directories
#

ifeq (,$(strip $(OUT_DIR)))
ifeq (,$(strip $(OUT_DIR_COMMON_BASE)))
OUT_DIR := $(TOPDIR)out
else
OUT_DIR := $(OUT_DIR_COMMON_BASE)/$(notdir $(PWD))
endif
endif

DEBUG_OUT_DIR := $(OUT_DIR)/debug

# Move the host or target under the debug/ directory
# if necessary.

# -----------------------------------------------------------
# host environment variant
HOST_OUT_ROOT_release := $(OUT_DIR)/host
HOST_OUT_ROOT_debug := $(DEBUG_OUT_DIR)/host

HOST_OUT_ROOT := $(HOST_OUT_ROOT_$(HOST_BUILD_TYPE))

HOST_OUT_release := $(HOST_OUT_ROOT_release)/$(HOST_OS)-$(HOST_ARCH)
HOST_OUT_debug := $(HOST_OUT_ROOT_debug)/$(HOST_OS)-$(HOST_ARCH)

HOST_OUT := $(HOST_OUT_$(HOST_BUILD_TYPE))

HOST_COMMON_OUT_ROOT := $(HOST_OUT_ROOT)/common

HOST_OUT_EXECUTABLES := $(HOST_OUT)/bin
HOST_OUT_SHARED_LIBRARIES := $(HOST_OUT)/lib

HOST_OUT_INTERMEDIATES := $(HOST_OUT)/obj
HOST_OUT_COMMON_INTERMEDIATES := $(HOST_COMMON_OUT_ROOT)/obj
HOST_OUT_INTERMEDIATE_HEADERS := $(HOST_OUT_INTERMEDIATES)/include
HOST_OUT_INTERMEDIATE_LIBRARIES := $(HOST_OUT_INTERMEDIATES)/lib

# -----------------------------------------------------------
# target environment variant
TARGET_OUT_ROOT_release := $(OUT_DIR)/target
TARGET_OUT_ROOT_debug := $(DEBUG_OUT_DIR)/target
TARGET_OUT_ROOT := $(TARGET_OUT_ROOT_$(TARGET_BUILD_TYPE))

TARGET_PRODUCT_OUT_ROOT := $(TARGET_OUT_ROOT)/product
PRODUCT_OUT := $(TARGET_PRODUCT_OUT_ROOT)/$(TARGET_DEVICE)
TARGET_COMMON_OUT_ROOT := $(TARGET_OUT_ROOT)/common
TARGET_OUT_INTERMEDIATES := $(PRODUCT_OUT)/obj
TARGET_OUT_COMMON_INTERMEDIATES := $(TARGET_COMMON_OUT_ROOT)/obj
TARGET_OUT_INTERMEDIATE_HEADERS := $(TARGET_OUT_INTERMEDIATES)/include
TARGET_OUT_INTERMEDIATE_LIBRARIES := $(TARGET_OUT_INTERMEDIATES)/lib

# -----------------------------------------------------------
#TARGET_OUT := $(PRODUCT_OUT)/$(TARGET_COPY_OUT_SYSTEM)
TARGET_OUT := $(PRODUCT_OUT)/$(TARGET_COPY_OUT_ROOT)/$(TARGET_COPY_OUT_SYSTEM)
TARGET_OUT_EXECUTABLES := $(TARGET_OUT)/bin
TARGET_OUT_SHARED_LIBRARIES := $(TARGET_OUT)/lib

TARGET_OUT_DATA := $(PRODUCT_OUT)/$(TARGET_COPY_OUT_DATA)
TARGET_OUT_DATA_EXECUTABLES := $(TARGET_OUT_EXECUTABLES)

TARGET_OUT_UNSTRIPPED := $(PRODUCT_OUT)/symbols

# -----------------------------------------------------------
TARGET_ROOT_OUT := $(PRODUCT_OUT)/$(TARGET_COPY_OUT_ROOT)

TARGET_ROOT_OUT_UNSTRIPPED := $(TARGET_OUT_UNSTRIPPED)

# About lua search paths
LUA_PATH := usr/local/share/lua/5.2
LUAUTILS_PATH := yudatun/luautils
TARGET_ROOT_OUT_LUAUTILS := $(TARGET_ROOT_OUT)/$(LUA_PATH)/$(LUAUTILS_PATH)

# -----------------------------------------------------------

COMMON_MODULE_CLASSES := TARGET-NOTICE_FILES HOST-NOTICE_FILES

# -----------------------------------------------------------
# open print config flag
#
ifeq ($(PRINT_BUILD_CONFIG),)
PRINT_BUILD_CONFIG := true
endif

# ------------------------------------------------------------
COMPILER_PATH := $(TOPDIR)platforms/$(HOST_COMPILER_TAG)

TARGET_COMPILER_PATH := $(COMPILER_PATH)/arm-gcc
TARGET_GNUEABI_PATH := $(TARGET_COMPILER_PATH)/arm-none-linux-gnueabi-$(TARGET_GCC_VERSION)
TARGET_GNUEABI_LIBC_PATH := $(TARGET_GNUEABI_PATH)/arm-none-linux-gnueabi/libc
TARGET_GNUEABI_BIN_PATH := $(TARGET_GNUEABI_PATH)/arm-none-linux-gnueabi/bin
