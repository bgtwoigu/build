#
# Copyright (C) 2013 The Yudatun Open Source Project
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation
#

#############################################################
# Standard rules for building a normal shared library.
#
# Additional inputs from base_rules.make:
# None.
#
# LOCAL_MODULE_SUFFIX will be set for you.
#############################################################

LOCAL_IS_HOST_MODULE := true

ifeq ($(strip $(LOCAL_MODULE_CLASS)),)
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
endif

ifeq ($(strip $(LOCAL_MODULE_SUFFIX)),)
LOCAL_MODULE_SUFFIX := $(HOST_SHARED_LIB_SUFFIX)
endif

ifneq ($(strip $(OVERRIDE_BUILT_MODULE_PATH)),)
$(error $(LOCAL_PATH): Illegal use of OVERRIDE_BUILT_MODULE_PATH)
endif

ifneq ($(strip $(LOCAL_MODULE_STEM)$(LOCAL_BUILT_MODULE_STEM)),)
$(error $(LOCAL_PATH): Cannot set module stem for a library)
endif

# Put the built modules of all shared libraries in a common directory
# to simplify the link line.
OVERRIDE_BUILT_MODULE_PATH := $(HOST_OUT_INTERMEDIATE_LIBRARIES)

include $(BUILD_SYSTEM)/binary.mk

$(LOCAL_BUILT_MODULE): $(all_objects) $(all_libraries) \
                       $(LOCAL_ADDITIONAL_DEPENDENCIES)
	$(transform-host-o-to-shared-lib)