#
# Copyright (C) 2013 The Yudatun Open Source Project
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation
#

# ------------------------------------------------------------
# Standard rules for building any target-side binaries
# with dynamic linkage (dynamic libraries or executables
# that link with dynamic libraries)
#
# Files including this file must define a rule to build
# the target $(linked_module).
# ------------------------------------------------------------

# ------------------------------------------------------------
# The name of the target file, without any path prepended.
# TODO: This duplicates logic from base_rules.mk because
#       We need to know its results before base_rules.mk
#       is included. Consolidate the duplicates.
LOCAL_MODULE_STEM := $(strip $(LOCAL_MODULE_STEM))
ifeq ($(LOCAL_MODULE_STEM),)
  LOCAL_MODULE_STEM := $(LOCAL_MODULE)
endif
LOCAL_INSTALLED_MODULE_STEM := $(LOCAL_MODULE_STEM)$(LOCAL_MODULE_SUFFIX)
LOCAL_BUILT_MODULE_STEM := $(strip $(LOCAL_INSTALLED_MODULE_STEM))

# ------------------------------------------------------------

# base_rules.make defines $(intermediates), but we need its value
# before we include base_rules. Make a guess, and verify that
# it's correct once the real value is defined.
guessed_intermediates := $(call local-intermediates-dir)

# Define the target that is the unmodified output of the linker.
# The basename of this target must be the same as the final output
# binary name, because it's used to set the "soname" in the binary.
# The includer of this file will define a rule to build this target.
linked_module := $(guessed_intermediates)/LINKED/$(LOCAL_BUILT_MODULE_STEM)

ALL_ORIGINAL_DYNAMIC_BINARIES += $(linked_module)

# Because TARGET_SYMBOL_FILTER_FILE depends on ALL_ORIGINAL_DYNAMIC_BINARIES,
# the linked_module rules won't necessarily inherit the PRIVATE_
# variables from LOCAL_BUILT_MODULE. This tells binary.make to explicitly
# define the PRIVATE_ variables for linked_module as well as for
# LOCAL_BUILT_MODULE.
LOCAL_INTERMEDIATE_TARGETS := $(linked_module)

# ------------------------------------------------------------
# Include binary.mk
include $(BUILD_SYSTEM)/binary.mk

# Make sure that our guess at the value of intermediates
# was correct.
ifneq ($(intermediates),$(guessed_intermediates))
$(error Internal error: guessed path '$(guessed_intermediates)' \
        doesn't match '$(intermediates))
endif

# -----------------------------------------------------------
# Compress
# -----------------------------------------------------------
compress_input := $(linked_module)

ifeq ($(strip $(LOCAL_COMPRESS_MODULE_SYMBOLS)),)
  LOCAL_COMPRESS_MODULE_SYMBOLS := $(strip $(TARGET_COMPRESS_MODULE_SYMBOLS))
endif

ifeq ($(LOCAL_COMPRESS_MODULE_SYMBOLS),true)
$(error Symbol compression not yet supported.)
compress_output :=
else
compress_output := $(compress_input)
endif

# -----------------------------------------------------------
# Store a copy with symbols for symbolic debugging
# -----------------------------------------------------------
ifeq ($(LOCAL_UNSTRIPPED_PATH),)
my_unstripped_path := $(TARGET_OUT_UNSTRIPPED)/$(patsubst $(PRODUCT_OUT)/%,%,$(my_module_path))
else
my_unstripped_path := $(LOCAL_UNSTRIPPED_PATH)
endif # LOCAL_UNSTRIPPED_PATH

symbolic_input := $(compress_output)
symbolic_output := $(my_unstripped_path)/$(LOCAL_BUILT_MODULE_STEM)
$(symbolic_output) : $(symbolic_input)
	@echo "target Symbolic: $(PRIVATE_MODULE) ($@)"
	$(copy-file-to-target-with-cp)

# -----------------------------------------------------------
# Strip
# -----------------------------------------------------------
strip_input := $(symbolic_output)
strip_output := $(LOCAL_BUILT_MODULE)

ifeq ($(strip $(LOCAL_STRIP_MODULE)),)
  LOCAL_STRIP_MODULE := $(strip $(TARGET_STRIP_MODULE))
endif

ifeq ($(LOCAL_STRIP_MODULE),true)
# Strip the binary
$(strip_output): $(strip_input) | $(TARGET_STRIP)
	$(transform-to-stripped)
else
# Don't strip the binary, just copy it. We can't skip this step
# because a copy of the binary must appear at LOCAL_BUILT_MODULE.
$(strip_output): $(strip_input)
	@echo "target Unstripped: $(PRIVATE_MODULE) ($@)"
	$(copy-file-to-target-with-cp)
endif # LOCAL_STRIP_MODULE
