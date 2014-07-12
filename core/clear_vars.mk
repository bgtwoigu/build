#
# Copyright (C) 2013 The Gotoos Open Source Project
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation
#

# ------------------------------------------------------------
# Clear out values of all varables used by rule templates.
#

LOCAL_MODULE :=

LOCAL_MODULE_CLASS :=
LOCAL_MODULE_PATH :=
LOCAL_MODULE_STEM :=
LOCAL_MODULE_SUFFIX :=
LOCAL_MODULE_TAGS :=

LOCAL_SRC_FILES :=
LOCAL_CC :=
LOCAL_CXX :=
LOCAL_CFLAGS :=
LOCAL_LDFLAGS :=
LOCAL_LDLIBS :=
LOCAL_C_INCLUDES :=
LOCAL_GENERATED_SOURCES :=
LOCAL_INTERMEDIATE_TARGETS :=
LOCAL_ADDITIONAL_DEPENDENCIES :=
LOCAL_NO_DEFAULT_COMPILER_FLAGS :=

LOCAL_SRC_FILES_$(TARGET_ARCH) :=
LOCAL_CFLAGS_$(TARGET_ARCH) :=

LOCAL_CFLAGS_32 :=
LOCAL_CFLAGS_64 :=

LOCAL_BUILT_MODULE :=
LOCAL_BUILT_MODULE_STEM :=
LOCAL_INSTALLED_MODULE :=
LOCAL_UNINSTALLABLE_MODULE :=
LOCAL_REQUIRED_MODULE :=
LOCAL_IS_HOST_MODULE :=
LOCAL_COMPRESS_MODULE_SYMBOLS :=
LOCAL_STRIP_MODULE :=
LOCAL_PREBUILT_MODULE_FILE :=

LOCAL_ARM_MODE :=

LOCAL_WHOLE_STATIC_LIBRARIES :=
LOCAL_GROUP_STATIC_LIBRARIES :=
LOCAL_SHARED_LIBRARIES :=
LOCAL_STATIC_LIBRARIES :=
LOCAL_SYSTEM_SHARED_LIBRARIES :=none

LOCAL_FORCE_STATIC_EXECUTABLE :=
LOCAL_UNSTRIPPED_PATH :=
OVERRIDE_BUILT_MODULE_PATH :=

LOCAL_COPY_HEADERS_TO :=
LOCAL_COPY_HEADERS :=

# ------------------------------------------------------------
# Trim MAKEFILE_LIST so that $(call my-dir) doesn't need to
# iterate over thousands of entries every time.
# Leave the current makefile to make sure we don't break anything
# that expects to be able to find the name of the current makefile.
#
MAKEFILE_LIST := $(lastword $(MAKEFILE_LIST))