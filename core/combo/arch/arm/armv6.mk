#
# Copyright (C) 2015 The Yudatun Open Source Project
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation
#

# Configuration for Linux on ARM.
# Generating binaries for the ARMv5TE architecture and higher
#

arch_variant_cflags := \
    -march=armv6 \
    -mfpu=vfp \
    -mfloat-abi=hard
