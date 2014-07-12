#
# Copyright (C) 2013 The Gotoos Open Source Project
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
  PLATFORM_VERSION := 13.9.10
endif