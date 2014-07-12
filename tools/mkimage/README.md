The Yudatun Open Source Project -- mkimage.lua
================================================================================

How to make image with filesystem ?
--------------------------------------------------------------------------------

In this case, we assume to the board is qemu and make system.img.

### config BoardConfig.mk

path: make/target/board/qemu/BoardConfig.mk

```
TARGET_USERIMAGES_USE_EXT4 := true  # config file system

BOARD_SYSTEMIMAGE_PARTITION_SIZE := 52428800 # config system partition size
```

### config Makefile

path: make/core/Makefile

```
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
    $(LUA) ./make/tools/mkimage/mkimage.lua \
    $(TARGET_OUT) $(systemimage_intermediates)/systemimage_info.txt $(1)
endef

$(BUILT_SYSTEMIMAGE): $(FULL_SYSTEMIMAGE_DEPS)
	$(call build-systemimage-target, $@)

INSTALLED_SYSTEMIMAGE_TARGET := $(PRODUCT_OUT)/system.img

$(INSTALLED_SYSTEMIMAGE_TARGET): $(BUILT_SYSTEMIMAGE)
	@echo "Install system fs image: $@"
	$(copy-file-to-target-with-cp)

```