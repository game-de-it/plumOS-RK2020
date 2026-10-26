#define _FILE_OFFSET_BITS 64
#define _POSIX_C_SOURCE 200809L

#include "picoarch_rk2020_host.h"

#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <linux/input.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <time.h>
#include <unistd.h>

#include "libretro-common/include/libretro.h"

struct retro_vfs_file_handle {
  FILE *file;
  char *path;
};

struct retro_vfs_dir_handle {
  DIR *dir;
  struct dirent *entry;
  char *path;
  int include_hidden;
};

static int rk2020_gamepad_fd = -2;

static int rk2020_key_is_down(const unsigned long *keybits, unsigned code) {
  const unsigned bits_per_word = sizeof(*keybits) * 8U;

  return !!(keybits[code / bits_per_word] &
            (1UL << (code % bits_per_word)));
}

void rk2020_poll_gamepad(int *buttons) {
  static const struct {
    unsigned code;
    unsigned retro_id;
  } key_map[] = {
      {BTN_DPAD_UP, RETRO_DEVICE_ID_JOYPAD_UP},
      {BTN_DPAD_DOWN, RETRO_DEVICE_ID_JOYPAD_DOWN},
      {BTN_DPAD_LEFT, RETRO_DEVICE_ID_JOYPAD_LEFT},
      {BTN_DPAD_RIGHT, RETRO_DEVICE_ID_JOYPAD_RIGHT},
      {BTN_SOUTH, RETRO_DEVICE_ID_JOYPAD_B},
      {BTN_EAST, RETRO_DEVICE_ID_JOYPAD_A},
      {BTN_NORTH, RETRO_DEVICE_ID_JOYPAD_X},
      {BTN_WEST, RETRO_DEVICE_ID_JOYPAD_Y},
      {BTN_TL, RETRO_DEVICE_ID_JOYPAD_L},
      {BTN_TR, RETRO_DEVICE_ID_JOYPAD_R},
      {BTN_TRIGGER_HAPPY3, RETRO_DEVICE_ID_JOYPAD_L2},
      {BTN_TRIGGER_HAPPY4, RETRO_DEVICE_ID_JOYPAD_R2},
      {BTN_TRIGGER_HAPPY1, RETRO_DEVICE_ID_JOYPAD_SELECT},
      {BTN_TRIGGER_HAPPY6, RETRO_DEVICE_ID_JOYPAD_START},
  };
  unsigned long keybits[(KEY_MAX + 1 + sizeof(unsigned long) * 8U - 1U) /
                        (sizeof(unsigned long) * 8U)];
  struct input_absinfo x;
  struct input_absinfo y;
  size_t index;

  if (!buttons)
    return;
  if (rk2020_gamepad_fd == -2) {
    rk2020_gamepad_fd = open("/dev/input/event2", O_RDONLY | O_NONBLOCK | O_CLOEXEC);
    if (rk2020_gamepad_fd < 0)
      fprintf(stderr, "RK2020 PicoArch gamepad open failed: %s\n", strerror(errno));
  }
  if (rk2020_gamepad_fd < 0)
    return;
  memset(keybits, 0, sizeof(keybits));
  if (ioctl(rk2020_gamepad_fd, EVIOCGKEY(sizeof(keybits)), keybits) < 0)
    return;
  for (index = 0; index < sizeof(key_map) / sizeof(key_map[0]); index++) {
    if (rk2020_key_is_down(keybits, key_map[index].code))
      *buttons |= 1U << key_map[index].retro_id;
  }
  if (ioctl(rk2020_gamepad_fd, EVIOCGABS(ABS_X), &x) == 0 &&
      x.maximum > x.minimum) {
    int quarter = (x.maximum - x.minimum) / 4;
    if (x.value < x.minimum + quarter)
      *buttons |= 1U << RETRO_DEVICE_ID_JOYPAD_LEFT;
    if (x.value > x.maximum - quarter)
      *buttons |= 1U << RETRO_DEVICE_ID_JOYPAD_RIGHT;
  }
  if (ioctl(rk2020_gamepad_fd, EVIOCGABS(ABS_Y), &y) == 0 &&
      y.maximum > y.minimum) {
    int quarter = (y.maximum - y.minimum) / 4;
    if (y.value < y.minimum + quarter)
      *buttons |= 1U << RETRO_DEVICE_ID_JOYPAD_UP;
    if (y.value > y.maximum - quarter)
      *buttons |= 1U << RETRO_DEVICE_ID_JOYPAD_DOWN;
  }
}

static retro_time_t rk2020_time_usec(void) {
  struct timespec ts;

  if (clock_gettime(CLOCK_MONOTONIC, &ts) != 0)
    return 0;
  return (retro_time_t)ts.tv_sec * INT64_C(1000000) + ts.tv_nsec / 1000;
}

static retro_perf_tick_t rk2020_perf_counter(void) {
  struct timespec ts;

  if (clock_gettime(CLOCK_MONOTONIC, &ts) != 0)
    return 0;
  return (retro_perf_tick_t)ts.tv_sec * UINT64_C(1000000000) + ts.tv_nsec;
}

static uint64_t rk2020_cpu_features(void) {
  return RETRO_SIMD_NEON | RETRO_SIMD_ASIMD;
}

static void rk2020_perf_register(struct retro_perf_counter *counter) {
  if (counter)
    counter->registered = true;
}

static void rk2020_perf_start(struct retro_perf_counter *counter) {
  if (counter)
    counter->start = rk2020_perf_counter();
}

static void rk2020_perf_stop(struct retro_perf_counter *counter) {
  retro_perf_tick_t now;

  if (!counter)
    return;
  now = rk2020_perf_counter();
  counter->total += now - counter->start;
  counter->call_cnt++;
}

static void rk2020_perf_log(void) {}

static struct retro_perf_callback perf_interface = {
    rk2020_time_usec,    rk2020_cpu_features, rk2020_perf_counter, rk2020_perf_register,
    rk2020_perf_start,   rk2020_perf_stop,    rk2020_perf_log,
};

bool rk2020_get_perf_interface(void *data) {
  struct retro_perf_callback *out = data;

  if (!out)
    return false;
  *out = perf_interface;
  return true;
}

static const char *rk2020_vfs_get_path(struct retro_vfs_file_handle *stream) {
  return stream ? stream->path : NULL;
}

static struct retro_vfs_file_handle *rk2020_vfs_open(const char *path, unsigned mode,
                                                    unsigned hints) {
  struct retro_vfs_file_handle *stream;
  const char *fmode;

  (void)hints;
  if (!path)
    return NULL;
  if ((mode & RETRO_VFS_FILE_ACCESS_READ_WRITE) == RETRO_VFS_FILE_ACCESS_READ_WRITE)
    fmode = mode & RETRO_VFS_FILE_ACCESS_UPDATE_EXISTING ? "r+b" : "w+b";
  else if (mode & RETRO_VFS_FILE_ACCESS_WRITE)
    fmode = mode & RETRO_VFS_FILE_ACCESS_UPDATE_EXISTING ? "r+b" : "wb";
  else
    fmode = "rb";

  stream = calloc(1, sizeof(*stream));
  if (!stream)
    return NULL;
  stream->file = fopen(path, fmode);
  if (!stream->file && (mode & RETRO_VFS_FILE_ACCESS_WRITE) &&
      (mode & RETRO_VFS_FILE_ACCESS_UPDATE_EXISTING))
    stream->file = fopen(path, "w+b");
  stream->path = strdup(path);
  if (!stream->file || !stream->path) {
    if (stream->file)
      fclose(stream->file);
    free(stream->path);
    free(stream);
    return NULL;
  }
  return stream;
}

static int rk2020_vfs_close(struct retro_vfs_file_handle *stream) {
  int rc;

  if (!stream)
    return -1;
  rc = stream->file ? fclose(stream->file) : -1;
  free(stream->path);
  free(stream);
  return rc;
}

static int64_t rk2020_vfs_tell(struct retro_vfs_file_handle *stream) {
  off_t offset;

  if (!stream || !stream->file)
    return -1;
  offset = ftello(stream->file);
  return offset < 0 ? -1 : (int64_t)offset;
}

static int64_t rk2020_vfs_seek(struct retro_vfs_file_handle *stream, int64_t offset,
                             int seek_position) {
  if (!stream || !stream->file || fseeko(stream->file, (off_t)offset, seek_position) != 0)
    return -1;
  return rk2020_vfs_tell(stream);
}

static int64_t rk2020_vfs_size(struct retro_vfs_file_handle *stream) {
  int64_t current;
  int64_t size;

  current = rk2020_vfs_tell(stream);
  if (current < 0 || rk2020_vfs_seek(stream, 0, SEEK_END) < 0)
    return -1;
  size = rk2020_vfs_tell(stream);
  if (rk2020_vfs_seek(stream, current, SEEK_SET) < 0)
    return -1;
  return size;
}

static int64_t rk2020_vfs_read(struct retro_vfs_file_handle *stream, void *buffer,
                             uint64_t length) {
  size_t count;

  if (!stream || !stream->file || !buffer)
    return -1;
  count = fread(buffer, 1, (size_t)length, stream->file);
  if (count == 0 && ferror(stream->file))
    return -1;
  return (int64_t)count;
}

static int64_t rk2020_vfs_write(struct retro_vfs_file_handle *stream, const void *buffer,
                              uint64_t length) {
  size_t count;

  if (!stream || !stream->file || !buffer)
    return -1;
  count = fwrite(buffer, 1, (size_t)length, stream->file);
  return count == 0 && ferror(stream->file) ? -1 : (int64_t)count;
}

static int rk2020_vfs_flush(struct retro_vfs_file_handle *stream) {
  return stream && stream->file ? fflush(stream->file) : -1;
}

static int rk2020_vfs_remove(const char *path) { return path ? remove(path) : -1; }

static int rk2020_vfs_rename(const char *old_path, const char *new_path) {
  return old_path && new_path ? rename(old_path, new_path) : -1;
}

static int64_t rk2020_vfs_truncate(struct retro_vfs_file_handle *stream, int64_t length) {
  if (!stream || !stream->file)
    return -1;
  return ftruncate(fileno(stream->file), (off_t)length);
}

static int rk2020_vfs_stat(const char *path, int32_t *size) {
  struct stat st;
  int flags = 0;

  if (!path || stat(path, &st) != 0)
    return 0;
  flags |= RETRO_VFS_STAT_IS_VALID;
  if (S_ISDIR(st.st_mode))
    flags |= RETRO_VFS_STAT_IS_DIRECTORY;
  if (S_ISCHR(st.st_mode))
    flags |= RETRO_VFS_STAT_IS_CHARACTER_SPECIAL;
  if (size)
    *size = st.st_size > INT32_MAX ? INT32_MAX : (int32_t)st.st_size;
  return flags;
}

static int rk2020_vfs_mkdir(const char *path) {
  if (!path)
    return -1;
  if (mkdir(path, 0755) == 0)
    return 0;
  return errno == EEXIST ? -2 : -1;
}

static struct retro_vfs_dir_handle *rk2020_vfs_opendir(const char *path,
                                                      bool include_hidden) {
  struct retro_vfs_dir_handle *stream;

  if (!path)
    return NULL;
  stream = calloc(1, sizeof(*stream));
  if (!stream)
    return NULL;
  stream->dir = opendir(path);
  stream->path = strdup(path);
  stream->include_hidden = include_hidden;
  if (!stream->dir || !stream->path) {
    if (stream->dir)
      closedir(stream->dir);
    free(stream->path);
    free(stream);
    return NULL;
  }
  return stream;
}

static bool rk2020_vfs_readdir(struct retro_vfs_dir_handle *stream) {
  if (!stream || !stream->dir)
    return false;
  do {
    stream->entry = readdir(stream->dir);
  } while (stream->entry && !stream->include_hidden && stream->entry->d_name[0] == '.');
  return stream->entry != NULL;
}

static const char *rk2020_vfs_dirent_get_name(struct retro_vfs_dir_handle *stream) {
  return stream && stream->entry ? stream->entry->d_name : NULL;
}

static bool rk2020_vfs_dirent_is_dir(struct retro_vfs_dir_handle *stream) {
  struct stat st;
  char *full_path;
  size_t length;
  bool result = false;

  if (!stream || !stream->entry)
    return false;
#ifdef DT_DIR
  if (stream->entry->d_type == DT_DIR)
    return true;
  if (stream->entry->d_type != DT_UNKNOWN)
    return false;
#endif
  length = strlen(stream->path) + strlen(stream->entry->d_name) + 2;
  full_path = malloc(length);
  if (!full_path)
    return false;
  snprintf(full_path, length, "%s/%s", stream->path, stream->entry->d_name);
  if (stat(full_path, &st) == 0)
    result = S_ISDIR(st.st_mode);
  free(full_path);
  return result;
}

static int rk2020_vfs_closedir(struct retro_vfs_dir_handle *stream) {
  int rc;

  if (!stream)
    return -1;
  rc = stream->dir ? closedir(stream->dir) : -1;
  free(stream->path);
  free(stream);
  return rc;
}

static struct retro_vfs_interface vfs_interface = {
    rk2020_vfs_get_path,       rk2020_vfs_open,          rk2020_vfs_close,
    rk2020_vfs_size,           rk2020_vfs_tell,          rk2020_vfs_seek,
    rk2020_vfs_read,           rk2020_vfs_write,         rk2020_vfs_flush,
    rk2020_vfs_remove,         rk2020_vfs_rename,        rk2020_vfs_truncate,
    rk2020_vfs_stat,           rk2020_vfs_mkdir,         rk2020_vfs_opendir,
    rk2020_vfs_readdir,        rk2020_vfs_dirent_get_name,
    rk2020_vfs_dirent_is_dir,  rk2020_vfs_closedir,
};

bool rk2020_get_vfs_interface(void *data, const char *core_path) {
  struct retro_vfs_interface_info *info = data;

  /* PCSX-ReARMed needs its bundled VFS to retain CD-ROM sector semantics. */
  if (core_path && strstr(core_path, "/pcsx_rearmed_libretro.so"))
    return false;
  if (!info || info->required_interface_version > 3)
    return false;
  info->required_interface_version = 3;
  info->iface = &vfs_interface;
  return true;
}
