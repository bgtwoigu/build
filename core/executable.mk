#
# Copyright (C) 2013 The Yudatun Open Source Project
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation
#

########################################
# Standard rules for building an executable file.
#
# Additional inputs from base_rules.make:
# None.
########################################

########################################
ifeq ($(strip $(LOCAL_MODULE_CLASS)),)
LOCAL_MODULE_CLASS := EXECUTABLES
endif

ifeq ($(strip $(LOCAL_MODULE_SUFFIX)),)
LOCAL_MODULE_SUFFIX := $(TARGET_EXECUTABLE_SUFFIX)
endif

########################################
# Include dynamic_binary.mk
include $(BUILD_SYSTEM)/dynamic_binary.mk

########################################
# Define PRIVATE_ variables from global vars
my_target_ld-linux_so := $(TARGET_LD-LINUX_SO)
my_target_global_ld_dirs := $(TARGET_GLOBAL_LD_DIRS)
my_target_global_ldflags := $(TARGET_GLOBAL_LDFLAGS)
my_target_fdo_lib := $(TARGET_FDO_LIB)
my_target_libgcc := $(TARGET_LIBGCC) $(TARGET_LIBGCC_EH)
my_target_crtbegin_dynamic_o := $(TARGET_CRTBEGIN_DYNAMIC_O)
my_target_crtbegin_static_o := $(TARGET_CRTBEGIN_STATIC_O)
my_target_crtend_o := $(TARGET_CRTEND_O)
$(linked_module) : PRIVATE_TARGET_GLOBAL_LD_DIRS := $(my_target_global_ld_dirs)
$(linked_module) : PRIVATE_TARGET_GLOBAL_LDFLAGS := $(my_target_global_ldflags)
$(linked_module) : PRIVATE_TARGET_FDO_LIB := $(my_target_fdo_lib)
$(linked_module) : PRIVATE_TARGET_LIBGCC := $(my_target_libgcc)
$(linked_module) : PRIVATE_TARGET_CRTBEGIN_DYNAMIC_O := $(my_target_crtbegin_dynamic_o)
$(linked_module) : PRIVATE_TARGET_CRTBEGIN_STATIC_O := $(my_target_crtbegin_static_o)
$(linked_module) : PRIVATE_TARGET_CRTEND_O := $(my_target_crtend_o)
$(linked_module) : PRIVATE_TARGET_OUT_INTERMEDIATE_LIBRARIES := $(TARGET_OUT_INTERMEDIATE_LIBRARIES)

ifeq ($(LOCAL_FORCE_STATIC_EXECUTABLE),true)
$(linked_module): $(all_objects) $(all_libraries) \
                  $(my_target_crtbegin_static_o) \
                  $(my_target_crtend_o)
	$(transform-o-to-static-executable)
else
$(linked_module) : PRIVATE_ALL_OBJECTS += $(my_target_ld-linux_so)
$(linked_module): $(all_objects) $(all_libraries) \
                  $(my_target_crtbegin_dynamic_o) \
                  $(my_target_crtend_o) \
                  $(my_target_ld-linux_so)
	$(transform-o-to-executable)
endif
