#
# Copyright (C) 2015 The Yudatun Open Source Project
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation
#

# At the moment, use the same settings than the one
# for armv5te, since TARGET_ARCH_VARIANT := armv5te-vfp
# will only be used to select an optimized VFP-capable assembly
# interpreter loop for Dalvik.
#
include $(BUILD_COMBOS)/arch/arm/armv5te.mk
