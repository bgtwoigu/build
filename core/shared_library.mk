#
# Copyright (C) 2014 The Yudatun Open Source Project
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation
#

###########################################################
# Standard rules for building a normal shared library.
#
# Additional inputs from base_rules.make:
# None.
#
# LOCAL_MODULE_SUFFIX will be set for you.
###########################################################

ifeq ($(strip $(LOCAL_MODULE_CLASS)),)
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
endif

ifeq ($(strip $(LOCAL_MODULE_SUFFIX)),)
LOCAL_MODULE_SUFFIX := $(TARGET_SHARED_LIB_SUFFIX)
endif

ifneq ($(strip $(OVERRIDE_BUILT_MODULE_PATH)),)
$(error $(LOCALPATH): Illegal use of OVERRIDE_BUILT_MODULE_PATH)
endif

ifneq ($(strip $(LOCAL_MODULE_STEM)$(LOCAL_BUILT_MODULE_STEM)),)
$(error $(LOCAL_PATH): Cannot set module stem for a library)
endif

# Put the built targets of all shared libraries in a common
# directory to simplify the link line.
OVERRIDE_BUILT_MODULE_PATH := $(TARGET_OUT_INTERMEDIATE_LIBRARIES)

include $(BUILD_SYSTEM)/dynamic_binary.mk

# Define PRIVATE_ variables from global vars
my_target_global_ld_dirs := $(TARGET_GLOBAL_LD_DIRS)
my_target_global_ldflags := $(TARGET_GLOBAL_LDFLAGS)
my_target_fdo_lib := $(TARGET_FDO_LIB)
my_target_libgcc := $(TARGET_LIBGCC)
my_target_crtbegin_so_o := $(TARGET_CRTBEGIN_SO_O)
my_target_crtend_so_o := $(TARGET_CRTEND_SO_O)
$(linked_module) : PRIVATE_TARGET_GLOBAL_LD_DIRS := $(my_target_global_ld_dirs)
$(linked_module) : PRIVATE_TARGET_GLOBAL_LDFLAGS := $(my_target_global_ldflags)
$(linked_module) : PRIVATE_TARGET_FDO_LIB := $(my_target_fdo_lib)
$(linked_module) : PRIVATE_TARGET_LIBGCC := $(my_target_libgcc)
$(linked_module) : PRIVATE_TARGET_CRTBEGIN_SO_O := $(my_target_crtbegin_so_o)
$(linked_module) : PRIVATE_TARGET_CRTEND_SO_O := $(my_target_crtend_so_o)

$(linked_module): $(all_objects) $(all_libraries) \
                  $(LOCAL_ADDITIONAL_DEPENDENCIES) \
                  $(my_target_crtbegin_so_o) $(my_target_crtend_so_o)
	$(transform-o-to-shared-lib)
