#
# Copyright (C) 2013 The Gotoos Open Source Project
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation
#

#
# config.mk
#
# Product-specific compile-time difinitions.
#

# The generic product target doesn't have any hardware-specific pieces.
TARGET_ARCH := arm
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_WITH_SELINUX := true

BOARD_SYSTEMIMAGE_PARTITION_SIZE := 52428800
BOARD_USERDATAIMAGE_PARTITION_SIZE := 104857600
