#
# Copyright (C) 2013 The Gotoos Open Source Project
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation
#

# ------------------------------------------------------------
# Common instructions for a generic module.

LOCAL_MODULE := $(strip $(LOCAL_MODULE))
ifeq ($(LOCAL_MODULE),)
  $(error $(LOCAL_PATH): LOCAL_MODULE is not defined)
endif

LOCAL_IS_HOST_MODULE := $(strip $(LOCAL_IS_HOST_MODULE))
ifdef LOCAL_IS_HOST_MODULE
  ifneq ($(LOCAL_IS_HOST_MODULE),true)
    $(error $(LOCAL_PATH): LOCAL_IS_HOST_MODULE must be "true" or empty, \
            not "$(LOCAL_IS_HOST_MODULE)" \
     )
  endif
  my_prefix := HOST_
  my_host := host-
else
  my_prefix := TARGET_
  my_host :=
endif # LOCAL_IS_HOST_MODULE

ifndef LOCAL_IS_HOST_MODULE
my_32_64_bit_suffix := $(if $(TARGET_IS_64_BIT),64,32)
endif

# ------------------------------------------------------------
# Validate and define fallbacks for input LOCAL_* variables.
#
LOCAL_UNINSTALLABLE_MODULE := $(strip $(LOCAL_UNINSTALLABLE_MODULE))
LOCAL_MODULE_TAGS := $(sort $(LOCAL_MODULE_TAGS))
ifeq (,$(LOCAL_MODULE_TAGS))
  LOCAL_MODULE_TAGS := optional
endif

# ------------------------------------------------------------
# User tags are not allowed anymore. Fail early because it will not be
# installed like it used to be.
ifneq ($(fileter $(LOCAL_MODULE_TAGS),user),)
  $(warning *** Module name: $(LOCAL_MODULE))
  $(warning *** Makefile location: $(LOCAL_MODULE_MAKEFILE))
  $(warning * )
  $(warning * Module is attempting to use the 'user' tag. This)
  $(warning * used to cause the module to be installed automatically.)
  $(warning * Now, the module must be listed in the PRODUCT_PACKAGES)
  $(warning * section of a product makefile to have it installed.)
  $(warning * )
  $(error user tag detected on module.)
endif

# Only the tags mentioned in this test are expected to be set by module
# makefiles. Anything else is either a type or a source of unexpected
# behaviors.
ifneq ($(filter-out debug eng tests optional samples shell_bash,$(LOCAL_MODULE_TAGS)),)
  $(warning unususal tag $(LOCAL_MODULE_TAGS) on $(LOCAL_MODULE) at $(LOCAL_PATH))
endif

# ------------------------------------------------------------
LOCAL_MODULE_CLASS := $(strip $(LOCAL_MODULE_CLASS))
ifneq ($(words $(LOCAL_MODULE_CLASS)),1)
  $(error $(LOCAL_PATH): LOCAL_MODULE_CLASS must contain exactly one word, \
            not "$(LOCAL_MODULE_CLASS)")
endif

ifneq (true,$(LOCAL_UNINSTALLABLE_MODULE))

LOCAL_MODULE_PATH := $(strip $(LOCAL_MODULE_PATH))
ifeq ($(LOCAL_MODULE_PATH),)
  ifdef LOCAL_IS_HOST_MODULE
    partition_tag :=
  else # !LOCAL_IS_HOST_MODULE
    partition_tag := $(if $(call should-install-to-system,$(LOCAL_MODULE_TAGS)),,_DATA)
  endif # LOCAL_IS_HOST_MODULE
  install_path_var := $(my_prefix)OUT$(partition_tag)_$(LOCAL_MODULE_CLASS)
  LOCAL_MODULE_PATH := $($(install_path_var))
  ifeq ($(strip $(LOCAL_MODULE_PATH)),)
    $(error $(LOCAL_PATH): unhandled install path "$(install_path_var)")
  endif
endif # LOCAL_MODULE_PATH

endif # LOCAL_UNINSTALLABLE_MODULE

ifdef LOCAL_IS_HOST_MODULE
my_module_path :=
else
my_module_path := $(strip $(LOCAL_MODULE_PATH))
endif

# ------------------------------------------------------------
ifneq ($(strip $(LOCAL_BUILT_MODULE)$(LOCAL_INSTALLED_MODULE)),)
$(error $(LOCAL_PATH): LOCAL_BUILT_MODULE and LOCAL_INSTALLED_MODULE \
        must not be defined by component makefiles)
endif

# ------------------------------------------------------------
intermediates := $(call local-intermediates-dir)

# ------------------------------------------------------------
# Pick a name for the intermediate and final targets.
#
LOCAL_MODULE_STEM := $(strip $(LOCAL_MODULE_STEM))
ifeq ($(LOCAL_MODULE_STEM),)
  LOCAL_MODULE_STEM := $(LOCAL_MODULE)
endif
LOCAL_INSTALLED_MODULE_STEM := $(LOCAL_MODULE_STEM)$(LOCAL_MODULE_SUFFIX)

LOCAL_BUILT_MODULE_STEM := $(strip $(LOCAL_BUILT_MODULE_STEM))
ifeq ($(LOCAL_BUILT_MODULE_STEM),)
  LOCAL_BUILT_MODULE_STEM := $(LOCAL_INSTALLED_MODULE_STEM)
endif

# OVERRIDE_BUILT_MODULE_PATH is only allowed to be used by the
# internal SHARED_LIBRARIES build files.
OVERRIDE_BUILT_MODULE_PATH := $(strip $(OVERRIDE_BUILT_MODULE_PATH))
ifdef OVERRIDE_BUILT_MODULE_PATH
  ifneq ($(LOCAL_MODULE_CLASS), SHARED_LIBRARIES)
    $(error $(LOCAL_PATH): Illegal use of OVERRIDE_BUILT_MODULE_PATH)
  endif
  built_module_path := $(OVERRIDE_BUILT_MODULE_PATH)
else
  built_module_path := $(intermediates)
endif

LOCAL_BUILT_MODULE := $(built_module_path)/$(LOCAL_BUILT_MODULE_STEM)
built_module_path :=

ifneq (true,$(LOCAL_UNINSTALLABLE_MODULE))
  LOCAL_INSTALLED_MODULE := $(LOCAL_MODULE_PATH)/$(LOCAL_INSTALLED_MODULE_STEM)
endif

# ------------------------------------------------------------
LOCAL_INTERMEDIATE_TARGETS += $(LOCAL_BUILT_MODULE)

$(LOCAL_INTERMEDIATE_TARGETS) : PRIVATE_INSTALLED_DIR := $(dir $(LOCAL_INSTALLED_MODULE))
$(LOCAL_INTERMEDIATE_TARGETS) : PRIVATE_HOST := $(my_host)
$(LOCAL_INTERMEDIATE_TARGETS) : PRIVATE_INTERMEDIATES_DIR := $(intermediates)

# Tell the module and all of its sub-modules who it is
$(LOCAL_INTERMEDIATE_TARGETS) : PRIVATE_MODULE := $(LOCAL_MODULE)

# ------------------------------------------------------------
# Provide a short-hand for building this module.
# We name both BUILT and INSTALLED in case
# LOCAL_UNINSTALLABLE_MODULE is set.
.PHONY: $(LOCAL_MODULE)
$(LOCAL_MODULE): $(LOCAL_BUILT_MODULE) $(LOCAL_INSTALLED_MODULE)

# -----------------------------------------------------------
# Module installation rule
# -----------------------------------------------------------

ifndef LOCAL_UNINSTALLABLE_MODULE
# Define a copy rule to install the module.
$(LOCAL_INSTALLED_MODULE): $(LOCAL_BUILT_MODULE)
	@echo "Install: $@"
	$(copy-file-to-target-with-cp)
endif # LOCAL_UNINSTALLABLE_MODULE

# -----------------------------------------------------------
# CHECK_BUILD goals
# -----------------------------------------------------------

# If nobody has defined a more specific module for the
# checked modules, use LOCAL_BUILT_MODULE.
ifndef LOCAL_CHECKED_MODULE
  LOCAL_CHECKED_MODULE := $(LOCAL_BUILT_MODULE)
endif

# If they request that this module not be checked, then don't.
# PLEASE DON't SET THIS. ANY PLACES THAT SET THIS WITHOUT
# GOOD REASON WILL HAVE IT REMOVED.
ifdef LOCAL_DONT_CHECK_MODULE
  LOCAL_CHECKED_MODULE :=
endif

# -----------------------------------------------------------
# Register with ALL_MODULES
#
ALL_MODULES += $(LOCAL_MODULE)

# Don't use += on subvars, or else they'll end up being
# recursively expanded.
ALL_MODULES.$(LOCAL_MODULE).CLASS := \
    $(ALL_MODULES.$(LOCAL_MODULE).CLASS) $(LOCAL_MODULE_CLASS)
ALL_MODULES.$(LOCAL_MODULE).PATH := \
    $(ALL_MODULES.$(LOCAL_MODULE).PATH) $(LOCAL_PATH)
ALL_MODULES.$(LOCAL_MODULE).TAG := \
    $(ALL_MODULES.$(LOCAL_MODULE).TAGS) $(LOCAL_MODULE_TAGS)
ALL_MODULES.$(LOCAL_MODULE).CHECKED := \
    $(ALL_MODULES.$(LOCAL_MODULE).CHECKED) $(LOCAL_CHECKED_MODULE)
ALL_MODULES.$(LOCAL_MODULE).BUILT := \
    $(ALL_MODULES.$(LOCAL_MODULE).BUILT) $(LOCAL_BUILT_MODULE)
ALL_MODULES.$(LOCAL_MODULE).INSTALLED := \
    $(ALL_MODULES.$(LOCAL_MODULE).INSTALLED) $(LOCAL_INSTALLED_MODULE)
ALL_MODULES.$(LOCAL_MODULE).REQUIRED := \
    $(ALL_MODULES.$(LOCAL_MODULE).REQUIRED) $(LOCAL_REQUIRED_MODULES)
ALL_MODULES.$(LOCAL_MODULE).MAKEFILE := \
    $(ALL_MODULES.$(LOCAL_MODULE).MAKEFILE) $(LOCAL_MODULE_MAKEFILE)
ifdef LOCAL_MODULE_OWNER
ALL_MODULES.$(LOCAL_MODULE).OWNER := \
    $(sort $(ALL_MODULES.$(LOCAL_MODULE).OWNER) $(LOCAL_MODULE_OWNER))
endif

INSTALLABLE_FILES.$(LOCAL_INSTALLED_MODULE).MODULE := $(LOCAL_MODULE)

# ------------------------------------------------------------
# Take care of LOCAL_MODULE_TAGS
# Keep track of all the tags we've seen.
ALL_MODULE_TAGS := $(sort $(ALL_MODULE_TAGS) $(LOCAL_MODULE_TAGS))

# Add this module to the tag list of each specified tag.
# Don't use "+=". If the variable hasn't been set with ":=",
# it will default to recursive expansion.
$(foreach tag,$(LOCAL_MODULE_TAGS), \
   $(eval ALL_MODULE_TAGS.$(tag) := \
      $(ALL_MODULE_TAGS.$(tag)) \
      $(LOCAL_INSTALLED_MODULE) \
    ) \
 )