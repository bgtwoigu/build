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

ifeq (cpio, $(TARGET_INITRAMFS_IMAGE_FILESYSTEM))
$(INSTALLED_INITRAMFS_TARGET): $(MKBOOTFS)
endif # TARGET_INITRAMFS_IMAGE_FILESYSTEM
$(INSTALLED_INITRAMFS_TARGET): $(INTERNAL_INITRAMFS_FILES)

$(INSTALLED_INITRAMFS_TARGET):
	$(call pretty, "Target initramfs image: $@")
ifeq (cpio, $(TARGET_INITRAMFS_IMAGE_FILESYSTEM))
	$(hide) $(MKBOOTFS) $(TARGET_OUT_ROOT) | gzip -c > $@
endif # TARGET_INITRAMFS_IMAGE_FILESYSTEM

#-----------------------------------------------------------
# The system image

ifeq (ext4, $(strip $(TARGET_SYSTEMIMAGE_FILESYSTEM)))
INTERNAL_SYSTEMIMAGE_DEPS := $(MKEXT4FS)
endif
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

define generate-systemimage-prop-file
$(if $(strip $(TARGET_SYSTEMIMAGE_FILESYSTEM)), \
  $(hide) echo "fs_type=$(TARGET_SYSTEMIMAGE_FILESYSTEM)" >> $(1))
$(if $(strip $(TARGET_SYSTEMIMAGE_SIZE)), \
  $(hide) echo "size=$(TARGET_SYSTEMIMAGE_SIZE)" >> $(1))
endef

define build-systemimage-target
    @echo "Target system image: $(1)"
    @mkdir -p $(dir $(1))
    @mkdir -p $(systemimage_intermediates)
    @rm -rf $(systemimage_intermediates)/systemimage_info.txt
    $(call generate-systemimage-prop-file, \
      $(systemimage_intermediates)/systemimage_info.txt)
endef

$(BUILT_SYSTEMIMAGE_TARGET): $(FULL_SYSTEMIMAGE_DEPS) $(INSTALLED_FILES_FILE)
	$(call build-systemimage-target,$@)

INSTALLED_SYSTEMIMAGE_TARGET := $(PRODUCT_OUT)/system.img

$(INSTALLED_SYSTEMIMAGE_TARGET): $(BUILT_SYSTEMIMAGE_TARGET)
	@echo "Install system image: $@"
