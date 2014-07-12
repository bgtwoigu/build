#
# Copyright (C) 2013 The Yudatun Open Source Project
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation
#

# ------------------------------------------------------------
# Generic functions
# TODO: Move these to definitions.make once we're able to include
# definitions.make before config.make.

#
# Return non-empty if $(1) is a C identifier; i.e., if it
# matches /^[a-zA-Z_][a-zA-Z0-9_]*$/.  We do this by first
# making sure that it isn't empty and doesn't start with
# a digit, then by removing each valid character.  If the
# final result is empty, then it was a valid C identifier.
#
# $(1): word to check
#

_ici_digits := 0 1 2 3 4 5 6 7 8 9
_ici_alphaunderscore := \
    a b c d e f g h i j k l m n o p q r s t u v w x y z \
    A B C D E F G H I J K L M N O P Q R S T U V W X Y Z _
define is-c-identifier
$(strip \
  $(if $(1), \
    $(if $(filter $(addsuffix %,$(_ici_digits)),$(1)),, \
       $(eval w := $(1)) \
       $(foreach c,$(_ici_digits) $(_ici_alphaunderscore), \
          $(eval w := $(subst $(c),,$(w))) \
        ) \
      $(if $(w),,TRUE) \
      $(eval w :=) \
     ) \
   ) \
 )
endef

# ------------------------------------------------------------
# These are the valid values of TARGET_BILD_VARIANT.
# Also, if anything else is passed as the variant in the
# PRODUCT-$TARGET_BUILD_PRODUCT-$TARGET_BUILD_VARIANT
# form. it will be treated as a goal, and the eng variant will be used.
INTERNAL_VALID_VARIANTS := user userdebug eng

# ------------------------------------------------------------
# Include the product definitions.
# We need to do this to translate TARGET_PRODUCT into its
# underlying TARGET_DEVICE before we start defining any rules.
#
include $(BUILD_SYSTEM)/node_fns.mk
include $(BUILD_SYSTEM)/product.mk

ifneq ($(strip $(TARGET_BUILD_APPS)),)
# An unbundled app build needs only the core product makefiles.
all_product_configs := $(call get-product-makefiles, \
    $(SRC_TARGET_DIR)/product/YudatunProducts.mk)
else
# Read in all of the product definitions specified by the YudatunProduct.mk
# files in the tree.
all_product_configs := $(get-all-product-makefiles)
endif

# Find the product config makefile for the current product.
# all_product_configs consists items like:
# <product_name>:<path_to_the_product_makefile>
# or just <path_to_the_product_makefile> in case the product name is the
# same as the base filename of the product config makefile.
current_product_makefile :=
all_product_makefiles :=
$(foreach f,$(all_product_configs), \
   $(eval _cpm_words := $(subst :,$(space),$(f))) \
   $(eval _cpm_word1 := $(word 1,$(_cpm_words)))  \
   $(eval _cpm_word2 := $(word 2,$(_cpm_words)))  \
   $(if $(_cpm_word2),   \
        $(eval all_product_makefiles += $(_cpm_word2))  \
        $(if $(filter $(TARGET_PRODUCT),$(_cpm_word1)), \
           $(eval current_product_makefile += $(_cpm_word2)), \
         ), \
        $(eval all_product_makefiles += $(f)) \
        $(if $(filter $(TARGET_PRODUCT),$(basename $(notdir $(f)))), \
           $(eval current_product_makefile += $(f)), \
         ) \
    ) \
 )
_cpm_words :=
_cpm_word1 :=
_cpm_word2 :=
current_product_makefile := $(strip $(current_product_makefile))
all_product_makefiles := $(strip $(all_product_makefiles))

# Import all or just the current product makefile
ifneq (,$(filter product-graph dump-products, $(MAKECMDGOALS)))
# Import all product makefiles.
$(call import-products, $(all_product_makefiles))
else
# Import just the current product.
ifndef current_product_makefile
$(error Can not locate config makefile for product "$(TARGET_PRODUCT)")
endif # current_product_makefile

ifneq (1, $(words $(current_product_makefile)))
$(error Product "$(TARGET_PRODUCT)" ambiguous: matches $(current_product_makefile))
endif
$(call import-products, $(current_product_makefile))
endif

# Sanity check
$(check-all-products)

ifneq ($(filter dump-product,$(MAKECMDGOALS)),)
$(dump-products)
$(error done)
endif

# Convert a short name like "sooner" into the path to the product
# file defining that product.
#
INTERNAL_PRODUCT := $(call resolve-short-product-name, $(TARGET_PRODUCT))
ifneq ($(current_product_makefile),$(INTERNAL_PRODUCT))
$(error PRODUCT_NAME inconsistent in $(current_product_makefile) and $(INTERNAL_PRODUCT))
endif
current_product_makefile :=
all_product_makefiles :=
all_product_configs :=

# ------------------------------------------------------------
# Find the device that this product maps to.
TARGET_DEVICE := $(PRODUCTS.$(INTERNAL_PRODUCT).PRODUCT_DEVICE)

# ------------------------------------------------------------
# A list of words like <source path>:<destination path>[:<owner>]
# The file at the source path sould be copied to the destination path
# when building this product. <destination path> is relative to
# $(PRODUCT_OUT), so it should look like, e.g., "etc/file.xml".
# The rules for these copy steps are defined in make/core/Makefile.
# The optional :<owner> is used to indicate the owner of a vendor file.
PRODUCT_COPY_FILES := \
    $(strip $(PRODUCTS.$(INTERNAL_PRODUCT).PRODUCT_COPY_FILES))
