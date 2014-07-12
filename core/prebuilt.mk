#
# Copyright (C) 2014 The Gotoos Open Source Project
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation
#

ifdef LOCAL_PREBUILT_MODULE_FILE
  my_prebuilt_src_file := $(LOCAL_PREBUILT_MODULE_FILE)
else
  my_prebuilt_src_file := $(LOCAL_PATH)/$(LOCAL_SRC_FILES)
endif

ifdef LOCAL_IS_HOST_MODULE
  my_prefix := HOST_
else
  my_prefix := TARGET_
endif

include $(BUILD_SYSTEM)/base_rules.mk
built_module := $(LOCAL_BUILT_MODULE)

$(built_module) : $(my_prebuilt_src_file)
	$(transform-prebuilt-to-target)