#
# Copyright (C) 2013 The Gotoos Open Source Project
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation
#

# ------------------------------------------------------------
# Standard rules for building an executable file.
#
# Additional inputs from base_rules.make:
# None.
# ------------------------------------------------------------

# ------------------------------------------------------------
ifeq ($(strip $(LOCAL_MODULE_CLASS)),)
LOCAL_MODULE_CLASS := EXECUTABLES
endif

ifeq ($(strip $(LOCAL_MODULE_SUFFIX)),)
LOCAL_MODULE_SUFFIX := $(TARGET_EXECUTABLE_SUFFIX)
endif

# ------------------------------------------------------------
# Include dynamic_binary.mk
include $(BUILD_SYSTEM)/dynamic_binary.mk

# ------------------------------------------------------------
# Define PRIVATE_ variables from global vars

my_target_global_ld_dirs := $(TARGET_GLOBAL_LD_DIRS)
my_target_global_ldflags := $(TARGET_GLOBAL_LDFLAGS)
my_target_libgcc := $(TARGET_LIBGCC)
$(linked_module) : PRIVATE_TARGET_GLOBAL_LD_DIRS := $(my_target_global_ld_dirs)
$(linked_module) : PRIVATE_TARGET_GLOBAL_LDFLAGS := $(my_target_global_ldflags)
$(linked_module) : PRIVATE_TARGET_LIBGCC := $(my_target_libgcc)

ifeq ($(LOCAL_FORCE_STATIC_EXECUTABLE),true)
$(linked_module): $(all_objects) $(all_libraries)
	$(transform-o-to-static-executable)
else
$(linked_module): $(all_objects) $(all_libraries)
	$(transform-o-to-executable)
endif