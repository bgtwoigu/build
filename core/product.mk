#
# Copyright (C) 2013 The Yudatun Open Source Project
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation
#

# -----------------------------------------------------
# Returns the list of all YudatunProducts.mk files.
# $(call ) isn't necessary.
#
define _find-gotoos-products-files
$(SRC_TARGET_DIR)/product/YudatunProducts.mk
endef

#
# Returns the sorted concatenation of PRODUCT_MAKEFILS
# varables set in the given YudatunProduct.mk files.
# $(1): the list of YudatunProduct.mk files.
#
define get-product-makefiles
$(sort \
   $(foreach f,$(1), \
      $(eval PRODUCT_MAKEFILES :=) \
      $(eval LOCAL_DIR := $(patsubst %/,%,$(dir $(f)))) \
      $(eval include $(f)) \
      $(PRODUCT_MAKEFILES) \
    ) \
   $(eval PRODUCT_MAKEFILES :=) \
   $(eval LOCAL_DIR :=) \
 )
endef

#
# Returns the sorted concatenation of all PRODUCT_MAKEFILES
# variables set in all YudatunProducts.mk files
# $(call ) isn't necessary.
#
define get-all-product-makefiles
$(call get-product-makefiles, $(_find-gotoos-products-files))
endef

# ----------------------------------------------------
# Returns the list of all product info from makefiles into YudatunProducts.mk
#
_product_var_list := \
    PRODUCT_NAME \
    PRODUCT_BRAND \
    PRODUCT_MODEL \
    PRODUCT_DEVICE \
    PRODUCT_PACKAGES \
    PRODUCT_PACKAGES_DEBUG \
    PRODUCT_PACKAGES_ENG \
    PRODUCT_COPY_FILES

define dump-product
$(info ==== $(1) ====) \
$(foreach v,$(_product_var_list), \
   $(info PRODUCTS.$(1).$(v) := $(PRODUCTS.$(1).$(v))) \
  ) \
$(info -----------)
endef

define dump-products
$(foreach p,$(PRODUCTS),$(call dump-product,$(p)))
endef

#
# $(1): product to inherit
#
# Does three things:
#  1. Inherits all of the variables form $1
#  2. Records the inheritance in the .INHERITS_FROM varable
#  3. Records that we've visited this node, in ALL_PRODUCTS
#
define inherit-product
  $(foreach v, $(_product_var_list), \
      $(eval $(v) := $($(v)) $(INHERIT_TAG)$(strip $(1))) \
    ) \
  $(eval inherit_var := \
      PRODUCTS.$(strip $(word 1,$(_include_stack))).INHERITS_FROM \
    ) \
  $(eval $(inherit_var) := $(sort $($(inherit_var)) $(strip $(1)))) \
  $(eval inherit_var :=) \
  $(eval ALL_PRODUCTS := $(sort $(ALL_PRODUCTS) $(word 1,$(_include_stack))))
endef

#
# $(1): product makefile list
#
# TODO: check to make sure that products have all the necessary vars defined
define import-products
$(call import-nodes,PRODUCTS,$(1),$(_product_var_list))
endef

#
# Does various consistency checks on all of the known products.
# Takes no parameters, so $(call ) is no necessary.
#
define check-all-products
$(if ,, \
   $(eval _cap_names :=) \
   $(foreach p,$(PRODUCTS), \
      $(eval pn := $(strip $(PRODUCTS.$(p).PRODUCT_NAME))) \
      $(if $(pn),,$(error $(p): PRODUCT_NAME must be defined.)) \
      $(if $(filter $(pn),$(_cap_names)), \
         $(error $(p): PRODUCT_NAME must be unique; "$(pn)" already used by \
            $(strip
               $(foreach pp,$(PRODUCTS), \
                  $(if $(filter $(pn),$(PRODUCTS.$(pp).PRODUCT_NAME)),)
                ) \
             ) \
          ) \
       ) \
      $(eval _cap_names += $(pn)) \
      $(if $(call is-c-identifier,$(pn)),, \
         $(error $(p): PRODUCT_NAME must be a valid C identifier, not "$(pn)") \
        ) \
      $(eval pb := $(strip $(PRODUCTS.$(p).PRODUCT_BRAND))) \
      $(if $(pb),,$(error $(p): PRODUCT_BRAND must be defined.)) \
      $(foreach cf,$(strip $(PRODUCTS.$(p).PRODUCT_COPY_FILES)), \
        $(if $(filter 2 3,$(words $(subst :,$(space),$(cf)))),, \
          $(error $(p): malformed COPY_FILE "$(cf)") \
         ) \
       )\
     ) \
 )
endef

#
# Returns the product makefile path for the product with the provided name
#
# $(1): short product name like "arm"
#
define _resolve-short-product-name
  $(eval pn := $(strip $(1)))
  $(eval p := \
     $(foreach p,$(PRODUCTS), \
        $(if $(filter $(pn),$(PRODUCTS.$(p).PRODUCT_NAME)),$(p)) \
      ) \
   )
  $(eval p := $(sort $(p)))
  $(if $(filter 1,$(words $(p))), \
     $(p), \
     $(if $(filter 0,$(words $(p))), \
        $(error No matches for product "$(pn)"), \
        $(error Product "$(pn)" ambiguous: matches $(p)) \
      ) \
   )
endef
define resolve-short-product-name
$(strip $(call _resolve-short-product-name,$(1)))
endef

# -------------------------------------------------------
# Return the list of target informations.
#
_product_stash_var_list := $(_product_var_list) \
    TARGET_ARCH \
    TARGET_ARCH_VARIANT \
    TARGET_CPU_VARIANT \
    TARGET_COMPRESS_MODULE_SYMBOLS \
    TARGET_NO_BOOTLOADER \
    TARGET_NO_KERNEL

_product_stash_var_list += \
    BOARD_KERNEL_CMDLINE \
    BOARD_KERNEL_BASE \
    BOARD_KERNEL_PAGESIZE

#
# Stash values of the varables in _product_stash_var_list.
# $(1): Renamed prefix
#
define stash-product-vars
$(foreach v,$(_product_stash_var_list), \
   $(eval $(strip $(1))_$(call rot13,$(v)) := $$($$(v))) \
 )
endef

#
# Assert that the variable stashed by stash-product-vars remains untouched.
# $(1): The prefix as supplied to stash-product-vars
#
define assert-product-vars
$(strip \
   $(eval changed_variables:=)
   $(foreach v,$(_product_stash_var_list), \
      $(if $(call streq,$($(v)),$($(strip $(1))_$(call rot13,$(v)))),, \
         $(eval $(warning $(v) has been modified: $($(v)))) \
         $(eval $(warning previous value: $($(strip $(1))_$(call rot13,$(v))))) \
         $(eval changed_variables := $(changed_variables) $(v)) \
       ) \
    ) \
   $(if $(changed_variables),\
     $(eval $(error The following variables have been changed: $(changed_variables))),)
 )
endef