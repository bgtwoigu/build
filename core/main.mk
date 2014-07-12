#
# Copyright (C) 2013 The Gotoos Open Source Project
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation
#

# -----------------------------------------------------------
# Use bash, not whatever shell somebody has instaled as /bin/sh
# This is repeated in config.mk, since envsetup.sh runs that file
# directly
#
SHELL := /bin/bash

# -----------------------------------------------------------
# this turns off the suffix rules built into make
.SUFFIXES:

#
# this turns off the RCS/SCCS implicit rules of GNU Make
% : RCS/%,v
% : RCS/%
% : %,v
% : s.%
% : SCCS/s.%

# If a rule fails, delete $@
.DELETE_ON_ERROR:

# -----------------------------------------------------------
# Check for broken versions of make.
# Allow any version under Cygwin since we don't actually
# build the platform there.
ifeq (,$(findstring CYGWIN,$(shell uname -sm)))
ifeq (0,$(shell expr $$(echo $(MAKE_VERSION) | sed "s/[^0-9\.].*//") = 3.81))
ifeq (0,$(shell expr $$(echo $(MAKE_VERSION) | sed "s/[^0-9\.].*//") = 3.82))
$(warning **********************************************************)
$(warning * You are using version $(MAKE_VERSION) of make.)
$(warning * Gotoos can only be built by versions 3.81 and 3.82.)
$(warning * see https://github.com/gotoos)
$(warning **********************************************************)
$(error stopping)
endif
endif
endif

# ----------------------------------------------------------
# Figure out where we are.
# Absolute path of the present working directory.
# This overrides the shell varable $PWD, which does not necessarily points to
# the top fo the source tree, for example when "Make -C" is used in m/mm/mmm
PWD := $(shell pwd)

TOP := .
TOPDIR :=

BUILD_SYSTEM := $(TOPDIR)make/core

# ----------------------------------------------------------
# This is the default target. It must be the first declared target.
.PHONY: goto
DEFAULT_GOAL := goto
$(DEFAULT_GOAL):

# Used to force goals to build. Only use for conditionally defined goals.
.PHONY: FORCE
FORCE:

# ----------------------------------------------------------
# Targets that provide quick help on the build system.
include $(BUILD_SYSTEM)/help.mk

# ----------------------------------------------------------
# Set up various standard variables based on configuration
# and host informations.
include $(BUILD_SYSTEM)/config.mk

# ----------------------------------------------------------
# This allows us to force a clean build - included after the config.mk
# environment setup is done. but before we generate any dependencies.
# This file does the rm -rf inline so the deps which are all done below will
# be generated correctly.
# include $(BUILD_SYSTEM)/cleanbuild.mk

# ----------------------------------------------------------
# Check build tools versions.

VERSION_CHECK_SEQUENCE_NUMBER := 1
-include $(OUT_DIR)/versions_checked.mk
ifneq ($(VERSION_CHECK_SEQUENCE_NUMBER),$(VERSIONS_CHECKED))

$(info Checking build tools versions...)

ifneq ($(HOST_OS),windows)
ifneq ($(HOST_OS)-$(HOST_ARCH),darwin-ppc)
# check for a case sensitive file system
ifeq (a,$(shell mkdir -p $(OUT_DIR); \
           echo a > $(OUT_DIR)/casecheck.txt; \
           echo A > $(OUT_DIR)/CaseCheck.txt; \
           cat $(OUT_DIR)/CaseCheck.txt))
$(warning ********************************************************************)
$(warning You are building on a case-insensitive filesystem.)
$(warning Please move your source tree to a case-sensitive filesystem.)
$(warning ********************************************************************)
$(error Case-insensitive filesystems not supported)
endif
endif
endif

# Make sure that there are no spaces in the absolute path; the
# build system can't deal with them.
ifneq ($(words $(shell pwd)),1)
$(warning ********************************************************************)
$(warning You are building in a directory whose absolute path contains)
$(warning a space character:)
$(warning $(space))
$(warning "$(shell pwd)")
$(warning $(space))
$(warning Please move your source tree to a path that does no contain any spaces.)
$(warning ********************************************************************)
$(error Directory names containing spaces not supported)
endif

$(shell echo 'VERSIONS_CHECKED := $(VERSION_CHECK_SEQUENCE_NUMBER)' \
         > $(OUT_DIR)/versions_checked.mk \
  )
$(shell echo 'BUILD_EMULATOR := $(BUILD_EMULATOR)' \
         >> $(OUT_DIR)/versions_checked.mk \
  )

endif

# ----------------------------------------------------------
# Bring in standard build system definitions.
include $(BUILD_SYSTEM)/definitions.mk

# ----------------------------------------------------------
# Check make command line and build variant

ifneq ($(filter user userdebug eng,$(MAKECMDGOALS)),)
$(info ************************************************************************)
$(info Do not pass '$(filter user userdebug eng,$(MAKECMDGOALS))' \
        on the make command line)
$(info Set TARGET_BUILD_VARIANT in buildspec.mk, or use lunch or choosecombo.)
$(info ************************************************************************)
$(error stopping)
endif

ifneq ($(filter-out $(INTERNAL_VALID_VARIANTS),$(TARGET_BUILD_VARIANT)),)
$(info ************************************************************************)
$(info Invalid variant: $(TARGET_BUILD_VARIANT))
$(info Valid values are: $(INTERNAL_VALID_VARIANTS))
$(info ************************************************************************)
$(error stopping)
endif

# -----------------------------------------------------------
# user/userdebug
user_variant := $(filter user userdebug,$(TARGET_BUILD_VARIANT))
enable_target_debugging := true
tags_to_install :=
ifneq (,$(user_variant))
  ifeq ($(user_variant),userdebug)
    # Pick up some extra useful tools
    tags_to_install += debug
  else
    # Disable debugging in plain user builds.
    enable_target_debugging :=
  endif

else # !user_variant

endif # !user_variant

# -----------------------------------------------------------
# eng
ifeq ($(TARGET_BUILD_VARIANT),eng)
tags_to_install := debug eng
endif

# ----------------------------------------------------------
# Define a function that, given a list of module tags, returns
# non-empty if that module should be installed in /system

# For most goals, anything not tagged with the "tests" tag should
# be installed in /system
define should-install-to-system
$(if $(filter tests,$(1)),,true)
endef

# ----------------------------------------------------------
# Typical build; included any Gotoos.mk files we can find.
#
subdirs := $(TOP)

FULL_BUILD := true

# ----------------------------------------------------------
# Before we go and include all of the module makefiles, stash away
# the PRODUCT_* values so that later we can verify they are not modified.
#
stash_product_vars := false
ifeq ($(stash_product_vars),true)
  $(call stash-product-vars,__STASHED)
endif

# ----------------------------------------------------------
ifneq ($(ONE_SHOT_MAKEFILE),)
# We've probably been invoked by the "mm" shell function
# with a subdirectory's makefile.
include $(ONE_SHOT_MAKEFILE)
# Change CUSTOM_MODULES to include only modules that were
# defined by this makefile; this will install all of those
# modules as a side-effect. Do this after including ONE_SHOT_MAKEFILE
# so that the modules will be installed in the same place they
# would have been with a normal make.

else # ONE_SHOT_MAKEFILE

#
# Include all of the makefiles in the system
#

subdir_makefiles := \
    $(shell make/tools/miscs/findleaves.py \
    --prune=$(OUT_DIR) --prune=.repo --prune=.git \
    $(subdirs) Gotoos.mk)

$(foreach mk, $(subdir_makefiles), \
  $(info including $(mk) ...)$(eval include $(mk)))

endif # ONE_SHOT_MAKEFILE

ifeq ($(stash_product_vars),true)
  $(call assert-product-vars,__STASHED)
endif

include $(BUILD_SYSTEM)/legacy_prebuilts.mk
ifneq ($(filter-out $(GRANDFATHERED_ALL_PREBUILT), \
          $(strip $(notdir $(ALL_PREBUILT)))),)
    $(warning *** Some files have been added to ALL_PREBUILT.)
    $(warning *)
    $(warning * ALL_PREBUILT is a deprecated mechanism that)
    $(warning * should not be used for new files.)
    $(warning * As an alternative, use PRODUCT_COPY_FILES in)
    $(warning * the appropriate product definition.)
    $(warning * make/target/product/core.mk is the product)
    $(warning * definition used in all products.)
    $(warning *)
    $(foreach bad_prebuilt, \
       $(filter-out $(GRANDFATHERED_ALL_PREBUILT), \
          $(strip $(notdir $(ALL_PREBUILT)))), \
             $(warning * unexpected $(bad_prebuilt) in ALL_PREBUILT))
    $(warning *)
    $(error ALL_PREBUILT contains unexpected files)
endif

# ----------------------------------------------------------
# All module makefiles have been included at this point.
# ----------------------------------------------------------

# ----------------------------------------------------------
# Fix up CUSTOM_MODULES to refer to installed files rather than
# just bare module names. Leave unknown modules alone in case
# they're actually full paths to a particular file.
known_custom_modules := $(filter $(ALL_MODULES),$(CUSTOM_MODULES))
unknown_custom_modules := $(filter-out $(ALL_MODULES),$(CUSTOM_MODULES))
CUSTOM_MODULES := \
  $(call module-installed-files,$(known_custom_modules)) \
  $(unknown_custom_modules)

# -------------------------------------------------------------------
# Define dependencies for modules that require other modules.
# This can only happen now, after we've read in all module makefiles.
#
# TODO: deal with the fact that a bare module name isn't
# unambiguous enough.  Maybe declare short targets like
# APPS:Quake or HOST:SHARED_LIBRARIES:libutils.
# BUG: the system image won't know to depend on modules that are
# brought in as requirements of other modules.

define add-required-deps
$(1): | $(2)
endef

$(foreach m,$(ALL_MODULES), \
  $(eval r := $(ALL_MODULES.$(m).REQUIRED)) \
  $(if $(r), \
    $(eval r := $(call module-installed-files,$(r))) \
    $(eval t_m := $(filter $(TARGET_OUT_ROOT)/%, $(ALL_MODULES.$(m).INSTALLED))) \
    $(eval h_m := $(filter $(HOST_OUT_ROOT)/%, $(ALL_MODULES.$(m).INSTALLED))) \
    $(eval t_r := $(filter $(TARGET_OUT_ROOT)/%, $(r))) \
    $(eval h_r := $(filter $(HOST_OUT_ROOT)/%, $(r))) \
    $(if $(t_m), $(eval $(call add-required-deps, $(t_m),$(t_r)))) \
    $(if $(h_m), $(eval $(call add-required-deps, $(h_m),$(h_r)))) \
   ) \
 )

t_m :=
h_m :=
t_r :=
h_r :=

# Resolve the dependencies on shared libraries.
$(foreach m,$(TARGET_DEPENDENCIES_ON_SHARED_LIBRARIES), \
  $(eval p := $(subst :,$(space),$(m))) \
  $(eval r := $(filter $(TARGET_OUT_ROOT)/%,$(call module-installed-files,\
    $(subst $(comma),$(space),$(lastword $(p)))))) \
  $(eval $(call add-required-deps,$(word 2,$(p)),$(r))))
$(foreach m,$(HOST_DEPENDENCIES_ON_SHARED_LIBRARIES), \
  $(eval p := $(subst :,$(space),$(m))) \
  $(eval r := $(filter $(HOST_OUT_ROOT)/%,$(call module-installed-files,\
    $(subst $(comma),$(space),$(lastword $(p)))))) \
  $(eval $(call add-required-deps,$(word 2,$(p)),$(r))))

m :=
r :=
p :=

add-required-deps :=

# ----------------------------------------------------------
# Figure out our module sets.
#
# Of the modules defined by the component makefiles,
# determine what we actually want to build.

ifdef FULL_BUILD
  # The base list of modules to build for this product is specified
  # by the appropriate product definition file, which was included
  # by product_config.make.
  product_MODULES := $(PRODUCTS.$(INTERNAL_PRODUCT).PRODUCT_PACKAGES)
  $(call expand-required-modules,product_MODULES,$(product_MODULES))
  product_FILES := $(call module-installed-files,$(product_MODULES))

else
  # We're not doing a full build, and are probably only including
  # a subset of the module makefiles. Don't try to build any modules
  # requested by the product, because we probably won't have rules
  # to build them.
  product_FILES :=
endif # FULL_BUILD

eng_MOUDLES := \
  $(sort \
     $(call get-tagged-modules,eng) \
     $(call module-installed-files,$(PRODUCTS.$(INTERNAL_PRODUCT).PRODUCT_PACKAGES_ENG)) \
   )

debug_MOUDLES := \
  $(sort \
     $(call get-tagged-modules,debug) \
     $(call module-installed-files,$(PRODUCTS.$(INTERNAL_PRODUCT).PRODUCT_PACKAGES_DEBUG)) \
   )

# ----------------------------------------------------------
# TODO: Remove the 3 places in the tree that use
# ALL_DEFAULT_INSTALLED_MODULES and get rid of it from this
# list.
# TODO: The shell is chosen by magic. Do we still need this?
modules_to_install := \
    $(sort \
       $(ALL_DEFAULT_INSTALLED_MODULES) \
       $(product_FILES) \
       $(foreach tag,$(tags_to_install),$($(tag)_MODULES)) \
       $(call get-tagged-modules,shell_$(TARGET_SHELL)) \
       $(CUSTOM_MODULES) \
     )

# ----------------------------------------------------------
# make/core/Makefile contains extra stuff that we don't
# want to pollute this top-level makefile with. It expects
# that ALL_DEFAULT_INSTALLED_MODULES contains everything
# that's built during the current make, but it also further
# extends ALL_DEFAULT_INSTALLED_MODULES.
ALL_DEFAULT_INSTALLED_MODULES := $(modules_to_install)
include $(BUILD_SYSTEM)/Makefile
modules_to_install := $(sort $(ALL_DEFAULT_INSTALLED_MODULES))
ALL_DEFAULT_INSTALLED_MODULES :=

# ---------------------------------------------------------

# This is used to get the ordering right, you can also use these,
# but they're considered undocumented, so don't complain if their
# behavior changes
.PHONY: prebuilt
prebuilt: $(ALL_PREBUILT)

# An internal target that depends on all copied headers
# (see copy_headers.mk). Other targets that need the
# headers to be copied first can depend on this target.
.PHONY: all_copied_headers
all_copied_headers: ;

$(ALL_C_CPP_ETC_OBJECTS): | all_copied_headers

# ALl the goto stuff, in directories
.PHONY: files
files: prebuilt \
       $(modules_to_install)

.PHONY: bootloader
bootloader: $(INSTALLED_BOOTLOADER_TARGET)

.PHONY: kernel
kernel: $(INSTALLED_KERNEL_TARGET)

.PHONY: initramfs
ramdisk: $(INSTALLED_INITRAMFS_TARGET)

.PHONY: bootimage
bootimage: $(INSTALLED_BOOTIMAGE_TARGET)

# -----------------------------------------------------------
# Rules that need to be present for the all targets, even
# if they don't do anything
.PHONY: systemimage
systemimage: $(INSTALLED_SYSTEMIMAGE_TARGET)

# ----------------------------------------------------------
# phony target that include any targets in $(ALL_MODULES)
.PHONY: all_modules
all_modules: $(ALL_MODULES)

# -----------------------------------------------------------
# Building a full system-- the default is to build gotocore
.PHONY: gotocore
gotocore: \
    $(INSTALLED_BOOTLOADER_TARGET) \
    $(INSTALLED_KERNEL_TARGET) \
    $(INSTALLED_BOOTIMAGE_TARGET) \
    $(INSTALLED_FILES_FILE) \
    systemimage \

goto: gotocore

# -----------------------------------------------------------
.PHONY: clean
clean:
	@rm -rf $(OUT_DIR)
	@echo "Entire build directory removed."

.PHONY: showcommands
showcommands:
	@echo > /dev/null
