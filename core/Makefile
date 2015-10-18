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


# -----------------------------------------------------------
# Targets for boot/OS images
# -----------------------------------------------------------

#---------------------------------------------------------------------
# the initramfs
INTERNAL_INITRAMFS_FILES := $(filter $(TARGET_OUT_ROOT)/%, \
    $(ALL_DEFAULT_INSTALLED_MODULES)) \
    $(ALL_PREBUILT)

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
