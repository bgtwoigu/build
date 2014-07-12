/**
 * Copyright (c) 2014 The Yudatun Open Source Project
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <ctype.h>

#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <dirent.h>

#include <private/yudatun_filesystem_config.h>

static void die(const char* why, ...)
{
    va_list ap;

    va_start(ap, why);
    fprintf(stderr, "error: ");
    vfprintf(stderr, why, ap);
    fprintf(stderr, "\n");
    va_end(ap);
    exit(1);
}

struct fs_config_entry {
    char* f_name;
    int   f_uid;
    int   f_gid;
    int   f_mode;
};

static struct fs_config_entry* s_canned_config = NULL;

/* Each line in the canned file should be a path plus three ints
** (uid, gid, mode). */
#ifdef PATH_MAX
#define CANNED_LINE_LENGTH (PATH_MAX + 100)
#else
#define CANNED_LINE_LENGTH (1024)
#endif // PATH_MAX

#define BUFFER_LENGTH 8192

static int s_verbose = 0;
static int s_total_size = 0;

static void read_canned_config(char* filename);
static void archive(const char* start, const char* prefix);
static void archive_dir(char* in, char* out, int ilen, int olen);
static void archive_file(char* in, char* out, int ilen, int olen);
static void archive_data(struct stat* s, char* out, int olen,
                         char *data, unsigned int datasize);
static void fix_stat(const char* path, struct stat* s);
static void archive_data_trailer(void);

int main(int argc, char* argv[])
{
    argc--;
    argv++;

    if (argc > 1 && strcmp(argv[0], "-f") == 0) {
        read_canned_config(argv[1]);
        argc -= 2;
        argv += 2;
    }

    if (argc == 0) die("no directories to process?!");

    while (argc-- > 0) {
        char* x = strchr(*argv, '=');
        if (x != 0) {
            *x++ = 0;
        } else {
            x = "";
        }

        archive(*argv, x);
        argv++;
    }

    archive_data_trailer();

    return EXIT_SUCCESS;
}

static void read_canned_config(char* filename)
{
    int allocated = 8;
    int used = 0;

    s_canned_config =
            (struct fs_config_entry*)malloc(allocated * sizeof (struct fs_config_entry));

    char line[CANNED_LINE_LENGTH];
    FILE* f = fopen(filename, "r");
    if (f == NULL) die("failed to open canned file");

    while (fgets(line, CANNED_LINE_LENGTH, f) != NULL) {
        if (!line[0]) break;
        if (used >= allocated) {
            allocated *= 2;
            s_canned_config = (struct fs_config_entry*)realloc(
                s_canned_config, allocated * sizeof (struct fs_config_entry));
        }

        struct fs_config_entry* cc = s_canned_config + used;
        if (isspace(line[0])) {
            cc->f_name = strdup("");
            cc->f_uid = atoi(strtok(line, " \n"));
        } else {
            cc->f_name = strdup(strtok(line, " \n"));
            cc->f_uid = atoi(strtok(NULL, " \n"));
        }
        cc->f_gid = atoi(strtok(NULL, " \n"));
        cc->f_mode = strtol(strtok(NULL, " \n"), NULL, 8);
        ++used;
    }
    if (used >= allocated) {
        ++allocated;
        s_canned_config = (struct fs_config_entry*)realloc(
            s_canned_config, allocated * sizeof (struct fs_config_entry));
    }
    s_canned_config[used].f_name = NULL;

    fclose(f);
}

static void archive(const char* start, const char* prefix)
{
    char in[BUFFER_LENGTH];
    char out[BUFFER_LENGTH];

    strcpy(in, start);
    strcpy(out, prefix);

    archive_dir(in, out, strlen(in), strlen(out));
}

static int compare(const void* a, const void* b)
{
    return strcmp(*(const char**)a, *(const char**)b);
}

static void archive_dir(char* in, char* out, int ilen, int olen)
{
    int i, t;
    DIR *d;
    struct dirent *de;

    if (s_verbose) {
        fprintf(stderr, "archive_dir('%s','%s','%d','%d')\n",
                in, out, ilen, olen);
    }

    d = opendir(in);
    if (d == NULL) die("cannot open directory '%s'", in);

    int size = 32;
    int entries = 0;
    char** names = malloc(size * sizeof (char*));
    if (names == NULL) {
        die("failed to allocate dir names array (size %d)", size);
    }

    while ((de = readdir(d)) != NULL) {
        /* xxx: hack. use a real exclude list */
        if (!strcmp(de->d_name, ".") || !strcmp(de->d_name, "..")) continue;
        if (!strcmp(de->d_name, "root")) continue;

        if (entries >= size) {
            size *= 2;
            names = realloc(names, size * sizeof (char*));
            if (names == NULL) {
                die("failed to reallocate dir names array (size %d)");
            }
        }
        names[entries] = strdup(de->d_name);
        if (names[entries] == NULL) {
            die("failed to strdup name \"%s\"", de->d_name);
        }
        ++entries;
    }

    qsort(names, entries, sizeof (char*), compare);

    for (i = 0; i < entries; ++i) {
        t = strlen(names[i]);
        in[ilen] = '/';
        memcpy(in + ilen + 1, names[i], t + 1);

        if (olen > 0) {
            out[olen] = '/';
            memcpy(out + olen + 1, names[i], t + 1);
            archive_file(in, out, ilen + t + 1, olen + t + 1);
        } else {
            memcpy(out, names[i], t + 1);
            archive_file(in, out, ilen + t + 1, t);
        }

        in[ilen] = 0;
        out[olen] = 0;

        free(names[i]);
    }
    free(names);
}

static void archive_file(char* in, char* out, int ilen, int olen)
{
    struct stat s;

    if (s_verbose) {
        fprintf(stderr, "_archive('%s','%s','%d','%d')\n",
                in, out, ilen, olen);
    }

    if (lstat(in, &s)) die("could not stat '%s'", in);

    if (S_ISREG(s.st_mode)) {
        char* data;
        int fd;

        fd = open(in, O_RDONLY);
        if (fd < 0) die("cannot open '%s' for read", in);

        data = (char*)malloc(s.st_size);
        if (data == NULL) die("cannot allocate %d bytes", s.st_size);

        if (read(fd, data, s.st_size) != s.st_size) {
            die("cannot read %d bytes", s.st_size);
        }

        archive_data(&s, out, olen, data, s.st_size);

        free(data);
        close(fd);
    } else if (S_ISDIR(s.st_mode)) {
        archive_data(&s, out, olen, 0, 0);
        archive_dir(in, out, ilen, olen);
    } else if (S_ISLNK(s.st_mode)) {
        char buf[1024];
        int size;
        size = readlink(in, buf, 1024);
        if (size < 0) die("cannot read symlink '%s'", in);
        archive_data(&s, out, olen, buf, size);
    } else {
        die("unknown '%s' (mode %d)?", in, s.st_mode);
    }
}

static void archive_data(struct stat* s, char* out, int olen,
                         char* data, unsigned int datasize)
{
    /* Nothing is special about this value, just picked something in the
    ** approximate range that was being used already, and avoiding small
    ** values which may be special.
    */
    static unsigned next_inode = 300000;

    while (s_total_size & 3) {
        s_total_size++;
        putchar(0);
    }

    fix_stat(out, s);

    /* New ASCII Format:
    ** The "new" ASCII format uses 8-byte hexadecimal fields for all numbers and
    ** separates device numbers into separate fields for major and minor num-
    ** bers.
    **
    ** struct cpio_newc_header {
    **     char    c_magic[6]; // The string "070701".
    **     char    c_ino[8];
    **     char    c_mode[8];
    **     char    c_uid[8];
    **     char    c_gid[8];
    **     char    c_nlink[8];
    **     char    c_mtime[8];
    **     char    c_filesize[8];
    **     char    c_devmajor[8];
    **     char    c_devminor[8];
    **     char    c_rdevmajor[8];
    **     char    c_rdevminor[8];
    **     char    c_namesize[8];
    **     char    c_check[8];
    ** };
    **
    ** More info please reference "cpio headers".
    */
    printf("%06x%08x%08x%08x%08x%08x%08x"
           "%08x%08x%08x%08x%08x%08x%08x%s%c",
           0x070701,     // magic, cpio magic number for c header
           next_inode++, // ino
           s->st_mode,   // mode
           0,            // uid
           0,            // gid
           1,            // nlink
           0,            // mtime
           datasize,     // filesize
           0,            // major
           0,            // minor
           0,            // r-major
           0,            // r-minor
           olen + 1,     // name size
           0,            // check sum
           out,          // name
           0             // end
           );

    s_total_size += 6 + 8 * 13 + olen + 1;

    if (strlen(out) != (unsigned int)olen) die("ACK!");

    while (s_total_size & 3) {
        s_total_size++;
        putchar(0);
    }

    if (datasize) {
        fwrite(data, datasize, 1, stdout);
        s_total_size += datasize;
    }
}

static void fix_stat(const char* path, struct stat* s)
{
    uint64_t capabilities;
    if (s_canned_config) {
        /* Use the list of file uid/gid/modes loaded from the file
        ** given with -f */
        struct fs_config_entry* empty_path_config = NULL;
        struct fs_config_entry* p;
        for (p = s_canned_config; p->f_name; ++p) {
            if (!p->f_name[0]) {
                empty_path_config = p;
            }
            if (strcmp(p->f_name, path) == 0) {
                s->st_uid = p->f_uid;
                s->st_gid = p->f_gid;
                s->st_mode = p->f_mode | (s->st_mode & ~07777);
                return;
            }
        }
        s->st_uid = empty_path_config->f_uid;
        s->st_gid = empty_path_config->f_gid;
        s->st_mode = empty_path_config->f_mode | (s->st_mode & ~07777);
    } else {
        /* Use the compiled-in fs_config() function */
        fs_config(path, S_ISDIR(s->st_mode), &s->st_uid,
                  &s->st_gid, &s->st_mode, &capabilities);
    }
}

static void archive_data_trailer(void)
{
    struct stat s;
    memset(&s, 0, sizeof(s));
    archive_data(&s, "TRAILER!!!", 10, 0, 0);

    while (s_total_size & 0xff) {
        s_total_size++;
        putchar(0);
    }
}
