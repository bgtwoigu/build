/**
 * Copyright (c) 2014 The Gotoos Open Source Project
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include <unistd.h>
#include <fcntl.h>

#include "bootimg.h"

static void* load_file(const char* fname, unsigned int* sizep);
static int write_padding(int fd, unsigned int pagesize, unsigned int itemsize);

static int usage(void)
{
    fprintf(stdout, "usage: mkbootimg\n"
            "       --kernel <filename>\n"
            "       --initramfs <filename>\n"
            "       [ --second <2ndbootloader-filename> ]\n"
            "       [ --cmdline <kernel-commandline> ]\n"
            "       [ --board <boardname> ]\n"
            "       [ --base <address> ]\n"
            "       [ --pagesize <pagesize> ]\n"
            "       -o | --output <filename>\n"
            );

    return 1;
}

int main(int argc, char* argv[])
{
    struct bootimg_header header;

    char* kernel_file = NULL;
    void* kernel_data = NULL;

    char* initramfs_file = NULL;
    void* initramfs_data = NULL;

    char* second_file = NULL;
    void* second_data = NULL;

    char* cmdline = "";
    char* bootimg = NULL;
    char* board = "";

    int fd;

    unsigned int pagesize = 4096;  /* default is 4KB */

    unsigned long base           = 0x10000000;
    unsigned long kernel_offset  = 0x00008000;
    unsigned long initramfs_offset = 0x01000000;
    unsigned long second_offset  = 0x00f00000;
    unsigned long tags_offset    = 0x00000100;

    argc--;
    argv++;

    memset(&header, 0, sizeof (header));

    while (argc > 0) {
        char* arg = argv[0];
        char* val = argv[1];

        if (argc < 2) {
            return usage();
        }

        argc -= 2;
        argv += 2;

        if (!strcmp(arg, "--output") || !strcmp(arg, "-o")) {
            bootimg = val;
        } else if (!strcmp(arg, "--kernel")) {
            kernel_file = val;
        } else if (!strcmp(arg, "--initramfs")) {
            initramfs_file = val;
        } else if (!strcmp(arg, "--second")) {
            second_file = val;
        } else if (!strcmp(arg, "--cmdline")) {
            cmdline = val;
        } else if (!strcmp(arg, "--base")) {
            base = strtoul(val, 0, 16);
        } else if (!strcmp(arg, "--kernel_offset")) {
            kernel_offset = strtoul(val, 0, 16);
        } else if (!strcmp(arg, "--initramfs_offset")) {
            initramfs_offset = strtoul(val, 0, 16);
        } else if (!strcmp(arg, "--second_offset")) {
            second_offset = strtoul(val, 0, 16);
        } else if (!strcmp(arg, "--tags_offset")) {
            tags_offset = strtoul(val, 0, 16);
        } else if (!strcmp(arg, "--board")) {
            board = val;
        } else if (!strcmp(arg, "--pagesize")) {
            pagesize = strtoul(val, 0, 10);
            if ((pagesize != 2048) && (pagesize != 4096)
                && (pagesize != 8192) && (pagesize != 16384)) {
                fprintf(stderr, "error: unsupported page size %u\n", pagesize);
                return -1;
            }
        } else {
            return usage();
        }
    }

    header.page_size    = pagesize;
    header.kernel_addr  = base + kernel_offset;
    header.initramfs_addr = base + initramfs_offset;
    header.second_addr  = base + second_offset;
    header.tags_addr    = base + tags_offset;

    if (bootimg == NULL) {
        fprintf(stderr, "error: no output filename specified\n");
        return usage();
    }

    if (kernel_file == NULL) {
        fprintf(stderr, "error: no kernel image specified\n");
        return usage();
    }

    if (initramfs_file == NULL) {
        fprintf(stderr, "error: no initramfs image specified\n");
        return usage();
    }

    if (strlen(board) >= BOOT_NAME_SIZE) {
        fprintf(stderr, "error: board name too large\n");
        return usage();
    }

    strcpy((char*)header.name, board);
    memcpy(header.magic, BOOT_MAGIC, BOOT_MAGIC_SIZE);

    if (strlen(cmdline) > (BOOT_ARGS_SIZE - 1)) {
        fprintf(stderr, "error: kernel commandline too large\n");
        return 1;
    }
    strcpy((char*)header.cmdline, cmdline);

    kernel_data = load_file(kernel_file, &header.kernel_size);
    if (kernel_data == NULL) {
        fprintf(stderr, "error: could not load kernel '%s'\n", kernel_file);
        return 1;
    }

    if (!strcmp(initramfs_file, "NONE")) {
        initramfs_data = NULL;
        header.initramfs_size = 0;
    } else {
        initramfs_data = load_file(initramfs_file, &header.initramfs_size);
        if (initramfs_data == NULL) {
            fprintf(stderr, "error: could not load initramfs '%s'\n",
                    initramfs_file);
            return 1;
        }
    }

    if (second_file != NULL) {
        second_data = load_file(second_file, &header.second_size);
        if (second_data == NULL) {
            fprintf(stderr, "error: could not load secondstage '%s'\n",
                    second_file);
            return 1;
        }
    }

    fd = open(bootimg, O_CREAT | O_TRUNC | O_WRONLY, 0644);
    if (fd < 0) {
        fprintf(stderr, "error: could not create '%s'\n", bootimg);
        return 1;
    }

    if (write(fd, &header, sizeof (header)) != sizeof (header)) goto fail;
    if (write_padding(fd, pagesize, sizeof (header))) goto fail;

    if (write(fd, kernel_data, header.kernel_size) != header.kernel_size)
        goto fail;
    if (write_padding(fd, pagesize, header.kernel_size)) goto fail;

    if (write(fd, initramfs_data, header.initramfs_size) != header.initramfs_size)
        goto fail;
    if (write_padding(fd, pagesize, header.initramfs_size)) goto fail;

    if (second_data != NULL) {
        if (write(fd, second_data, header.second_size) != header.second_size)
            goto fail;
        if (write_padding(fd, pagesize, header.initramfs_size)) goto fail;
    }

    return 0;

fail:
    unlink(bootimg);
    close(fd);
    fprintf(stderr, "error: failed writing '%s': %s\n",
            bootimg, strerror(errno));
    return 1;
}

static void* load_file(const char* fname, unsigned int* sizep)
{
    char* data = NULL;
    int size;
    int fd;

    fd = open(fname, O_RDONLY);
    if (fd < 0) return NULL;

    size = lseek(fd, 0, SEEK_END);
    if (size < 0) goto oops;

    if (lseek(fd, 0, SEEK_SET) != 0) goto oops;

    data = (char*)malloc(size);
    if (data == NULL) goto oops;

    if (read(fd, data, size) != size) goto oops;
    close(fd);
    if (sizep != NULL) *sizep = size;

    return data;

oops:
    close(fd);
    if (data != NULL) free(data);
    return NULL;
}

static unsigned char s_padding[16384] = { 0, };

static int write_padding(int fd, unsigned int pagesize, unsigned int itemsize)
{
    unsigned int pagemask = pagesize - 1;
    unsigned int count;

    if ((itemsize & pagemask) == 0) {
        return 0;
    }
    count = pagesize - (itemsize & pagemask);
    if (write(fd, s_padding, count) != count) {
        return -1;
    } else {
        return 0;
    }
}
