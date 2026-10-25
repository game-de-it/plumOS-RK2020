#ifndef PLUMOS_PICOARCH_RK2020_HOST_H
#define PLUMOS_PICOARCH_RK2020_HOST_H

#include <stdbool.h>

bool rk2020_get_perf_interface(void *data);
bool rk2020_get_vfs_interface(void *data, const char *core_path);

#endif
