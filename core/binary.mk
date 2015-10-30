#
# Copyright (C) 2013 - 2015 The Yudatun Open Source Project
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation
#

# ------------------------------------------------------------
# Include base_rules.mk
include $(BUILD_SYSTEM)/base_rules.mk

# ------------------------------------------------------------
# Standard rules for building binary object files from
# source files.
#
# The list of object files is exported in $(all_objects)
# ------------------------------------------------------------

#---------------------------------------
# Compute the dependency of the shared libraries
#---------------------------------------
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

#---------------------------------------
# The following LOCAL_ variables will be modified in this file.
# Because the same LOCAL_ variables may be used to define modules
# for both 1st arch and and arch.
my_src_files := $(LOCAL_SRC_FILES)
my_static_libraries := $(LOCAL_STATIC_LIBRARIES)
my_whole_static_libraries := $(LOCAL_WHOLE_STATIC_LIBRARIES)
my_shared_libraries := $(LOCAL_SHARED_LIBRARIES)
my_cflags := $(LOCAL_CFLAGS)
my_cppflags := $(LOCAL_CPPFLAGS)
my_ldflags := $(LOCAL_LDFLAGS)
my_asflags := $(LOCAL_ASFLAGS)
my_cc := $(LOCAL_CC)
my_cxx := $(LOCAL_CXX)
my_c_includes := $(LOCAL_C_INCLUDES)
my_generated_sources := $(LOCAL_GENERATED_SOURCES)
my_clang := $(strip $(LOCAL_CLANG))
ifdef LOCAL_CLANG_$(my_32_64_bit_suffix)
my_clang := $(strip $(LOCAL_CLANG_$(my_32_64_bit_suffix)))
endif
ifdef LOCAL_CLANG_$($(my_prefix)ARCH)
my_clang := $(strip $(LOCAL_CLANG_$($(my_prefix)ARCH)))
endif

# clang is enabled by default for host builds
# enable it unless we've specifically disabled clang above
ifdef LOCAL_IS_HOST_MODULE
  ifneq ($(HOST_OS),windows)
    ifeq ($(my_clang),)
      my_clang :=
    endif # my_clang
  endif # HOST_OS
endif

# Add option to make clan the default for device build
ifeq ($(USE_CLANG_PLATFORM_BUILD),true)
  ifeq ($(my_clang),)
    my_clang := true
  endif
endif # USE_CLANG_PLATFORM_BUILD

#---------------------------------------
ifndef LOCAL_IS_HOST_MODULE

my_src_files += \
    $(LOCAL_SRC_FILES_$(TARGET_ARCH)) \
    $(LOCAL_SRC_FILES_$(my_32_64_bit_suffix))
my_shared_libraries += \
    $(LOCAL_SHARED_LIBRARIES_$(TARGET_ARCH)) \
    $(LOCAL_SHARED_LIBRARIES_$(my_32_64_bit_suffix))
my_cflags += \
    $(LOCAL_CFLAGS_$(TARGET_ARCH)) \
    $(LOCAL_CFLAGS_$(my_32_64_bit_suffix))
my_cppflags += \
    $(LOCAL_CPPFLAGS_$(TARGET_ARCH)) \
    $(LOCAL_CPPFLAGS_$(my_32_64_bit_suffix))
my_ldflags += \
    $(LOCAL_LDFLAGS_$(TARGET_ARCH)) \
    $(LOCAL_LDFLAGS_$(my_32_64_bit_suffix))
my_asflags += \
    $(LOCAL_ASFLAGS_$(TARGET_ARCH)) \
    $(LOCAL_ASFLAGS_$(my_32_64_bit_suffix))
my_c_includes += \
    $(LOCAL_C_INCLUDES_$(TARGET_ARCH)) \
    $(LOCAL_C_INCLUDES_$(my_32_64_bit_suffix))
my_generated_sources += \
    $(LOCAL_GENERATED_SOURCES_$(TARGET_ARCH)) \
    $(LOCAL_GENERATED_SOURCES_$(my_32_64_bit_suffix))

# arch-specific static libraries go first so that generic ones
# can depend on them
my_static_libraries := \
    $(LOCAL_STATIC_LIBRARIES_$(TARGET_ARCH)) \
    $(LOCAL_STATIC_LIBRARIES_$(my_32_64_bit_suffix)) \
    $(my_static_libraries)

my_whole_static_libraries := \
    $(LOCAL_WHOLE_STATIC_LIBRARIES_$(TARGET_ARCH)) \
    $(LOCAL_WHOLE_STATIC_LIBRARIES_$(my_32_64_bit_suffix)) \
    $(my_whole_static_libraries)

my_cflags := $(filter-out $($(my_prefix)GLOBAL_UNSUPPORTED_CFLAGS),$(my_cflags))

endif # !LOCAL_IS_HOST_MODULE

#-----------------------------------------------------------
# add clang flags
ifeq ($(strip $(LOCAL_ADDRESS_SANITIZER)),true)
  my_clang := true
  # Frame pointer based unwinder in ASan requires ARM frame setup.
  LOCAL_ARM_MODE := arm
  my_cflags += $(ADDRESS_SANITIZER_CONFIG_EXTRA_CFLAGS)
  my_ldflags += $(ADDRESS_SANITIZER_CONFIG_EXTRA_LDFLAGS)
  ifdef LOCAL_IS_HOST_MODULE
      my_ldflags += $(ADDRESS_SANITIZER_CONFIG_EXTRA_LDFLAGS_HOST)
      my_ldlibs += $(ADDRESS_SANITIZER_CONFIG_EXTRA_LDLIBS_HOST)
      my_shared_libraries += \
          $(ADDRESS_SANITIZER_CONFIG_EXTRA_SHARED_LIBRARIES_HOST)
      my_static_libraries += \
          $(ADDRESS_SANITIZER_CONFIG_EXTRA_STATIC_LIBRARIES_HOST)
  else
      my_ldflags += $(ADDRESS_SANITIZER_CONFIG_EXTRA_LDFLAGS_TARGET)
      my_ldlibs += $(ADDRESS_SANITIZER_CONFIG_EXTRA_LDLIBS_TARGET)
      my_shared_libraries += \
          $(ADDRESS_SANITIZER_CONFIG_EXTRA_SHARED_LIBRARIES_TARGET)
      my_static_libraries += \
          $(ADDRESS_SANITIZER_CONFIG_EXTRA_STATIC_LIBRARIES_TARGET)
  endif
endif

ifeq ($(strip $(WITHOUT_$(my_prefix)CLANG)),true)
  my_clang :=
endif

#-----------------------------------------------------------
# Define PRIVATE_ variables from global vars
#
ifndef LOCAL_IS_HOST_MODULE

my_target_project_includes := $(TARGET_PROJECT_INCLUDES)
my_target_c_includes := $(TARGET_C_INCLUDES)
my_target_global_cppflags :=

ifeq ($(my_clang),true)
my_target_global_cflags := $(CLANG_TARGET_GLOBAL_CFLAGS)
my_target_global_cppflags += $(CLANG_TARGET_GLOBAL_CPPFLAGS)
my_target_global_ldflags := $(CLANG_TARGET_GLOBAL_LDFLAGS)
else
my_target_global_cflags := $(TARGET_GLOBAL_CFLAGS)
my_target_global_cppflags += $(TARGET_GLOBAL_CPPFLAGS)
my_target_global_ldflags := $(TARGET_GLOBAL_LDFLAGS)
endif # my_clang

$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_TARGET_PROJECT_INCLUDES := $(my_target_project_includes)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_TARGET_C_INCLUDES := $(my_target_c_includes)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_TARGET_GLOBAL_CFLAGS := $(my_target_global_cflags)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_TARGET_GLOBAL_CPPFLAGS := $(my_target_global_cppflags)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_TARGET_GLOBAL_LDFLAGS := $(my_target_global_ldflags)

else # LOCAL_IS_HOST_MODULE

ifeq ($(my_clang),true)
my_host_global_cflags := $(CLANG_HOST_GLOBAL_CFLAGS)
my_host_global_cppflags := $(CLANG_HOST_GLOBAL_CPPFLAGS)
my_host_global_ldflags := $(CLANG_HOST_GLOBAL_LDFLAGS)
my_host_c_includes := $(HOST_C_INCLUDES)
else
my_host_global_cflags := $(HOST_GLOBAL_CFLAGS)
my_host_global_cppflags := $(HOST_GLOBAL_CPPFLAGS)
my_host_global_ldflags := $(HOST_GLOBAL_LDFLAGS)
my_host_c_includes := $(HOST_C_INCLUDES)
endif # my_clang

$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_HOST_C_INCLUDES := $(my_host_c_includes)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_HOST_GLOBAL_CFLAGS := $(my_host_global_cflags)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_HOST_GLOBAL_CPPFLAGS := $(my_host_global_cppflags)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_HOST_GLOBAL_LDFLAGS := $(my_host_global_ldflags)

endif

#-----------------------------------------------------------
installed_shared_library_module_names := \
    $(my_system_shared_libraries) $(my_shared_libraries)
installed_shared_library_module_names := $(sort $(installed_shared_library_module_names))

#-----------------------------------------------------------
# Define per-module debugging flags. Users can turn on
# debugging for a particular module by setting
# DEBUG_MODULE_ModuleName to a non-empty value in their
# environment or buildspec.mk, and setting
# HOST_/TARGET_CUSTOM_DEBUG_CFLAGS to the debug flags that
# they want to use.
#-----------------------------------------------------------
ifdef DEBUG_MODULE_$(strip $(LOCAL_MODULE))
  debug_cflags := $($(my_prefix)CUSTOM_DEBUG_CFLAGS)
else
  debug_cflags :=
endif

LOCAL_C_INCLUDES += $(TOPDIR)$(LOCAL_PATH) $(intermediates)

#-----------------------------------------------------------
# Define PRIVATE_ variables used by multiple module types
#
$(LOCAL_INTERMEDIATE_TARGETS) : PRIVATE_NO_DEFAULT_COMPILER_FLAGS := \
    $(strip $(LOCAL_NO_DEFAULT_COMPILER_FLAGS))

ifeq ($(strip $(my_cc)),)
  ifeq ($(my_clang),true)
    my_cc := $(CLANG)
  else
    my_cc := $($(my_prefix)CC)
  endif # my_clang
endif
$(LOCAL_INTERMEDIATE_TARGETS) : PRIVATE_CC := $(my_cc)

ifeq ($(strip $(my_cxx)),)
  ifeq ($(my_clang),true)
    my_cxx := $(CLANG_CXX)
  else
    my_cxx := $($(my_prefix)CXX)
  endif
endif
$(LOCAL_INTERMEDIATE_TARGETS) : PRIVATE_CXX := $(my_cxx)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_CLANG := $(my_clang)

# TODO: support a mix of standard extensions so that this isn't necessary
LOCAL_CPP_EXTENSION := $(strip $(LOCAL_CPP_EXTENSION))
ifeq ($(LOCAL_CPP_EXTENSION),)
  LOCAL_CPP_EXTENSION := .cpp
endif
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_CPP_EXTENSION := $(LOCAL_CPP_EXTENSION)

#-----------------------------------------------------------
ifeq (true,$(LOCAL_GROUP_STATIC_LIBRARIES))
$(LOCAL_BUILT_MODULE) : PRIVATE_GROUP_STATIC_LIBRARIES := true
else
$(LOCAL_BUILT_MODULE) : PRIVATE_GROUP_STATIC_LIBRARIES :=
endif

#-----------------------------------------------------------
# Define arm-vs-thumb-mode flags
#
LOCAL_ARM_MODE := $(strip $(LOCAL_ARM_MODE))
ifeq ($(TARGET_ARCH),arm)

arm_objects_mode := $(if $(LOCAL_ARM_MODE),$(LOCAL_ARM_MODE),arm)
normal_objects_mode := $(if $(LOCAL_ARM_MODE),$(LOCAL_ARM_MODE),thumb)
arm_objects_cflags := $($(my_prefix)$(arm_objects_mode)_CFLAGS)
normal_objects_cflags := $($(my_prefix)$(normal_objects_mode)_CFLAGS)

ifeq ($(my_clang),true)
arm_objects_cflags := $(call convert-to-$(my_host)clang-flags,$(arm_objects_cflags))
normal_objects_cflags := $(call convert-to-$(my_host)clang-flags,$(normal_objects_cflags))
endif

else # TARGET_ARCH

arm_objects_mode :=
normal_objects_mode :=
arm_objects_cflags :=
normal_objects_cflags :=

endif

#-----------------------------------------------------------
# S: Compile generated .S and .s files to .o.
#-----------------------------------------------------------
gen_S_sources := $(filter %.S,$(my_generated_sources))
gen_S_objects := $(gen_S_sources:%.S=%.o)

ifneq ($(strip $(gen_S_sources)),)
$(gen_S_objects): $(intermediates)/%.o: $(intermediates)/%.S \
    $(LOCAL_ADDITIONAL_DEPENDENCIES)
	$(transform-$(PRIVATE_HOST)s-to-o)
-include $(gen_S_objects:%.o=%.P)
endif

gen_s_sources := $(filter %.s,$(my_generated_sources))
gen_s_objects := $(gen_s_sources:%.s=%.o)

ifneq ($(strip $(gen_s_objects)),)
$(gen_s_objects): $(intermediates)/%.o: $(intermediates)/%.s \
    $(LOCAL_ADDITIONAL_DEPENDENCIES)
	$(transform-$(PRIVATE_HOST)s-to-o-no-deps)
-include $(gen_s_objects:%.o=%.P)
endif

gen_asm_objects := $(gen_S_objects) $(gen_s_objects)

#-----------------------------------------------------------
# o: Include generated .o files in output.
#-----------------------------------------------------------
gen_o_objects := $(filter %.o,$(my_generated_sources))

#-----------------------------------------------------------
# AS: Compile .S files to .o
#-----------------------------------------------------------

asm_sources_S := $(filter %.S,$(my_src_files))
asm_objects_S := $(addprefix $(intermediates)/,$(asm_sources_S:.S=.o))

ifneq ($(strip $(asm_objects_S)),)
$(asm_objects_S): $(intermediates)/%.o: $(TOPDIR)$(LOCAL_PATH)/%.S \
    $(LOCAL_ADDITIONAL_DEPENDENCIES) \
    | $(my_compiler_dependencies)
	$(transform-$(PRIVATE_HOST)s-to-o)
-include $(asm_objects_S:%.o=%.P)
endif

asm_sources_s := $(filter %.s,$(my_src_files))
asm_objects_s := $(addprefix $(intermediates)/,$(asm_sources_s:.s=.o))

ifneq ($(strip $(asm_objects_s)),)
$(asm_objects_s): $(intermediates)/%.o: $(TOPDIR)$(LOCAL_PATH)/%.s \
    $(LOCAL_ADDITIONAL_DEPENDENCIES) \
    | $(my_compiler_dependencies)
	$(transform-$(PRIVATE_HOST)s-to-o-no-deps)
-include $(asm_objects_s:%.o=%.P)
endif

asm_objects := $(asm_objects_S) $(asm_objects_s)

#-----------------------------------------------------------
# C: Compile generated .c files to .o
#-----------------------------------------------------------
gen_c_sources := $(filter %.c,$(LOCAL_GENERATED_SOURCES))
gen_c_objects := $(gen_c_sources:%.c=%.o)
ifneq ($(strip $(gen_c_objects)),)
$(gen_c_objects): $(intermediates)/%.o: $(intermediates)/%.c \
                  $(LOCAL_ADDITIONAL_DEPENDENCIES)
	$(transform-$(PRIVATE_HOST)c-to-o)
endif

#-----------------------------------------------------------
# C: Compile .c files to .o
#-----------------------------------------------------------
c_arm_sources    := $(patsubst %.c.arm,%.c,$(filter %.c.arm,$(my_src_files)))
c_arm_objects    := $(addprefix $(intermediates)/,$(c_arm_sources:.c=.o))

c_normal_sources := $(filter %.c,$(my_src_files))
c_normal_objects := $(addprefix $(intermediates)/,$(c_normal_sources:.c=.o))

$(c_normal_objects): PRIVATE_ARM_MODE := $(normal_objects_mode)
$(c_normal_objects): PRIVATE_ARM_CFLAGS := $(normal_objects_cflags)

$(c_arm_objects):    PRIVATE_ARM_MODE := $(arm_objects_mode)
$(c_arm_objects):    PRIVATE_ARM_CFLAGS := $(arm_objects_cflags)
$(c_normal_objects): PRIVATE_ARM_MODE := $(normal_objects_mode)
$(c_normal_objects): PRIVATE_ARM_CFLAGS := $(normal_objects_cflags)

c_objects := $(c_arm_objects) $(c_normal_objects)

ifneq ($(strip $(c_objects)),)
$(c_objects): $(intermediates)/%.o: $(TOPDIR)$(LOCAL_PATH)/%.c \
              $(LOCAL_ADDITIONAL_DEPENDENCIES)
	$(transform-$(PRIVATE_HOST)c-to-o)
endif

#-----------------------------------------------------------
# C++: Compile generated .cpp files to .o.
#-----------------------------------------------------------
gen_cpp_sources := $(filter %$(LOCAL_CPP_EXTENSION),$(my_generated_sources))
gen_cpp_objects := $(gen_cpp_sources:%$(LOCAL_CPP_EXTENSION)=%.o)

ifneq ($(strip $(gen_cpp_objects)),)
# Compile all generated files as thumb.
# TODO: support compiling certain generated files as arm.
$(gen_cpp_objects): PRIVATE_ARM_MODE := $(normal_objects_mode)
$(gen_cpp_objects): PRIVATE_ARM_CFLAGS := $(normal_objects_cflags)
$(gen_cpp_objects): $(intermediates)/%.o: \
    $(intermediates)/%$(LOCAL_CPP_EXTENSION) \
    $(LOCAL_ADDITIONAL_DEPENDENCIES)
	$(transform-$(PRIVATE_HOST)cpp-to-o)
-include $(gen_cpp_objects:%.o=%.P)
endif

#-----------------------------------------------------------
# C++: Compile .cpp files to .o.
#-----------------------------------------------------------

# we also do this on host modules, even though
# it's not really arm, because there are files that are shared.
cpp_arm_sources    := $(patsubst %$(LOCAL_CPP_EXTENSION).arm,%$(LOCAL_CPP_EXTENSION),$(filter %$(LOCAL_CPP_EXTENSION).arm,$(my_src_files)))
cpp_arm_objects    := $(addprefix $(intermediates)/,$(cpp_arm_sources:$(LOCAL_CPP_EXTENSION)=.o))

cpp_normal_sources := $(filter %$(LOCAL_CPP_EXTENSION),$(my_src_files))
cpp_normal_objects := $(addprefix $(intermediates)/,$(cpp_normal_sources:$(LOCAL_CPP_EXTENSION)=.o))

$(cpp_arm_objects):    PRIVATE_ARM_MODE := $(arm_objects_mode)
$(cpp_arm_objects):    PRIVATE_ARM_CFLAGS := $(arm_objects_cflags)
$(cpp_normal_objects): PRIVATE_ARM_MODE := $(normal_objects_mode)
$(cpp_normal_objects): PRIVATE_ARM_CFLAGS := $(normal_objects_cflags)

cpp_objects        := $(cpp_arm_objects) $(cpp_normal_objects)

ifneq ($(strip $(cpp_objects)),)
$(cpp_objects): $(intermediates)/%.o: \
    $(TOPDIR)$(LOCAL_PATH)/%$(LOCAL_CPP_EXTENSION) \
    $(LOCAL_ADDITIONAL_DEPENDENCIES)
	$(transform-$(PRIVATE_HOST)cpp-to-o)
-include $(cpp_objects:%.o=%.P)
endif

#-----------------------------------------------------------
# Common object handling.
#
# some rules depend on asm_objects being first. If your code
# depends on being first, it's reasonable to require it to be
# assembly.
#

normal_objects := \
    $(asm_objects)   \
    $(c_objects)     \
    $(gen_c_objects) \
    $(cpp_objects)   \
    $(gen_cpp_objects)

all_objects := \
    $(normal_objects) $(gen_o_objects)

my_c_includes += $(TOPDIR)$(LOCAL_PATH) $(intermediates)

# all_objects includes gen_o_objects which were part of
# LOCAL_GENERATED_SOURCES; use normal_objects here to avoid
# creating circular dependencies. This assumes that custom
# build rules which generate .o files don't consume other
# generated sources as input (or if they do they take care of
# that dependency themselves).
$(normal_objects) : | $(LOCAL_GENERATED_SOURCES)
$(all_objects) : $(import_includes)
ALL_C_CPP_ETC_OBJECTS += $(all_objects)

#-----------------------------------------------------------
# Copy headers to the install tree
#-----------------------------------------------------------
include $(BUILD_COPY_HEADERS)

#-----------------------------------------------------------
# Standard library handling
#-----------------------------------------------------------

#-----------------------------------------------------------
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
#-----------------------------------------------------------

# Get the list of BUILT libraries, which are under various
# intermediates direcotries
so_suffix := $($(my_prefix)SHARED_LIB_SUFFIX)
a_suffix := $($(my_prefix)STATIC_LIB_SUFFIX)

#-----------------------------------------------------------
built_shared_libraries := \
  $(addprefix $($(my_prefix)OUT_INTERMEDIATE_LIBRARIES)/, \
      $(addsuffix $(so_suffix), \
          $(installed_shared_library_module_names)))

#-----------------------------------------------------------
built_static_libraries := \
  $(foreach lib,$(my_static_libraries), \
      $(call intermediates-dir-for, \
          STATIC_LIBRARIES,$(lib),$(LOCAL_IS_HOST_MODULE))/$(lib)$(a_suffix) \
   )

#-----------------------------------------------------------
built_whole_libraries := \
  $(foreach lib,$(my_whole_static_libraries), \
      $(call intermediates-dir-for, \
          STATIC_LIBRARIES,$(lib),$(LOCAL_IS_HOST_MODULE))/$(lib)$(a_suffix) \
    )

#-----------------------------------------------------------
# Rule-specific variable definitions
#-----------------------------------------------------------

ifeq ($(my_clang),true)
my_cflags += $(LOCAL_CLANG_CFLAGS)
my_cpplags += $(LOCAL_CLANG_CPPFLAGS)
my_asflags += $(LOCAL_CLANG_ASFLAGS)
my_ldflags += $(LOCAL_CLANG_LDFLAGS)
my_cflags += $(LOCAL_CLANG_CFLAGS_$($(my_prefix)ARCH)) $(LOCAL_CLANG_CFLAGS_$(my_32_64_bit_suffix))
my_cppflags += $(LOCAL_CLANG_CPPFLAGS_$($(my_prefix)ARCH)) $(LOCAL_CLANG_CPPFLAGS_$(my_32_64_bit_suffix))
my_ldflags += $(LOCAL_CLANG_LDFLAGS_$($(my_prefix)ARCH)) $(LOCAL_CLANG_LDFLAGS_$(my_32_64_bit_suffix))
my_asflags += $(LOCAL_CLANG_ASFLAGS_$($(my_prefix)ARCH)) $(LOCAL_CLANG_ASFLAGS_$(my_32_64_bit_suffix))

my_cflags := $(call convert-to-$(my_host)clang-flags,$(my_cflags))
my_cppflags := $(call convert-to-$(my_host)clang-flags,$(my_cppflags))
my_asflags := $(call convert-to-$(my_host)clang-flags,$(my_asflags))
my_ldflags := $(call convert-to-$(my_host)clang-flags,$(my_ldflags))
endif

$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_C_INCLUDES := $(my_c_includes)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_IMPORT_INCLUDES := $(import_includes)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_ASFLAGS := $(my_asflags)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_CONLYFLAGS := $(LOCAL_CONLYFLAGS)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_CFLAGS := $(my_cflags)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_CPPFLAGS := $(my_cppflags)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_LDFLAGS := $(my_ldflags)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_LDLIBS := $(LOCAL_LDLIBS)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_DEBUG_CFLAGS := $(debug_cflags)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_NO_CRT := $(strip $(LOCAL_NO_CRT)) $(LOCAL_NO_CRT_$(TARGET_ARCH))

#-----------------------------------------------------------
# this is really the way to get the files onto the command
# line instead of using $^, because then LOCAL_ADDITIONAL_DEPENDENCIES
# donesn't work
$(LOCAL_INTERMEDIATE_TARGETS) : PRIVATE_ALL_SHARED_LIBRARIES := $(built_shared_libraries)
$(LOCAL_INTERMEDIATE_TARGETS) : PRIVATE_ALL_STATIC_LIBRARIES := $(built_static_libraries)
$(LOCAL_INTERMEDIATE_TARGETS) : PRIVATE_ALL_WHOLE_STATIC_LIBRARIES := $(built_whole_libraries)
$(LOCAL_INTERMEDIATE_TARGETS) : PRIVATE_ALL_OBJECTS := $(all_objects)

#-----------------------------------------------------------
# Define library dependencies.
#-----------------------------------------------------------
# all_libraries is used for the dependencies on LOCAL_BUILT_MODULE.
all_libraries := \
    $(built_shared_libraries) \
    $(built_static_libraries) \
    $(built_whole_libraries)
