#
# Copyright (C) 2013 The Yudatun Open Source Project
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation
#

LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)

LOCAL_SRC_FILES := \
    mkbootimg.c

LOCAL_MODULE := mkbootimg
LOCAL_MODULE_TAG := optional

include $(BUILD_HOST_EXECUTABLE)
