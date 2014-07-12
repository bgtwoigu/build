/**
 * Copyright (c) 2013 The Gotoos Open Source Project
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define LOGI(...)                                      \
    do {                                               \
        fprintf(stderr, "%s::%s(): ",                  \
                __FILE__, __FUNCTION__);               \
        fprintf(stderr, __VA_ARGS__ );                 \
        fflush(stderr);                                \
    } while (0)

int main(int argc, char* argv[])
{
    char* buf = NULL;
    int buf_len = 0;
    FILE *file = NULL;
    int file_len = 0;
    int nbytes = 0;
    char* ptr = NULL;
    int i = 0;
    unsigned int checksum = 0;

    if (argc != 4) {
        fprintf(stdout, "Usage: mkbl1 <source file> <destination file> <size>\n");
        return -1;
    }

    buf_len = atoi(argv[3]);
    buf = (char*)malloc(buf_len);
    if (buf == NULL) {
        LOGI("malloc error\n");
        return -1;
    }
    memset(buf, 0, buf_len);

    file = fopen(argv[1], "rb");
    if (file == NULL) {
        LOGI("Source file open error\n");
        free(buf);
        return -1;
    }

    /* count file size */
    fseek(file, 0L, SEEK_END);
    file_len = ftell(file);
    fseek(file, 0L, SEEK_SET);

    if (buf_len > file_len) {
        LOGI("Unsupported size\n");
        free(buf);
        fclose(file);
        return -1;
    }

    nbytes = fread(buf, 1, buf_len, file);
    if (nbytes != buf_len) {
        LOGI("Source file read error\n");
        free(buf);
        fclose(file);
        return -1;
    }
    fclose(file);

    ptr = buf + 16;
    for (i = 0, checksum = 0; i < buf_len - 16; i++) {
        checksum += (0x000000FF) & *ptr++;
    }
    ptr = buf + 8;
    *((unsigned int*)ptr) = checksum;

    file = fopen(argv[2], "wb");
    if (file == NULL) {
        LOGI("Destination file open error\n");
        free(buf);
        return -1;
    }
    ptr = buf;
    nbytes = fwrite(ptr, 1, buf_len, file);
    if (nbytes != buf_len) {
        LOGI("Destination file write error\n");
        free(buf);
        fclose(file);
        return -1;
    }

    free(buf);
    fclose(file);

    return 0;
}
