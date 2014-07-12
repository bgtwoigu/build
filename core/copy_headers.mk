#
# Copyright (C) 2013 The Gotoos Open Source Project
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation
#

# --------------------------------------------------------------------
# Copy headers to the install tree.
# --------------------------------------------------------------------

ifneq ($(strip $(LOCAL_IS_HOST_MODULE)),)
  my_prefix := HOST_
else
  my_prefix := TARGET_
endif

# Create a rule to copy each header, and make the
# all_copied_headers phony target depend on each
# destination header. copy-one-header defines the
# actual rule.
#
$(foreach header,$(LOCAL_COPY_HEADERS), \
  $(eval _chFrom := $(LOCAL_PATH)/$(header)) \
  $(eval _chTo := \
    $(if $(LOCAL_COPY_HEADERS_TO),\
      $($(my_prefix)OUT_INTERMEDIATE_HEADERS)/$(LOCAL_COPY_HEADERS_TO)/$(notdir $(header)),\
      $($(my_prefix)OUT_INTERMEDIATE_HEADERS)/$(notdir $(header)))) \
  $(eval $(call copy-one-header,$(_chFrom),$(_chTo))) \
  $(eval all_copied_headers: $(_chTo)) \
 )
_chFrom :=
_chTo :=

# Define a rule to copy a header. Used via $(eval) by copy_headers.make
# $(1): source header
# $(2): destination header
define copy-one-header
$(2): $(1)
	@echo "Header: $$@"
	$$(copy-file-to-new-target-with-cp)
endef