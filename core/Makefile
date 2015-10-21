#
# Copyright (C) 2013 The Yudatun Open Source Project
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation
#

# Put some miscellaneous rules here.

# -----------------------------------------------------------
# Define rules to copy PRODUCT_COPY_FILES defined by the product.
# PRODUCT_COPY_FILES contains words like <source file>:<dest file>[:<owner>]
# <dest file> is relative to $(PRODUCT_OUT), so it should look like,
# e.g., "/etc/file.xml".
# The filter part means "only eval the copy-one-file rule if this
# src:dest pair is the first one to match the same dest"
# $(1): the src:dest pair

# filter out the duplicate <source file>:<dest file> pairs.
unique_product_copy_files_pairs :=
$(foreach cf, $(PRODUCT_COPY_FILES), \
  $(if $(filter $(unique_product_copy_files_pairs), $(cf)),, \
    $(eval unique_product_copy_files_pairs += $(cf)) \
   ) \
 )
unique_product_copy_files_destinations :=
$(foreach cf, $(unique_product_copy_files_pairs), \
  $(eval _src := $(call word-colon,1,$(cf))) \
  $(eval _dst := $(call word-colon,2,$(cf))) \
  $(if $(filter $(unique_product_copy_files_destinations), $(_dst)), \
    $(info PRODUCT_COPY_FILES $(cf) ignored.), \
    $(eval _fulldst := $(call append-path,$(PRODUCT_OUT),$(_dst))) \
    $(eval $(call copy-one-file,$(_src),$(_fulldst))) \
    $(eval ALL_DEFAULT_INSTALLED_MODULES += $(_fulldst)) \
    $(eval unique_product_copy_files_destinations += $(_dst)) \
   ) \
 )
unique_product_copy_files_pairs :=
unique_product_copy_files_destinations :=

#------------------------------------------------------------
# Targets for boot/OS images
#------------------------------------------------------------

#------------------------------------------------------------
# The initramfs image
INTERNAL_INITRAMFS_FILES := $(filter $(TARGET_OUT_ROOT)/%, \
    $(ALL_PREBUILT) \
    $(ALL_DEFAULT_INSTALLED_MODULES))

BUILT_INITRAMFS_TARGET := $(PRODUCT_OUT)/initramfs.img

# We just build this directly to the install location.
INSTALLED_INITRAMFS_TARGET := $(BUILT_INITRAMFS_TARGET)

$(INSTALLED_INITRAMFS_TARGET): $(MKBOOTFS)
$(INSTALLED_INITRAMFS_TARGET): $(INTERNAL_INITRAMFS_FILES)

$(INSTALLED_INITRAMFS_TARGET):
	$(call pretty, "Target initramfs image: $@")
	$(hide) $(MKBOOTFS) $(TARGET_OUT_ROOT) | gzip -c > $@

#-----------------------------------------------------------
# The system image

INTERNAL_SYSTEMIMAGE_DEPS := $(MKEXT4FS)
INTERNAL_SYSTEMIMAGE_DEPS += $(SIMG2IMG)
INTERNAL_SYSTEMIMAGES_BINARY_PATH := $(sort $(dir $(INTERNAL_SYSTEMIMAGE_DEPS)))

INTERNAL_SYSTEMIMAGE_FILES := $(filter $(TARGET_OUT_SYSTEM)/%, \
    $(ALL_PREBUILT) \
    $(ALL_DEFAULT_INSTALLED_MODULES))

FULL_SYSTEMIMAGE_DEPS := \
    $(INTERNAL_SYSTEMIMAGE_FILES) \
    $(INTERNAL_SYSTEMIMAGE_DEPS)

# installed file list
INSTALLED_FILES_FILE := $(PRODUCT_OUT)/installed-files.txt
$(INSTALLED_FILES_FILE): $(FULL_SYSTEMIMAGE_DEPS)
	@echo "Installed file list: $@"
	@mkdir -p $(dir $@)
	@rm -f $@
	$(hide) build/tools/misc/filelist.py $(TARGET_OUT_SYSTEM) > $@

.PHONY: installed-file-list
installed-file-list: $(INSTALLED_FILES_FILE)

systemimage_intermediates := \
    $(call intermediates-dir-for,PACKAGING,systemimage)
BUILT_SYSTEMIMAGE_TARGET := $(systemimage_intermediates)/system.img

INTERNAL_SYSTEMIMAGE_ARGS := -v -l system

TARGET_SYSTEMIMAGE_SIZE := $(strip $(TARGET_SYSTEMIMAGE_SIZE))
ifdef TARGET_SYSTEMIMAGE_SIZE
  INTERNAL_SYSTEMIMAGE_ARGS += --size=$(TARGET_SYSTEMIMAGE_SIZE)
endif

TARGET_SYSTEMIMAGE_MOUNTPOINT := $(strip $(TARGET_SYSTEMIMAGE_MOUNTPOINT))
ifdef TARGET_SYSTEMIMAGE_MOUNTPOING
  INTERNAL_SYSTEMIMAGE_ARGS += --mount-point=$(TARGET_SYSTEMIMAGE_MOUNTPOINT)
else
  INTERNAL_SYSTEMIMAGE_ARGS += --mount-point=system
endif

ifeq (true, $(strip $(TARGET_SYSTEMIMAGE_GZIP)))
  INTERNAL_SYSTEMIMAGE_ARGS += --gzip
endif

ifeq (true, $(strip $(TARGET_SYSTEMIMAGE_SPARSE)))
  INTERNAL_SYSTEMIMAGE_ARGS += --sparse
endif

ifeq (true, $(strip $(TARGET_SYSTEMIMAGE_CRC)))
  INTERNAL_SYSTEMIMAGE_ARGS += --crc
endif

define build-systemimage-target
    @echo "Target system image: $(1)"
    @mkdir -p $(dir $(1))
    $(hide) PATH=$(foreach p,$(INTERNAL_USERIMAGES_BINARY_PATHS),$(p):)$$PATH \
      ./build/tools/partition-box/mkext4fs $(INTERNAL_SYSTEMIMAGE_ARGS) \
        $(TARGET_OUT_SYSTEM) $(1) || \
        (echo "Out of space? the tree size of $(TARGET_OUT_SYSTEM) is (MB): " 1>&2 ; \
         du -sm $(TARGET_OUT_SYSTEM) 1>&2; \
         maxsize=$(TARGET_SYSTEMIMAGE_SIZE); \
         echo "The max is $$(( maxsize / 1048576 )) MB." 1>&2; \
         exit 1)
endef

$(BUILT_SYSTEMIMAGE_TARGET): $(FULL_SYSTEMIMAGE_DEPS) $(INSTALLED_FILES_FILE)
	$(call build-systemimage-target,$@)

INSTALLED_SYSTEMIMAGE_TARGET := $(PRODUCT_OUT)/system.img

$(INSTALLED_SYSTEMIMAGE_TARGET): $(BUILT_SYSTEMIMAGE_TARGET)
	@echo "Install system image: $@"
	$(copy-file-to-target-with-cp)
