#
# Copyright (C) 2013 The Gotoos Open Source Project
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
    $(TOPDIR)core/include \
    $(TOPDIR)libcore/include \
    $(TOPDIR)libcore/lua-5.2.2/src

SRC_TARGET_DIR := $(TOPDIR)make/target

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
COMMON_GLOBAL_CFLAGS := -DGOTOOS -fmessage-length=0 -W -Wall -Wno-unused -Winit-self -Wpointer-arith
COMMON_RELEASE_CFLAGS := -DNDEBUG -UDEBUG

# list of flags to turn specific warnings in to errors
TARGET_ERROR_FLAGS := -Werror=return-type -Werror=non-virtual-dtor -Werror=address -Werror=sequence-point

# TODO: do symbol compression
TARGET_COMPRESS_MODULE_SYMBOLS := false

# Default shell is bash.
TARGET_SHELL := bash

# ------------------------------------------------------------
# Define most of the global variables. These are the ones that
# are specifice to the user's build configuration.
#
include $(BUILD_SYSTEM)/envsetup.mk

# ------------------------------------------------------------
# Borads may be defined under $(SRC_TARGET_DIR)/board/$(TARGET_DEVICE)
#
board_config_mk := \
  $(strip \
     $(wildcard \
         $(SRC_TARGET_DIR)/board/$(TARGET_DEVICE)/BoardConfig.mk \
       ) \
   )
ifeq ($(board_config_mk),)
  $(error No config file found for TARGET_DEVICE $(TARGET_DEVICE))
endif
ifneq ($(words $(board_config_mk)),1)
  $(error Multiple board config files for TARGET_DEVICE $(TARGET_DEVICE): $(board_config_mk))
endif

include $(board_config_mk)

ifeq ($(TARGET_ARCH),)
  $(error TARGET_ARCH not defined by board config: $(board_config_mk))
endif
TARGET_DEVICE_DIR := $(patsubst %/,%,$(dir $(board_config_mk)))
board_config_mk :=

# -----------------------------------------------------------
#
combo_target := HOST_
include $(BUILD_SYSTEM)/combo/select.mk

combo_target := TARGET_
include $(BUILD_SYSTEM)/combo/select.mk

# -----------------------------------------------------------
# General tools.

MKBOOTFS := $(HOST_OUT_EXECUTABLES)/mkbootfs$(HOST_EXECUTABLE_SUFFIX)
MKBOOTIMG := $(HOST_OUT_EXECUTABLES)/mkbootimg$(HOST_EXECUTABLE_SUFFIX)
MKEXT4FS := $(HOST_OUT_EXECUTABLES)/mkext4fs$(HOST_EXECUTABLE_SUFFIX)
MKEXTUSERIMG := $(HOST_OUT_EXECUTABLES)/mkuserimg.sh
LUA := $(HOST_OUT_EXECUTABLES)/lua$(HOST_EXECUTABLE_SUFFIX)
SIMG2IMG := $(HOST_OUT_EXECUTABLES)/simg2img$(HOST_EXECUTABLE_SUFFIX)
E2FSCK := $(HOST_OUT_EXECUTABLES)/e2fsck$(HOST_EXECUTABLE_SUFFIX)

# -----------------------------------------------------------
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

# Many host compilers don't support these flags, so we have to make sure to only
# specify them for the target compilers checked in to the source tree.
TARGET_GLOBAL_CFLAGS += $(TARGET_ERROR_FLAGS)

TARGET_GLOBAL_CFLAGS += $(TARGET_RELEASE_CFLAGS)

TARGET_GLOBAL_LD_DIRS += -L$(TARGET_OUT_INTERMEDIATE_LIBRARIES)

# -----------------------------------------------------------
#
include $(BUILD_SYSTEM)/dumpvar.mk
