#
# Copyright (C) 2013 The Gotoos Open Source Project
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation
#

#
# the setpath shell function in envsetup.sh uses this
# to figure out what to add to the path given the config
# we have chosen.
#

ifeq ($(CALLED_FROM_SETUP),true)

ifneq ($(filter /%,$(HOST_OUT_EXECUTABLES)),)
GBP := $(HOST_OUT_EXECUTABLES)
else
GBP := $(PWD)/$(HOST_OUT_EXECUTABLES)
endif

# Add the ARM toolchain bin dir if it actually exists
ifeq ($(TARGET_ARCH),arm)
  ifneq ($(wildcard $(PWD)/compiler/$(HOST_COMPILER_TAG)/arm-gcc/arm-none-linux-gnueabi-$(TARGET_GCC_VERSION)/bin),)
  # this should be copied to HOST_OUT_EXECUTABLES instead
  GBP := $(GBP):$(PWD)/compiler/$(HOST_COMPILER_TAG)/arm-gcc/arm-none-linux-gnueabi-$(TARGET_GCC_VERSION)/bin
  endif

  ifneq ($(wildcard $(PWD)/compiler/$(HOST_COMPILER_TAG)/arm-gcc/arm-none-eabi-$(TARGET_GCC_VERSION)/bin),)
  #
  GBP := $(GBP):$(PWD)/compiler/$(HOST_COMPILER_TAG)/arm-gcc/arm-none-eabi-$(TARGET_GCC_VERSION)/bin
  endif
endif

GOTOOS_BUILD_PATHS := $(GBP)
GOTOOS_COMPILERS := compiler/$(HOST_COMPILER_TAG)
GOTOOS_GCC_COMPILER := compiler/$(HOST_COMPILER_TAG)/arm-gcc

# The "dumpvar" stuff lets you say something like
#
#   CALLED_FROM_SETUP=true \
#     make -f config/envsetup.make dumpvar-TARGET_OUT
# or
#   CALLED_FROM_SETUP=true \
#     make -f config/envsetup.make dumpvar-abs-HOST_OUT_EXECUTABLES
#
# The plain (non-abs) version just dumps the value of the named variable.
# The "abs" version will treat the variable as a path, and dumps an
# absolute path to it.
dumpvar_goals := \
    $(strip $(patsubst dumpvar-%,%,$(filter dumpvar-%,$(MAKECMDGOALS))))
ifdef dumpvar_goals

  ifneq ($(words $(dumpvar_goals)),1)
    $(error Only one "dumpvar-" goal allowed. Saw "$(MAKECMDGOALS)")
  endif

  # If the goal is of the form "dumpvar-abs-VARNAME", then
  absolute_dumpvar := $(strip $(filter abs-%,$(dumpvar_goals)))
  ifdef absolute_dumpvar
    dumpvar_goals := $(patsubst abs-%,%,$(dumpvar_goals))
    ifneq ($(filter /%,$($(dumpvar_goals))),)
      DUMPVAR_VALUE := $($(dumpvar_goals))
    else
      DUMPVAR_VALUE := $(PWD)/$($(dumpvar_goals))
    endif
    dumpvar_target := dumpvar-abs-$(dumpvar_goals)
  else
    DUMPVAR_VALUE := $($(dumpvar_goals))
    dumpvar_target := dumpvar-$(dumpvar_goals)
  endif # absolute_dumpvar

.PHONY: $(dumpvar_target)
$(dumpvar_target):
	@echo $(DUMPVAR_VALUE)

endif # dumpvar_goals

ifneq ($(dumpvar_goals),report_config)
PRINT_BUILD_CONFIG :=
endif

endif # CALLED_FROM_SETUP

ifneq ($(PRINT_BUILD_CONFIG),)
HOST_OS_EXTRA:= $(shell uname -svr)
$(info =============================================)
$(info PLATFORM_VERSION=$(PLATFORM_VERSION))
$(info TARGET_PRODUCT=$(TARGET_PRODUCT))
$(info TARGET_BUILD_VARIANT=$(TARGET_BUILD_VARIANT))
$(info TARGET_BUILD_TYPE=$(TARGET_BUILD_TYPE))
$(info TARGET_BUILD_APPS=$(TARGET_BUILD_APPS))
$(info TARGET_ARCH=$(TARGET_ARCH))
$(info TARGET_ARCH_VARIANT=$(TARGET_ARCH_VARIANT))
$(info TARGET_CPU_VARIANT=$(TARGET_CPU_VARIANT))
$(info HOST_ARCH=$(HOST_ARCH))
$(info HOST_OS=$(HOST_OS))
$(info HOST_OS_EXTRA=$(HOST_OS_EXTRA))
$(info HOST_BUILD_TYPE=$(HOST_BUILD_TYPE))
$(info OUT_DIR=$(OUT_DIR))
$(info =============================================)
endif
