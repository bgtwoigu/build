#
# Copyright (C) 2013 The Gotoos Open Source Project
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation
#

# -----------------------------------------------------------
# Standard rules for building a static library for the host.
#
# Additional inputs from base_rules.make:
# None.
#
# LOCAL_MODULE_SUFFIX will be set for you.
# -----------------------------------------------------------

# -----------------------------------------------------------
ifeq ($(strip $(LOCAL_MODULE_CLASS)),)
LOCAL_MODULE_CLASS := STATIC_LIBRARIES
endif

ifeq ($(strip $(LOCAL_MODULE_SUFFIX)),)
LOCAL_MODULE_SUFFIX := $(HOST_STATIC_LIB_SUFFIX)
endif

ifneq ($(strip $(LOCAL_MODULE_STEM)$(LOCAL_BUILT_MODULE_STEM)),)
$(error $(LOCAL_PATH): Cannot set module stem for a library)
endif
LOCAL_UNINSTALLABLE_MODULE := true

LOCAL_IS_HOST_MODULE := true

# -----------------------------------------------------------
include $(BUILD_SYSTEM)/binary.mk

# ----------------------------------------------------------
$(LOCAL_BUILT_MODULE) : $(built_whole_libraries)
$(LOCAL_BUILT_MODULE) : $(all_objects)
	$(transform-host-o-to-static-lib)