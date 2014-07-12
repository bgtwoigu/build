#
# Copyright (C) 2013 The Yudatun Open Source Project
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation
#

# ------------------------------------------------------------
# Standard rules for building binary object files from
# source files.
#
# The list of object files is exported in $(all_objects)
# ------------------------------------------------------------

# ------------------------------------------------------------
# Compute the dependency of the shared libraries
# ------------------------------------------------------------
# On the target, we compile with -nostdlib, so we must add in the default
# system shared libraries, unless they have requested not to by supplying a
# LOCAL_SYSTEM_SHARED_LIBRARIES value. On would supply
# that, for example, when building libc itself.
ifdef LOCAL_IS_HOST_MODULE
  ifeq ($(LOCAL_SYSTEM_SHARED_LIBRARIES),none)
    LOCAL_SYSTEM_SHARED_LIBRARIES :=
  endif
else
  ifeq ($(LOCAL_SYSTEM_SHARED_LIBRARIES),none)
    LOCAL_SYSTEM_SHARED_LIBRARIES := $(TARGET_DEFAULT_SYSTEM_SHARED_LIBRARIES)
  endif
endif

# The following LOCAL_ variables will be modified in this file.
# Because the same LOCAL_ variables may be used to define modules
# for both 1st arch and and arch.
my_src_files := $(LOCAL_SRC_FILES)
my_cflags := $(LOCAL_CFLAGS)

ifndef LOCAL_IS_HOST_MODULE
my_src_files += $(LOCAL_SRC_FILES_$(TARGET_ARCH))
my_cflags += \
    $(LOCAL_CFLAGS_$(TARGET_ARCH)) \
    $(LOCAL_CFLAGS_$(my_32_64_bit_suffix))
endif

# ------------------------------------------------------------
# Include base_rules.mk
include $(BUILD_SYSTEM)/base_rules.mk

# ------------------------------------------------------------
# Define PRIVATE_ variables from global vars
#
my_target_project_includes := $(TARGET_PROJECT_INCLUDES)
my_target_c_includes := $(TARGET_C_INCLUDES)
my_target_global_cflags := $(TARGET_GLOBAL_CFLAGS)

$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_TARGET_PROJECT_INCLUDES := $(my_target_project_includes)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_TARGET_C_INCLUDES := $(my_target_c_includes)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_TARGET_GLOBAL_CFLAGS := $(my_target_global_cflags)

# -----------------------------------------------------------
# Define per-module debugging flags. Users can turn on
# debugging for a particular module by setting
# DEBUG_MODULE_ModuleName to a non-empty value in their
# environment or buildspec.mk, and setting
# HOST_/TARGET_CUSTOM_DEBUG_CFLAGS to the debug flags that
# they want to use.
# -----------------------------------------------------------
ifdef DEBUG_MODULE_$(strip $(LOCAL_MODULE))
  debug_cflags := $($(my_prefix)CUSTOM_DEBUG_CFLAGS)
else
  debug_cflags :=
endif

LOCAL_C_INCLUDES += $(TOPDIR)$(LOCAL_PATH) $(intermediates)

# ------------------------------------------------------------
# Define PRIVATE_ variables used by multiple module types
#
$(LOCAL_INTERMEDIATE_TARGETS) : PRIVATE_NO_DEFAULT_COMPILER_FLAGS := \
    $(strip $(LOCAL_NO_DEFAULT_COMPILER_FLAGS))

ifeq ($(strip $(LOCAL_CC)),)
  LOCAL_CC := $($(my_prefix)CC)
endif
$(LOCAL_INTERMEDIATE_TARGETS) : PRIVATE_CC := $(LOCAL_CC)

ifeq ($(strip $(LOCAL_CXX)),)
  LOCAL_CXX := $($(my_prefix)CXX)
endif
$(LOCAL_INTERMEDIATE_TARGETS) : PRIVATE_CXX := $(LOCAL_CXX)

$(LOCAL_INTERMEDIATE_TARGETS) : PRIVATE_CFLAGS := $(my_cflags)
$(LOCAL_INTERMEDIATE_TARGETS) : PRIVATE_CONLYFLAGS := $(LOCAL_CONLYFLAGS)
$(LOCAL_INTERMEDIATE_TARGETS) : PRIVATE_DEBUG_CLFAGS := $(debug_cflags)
$(LOCAL_INTERMEDIATE_TARGETS) : PRIVATE_C_INCLUDES := $(LOCAL_C_INCLUDES)

# ------------------------------------------------------------
ifeq (true,$(LOCAL_GROUP_STATIC_LIBRARIES))
$(LOCAL_BUILT_MODULE) : PRIVATE_GROUP_STATIC_LIBRARIES := true
else
$(LOCAL_BUILT_MODULE) : PRIVATE_GROUP_STATIC_LIBRARIES :=
endif


# ------------------------------------------------------------
# Define arm-vs-thumb-mode flags
#
LOCAL_ARM_MODE := $(strip $(LOCAL_ARM_MODE))
ifeq ($(TARGET_ARCH),arm)

arm_objects_mode := $(if $(LOCAL_ARM_MODE),$(LOCAL_ARM_MODE),arm)
normal_objects_mode := $(if $(LOCAL_ARM_MODE),$(LOCAL_ARM_MODE),thumb)
arm_objects_cflags := $($(my_prefix)$(arm_objects_mode)_CFLAGS)
normal_objects_cflags := $($(my_prefix)$(normal_objects_mode)_CFLAGS)

else # TARGET_ARCH

arm_objects_mode :=
normal_objects_mode :=
arm_objects_cflags :=
normal_objects_cflags :=

endif

# -----------------------------------------------------------
# C: Compile generated .c files to .o
# -----------------------------------------------------------
gen_c_sources := $(filter %.c,$(LOCAL_GENERATED_SOURCES))
gen_c_objects := $(gen_c_sources:%.c=%.o)
ifneq ($(strip $(gen_c_objects)),)
$(gen_c_objects): $(intermediates)/%.o: $(intermediates)/%.c \
                  $(LOCAL_ADDITIONAL_DEPENDENCIES)
	$(transform-$(PRIVATE_HOST)c-to-o)
endif

# -----------------------------------------------------------
# o: Include generated .o files in output.
# -----------------------------------------------------------
gen_o_objects := $(filter %.o,$(LOCAL_GENERATED_SOURCES))

# -----------------------------------------------------------
# AS: Compile .S files to .o
# -----------------------------------------------------------
asm_sources_S := $(filter %.S,$(my_src_files))
asm_objects_S := $(addprefix $(intermediates)/,$(asm_sources_S:.S=.o))

ifneq ($(strip $(asm_objects_S)),)
$(asm_objects_S): $(intermediates)/%.o: $(TOPDIR)$(LOCAL_PATH)/%.S \
    $(LOCAL_ADDITIONAL_DEPENDENCIES)
	$(transform-$(PRIVATE_HOST)s-to-o)
-include $(asm_objects_S:%.o=%.P)
endif

asm_sources_s := $(filter %.s,$(my_src_files))
asm_objects_s := $(addprefix $(intermediates)/,$(asm_sources_s:.s=.o))

ifneq ($(strip $(asm_objects_s)),)
$(asm_objects_s): $(intermediates)/%.o: $(TOPDIR)$(LOCAL_PATH)/%.s \
    $(LOCAL_ADDITIONAL_DEPENDENCIES)
	$(transform-$(PRIVATE_HOST)s-to-o)
-include $(asm_objects_s:%.o=%.P)
endif

asm_objects := $(asm_objects_S) $(asm_objects_s)

# -----------------------------------------------------------
# C: Compile .c files to .o
# -----------------------------------------------------------
c_normal_sources := $(filter %.c,$(my_src_files))
c_normal_objects := $(addprefix $(intermediates)/,$(c_normal_sources:.c=.o))

$(c_normal_objects): PRIVATE_ARM_MODE := $(normal_objects_mode)
$(c_normal_objects): PRIVATE_ARM_CFLAGS := $(normal_objects_cflags)

c_objects := $(c_normal_objects)
ifneq ($(strip $(c_objects)),)
$(c_objects): $(intermediates)/%.o: $(TOPDIR)$(LOCAL_PATH)/%.c
	$(transform-$(PRIVATE_HOST)c-to-o)
endif

# ----------------------------------------------------------
# Common object handling.
# ----------------------------------------------------------

# ----------------------------------------------------------
# some rules depend on asm_objects being first. If your code depends on
# being first, it's reasonable to require it to be assembly.
#
normal_objects :=    \
    $(asm_objects)   \
    $(c_objects)     \
    $(gen_c_objects)

all_objects := \
    $(normal_objects) $(gen_o_objects)

LOCAL_C_INCLUDES += $(TOPDIR)$(LOCAL_PATH) $(intermediates)

# all_objects includes gen_o_objects which were part of LOCAL_GENERATED_SOURCES;
# use normal_objects here to avoid creating circular dependencies. This assumes
# that custom build rules which generate .o files don't consume other generated
# sources as input (or if they do they take care of that dependency themselves).
$(normal_objects) : | $(LOCAL_GENERATED_SOURCES)
$(all_objects) : $(import_includes)
ALL_C_CPP_ETC_OBJECTS += $(all_objects)

# -----------------------------------------------------------
# Copy headers to the install tree
# -----------------------------------------------------------
include $(BUILD_COPY_HEADERS)

# -----------------------------------------------------------
# Standard library handling
# -----------------------------------------------------------

# -----------------------------------------------------------
# The list of libraries that this module will link against are
# in these variables. Each is a list of bare module names like "libc libm"
#
# LOCAL_SHARED_LIBRARIES
# LOCAL_STATIC_LIBRARIES
# LOCAL_WHOLE_STATIC_LIBRARIES
#
# We need to convert the bare names into the dependencies that
# we'll use for LOCAL_BUILT_MODULE and LOCAL_INSTALLED_MODULE.
# LOCAL_BUILT_MODULE should depend on the BUILT version of the
# libraries, so that simply building this module doesn't force
# an install of a library. Similarly, LOCAL_INSTALLED_MODULE
# should depend on the INSTALLED versions of the libraries so
# that they get installed when this module does.
#
# NOTE:
# WHOLE_STATIC_LIBRARIES are libraries that are pulled into the
# module without leaving anything out, which is useful for turning
# a collection of .a files into a .so file. Linking against a normal
# STATIC_LIBRARY will only pull in code/symbols that are
# referenced by the module. (see gcc/ld's --whole-archive option)
# -----------------------------------------------------------

# Get the list of BUILT libraries, which are under various
# intermediates direcotries
so_suffix := $($(my_prefix)SHARED_LIB_SUFFIX)
a_suffix := $($(my_prefix)STATIC_LIB_SUFFIX)

# -----------------------------------------------------------
LOCAL_SHARED_LIBRARIES += $(LOCAL_SYSTEM_SHARED_LIBRARIES)
built_shared_libraries := \
  $(addprefix $($(my_prefix)OUT_INTERMEDIATE_LIBRARIES)/, \
      $(addsuffix $(so_suffix), \
          $(LOCAL_SHARED_LIBRARIES)))

# -----------------------------------------------------------
built_static_libraries := \
  $(foreach lib,$(LOCAL_STATIC_LIBRARIES), \
      $(call intermediates-dir-for, \
          STATIC_LIBRARIES,$(lib),$(LOCAL_IS_HOST_MODULE))/$(lib)$(a_suffix) \
   )

# -----------------------------------------------------------
built_whole_libraries := \
  $(foreach lib,$(LOCAL_WHOLE_STATIC_LIBRARIES), \
      $(call intermediates-dir-for, \
          STATIC_LIBRARIES,$(lib),$(LOCAL_IS_HOST_MODULE))/$(lib)$(a_suffix) \
    )

# -----------------------------------------------------------
# Rule-specific variable definitions
# -----------------------------------------------------------
$(LOCAL_INTERMEDIATE_TARGETS) : PRIVATE_LDFLAGS := $(LOCAL_LDFLAGS)
$(LOCAL_INTERMEDIATE_TARGETS) : PRIVATE_LDLIBS := $(LOCAL_LDLIBS)

# -----------------------------------------------------------
# this is really the way to get the files onto the command
# line instead of using $^, because then LOCAL_ADDITIONAL_DEPENDENCIES
# donesn't work
$(LOCAL_INTERMEDIATE_TARGETS) : PRIVATE_ALL_SHARED_LIBRARIES := $(built_shared_libraries)
$(LOCAL_INTERMEDIATE_TARGETS) : PRIVATE_ALL_STATIC_LIBRARIES := $(built_static_libraries)
$(LOCAL_INTERMEDIATE_TARGETS) : PRIVATE_ALL_WHOLE_STATIC_LIBRARIES := $(built_whole_libraries)
$(LOCAL_INTERMEDIATE_TARGETS) : PRIVATE_ALL_OBJECTS := $(all_objects)

# -----------------------------------------------------------
# Define library dependencies.
# -----------------------------------------------------------
# all_libraries is used for the dependencies on LOCAL_BUILT_MODULE.
all_libraries := \
    $(built_shared_libraries) \
    $(built_static_libraries) \
    $(built_whole_libraries)
