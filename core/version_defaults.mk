#
# Copyright (C) 2013 The Yudatun Open Source Project
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation
#

#
# Handle various build version information.
#
# Guarantees that the following are defined:
#     PLATFORM_VERSION
#

ifeq ($(PLATFORM_VERSION),)
  # This is the canonical definition of the platform version,
  # which is the version that we reveal to the end user.
  # Update this value when the platform version changes (rather
  # than overriding it somewhere else). Can be an arbitrary string.
  PLATFORM_VERSION := 0.0
endif

ifeq "" "$(PLATFORM_SDK_VERSION)"
  # This is the canonical definition of the SDK version, which defines
  # the set of APIs and functionality available in the platform.  It
  # is a single integer that increases monotonically as updates to
  # the SDK are released.  It should only be incremented when the APIs for
  # the new release are frozen (so that developers don't write apps against
  # intermediate builds).  During development, this number remains at the
  # SDK version the branch is based on and PLATFORM_VERSION_CODENAME holds
  # the code-name of the new development work.
  PLATFORM_SDK_VERSION := 1
endif
