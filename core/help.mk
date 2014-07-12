#
# Copyright (C) 2013 The Gotoos Open Source Project
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation
#

ifeq ($(MAKECMDGOALS),help)
dont_bother := true
endif
ifeq ($(MAKECMDGOALS),out)
dont_bother := true
endif

.PHONY: help
help:
	@echo
	@echo
	@echo "-----------------------------------------------------"
	@echo "goto                 Default target"
	@echo "clean                (aka clobber) equivalent to rm -rf out/"
	@echo "help                 You're reading it ringht now"

.PHONY: out
out:
	@echo "I'm sure you're nice and all, but no thanks."