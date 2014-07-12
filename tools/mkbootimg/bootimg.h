/**
 * Copyright (c) 2014 The Yudatun Open Source Project
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#ifndef _TOOLS_BOOTIMG_H_
#define _TOOLS_BOOTIMG_H_

/*
 * +-----------------+
 * | boot header     | 1 page
 * +-----------------+
 * | kernel          | n pages
 * +-----------------+
 * | initramfs       | m pages
 * +-----------------+
 * | second stage    | o pages
 * +-----------------+
 *
 * n = (kernel_size + page_size - 1) / page_size
 * m = (initramfs_size + page_size - 1) / page_size
 * o = (second_size + page_size - 1) / page_size
 *
 * 0. all entities are page_size aligned in flash
 * 1. kernel and initramfs are required (size != 0)
 * 2. second is optional (second_size == 0 -> no second)
 * 3. load each element (kernel, initramfs, second) at
 *    the specified physical address (kernel_addr, etc)
 * 4. prepare tags at tag_addr.  kernel_args[] is
 *    appended to the kernel commandline in the tags.
 * 5. r0 = 0, r1 = MACHINE_TYPE, r2 = tags_addr
 * 6. if second_size != 0: jump to second_addr
 *    else: jump to kernel_addr
 */

#define BOOT_MAGIC "YUDATUN!!"
#define BOOT_MAGIC_SIZE  8
#define BOOT_NAME_SIZE  16
#define BOOT_ARGS_SIZE 512

struct bootimg_header
{
    unsigned char magic[BOOT_MAGIC_SIZE];

    unsigned int kernel_size;   /* size in bytes */
    unsigned int kernel_addr;   /* physical load addr */

    unsigned int initramfs_size;  /* size in bytes */
    unsigned int initramfs_addr;  /* physical load addr */

    unsigned int second_size;   /* size in bytes */
    unsigned int second_addr;   /* physical load addr */

    unsigned int tags_addr;     /* physical addr for kernel tags */
    unsigned int page_size;     /* flash page size we assume */
    unsigned int reserved[2];   /* future expansion: should be 0 */

    /* asciiz product name */
    unsigned char name[BOOT_NAME_SIZE];

    unsigned char cmdline[BOOT_ARGS_SIZE];

    unsigned int id[8];  /* timestamp / checksum / sha1 / etc */
};

#endif /* _TOOLS_BOOTIMG_H_ */
