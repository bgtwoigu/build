#
# Copyright (C) 2013 The Yudatun Open Source Project
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation
#

# ------------------------------------------------------------
# Common build system definitions. Mostly standard commands
# for building various types of targets, which are used by
# others to construct the final targets.
#-------------------------------------------------------------

#
# The short names of all of the targets in the system.
# For each element of ALL_MODULES, two other variables
# are defined:
#     $(ALL_MODULES.$(target)).BUILT
#     $(ALL_MODULES.$(target)).INSTALLED
# The BUILT variable contains LOCAL_BUILT_MODULE for that
# target, and the INSTALLED variable contains the LOCAL_INSTALLED_MODULE.
# Some targets may have multiple files listed in the BUILT and INSTALLED
# sub-variables.
ALL_MODULES :=

# Full paths to targets that should be added to the "make yudatun"
# set of installed targets.
ALL_DEFAULT_INSTALLED_MODULES :=

# FUll paths to all prebuilt files that will be copied
# (used to make the dependency on cp)
ALL_PREBUILT :=

# The list of tags that have been defined by
# LOCAL_MODULE_TAGS. Each word in this variable maps
# to a corresponding ALL_MODULE_TAGS.<tagname> variable
# that contains all of the INSTALLED_MODULEs with that tag
ALL_MODULE_TAGS :=

# Target and host installed module's dependencies on shared libraries.
# They are list of "<module_name>:<installed_file>:lib1,lib2...".
TARGET_DEPENDENCIES_ON_SHARED_LIBRARIES :=
HOST_DEPENDENCIES_ON_SHARED_LIBRARIES :=

# Full path to all asm, C, C++ files and so on.
# These all have an order-only dependency on the copied headers.
ALL_C_CPP_ETC_OBJECTS :=

# ------------------------------------------------------------
# Retrieve the directory of the current makefile

#
# Figure out where we are.
#
define my-dir
$(strip \
   $(eval LOCAL_MODULE_MAKEFILE := $$(lastword $$(MAKEFILE_LIST))) \
   $(if $(filter $(CLEAR_VARS),$(LOCAL_MODULE_MAKEFILE)), \
      $(error LOCAL_PATH must be set before including $$(CLEAR_VARS)) \
    , \
      $(patsubst %/,%,$(dir $(LOCAL_MODULE_MAKEFILE))) \
    ) \
 )
endef

# -----------------------------------------------------------
# The intermediates directory. Where object files go for a given target.
# We could technically get away without the "_intermediates" suffix on
# the directory, but it's nice to be able to grep for that string to find out
# if anyone's abusing the system.
# -----------------------------------------------------------

# Uses LOCAL_MODULE and LOCAL_IS_HOST_MODULE to determine the
# intermediates directory
#
# $(1): if non-empty, force the intermediates to be COMMON
define local-intermediates-dir
$(strip \
    $(if $(strip $(LOCAL_MODULE_CLASS)),, \
        $(error $(LOCAL_PATH): LOCAL_MODULE_CLASS not defined before \
                   call to local-intermediates-dir) \
      ) \
    $(if $(strip $(LOCAL_MODULE)),, \
        $(error $(LOCAL_PATH): LOCAL_MODULE not defined before \
                   call to local-intermediates-dir) \
      ) \
     $(call intermediates-dir-for, $(LOCAL_MODULE_CLASS),$(LOCAL_MODULE), \
             $(LOCAL_IS_HOST_MODULE),$(1)) \
  )
endef

# $(1): target class, like "EXECUTABLES"
# $(2): target name, like "init"
# $(3): if none-empty, this is a HOST target
# $(4): if none-empty, force the intermediates to be COMMON
define intermediates-dir-for
$(strip \
    $(eval _idfClass := $(strip $(1))) \
    $(if $(_idfClass),, \
        $(error $(LOCAL_PATH): Class not defined in call to intermediates-dir-for) \
      ) \
    $(eval _idfName := $(strip $(2))) \
    $(if $(_idfName),, \
        $(error $(LOCAL_PATH): Name not defined in call to intermediates-dir-for) \
      ) \
    $(eval _idfPrefix := $(if $(strip $(3)),HOST,TARGET)) \
    $(if $(filter $(_idfPrefix)-$(_idfClass),$(COMMON_MODULE_CLASSES))$(4), \
        $(eval _idfIntBase := $($(_idfPrefix)_OUT_COMMON_INTERMEDIATES)) \
      , \
         $(eval _idfIntBase := $($(_idfPrefix)_OUT_INTERMEDIATES)) \
      ) \
    $(_idfIntBase)/$(_idfClass)/$(_idfName)_intermediates \
  )
endef

# ------------------------------------------------------------
# Run rot13 on a string
# $(1): the string. Must be one line.
#
define rot13
  $(shell echo $(1) | tr 'a-zA-Z' 'n-za-mN-ZA-M')
endef

# ------------------------------------------------------------
# Returns true if $(1) and $(2) are equal. Returns
# the empty string if they are not equal.
define streq
$(strip $(if $(strip $(1)),\
  $(if $(strip $(2)),\
    $(if $(filter-out __,_$(subst $(strip $(1)),,$(strip $(2)))$(subst $(strip $(2)),,$(strip $(1)))_),,true), \
    ),\
  $(if $(strip $(2)),\
    ,\
    true)\
 ))
endef

# ------------------------------------------------------------
# Convert a list of short modules names (e.g., "init")
# into the list of files that are installed for those modules.
# NOTE: this won't return reliable results until after all
# $(1): target list
#
define module-installed-files
  $(foreach module,$(1), \
     $(ALL_MODULES.$(module).INSTALLED) \
   )
endef

# ------------------------------------------------------------
# Given an accept and reject list, find the matching
# set of targets. If a target has multiple tags and
# any of them are rejected, the target is rejected.
# Reject overrides accept.
#
# $(1): list of tags to accept
# $(2): list of tags to reject
define get-tagged-modules
$(filter-out \
   $(call modules-for-tag-list,$(2)), \
   $(call modules-for-tag-list,$(1)) \
 )
endef

# Given a list of tags, return the targets that specify
# any of those tags.
# $(1): tag list
define modules-for-tag-list
$(sort \
   $(foreach tag,$(1),$(ALL_MODULE_TAGS.$(tag))) \
 )
endef

# ------------------------------------------------------------
# Expand a module name list with REQUIRED modules
#
# $(1): The variable name that holds the initial module name list.
#       The variable will be modified to hold the expanded results.
# $(2): The initial module name list.
# Returns empty string (maybe with some whitespace).
define expand-required-modules
$(eval _erm_new_modules := \
   $(sort \
      $(filter-out $($(1)), \
         $(foreach m,$(2),$(ALL_MODULES.$(m).REQUIRED)) \
       ) \
    ) \
 ) \
$(if $(_erm_new_modules), \
   $(eval $(1) += $(_erm_new_modules)) \
   $(call expand-required-modules,$(1),$(_erm_new_modules)) \
 )
endef

# -----------------------------------------------------------
# Output the command lines, or not
# -----------------------------------------------------------

ifeq ($(strip $(SHOW_COMMANDS)),)

define pretty
@echo $1
endef
hide := @

else

define pretty
endef
hide :=

endif # SHOW_COMMANDS

# -----------------------------------------------------------
# Copy a single file from one place to another with cp.
define copy-file-to-target-with-cp
@mkdir -p $(dir $@)
$(hide) cp -fp $< $@
endef

# The same as copy-file-to-new-target, but don't preserve
# the old modification time.
define copy-file-to-new-target-with-cp
@mkdir -p $(dir $@)
$(hide) cp -f $< $@
endef

# Copy a prebuilt file to a target location.
define transform-prebuilt-to-target
@echo "$(if $(PRIVATE_IS_HOST_MODULE),host,target) Prebuilt: $(PRIVATE_MODULE) $@"
$(copy-file-to-target-with-cp)
endef

# Copy a prebuilt file to a target location, stripping "# comment" comments.
define transform-prebuilt-to-target-strip-comments
@echo "$(if $(PRIVATE_IS_HOST_MODULE),host,target) Prebuilt: $(PRIVATE_MODULE) ($@)"
$(copy-file-to-target-strip-comments)
endef

# The same as copy-file-to-target, but strip out "# comment"-style
# comments (for config files and such).
define copy-file-to-target-strip-comments
@mkdir -p $(dir $@)
$(hide) sed -e 's/#.*$$//' -e 's/[ \t]*$$//' -e '/^$$/d' < $< > $@
endef

# ------------------------------------------------------------
# On some platforms (MacOS), after copying a static
# library, ranlib must be run to update an internal
# timestamp!?!?!
# ------------------------------------------------------------

ifeq ($(HOST_RUN_RANLIB_AFTER_COPYING),true)
define transform-host-ranlib-copy-hack
    $(hide) ranlib $@ || true
endef
else
define transform-host-ranlib-copy-hack
@true
endef
endif

ifeq ($(TARGET_RUN_RANLIB_AFTER_COPYING),true)
define transform-ranlib-copy-hack
    $(hide) ranlib $@
endef
else
define transform-ranlib-copy-hack
@true
endef
endif

#-------------------------------------------------------------------------------
# Target
#-------------------------------------------------------------------------------

# -----------------------------------------------------------
# Commands for running gcc to compile a C file.
# -----------------------------------------------------------

define transform-s-to-o
$(transform-s-to-o-no-deps)
$(transform-d-to-p)
endef

define transform-s-to-o-no-deps
@echo "target asm: $(PRVIATE_MODULE) <= $<"
$(call transform-c-or-s-to-o-no-deps, $(PRIVATE_ASFLAGS))
endef

define transform-c-to-o
$(transform-c-to-o-no-deps)
$(transform-d-to-p)
endef

define transform-c-to-o-no-deps
@echo "target $(PRIVATE_ARM_MODE) C: $(PRIVATE_MODULE) <= $<"
$(call transform-c-or-s-to-o-no-deps, $(PRIVATE_CFLAGS) $(PRIVATE_CONLYFLAGS) $(PRIVATE_DEBUG_CFLAGS))
endef

# $(1): extra flags
define transform-c-or-s-to-o-no-deps
@mkdir -p $(dir $@)
$(hide) $(PRIVATE_CC) \
    $(addprefix -I , $(PRIVATE_C_INCLUDES)) \
    $(addprefix -isystem ,\
       $(if $(PRIVATE_NO_DEFAULT_COMPILER_FLAGS),, \
          $(filter-out $(PRIVATE_C_INCLUDES), \
             $(PRIVATE_TARGET_PROJECT_INCLUDES) \
             $(PRIVATE_TARGET_C_INCLUDES)))) \
    -c \
    $(if $(PRIVATE_NO_DEFAULT_COMPILER_FLAGS),, \
         $(PRIVATE_TARGET_GLOBAL_CFLAGS) \
         $(PRIVATE_ARM_CFLAGS) \
     ) \
     $(1) \
     -MD -MF $(patsubst %.o,%.d,$@) -o $@ $<
endef

# ---------------------------------------------------------
# Commands for running gcc to compile a C++ file
# ---------------------------------------------------------
define transform-cpp-to-o
@mkdir -p $(dir $@)
@echo "target $(PRIVATE_ARM_MODE) C++: $(PRIVATE_MODULE) <= $<"
$(hide) $(PRIVATE_CXX) \
    $(addprefix -I , $(PRIVATE_C_INCLUDES)) \
    $(addprefix -isystem ,\
        $(if $(PRIVATE_NO_DEFAULT_COMPILER_FLAGS),, \
            $(filter-out $(PRIVATE_C_INCLUDES), \
                $(PRIVATE_TARGET_PROJECT_INCLUDES) \
                $(PRIVATE_TARGET_C_INCLUDES)))) \
    -c \
    $(if $(PRIVATE_NO_DEFAULT_COMPILER_FLAGS),, \
        $(PRIVATE_TARGET_GLOBAL_CFLAGS) \
        $(PRIVATE_TARGET_GLOBAL_CPPFLAGS) \
        $(PRIVATE_ARM_CFLAGS) \
     ) \
    $(PRIVATE_CFLAGS) \
    $(PRIVATE_CPPFLAGS) \
    $(PRIVATE_DEBUG_CFLAGS) \
    -MD -MF $(patsubst %.o,%.d,$@) -o $@ $<
$(transform-d-to-p)
endef

# ------------------------------------------------------------
# Commands for running gcc to link a target executable
# ------------------------------------------------------------
define transform-o-to-executable
@mkdir -p $(dir $@)
@echo "target Executable: $(PRIVATE_MODULE) ($@)"
$(transform-o-to-executable-inner)
endef

define transform-o-to-executable-inner
$(hide) $(PRIVATE_CXX) -nostdlib -Bdynamic -fPIE -pie \
    -Wl,-dynamic-linker,$(TARGET_LINKER) \
    -Wl,--gc-sections \
    -Wl,-z,nocopyreloc \
    $(PRIVATE_TARGET_GLOBAL_LD_DIRS) \
    -Wl,-rpath-link=$(PRIVATE_TARGET_OUT_INTERMEDIATE_LIBRARIES) \
    $(if $(filter true,$(PRIVATE_NO_CRT)),,$(PRIVATE_TARGET_CRTBEGIN_DYNAMIC_O)) \
    $(PRIVATE_ALL_OBJECTS) \
    -Wl,--whole-archive \
    $(call normalize-target-libraries,$(PRIVATE_ALL_WHOLE_STATIC_LIBRARIES)) \
    -Wl,--no-whole-archive \
    $(if $(PRIVATE_GROUP_STATIC_LIBRARIES),-Wl$(comma)--start-group) \
    $(call normalize-target-libraries,$(PRIVATE_ALL_STATIC_LIBRARIES)) \
    $(if $(PRIVATE_GROUP_STATIC_LIBRARIES),-Wl$(comma)--end-group) \
    $(if $(TARGET_BUILD_APPS),$(PRIVATE_TARGET_LIBGCC)) \
    $(call normalize-target-libraries,$(PRIVATE_ALL_SHARED_LIBRARIES)) \
    -o $@ \
    $(PRIVATE_TARGET_GLOBAL_LDFLAGS) \
    $(PRIVATE_LDFLAGS) \
    $(PRIVATE_TARGET_FDO_LIB) \
    $(PRIVATE_TARGET_LIBGCC) \
    $(if $(filter true,$(PRIVATE_NO_CRT)),,$(PRIVATE_TARGET_CRTEND_O))
endef

# ------------------------------------------------------------
# Commands for running gcc to link a statically linked executable.
# In practice, We only use this on arm, so the other platforms
# don't have the transform-o-to-static-executable defined
# ------------------------------------------------------------
define transform-o-to-static-executable
@mkdir -p $(dir $@)
@echo "target StaticExecutable: $(PRIVATE_MODULE) ($@)"
$(transform-o-to-static-executable-inner)
endef

define transform-o-to-static-executable-inner
$(hide) $(PRIVATE_CXX) -nostdlib -Bstatic \
    -Wl,--gc-sections \
    -o $@ \
    $(PRIVATE_TARGET_GLOBAL_LD_DIRS) \
    $(if $(filter true,$(PRIVATE_NO_CRT)),,$(PRIVATE_TARGET_CRTBEGIN_STATIC_O)) \
    $(PRIVATE_TARGET_GLOBAL_LDFLAGS) \
    $(PRIVATE_LDFLAGS) \
    $(PRIVATE_ALL_OBJECTS) \
    -Wl,--whole-archive \
    $(call normalize-target-libraries,$(PRIVATE_ALL_WHOLE_STATIC_LIBRARIES)) \
    -Wl,--no-whole-archive \
    $(call normalize-target-libraries,$(filter-out %libc_nomalloc.a,$(filter-out %libc.a,$(PRIVATE_ALL_STATIC_LIBRARIES)))) \
    -Wl,--start-group \
    $(call normalize-target-libraries,$(filter %libc.a,$(PRIVATE_ALL_STATIC_LIBRARIES))) \
    $(call normalize-target-libraries,$(filter %libc_nomalloc.a,$(PRIVATE_ALL_STATIC_LIBRARIES))) \
    $(PRIVATE_TARGET_FDO_LIB) \
    $(PRIVATE_TARGET_LIBGCC) \
    -Wl,--end-group \
    $(if $(filter true,$(PRIVATE_NO_CRT)),,$(PRIVATE_TARGET_CRTEND_O))
endef

# -----------------------------------------------------------
# Commands for running gcc to link a shared library or package
# -----------------------------------------------------------
define transform-o-to-shared-lib
@mkdir -p $(dir $@)
@echo "target SharedLib: $(PRIVATE_MODULE) ($@)"
$(transform-o-to-shared-lib-inner)
endef

define transform-o-to-shared-lib-inner
$(hide) $(PRIVATE_CXX) \
    -nostdlib -Wl,-soname,$(notdir $@) \
    -Wl,--gc-sections \
    -Wl,-shared,-Bsymbolic \
    $(PRIVATE_TARGET_GLOBAL_LD_DIRS) \
    $(if $(filter true,$(PRIVATE_NO_CRT)),,$(PRIVATE_TARGET_CRTBEGIN_SO_O)) \
    $(PRIVATE_ALL_OBJECTS) \
    -Wl,--whole-archive \
    $(call normalize-target-libraries,$(PRIVATE_ALL_WHOLE_STATIC_LIBRARIES)) \
    -Wl,--no-whole-archive \
    $(if $(PRIVATE_GROUP_STATIC_LIBRARIES),-Wl$(comma)--start-group) \
    $(call normalize-target-libraries,$(PRIVATE_ALL_STATIC_LIBRARIES)) \
    $(if $(PRIVATE_GROUP_STATIC_LIBRARIES),-Wl$(comma)--end-group) \
    $(call normalize-target-libraries,$(PRIVATE_ALL_SHARED_LIBRARIES)) \
    -o $@ \
    $(PRIVATE_TARGET_GLOBAL_LDFLAGS) \
    $(PRIVATE_LDFLAGS) \
    $(PRIVATE_TARGET_FDO_LIB) \
    $(PRIVATE_TARGET_LIBGCC) \
    $(if $(filter true,$(PRIVATE_NO_CRT)),,$(PRIVATE_TARGET_CRTEND_SO_O))
endef

#------------------------------------------------------------
# Commands for running ar
# Explicitly delete the archive first so that ar doesn't
# try to add to an existing archive.
#------------------------------------------------------------
define transform-o-to-static-lib
@mkdir -p $(dir $@)
@rm -f $@
$(extract-and-include-target-whole-static-libs)
@echo "target StaticLib: $(PRIVATE_MODULE) ($@)"
$(call split-long-arguments, $(TARGET_AR) $(TARGET_GLOBAL_ARFLAGS) $(PRIVATE_ARFLAGS) $@,$(filter %.o, $^))
endef

define extract-and-include-target-whole-static-libs
$(foreach lib,$(PRIVATE_ALL_WHOLE_STATIC_LIBRARIES), \
    $(call _extract-and-include-single-target-whole-static-lib, $(lib)))
endef

# $(1): the full path of the source static library.
define _extract-and-include-single-target-whole-static-lib
@echo "preparing StaticLib: $(PRIVATE_MODULE) [including $(1)]"
$(hide) ldir=$(PRIVATE_INTERMEDIATES_DIR)/WHOLE/$(basename $(notdir $(1)))_objs;\
    rm -rf $$ldir; \
    mkdir -p $$ldir; \
    filelist=; \
    for f in `$(TARGET_AR) t $(1)`; do \
        $(TARGET_AR) p $(1) $$f > $$ldir/$$f; \
        filelist="$$filelist $$ldir/$$f"; \
    done ; \
    $(TARGET_AR) $(TARGET_GLOBAL_ARFLAGS) \
        $(PRIVATE_ARFLAGS) $@ $$filelist

endef

# -----------------------------------------------------------
# Commands for filtering a target executable or library
# -----------------------------------------------------------

define transform-to-stripped
@mkdir -p $(dir $@)
@echo "target Strip: $(PRIVATE_MODULE) ($@)"
$(hide) $(TARGET_STRIP_COMMAND)
endef

#-------------------------------------------------------------------------------
# Host
#-------------------------------------------------------------------------------

# -----------------------------------------------------------
# Commands for running gcc to compile a host C file.
# -----------------------------------------------------------
define transform-host-c-to-o
$(transform-host-c-to-o-no-deps)
$(transform-d-to-p)
endef

define transform-host-c-to-o-no-deps
@echo "host C: $(PRIVATE_MODULE) <= $<"
$(call transform-host-c-or-s-to-o-no-deps,  $(PRIVATE_CFLAGS) $(PRIVATE_CONLYFLAGS) $(PRIVATE_DEBUG_CFLAGS))
endef

# $(1): extra flags
define transform-host-c-or-s-to-o-no-deps
@mkdir -p $(dir $@)
$(hide) $(PRIVATE_CC) \
    $(addprefix -I , $(PRIVATE_C_INCLUDES)) \
    $(addprefix -isystem ,\
       $(if $(PRIVATE_NO_DEFAULT_COMPILER_FLAGS),, \
          $(filter-out $(PRIVATE_C_INCLUDES), \
             $(HOST_PROJECT_INCLUDES) \
             $(HOST_C_INCLUDES)))) \
    -c \
    $(if $(PRIVATE_NO_DEFAULT_COMPILER_FLAGS),, \
         $(HOST_GLOBAL_CFLAGS) \
     ) \
     $(1) \
     -MD -MF $(patsubst %.o,%.d,$@) -o $@ $<
endef

# ------------------------------------------------------------
# Commands for running gcc to link a host executable.
# ------------------------------------------------------------
define transform-host-o-to-executable
@mkdir -p $(dir $@)
@echo "host Executable: $(PRIVATE_MODULE) ($@)"
$(transform-host-o-to-executable-inner)
endef

define transform-host-o-to-executable-inner
$(hide) $(PRIVATE_CXX) \
    -Wl,-rpath-link=$(HOST_OUT_INTERMEDIATE_LIBRARIES) \
    -Wl,-rpath=$(HOST_OUT_INTERMEDIATE_LIBRARIES) \
    $(HOST_GLOBAL_LD_DIRS) \
    $(if $(PRIVATE_NO_DEFAULT_COMPILER_FLAGS),, \
        $(HOST_GLOBAL_LDFLAGS) \
      ) \
    $(PRIVATE_LDFLAGS) \
    $(PRIVATE_ALL_OBJECTS) \
    -Wl,--whole-archive \
    $(call normalize-host-libraries,$(PRIVATE_ALL_WHOLE_STATIC_LIBRARIES)) \
    -Wl,--no-whole-archive \
    $(if $(PRIVATE_GROUP_STATIC_LIBRARIES),Wl$(comma)--start-group) \
    $(call normalize-host-libraries,$(PRIVATE_ALL_STATIC_LIBRARIES)) \
    $(if $(PRIVATE_GROUP_STATIC_LIBRARIES),Wl$(comma)--end-group) \
    $(call normalize-host-libraries,$(PRIVATE_ALL_SHARED_LIBRARIES)) \
    -o $@ \
    $(PRIVATE_LDLIBS)
endef

#-------------------------------------------------------------
# Commands for runing gcc to link a host shared library
#-------------------------------------------------------------
define transform-host-o-to-shared-lib
@mkdir -p $(dir $@)
@echo "host SharedLib: $(PRIVATE_MODULE) ($@)"
$(transform-host-o-to-shared-lib-inner)
endef

define transform-host-o-to-shared-lib-inner
$(hide) $(PRIVATE_CXX) \
	$(PRIVATE_TARGET_GLOBAL_LDFLAGS) \
	-Wl,-rpath-link=$(HOST_OUT_INTERMEDIATE_LIBRARIES) \
	-Wl,-rpath=$(HOST_OUT_INTERMEDIATE_LIBRARIES) \
	-shared -Wl,-soname,$(notdir $@) \
	$(PRIVATE_LDFLAGS) \
	$(HOST_GLOBAL_LD_DIRS) \
	$(if $(PRIVATE_NO_DEFAULT_COMPILER_FLAGS),, \
		$(HOST_GLOBAL_LDFLAGS) \
	) \
	$(PRIVATE_ALL_OBJECTS) \
	-Wl,--whole-archive \
	$(call normalize-host-libraries,$(PRIVATE_ALL_WHOLE_STATIC_LIBRARIES)) \
	-Wl,--no-whole-archive \
	$(if $(PRIVATE_GROUP_STATIC_LIBRARIES),-Wl$(comma)--start-group) \
	$(call normalize-host-libraries,$(PRIVATE_ALL_STATIC_LIBRARIES)) \
	$(if $(PRIVATE_GROUP_STATIC_LIBRARIES),-Wl$(comma)--end-group) \
	$(call normalize-host-libraries,$(PRIVATE_ALL_SHARED_LIBRARIES)) \
	-o $@ \
	$(PRIVATE_LDLIBS)
endef

# ------------------------------------------------------------
# Commands for running host ar
# ------------------------------------------------------------

define transform-host-o-to-static-lib
@mkdir -p $(dir $@)
@rm -f $@
$(extract-and-include-host-whole-static-libs)
@echo "host StaticLib: $(PRIVATE_MODULE) ($@)"
$(call split-long-arguments,$(HOST_AR) $(HOST_GLOBAL_ARFLAGS) $(PRIVATE_ARFLAGS) $@,$(filter %.o,$^))
endef

define extract-and-include-host-whole-static-libs
$(foreach lib,$(PRIVATE_ALL_WHOLE_STATIC_LIBRARIES), \
   $(call _extract-and-include-single-host-whole-static-lib,$(lib)) \
 )
endef

# $(1): the full path of the source static library.
define _extract-and-include-single-host-whole-static-lib
@echo "preparing StaticLib: $(PRIVATE_MODULE) [including $(1)]"
$(hide) ldir=$(PRIVATE_INTERMEDIATES_DIR)/WHOLE/$(basename $(notdir $(1)))_objs; \
    rm -rf $$ldir; \
    mkdir -p $$ldir; \
    filelist=; \
    for f in `$(HOST_AR) t $(1) | \grep '\.o$$'`; do \
        $(HOST_AR) p $(1) $$f > $$ldir/$$f; \
        filelist="$$filelist $$ldir/$$f"; \
    done; \
    $(HOST_AR) $(HOST_GLOBAL_ARFLAGS) $(PRIVATE_ARFLAGS) $@ $$filelist
endef

# -----------------------------------------------------------
# Commands for munging the dependency files GCC generates
# -----------------------------------------------------------
# $(1): the input .d file
# $(2): the output .P file
define transform-d-to-p-args
$(hide) cp $(1) $(2); \
	sed -e 's/#.*//' -e 's/^[^:]*: *//' -e 's/ *\\$$//' \
		-e '/^$$/ d' -e 's/$$/ :/' < $(1) >> $(2); \
	rm -f $(1)
endef

define transform-d-to-p
$(call transform-d-to-p-args,$(@:%.o=%.d),$(@:%.o=%.P))
endef

# -----------------------------------------------------------
# Split long argument list into smaller groups and call the
# command repeatedly call the command at least once even if
# there are no arguments, so otherwise the output file won't
# be created.
#
# $(1): the command without arguments
# $(2): the arguments
# -----------------------------------------------------------
define split-long-arguments
$(hide) $(1) $(wordlist 1,500,$(2))
$(call _concat-if-arg2-not-empty,$(1),$(wordlist 501,1000,$(2)))
$(call _concat-if-arg2-not-empty,$(1),$(wordlist 1001,1500,$(2)))
$(call _concat-if-arg2-not-empty,$(1),$(wordlist 1501,2000,$(2)))
$(call _concat-if-arg2-not-empty,$(1),$(wordlist 2001,2500,$(2)))
$(call _concat-if-arg2-not-empty,$(1),$(wordlist 2501,3000,$(2)))
$(call _concat-if-arg2-not-empty,$(1),$(wordlist 3001,99999,$(2)))
endef

# -----------------------------------------------------------
# Commands for running ar
# -----------------------------------------------------------
define _concat-if-arg2-not-empty
$(if $(2),$(hide) $(1) $(2))
endef

# -----------------------------------------------------------
# Convert "path/to/libxxx.so" to "-lxxx"
# Any "path/to/libxxx.a" elements pass through unchanged.
# -----------------------------------------------------------
define normalize-libraries
$(foreach so,$(filter %.so,$(1)),-l$(patsubst lib%.so,%,$(notdir $(so))))\
$(filter-out %.so,$(1))
endef

# TODO: change users to call the common version.
define normalize-host-libraries
$(call normalize-libraries,$(1))
endef

define normalize-target-libraries
$(call normalize-libraries,$(1))
endef

#-------------------------------------------------------------
# Read the word out of a colon-separated list of words.
# This has the same behavior as the built-in function
# $(word n,str).
#
# The individual words may not contain spaces.
#
# $(1): 1 based index
# $(2): value of the form a:b:c...
#------------------------------------------------------------

define word-colon
$(word $(1),$(subst :,$(space),$(2)))
endef

#-------------------------------------------------------------
# Append a leaf to a base path. Properly deals with
# base paths ending in /.
#
# $(1): base path
# $(2): leaf path
#-------------------------------------------------------------

define append-path
$(subst //,/,$(1)/$(2))
endef

#-------------------------------------------------------------
# Define a rule to copy a file. For use via $(eval).
# $(1): source file
# $(2): destination file
#-------------------------------------------------------------

define copy-one-file
$(2): $(1)
	@echo "Copy: $$@"
	$$(copy-file-to-target-with-cp)
endef

# ---------------------------------------------------------
# Find all of the S files under the named directories.
# Meant to be used like:
#    SRC_FILES := $(call all-c-files-under,src tests)
# ---------------------------------------------------------

define all-S-files-under
$(patsubst ./%,%, \
  $(shell cd $(LOCAL_PATH) ; \
          find -L $(1) -name "*.S" -and -not -name ".*") \
 )
endef

# ---------------------------------------------------------
# Find all of the c files under the named directories.
# Meant to be used like:
#    SRC_FILES := $(call all-c-files-under,src tests)
# --------------------------------------------------------

define all-c-files-under
$(patsubst ./%,%, \
  $(shell cd $(LOCAL_PATH) ; \
          find -L $(1) -name "*.c" -and -not -name ".*") \
 )
endef

# ------------------------------------------------------------
# Find all of the c files from here.  Meant to be used like:
#    SRC_FILES := $(call all-subdir-c-files)
# ------------------------------------------------------------

define all-subdir-c-files
$(call all-c-files-under,.)
endef
