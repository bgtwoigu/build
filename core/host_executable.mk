#
# Copyright (C) 2013 The Yudatun Open Source Project
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation
#

# -----------------------------------------------------------
# Standard rules for building an executable file.
#
# Additional inputs from base_rules.make
# None.
#

LOCAL_IS_HOST_MODULE := true

ifeq ($(strip $(LOCAL_MODULE_CLASS)),)
LOCAL_MODULE_CLASS := EXECUTABLES
endif

ifeq ($(strip $(LOCAL_MODULE_SUFFIX)),)
LOCAL_MODULE_SUFFIX := $(HOST_EXECUTABLE_SUFFIX)
endif

# -----------------------------------------------------------
include $(BUILD_SYSTEM)/binary.mk

# -----------------------------------------------------------
$(LOCAL_BUILT_MODULE): $(all_objects) $(all_libraries)
	$(transform-host-o-to-executable)
