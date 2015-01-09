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

# -----------------------------------------------------------
# bootloader
ifneq ($(strip $(TARGET_NO_BOOTLOADER)), true)
  INSTALLED_BOOTLOADER_TARGET := $(PRODUCT_OUT)/bootloader
else
  INSTALLED_BOOTLOADER_TARGET :=
endif

INTERNAL_BOOTLOADER_FILE := $(TARGET_BOARDER_BOOTLOADER)

$(INSTALLED_BOOTLOADER_TARGET): $(INTERNAL_BOOTLOADER_FILE)
	$(call pretty, "Target bootloader: $< --> $@")
	$(copy-file-to-target-with-cp)

# -----------------------------------------------------------
# kernel
#ifneq ($(strip $(TARGET_NO_KERNEL)), true)
#  INSTALLED_KERNEL_TARGET := $(PRODUCT_OUT)/kernel
#else
#  INSTALLED_KERNEL_TARGET :=
#endif

#INTERNAL_KERNEL_FILE := $(TARGET_BOARDER_KERNEL)

#$(INSTALLED_KERNEL_TARGET): $(INTERNAL_KERNEL_FILE)
#	$(call pretty, "Target kernel: $< --> $@")
#	$(copy-file-to-target-with-cp)

# -----------------------------------------------------------
# the initramfs
INTERNAL_INITRAMFS_FILES := $(filter $(TARGET_ROOT_OUT)/%, \
    $(ALL_DEFAULT_INSTALLED_MODULES)) \
    $(ALL_PREBUILT)

BUILT_INITRAMFS_TARGET := $(PRODUCT_OUT)/initramfs.img
# We just build this directly to the install location.
INSTALLED_INITRAMFS_TARGET := $(BUILT_INITRAMFS_TARGET)
$(INSTALLED_INITRAMFS_TARGET): $(MKBOOTFS) $(INTERNAL_INITRAMFS_FILES)
	$(call pretty, "Target initramfs image: $@ <-- $<")
	$(hide) $(MKBOOTFS) $(TARGET_ROOT_OUT) | gzip -c > $@

# -----------------------------------------------------------
# second stage
ifneq ($(strip $(TARGET_NO_BOOTLOADER)),true)
  INSTALLED_BOOTLOADER_MODULE := $(PRODUCT_OUT)/bootloader
  ifeq ($(strip $(TARGET_BOOTLOADER_IS_2ND)),true)
    INSTALLED_2NDBOOTLOADER_TARGET := $(PRODUCT_OUT)/2ndbootloader
  else
    INSTALLED_2NDBOOTLOADER_TARGET :=
  endif
else
  INSTALLED_BOOTLOADER_MODULE :=
  INSTALLED_2NDBOOTLOADER_TARGET :=
endif # TARGET_NO_BOOTLOADER

# -----------------------------------------------------------
# the boot image, which is a collection of other images.
INTERNAL_BOOTIMAGE_ARGS := \
    $(addprefix --second, $(INSTALLED_2NDBOOTLOADER_TARGET)) \
    --kernel $(INSTALLED_KERNEL_TARGET) \
    --initramfs $(INSTALLED_INITRAMFS_TARGET)

INTERNAL_BOOTIMAGE_FILES := $(filter-out --%,$(INTERNAL_BOOTIMAGE_ARGS))

BOARD_KERNEL_CMDLINE := $(strip $(BOARD_KERNEL_CMDLINE))
ifdef BOARD_KERNEL_CMDLINE
  INTERNAL_BOOTIMAGE_ARGS += --cmdline "$(BOARD_KERNEL_CMDLINE)"
endif

BOARD_KERNEL_BASE := $(strip $(BOARD_KERNEL_BASE))
ifdef BOARD_KERNEL_BASE
  INTERNAL_BOOTIMAGE_ARGS += --base $(BOARD_KERNEL_BASE)
endif

BOARD_KERNEL_PAGESIZE := $(strip $(BOARD_KERNEL_PAGESIZE))
ifdef BOARD_KERNEL_PAGESIZE
  INTERNAL_BOOTIMAGE_ARGS += --pagesize $(BOARD_KERNEL_PAGESIZE)
endif

INSTALLED_BOOTIMAGE_TARGET := $(PRODUCT_OUT)/boot.img

$(INSTALLED_BOOTIMAGE_TARGET): $(MKBOOTIMG) $(INTERNAL_BOOTIMAGE_FILES)
	$(call pretty,"Target boot image: $@")
	$(hide) $(MKBOOTIMG) $(INTERNAL_BOOTIMAGE_ARGS) $(BOARD_MKBOOTIMG_ARGS) --output $@

# -----------------------------------------------------------
# Targets for user images
# -----------------------------------------------------------

INTERNAL_USERIMAGES_EXT_VARIANT :=
ifeq ($(TARGET_USERIMAGES_USE_EXT2),true)
INTERNAL_USERIMAGES_USE_EXT := true
INTERNAL_USERIMAGES_EXT_VARIANT := ext2
else
ifeq ($(TARGET_USERIMAGES_USE_EXT3),true)
INTERNAL_USERIMAGES_USE_EXT := true
INTERNAL_USERIMAGES_EXT_VARIANT := ext3
else
ifeq ($(TARGET_USERIMAGES_USE_EXT4),true)
INTERNAL_USERIMAGES_USE_EXT := true
INTERNAL_USERIMAGES_EXT_VARIANT := ext4
endif # TARGET_USERIMAGES_USE_EXT4
endif # TARGET_USERIMAGES_USE_EXT3
endif # TARGET_USERIMAGES_USE_EXT2

ifneq (true,$(TARGET_USERIMAGES_SPARSE_EXT_DISABLED))
  INTERNAL_USERIMAGES_SPARSE_EXT_FLAG := -s
endif

ifeq ($(INTERNAL_USERIMAGES_USE_EXT),true)
INTERNAL_USERIMAGES_DEPS := $(MKEXTUSERIMG) $(LUA) $(MKEXT4FS) $(SIMG2IMG) $(E2FSCK)
else
INTERNAL_USERIMAGES_DEPS := $(MKYAFFS2)
endif
INTERNAL_USERIMAGES_BINARY_PATHS := $(sort $(dir $(INTERNAL_USERIMAGES_DEPS)))

# $(1): the path of the output dictionary file
# $(2): additional "key=value" pairs to append to the dictionary file.
define generate-userimage-prop-dictinary
  $(if $(INTERNAL_USERIMAGES_EXT_VARIANT), \
    $(hide) echo "fs_type=$(INTERNAL_USERIMAGES_EXT_VARIANT)" >> $(1))
  $(if $(BOARD_SYSTEMIMAGE_PARTITION_SIZE), \
    $(hide) echo "system_size=$(BOARD_SYSTEMIMAGE_PARTITION_SIZE)" >> $(1))
  $(if $(BOARD_USERDATAIMAGE_PARTITION_SIZE), \
    $(hide) echo "userdata_size=$(BOARD_USERDATAIMAGE_PARTITION_SIZE)" >> $(1))
  $(if $(BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE), \
    $(hide) echo "cache_fs_type=$(BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE)" >> $(1))
  $(if $(BOARD_CACHEIMAGE_PARTITION_SIZE), \
    $(hide) echo "cache_size=$(BOARD_CACHEIMAGE_PARTITION_SIZE)" >> $(1))
  $(if $(BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE), \
    $(hide) echo "vendor_fs_type=$(BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE)" >> $(1))
  $(if $(BOARD_VENDORIMAGE_PARTITION_SIZE), \
    $(hide) echo "vendor_size=$(BOARD_VENDORIMAGE_PARTITION_SIZE)" >> $(1))
  $(if $(INTERNAL_USERIMAGES_SPARSE_EXT_FLAG), \
    $(hide) echo "extfs_sparse_flag=$(INTERNAL_USERIMAGES_SPARSE_EXT_FLAG)" >> $(1))
  $(if $(mkyaffs2_extra_flags), \
    $(hide) echo "mkyaffs2_extra_flags=$(mkyaffs2_extra_flags)" >> $(1))
  $(if $(ENABLE_SELINUX), \
    $(hide) echo "selinux_fc=$(SELINUX_FC)" >> $(1))
  $(if $(2),$(hide) $(foreach kv,$(2),echo "$(kv)" >> $(1);))
endef

# -----------------------------------------------------------
# the system image

INTERNAL_SYSTEMIMAGE_FILES := $(filter $(TARGET_OUT)/%, \
    $(ALL_PREBUILT) \
    $(ALL_DEFAULT_INSTALLED_MODULES) \
    )
FULL_SYSTEMIMAGE_DEPS := \
    $(INTERNAL_SYSTEMIMAGE_FILES) \
    $(INTERNAL_USERIMAGES_DEPS)

systemimage_intermediates := \
	$(call intermediates-dir-for,PACKAGING,systemimage)
BUILT_SYSTEMIMAGE := $(systemimage_intermediates)/system.img

# $(1): output file
define build-systemimage-target
  @echo "Target system fs image: $(1)"
  @mkdir -p $(dir $(1)) $(systemimage_intermediates)
  @rm -rf $(systemimage_intermediates)/systemimage_info.txt
  $(call generate-userimage-prop-dictinary, \
     $(systemimage_intermediates)/systemimage_info.txt, skip_fsck=true)
  $(hide) PATH=$(foreach p,$(INTERNAL_USERIMAGES_BINARY_PATHS),$(p):)$$PATH \
    $(LUA) ./build/tools/mkimage/mkimage.lua \
    $(TARGET_OUT) $(systemimage_intermediates)/systemimage_info.txt $(1)
endef

$(BUILT_SYSTEMIMAGE): $(FULL_SYSTEMIMAGE_DEPS)
	$(call build-systemimage-target, $@)

INSTALLED_SYSTEMIMAGE_TARGET := $(PRODUCT_OUT)/system.img

$(INSTALLED_SYSTEMIMAGE_TARGET): $(BUILT_SYSTEMIMAGE)
	@echo "Install system fs image: $@"
	$(copy-file-to-target-with-cp)
