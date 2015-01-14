#
# Copyright (C) 2015 The Yudatun Open Source Project
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation
#

# Shared by HOST_x86.mk and HOST_x86_64.mk.

ifeq ($(HOST_OS),linux)
CLANG_CONFIG_x86_LINUX_HOST_EXTRA_ASFLAGS := \
  --gcc-toolchain=$(HOST_TOOLCHAIN_FOR_CLANG) \
  --sysroot=$(HOST_TOOLCHAIN_FOR_CLANG)/sysroot

CLANG_CONFIG_x86_LINUX_HOST_EXTRA_CFLAGS := \
  --gcc-toolchain=$(HOST_TOOLCHAIN_FOR_CLANG)

ifneq ($(strip $(HOST_IS_64_BIT)),)
CLANG_CONFIG_x86_LINUX_HOST_EXTRA_CPPFLAGS := \
  --gcc-toolchain=$(HOST_TOOLCHAIN_FOR_CLANG) \
  --sysroot=$(HOST_TOOLCHAIN_FOR_CLANG)/sysroot \
  -isystem $(HOST_TOOLCHAIN_FOR_CLANG)/x86_64-linux/include/c++/4.8 \
  -isystem $(HOST_TOOLCHAIN_FOR_CLANG)/x86_64-linux/include/c++/4.8/x86_64-linux \
  -isystem $(HOST_TOOLCHAIN_FOR_CLANG)/x86_64-linux/include/c++/4.8/backward

CLANG_CONFIG_x86_LINUX_HOST_EXTRA_LDFLAGS := \
  --gcc-toolchain=$(HOST_TOOLCHAIN_FOR_CLANG) \
  --sysroot=$(HOST_TOOLCHAIN_FOR_CLANG)/sysroot \
  -B$(HOST_TOOLCHAIN_FOR_CLANG)/x86_64-linux/bin \
  -B$(HOST_TOOLCHAIN_FOR_CLANG)/lib/gcc/x86_64-linux/4.8 \
  -L$(HOST_TOOLCHAIN_FOR_CLANG)/lib/gcc/x86_64-linux/4.8 \
  -L$(HOST_TOOLCHAIN_FOR_CLANG)/x86_64-linux/lib64/
else
CLANG_CONFIG_x86_LINUX_HOST_EXTRA_CPPFLAGS := \
  --gcc-toolchain=$(HOST_TOOLCHAIN_FOR_CLANG) \
  --sysroot=$(HOST_TOOLCHAIN_FOR_CLANG)/sysroot \
  -isystem $(HOST_TOOLCHAIN_FOR_CLANG)/x86_64-linux/include/c++/4.8 \
  -isystem $(HOST_TOOLCHAIN_FOR_CLANG)/x86_64-linux/include/c++/4.8/x86_64-linux/32 \
  -isystem $(HOST_TOOLCHAIN_FOR_CLANG)/x86_64-linux/include/c++/4.8/backward

CLANG_CONFIG_x86_LINUX_HOST_EXTRA_LDFLAGS := \
  --gcc-toolchain=$(HOST_TOOLCHAIN_FOR_CLANG) \
  --sysroot=$(HOST_TOOLCHAIN_FOR_CLANG)/sysroot \
  -B$(HOST_TOOLCHAIN_FOR_CLANG)/x86_64-linux/bin \
  -B$(HOST_TOOLCHAIN_FOR_CLANG)/lib/gcc/x86_64-linux/4.8/32 \
  -L$(HOST_TOOLCHAIN_FOR_CLANG)/lib/gcc/x86_64-linux/4.8/32 \
  -L$(HOST_TOOLCHAIN_FOR_CLANG)/x86_64-linux/lib32/
endif
endif  # Linux

ifeq ($(HOST_OS),windows)
# nothing required here yet
endif
