#
# Copyright (c) 2013 The Yudatun Open Source Project
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#
LOCAL_PATH := $(my-dir)
include $(CLEAR_VARS)

LOCAL_SRC_FILES := mkbl1.c

LOCAL_MODULE := mkbl1

include $(BUILD_HOST_EXECUTABLE)
