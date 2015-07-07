#
# Copyright (C) 2013 The Yudatun Open Source Project
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation

function hmm()
{
cat <<EOF
Invoke ". build/envsetup.sh" from your shell to add the following functions to your environment:
- lunch:    lunch <product_name>-<build_variant>.
- croot:    changes directory to the top of the tree.
- mm:       builds all of the modules in the current directory, but not their dependencies.
- mmm:      builds all of the modules in the supplied directories, but not their dependencies.
- emulator: emulator <kernel> <ramdisk>

Look at the source to view more functions. The complete list is:
EOF
    T=$(gettop)
    local A
    A=""
    for i in `cat $T/build/envsetup.sh | sed -n "/^function /s/function \([a-z_]*\).*/\1/p" | sort`; do
        A="$A $i"
    done
    echo $A
}

# Clear this variable. It will be built up again when the vendorsetup.sh
# files are included at the end of this file
unset LUNCH_MENU_CHOICES
function add_lunch_combo()
{
    local new_combo=$1
    local c
    for c in ${LUNCH_MENU_CHOICES[@]} ; do
        if [ "$new_combo" = "$c" ] ; then
            return
        fi
    done
    LUNCH_MENU_CHOICES=(${LUNCH_MENU_CHOICES[@]} $new_combo)
}

# qemu
add_lunch_combo yudatun_qemu-eng
add_lunch_combo yudatun_qemu-user
add_lunch_combo yudatun_qemu-userdebug
# raspberrypi
add_lunch_combo yudatun_raspberrypi-eng
add_lunch_combo yudatun_raspberrypi-user
add_lunch_combo yudatun_raspberrypi-userdebug

VARIANT_CHOICES=(user userdebug eng)

function lunch()
{
    local answer

    if [ "$1" ] ; then
        answer=$1
    else
        print_lunch_menu
        echo -n "Which would you like? [yudatun_qemu-eng] "
        read answer
    fi

    local selection=

    if [ -z "$answer" ] ; then
        selection="yudatun_qemu-eng"
    elif (echo -n $answer | grep -q -e "^[0-9][0-9]*$") ; then
        if [ $answer -le ${#LUNCH_MENU_CHOICES[@]} ] ; then
            selection=${LUNCH_MENU_CHOICES[$(($answer-1))]}
        fi
    elif (echo -n $answer | grep -q -e "^[^\-][^\-]*-[^\-][^\-]*$") ; then
        selection=$answer
    fi

    if [ -z "$selection" ] ; then
        echo
        echo "Invalid lunch combo: $answer"
        return 1
    fi

    export TARGET_BUILD_APPS=

    local product=$(echo -n $selection | sed -e "s/-.*$//")
    check_product $product
    if [ $? -ne 0 ] ; then
        echo
        echo "** Don't have a product spec for: '$product'"
        echo "** Do you have the right repo manifest?"
        product=
    fi

    local variant=$(echo -n $selection | sed -e "s/^[^\-]*-//")
    check_variant $variant
    if [ $? -ne 0 ] ; then
        echo
        echo "** Invalid variant: '$variant'"
        echo "** Must be one of ${VARIANT_CHOICES[@]}"
        variant=
    fi

    if [ -z "$product" -o -z "$variant" ] ; then
        echo
        return 1
    fi

    export TARGET_PRODUCT=$product
    export TARGET_BUILD_VARIANT=$variant
    export TARGET_BUILD_TYPE=release
    echo

    set_stuff_for_environment
    print_config
}

function print_lunch_menu()
{
    local uname=$(uname)
    echo
    echo "You're building on" $uname
    echo
    echo "Lunch menu ... pick a combo:"

    local i=1
    local choice
    for choice in ${LUNCH_MENU_CHOICES[@]} ; do
        echo "    $i. $choice"
        i=$(($i+1))
    done
    echo
}

# check to see if the supplied product is one we can build
function check_product()
{
    T=$(gettop)
    if [ ! "$T" ] ; then
        echo "Couldn't locate the top of the tree. Try setting TOP." >&2
        return
    fi
    CALLED_FROM_SETUP=true BUILD_SYSTEM=build/core \
        TARGET_PRODUCT=$1 \
        TARGET_BUILD_VARIANT= \
        TARGET_BUILD_TYPE= \
        TARGET_BUILD_APPS= \
        get_build_var TARGET_DEVICE > /dev/null
    # hide successful answers, but allow the errors to show
}

# check to see if the supplied variant is valid
function check_variant()
{
    for v in ${VARIANT_CHOICES[@]} ; do
        if [ "$v" = "$1" ] ; then
            return 0
        fi
    done
    return 1
}

function set_stuff_for_environment()
{
    set_paths
    export YUDATUN_BUILD_TOP=$(gettop)
}

function get_target_arch()
{
    get_build_var TARGET_ARCH
}

# This function sets YUDATUN_BUILD_PATHS to what it is adding
# to PATH, and the next time it is run, it removes that from PATH.
# This is required so lunch can be run more than once and still have
# working paths
function set_paths()
{
    T=$(gettop)
    if [ ! "$T" ] ; then
        echo "Couldn't locate the top of the tree. Try setting TOP."
        return
    fi

    # out with the old
    if [ -n "$YUDATUN_BUILD_PATHS" ] ; then
        export PATH=${PATH/$YUDATUN_BUILD_PATHS/}
    fi

    yudatun_target_gcc_dir=$(get_abs_build_var YUDATUN_TARGET_GCC)

    # defined in core/config.mk
    target_gcc_version=$(get_build_var TARGET_GCC_VERSION)
    export TARGET_GCC_VERSION=$target_gcc_version
    target_linux_eabi_prefix=$(get_build_var TARGET_LINUX_EABI_PREFIX)
    export TARGET_LINUX_EABI_PREFIX=$target_linux_eabi_prefix

    # defined in core/config.mk
    export YUDATUN_EABI_TOOLCHAIN=
    local ARCH=$(get_target_arch)
    case $ARCH in
        arm) toolchain_dir=$target_linux_eabi_prefix-$target_gcc_version/bin
            ;;
        *)
            echo "Can't find toolchain for unknown architecture: $ARCH"
            toolchain_dir=xxxxxxxxx
            ;;
    esac

    if [ -d "$yudatun_target_gcc_dir/$toolchain_dir" ] ; then
        export YUDATUN_EABI_TOOLCHAIN=$yudatun_target_gcc_dir/$toolchain_dir
    fi

    export YUDATUN_TOOLCHAIN=$YUDATUN_EABI_TOOLCHAIN
    export YUDATUN_BUILD_PATHS=$(get_build_var YUDATUN_BUILD_PATHS):$YUDATUN_TOOLCHAIN:
    export PATH=$YUDATUN_BUILD_PATHS$PATH

    unset YUDATUN_PRODUCT_OUT
    export YUDATUN_PRODUCT_OUT=$(get_abs_build_var PRODUCT_OUT)
    export OUT=$YUDATUN_PRODUCT_OUT

    unset YUDATUN_HOST_OUT
    export YUDATUN_HOST_OUT=$(get_abs_build_var HOST_OUT)
}

function print_config()
{
    T=$(gettop)
    if [ ! "$T" ] ; then
        echo "Couldn't locate the top of the tree. Try setting TOP." >&2
        return
    fi
    get_build_var report_config
}

# Get the value of a build variable as an absolute path.
function get_abs_build_var()
{
    T=$(gettop)
    if [ ! "$T" ] ; then
        echo "Couldn't locate the top of the tree. Try setting TOP." >&2
        return
    fi
    (\cd $T; CALLED_FROM_SETUP=true BUILD_SYSTEM=build/core \
        make --no-print-directory -C "$T" -f build/core/config.mk dumpvar-abs-$1)
}

# Get the exact value of a build variable.
function get_build_var()
{
    T=$(gettop)
    if [ ! "$T" ] ; then
        echo "Couldn't locate the top of the tree. Try setting TOP." >&2
        return
    fi
    CALLED_FROM_SETUP=true BUILD_SYSTEM=build/core \
        make --no-print-directory -C "$T" -f build/core/config.mk dumpvar-$1
}

function mm()
{
    # If we're sitting in the root of the build tree, just do a
    # normal make.
    if [ -f build/core/envsetup.mk -a -f Makefile ]; then
        make $@
    else
        # Find the closest Android.mk file.
        T=$(gettop)
        local M=$(findmakefile)
        # Remove the path to top as the makefilepath needs to be relative
        local M=`echo $M|sed 's:'$T'/::'`
        if [ ! "$T" ]; then
            echo "Couldn't locate the top of the tree.  Try setting TOP."
        elif [ ! "$M" ]; then
            echo "Couldn't locate a makefile from the current directory."
        else
            ONE_SHOT_MAKEFILE=$M make -C $T -f build/core/main.mk all_modules $@
        fi
    fi
}

function findmakefile()
{
    TOPFILE=build/core/envsetup.mk
    local HERE=$PWD
    T=
    while [ \( ! \( -f $TOPFILE \) \) -a \( $PWD != "/" \) ]; do
        T=`PWD= /bin/pwd`
        if [ -f "$T/Yudatun.mk" ]; then
            echo $T/Yudatun.mk
            \cd $HERE
            return
        fi
        \cd ..
    done
    \cd $HERE
}

function mmm()
{
    T=$(gettop)
    if [ "$T" ] ; then
        local MAKEFILE=
        local MODULE=
        local ARGS=
        local DIR TOP_CHOP
        local DASH_ARGS=$(echo "$@" | awk -v RS=" " -v ORS=" " '/^-.*$/')
        local DIRS=$(echo "$@" | awk -v RS=" " -v ORS=" " '/^[^-].*$/')
        for DIR in $DIRS ; do
            MODULES=`echo $DIR | sed -n -e 's/.*:\(.*$\)/\1/p' | sed 's/,/ /'`
            if [ "$MODULES" = "" ] ; then
                MODULES=all_modules
            fi
            DIR=`echo $DIR | sed -e 's/:.*//' -e 's:/$::'`
            if [ -f $DIR/Yudatun.mk ] ; then
                TO_CHOP=`(\cd -P -- $T && pwd -P) | wc -c | tr -d ''`
                TO_CHOP=`expr $TO_CHOP + 1`
                START=`PWD= /bin/pwd`
                MFILE=`echo $START | cut -c${TO_CHOP}-`
                if [ "$MFILE" = "" ] ; then
                    MFILE=$DIR/Yudatun.mk
                else
                    MFILE=$MFILE/$DIR/Yudatun.mk
                fi
                MAKEFILE="$MAKEFILE $MFILE"
            else
                if [ "$DIR" = snode ] ; then
                    ARGS="$ARGS snod"
                elif [ "$DIR" = showcommands ] ; then
                    ARGS="$ARGS showcommands"
                elif [ "$DIR" = dist ] ; then
                    ARGS="$ARGS dist"
                else
                    echo "No Yudatun.mk in $DIR"
                    return 1
                fi
            fi
        done
        ONE_SHOT_MAKEFILE="$MAKEFILE" make -C $T -f build/core/main.mk \
            $DASH_ARGS $MODULES $ARGS
    else
        echo "Couldn't locate the top of the tree. Try setting TOP."
    fi
}

function mma()
{
    local T=$(gettop)
    local DRV=$(getdriver $T)
    if [ -f build/core/envsetup.mk -a -f Makefile ]; then
        $DRV make $@
    else
        if [ ! "$T" ]; then
            echo "Couldn't locate the top of the tree.  Try setting TOP."
        fi
        local MY_PWD=`PWD= /bin/pwd|sed 's:'$T'/::'`
        $DRV make -C $T -f build/core/main.mk $@ all_modules BUILD_MODULES_IN_PATHS="$MY_PWD"
    fi
}

function mmma()
{
    local T=$(gettop)
    local DRV=$(getdriver $T)
    if [ "$T" ]; then
        local DASH_ARGS=$(echo "$@" | awk -v RS=" " -v ORS=" " '/^-.*$/')
        local DIRS=$(echo "$@" | awk -v RS=" " -v ORS=" " '/^[^-].*$/')
        local MY_PWD=`PWD= /bin/pwd`
        if [ "$MY_PWD" = "$T" ]; then
            MY_PWD=
        else
            MY_PWD=`echo $MY_PWD|sed 's:'$T'/::'`
        fi
        local DIR=
        local MODULE_PATHS=
        local ARGS=
        for DIR in $DIRS ; do
            if [ -d $DIR ]; then
                if [ "$MY_PWD" = "" ]; then
                    MODULE_PATHS="$MODULE_PATHS $DIR"
                else
                    MODULE_PATHS="$MODULE_PATHS $MY_PWD/$DIR"
                fi
            else
                case $DIR in
                    showcommands | snod | dist | incrementaljavac) ARGS="$ARGS $DIR";;
                    *) echo "Couldn't find directory $DIR"; return 1;;
                esac
            fi
        done
        $DRV make -C $T -f build/core/main.mk $DASH_ARGS $ARGS all_modules BUILD_MODULES_IN_PATHS="$MODULE_PATHS"
    else
        echo "Couldn't locate the top of the tree.  Try setting TOP."
    fi
}

function croot()
{
    T=$(gettop)
    if [ "$T" ] ; then
        cd $T
    else
        echo "Couldn't locate the top of the tree. Try setting TOP."
    fi
}

function check_path()
{
    local path=`type -P $1`
    if [ ! -x "$path" ] ; then
        echo "Unable to find $1 in path. Try to 'sudo apt-get install $1'"
        return
    fi
}

function gettop()
{
    local TOPFILE=build/core/envsetup.mk
    if [ -n "$TOP" -a -f "$TOP/$TOPFILE" ] ; then
        echo $TOP
    else
        if [ -f $TOPFILE ] ; then
            # The following circumlocution (repeated below as well) ensures
            # that we record the true directory name and not one that is faked
            # up with symlink names.
            PWD= /bin/pwd
         else
            local HERE=$PWD
            T=
            # The following codes ensures that goto a directory which can
            # found file "build/core/envsetup.mk"
            while [ \( ! \( -f $TOPFILE \) \) -a \( $PWD != "/" \) ] ; do
                \cd ..
                T=$(PWD= /bin/pwd)
            done
            \cd $HERE
            if [ -f "$T/$TOPFILE" ] ; then
                echo $T
            fi
        fi
    fi
}

function check_build_dependence()
{
    local path=`type -P $1`
    if [ ! -x "$path" ] ; then
        echo "ERROR: build yudatun needs: $1."
        echo "Please try: sudo apt-get install $1"
    else
        echo "Build yudatun needs \"$1\" was configed successfully."
    fi
}

function yudatun_upload()
{
    git push ssh://yudatun@review.gerrithub.io:29418/yudatun/$1 HEAD:refs/for/$2
}

function emulator-pb()
{
    check_path qemu-system-arm

    qemu-system-arm -M versatilepb -m 128M \
        -kernel $1 \
        -initrd $2 \
        -append "root=/dev/ram rdinit=/init"
}

function emulator-a9()
{
    check_path qemu-system-arm

    qemu-system-arm -M vexpress-a9 -m 1024M -cpu cortex-a9 \
        -kernel $1 \
        -initrd $2 \
        -append "root=/dev/ram rdinit=/init"
}

function emulator-nographic-pb()
{
    check_path qemu-system-arm

    qemu-system-arm -nographic -M versatilepb -m 128M \
        -kernel $1 \
        -initrd $2 \
        -append "root=/dev/ram rdinit=/init console=ttyAMA0"
}

function emulator-nographic-a9()
{
    check_path qemu-system-arm

    qemu-system-arm -nographic -M vexpress-a9 -m 1024M -cpu cortex-a9 \
        -kernel $1 \
        -initrd $2 \
        -append "root=/dev/ram rdinit=/init console=ttyAMA0"
}

function emulator-a9-serial()
{
    check_path qemu-system-arm

    qemu-system-arm -M vexpress-a9 -m 1024M -cpu cortex-a9 \
        -kernel $1 -initrd $2 \
        -serial stdio -append "console=ttyAMA0"
}

function create_flash_image()
{
    dd if=/dev/zero of=flash.bin bs=1 count=6M
    dd if=bootloader of=flash.bin conv=notrunc bs=1
    dd if=kernel of=flash.bin conv=notrunc bs=1 seek=2M
    dd if=initramfs.img of=flash.bin conv=notrunc bs=1 seek=4M
}

function gdbserver-a9()
{
    qemu-system-arm -d in_asm -M vexpress-a9 -m 1024 -cpu cortex-a9 -kernel $1 -serial stdio -s -S
}

if [ "x$SHELL" != "x/bin/bash" ] ; then
    case 'ps -o command -p $$' in
        *bash*)
            ;;
        *)
            echo "WARNING: Only bash is supported, use of other shell would lead to erroneous results"
            ;;
    esac
fi

check_build_dependence python
