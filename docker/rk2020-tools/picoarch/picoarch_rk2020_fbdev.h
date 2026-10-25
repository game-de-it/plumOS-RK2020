#ifndef PLUMOS_PICOARCH_RK2020_FBDEV_H
#define PLUMOS_PICOARCH_RK2020_FBDEV_H

#include <fcntl.h>
#include <errno.h>
#include <linux/fb.h>
#include <pthread.h>
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <unistd.h>

static int rk2020_fb_fd = -1;
static uint8_t *rk2020_fb_map;
static size_t rk2020_fb_size;
static struct fb_fix_screeninfo rk2020_fb_fix;
static struct fb_var_screeninfo rk2020_fb_var;
static uint32_t rk2020_fb_draw_yoffset;
static int rk2020_fb_double_buffer;
static pthread_t rk2020_fb_thread;
static pthread_mutex_t rk2020_fb_mutex = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t rk2020_fb_cond = PTHREAD_COND_INITIALIZER;
static uint16_t *rk2020_fb_frames[2];
static int rk2020_fb_thread_started;
static int rk2020_fb_thread_stop;
static int rk2020_fb_active = -1;
static int rk2020_fb_pending = -1;
static volatile sig_atomic_t rk2020_fb_scanout_reactivate = 1;
static struct sigaction rk2020_fb_previous_sigcont;
static int rk2020_fb_sigcont_installed;

static void rk2020_fb_handle_sigcont(int signum)
{
	(void)signum;
	rk2020_fb_scanout_reactivate = 1;
}

static int rk2020_fb_take_scanout_reactivate(void)
{
	sigset_t sigcont_set;
	sigset_t previous_set;
	int requested;

	if (!rk2020_fb_scanout_reactivate)
		return 0;
	sigemptyset(&sigcont_set);
	sigaddset(&sigcont_set, SIGCONT);
	pthread_sigmask(SIG_BLOCK, &sigcont_set, &previous_set);
	requested = rk2020_fb_scanout_reactivate != 0;
	rk2020_fb_scanout_reactivate = 0;
	pthread_sigmask(SIG_SETMASK, &previous_set, NULL);
	return requested;
}

static int rk2020_fb_activate_scanout(uint32_t yoffset, const char *reason)
{
	struct fb_var_screeninfo next = rk2020_fb_var;
	int blank_errno = 0;
	int pan_errno = 0;

	next.xoffset = 0;
	next.yoffset = yoffset;
	next.activate = FB_ACTIVATE_NOW;
	if (ioctl(rk2020_fb_fd, FBIOBLANK, FB_BLANK_UNBLANK) < 0)
		blank_errno = errno;
	if (ioctl(rk2020_fb_fd, FBIOPAN_DISPLAY, &next) < 0)
		pan_errno = errno;
	else
		rk2020_fb_var = next;
	if (blank_errno || pan_errno) {
		fprintf(stderr,
			"RK2020 PicoArch framebuffer scanout activation failed: reason=%s blank=%s pan=%s\n",
			reason, blank_errno ? strerror(blank_errno) : "ok",
			pan_errno ? strerror(pan_errno) : "ok");
		return -1;
	}
	fprintf(stderr,
		"RK2020 PicoArch framebuffer scanout activated: reason=%s yoffset=%u\n",
		reason, yoffset);
	return 0;
}

static void rk2020_fb_present_pixels(const uint16_t *pixels)
{
	unsigned dst_y;
	unsigned dst_width = rk2020_fb_var.xres;
	unsigned dst_height = rk2020_fb_var.yres;
	uint8_t *draw_base;
	int reactivate;

	if (!rk2020_fb_map || !pixels)
		return;
	reactivate = rk2020_fb_take_scanout_reactivate();
	draw_base = rk2020_fb_map +
		(size_t)rk2020_fb_draw_yoffset * rk2020_fb_fix.line_length;
	/* RK2020 exposes the landscape LCD as a physical 320x480 framebuffer.
	 * Present the logical 480x320 PicoArch surface counter-clockwise, matching
	 * the frontend, RetroArch, and PCSX-ReARMed contract. */
	for (dst_y = 0; dst_y < dst_height; dst_y++) {
		unsigned logical_x = dst_height - 1U - dst_y;
		uint32_t *dst = (uint32_t *)(draw_base +
			(size_t)dst_y * rk2020_fb_fix.line_length +
			(size_t)rk2020_fb_var.xoffset * sizeof(*dst));
		unsigned dst_x;

		for (dst_x = 0; dst_x < dst_width; dst_x++) {
			uint16_t p = pixels[(size_t)dst_x * SCREEN_WIDTH + logical_x];
			uint32_t r = (p >> 11) & 0x1f;
			uint32_t g = (p >> 5) & 0x3f;
			uint32_t b = p & 0x1f;

			dst[dst_x] = 0xff000000u | ((r << 3 | r >> 2) << 16) |
			         ((g << 2 | g >> 4) << 8) | (b << 3 | b >> 2);
		}
	}
	if (rk2020_fb_double_buffer) {
		struct fb_var_screeninfo next = rk2020_fb_var;
		int blank_errno = 0;

		if (reactivate &&
		    ioctl(rk2020_fb_fd, FBIOBLANK, FB_BLANK_UNBLANK) < 0)
			blank_errno = errno;
		next.xoffset = 0;
		next.yoffset = rk2020_fb_draw_yoffset;
		/* The emulation/audio clock runs at the core's native rate. Waiting for
		 * the LCD here would drop one a 60 Hz frame roughly once
		 * per second, so the presenter must remain nonblocking. */
		next.activate = FB_ACTIVATE_NOW;
		if (ioctl(rk2020_fb_fd, FBIOPAN_DISPLAY, &next) == 0) {
			rk2020_fb_var = next;
			rk2020_fb_draw_yoffset = next.yoffset == 0 ? next.yres : 0;
			if (reactivate) {
				fprintf(stderr,
					"RK2020 PicoArch framebuffer scanout activated: reason=frame-resume yoffset=%u blank=%s\n",
					next.yoffset,
					blank_errno ? strerror(blank_errno) : "ok");
			}
		} else {
			rk2020_fb_double_buffer = 0;
			rk2020_fb_draw_yoffset = rk2020_fb_var.yoffset;
			rk2020_fb_scanout_reactivate = 1;
		}
	} else if (reactivate) {
		if (rk2020_fb_activate_scanout(rk2020_fb_draw_yoffset,
		    "frame-resume") < 0)
			rk2020_fb_scanout_reactivate = 1;
	}
}

static void *rk2020_fb_present_thread(void *unused)
{
	(void)unused;
	for (;;) {
		int frame;

		pthread_mutex_lock(&rk2020_fb_mutex);
		while (rk2020_fb_pending < 0 && !rk2020_fb_thread_stop)
			pthread_cond_wait(&rk2020_fb_cond, &rk2020_fb_mutex);
		if (rk2020_fb_thread_stop) {
			pthread_mutex_unlock(&rk2020_fb_mutex);
			break;
		}
		frame = rk2020_fb_pending;
		rk2020_fb_pending = -1;
		rk2020_fb_active = frame;
		pthread_mutex_unlock(&rk2020_fb_mutex);

		rk2020_fb_present_pixels(rk2020_fb_frames[frame]);

		pthread_mutex_lock(&rk2020_fb_mutex);
		rk2020_fb_active = -1;
		pthread_mutex_unlock(&rk2020_fb_mutex);
	}
	return NULL;
}

static int rk2020_fb_init(void)
{
	struct sigaction sigcont_action;

	rk2020_fb_fd = open("/dev/fb0", O_RDWR);
	if (rk2020_fb_fd < 0 ||
	    ioctl(rk2020_fb_fd, FBIOGET_FSCREENINFO, &rk2020_fb_fix) < 0 ||
	    ioctl(rk2020_fb_fd, FBIOGET_VSCREENINFO, &rk2020_fb_var) < 0) {
		fprintf(stderr, "RK2020 PicoArch framebuffer query failed: %s\n",
			strerror(errno));
		return -1;
	}
	if (rk2020_fb_var.xres != SCREEN_HEIGHT ||
	    rk2020_fb_var.yres != SCREEN_WIDTH ||
	    rk2020_fb_var.bits_per_pixel != 32 ||
	    rk2020_fb_fix.line_length <
		(rk2020_fb_var.xoffset + rk2020_fb_var.xres) * 4) {
		fprintf(stderr,
			"RK2020 PicoArch framebuffer contract mismatch: %ux%u bpp=%u stride=%u\n",
			rk2020_fb_var.xres, rk2020_fb_var.yres,
			rk2020_fb_var.bits_per_pixel, rk2020_fb_fix.line_length);
		return -1;
	}
	rk2020_fb_size = rk2020_fb_fix.smem_len
	                 ? rk2020_fb_fix.smem_len
	                 : (size_t)rk2020_fb_fix.line_length * rk2020_fb_var.yres_virtual;
	if (rk2020_fb_size < (size_t)rk2020_fb_fix.line_length *
	                    (rk2020_fb_var.yoffset + rk2020_fb_var.yres)) {
		return -1;
	}
	rk2020_fb_map = mmap(NULL, rk2020_fb_size, PROT_READ | PROT_WRITE,
	                   MAP_SHARED, rk2020_fb_fd, 0);
	if (rk2020_fb_map == MAP_FAILED) {
		rk2020_fb_map = NULL;
		fprintf(stderr, "RK2020 PicoArch framebuffer mmap failed: %s\n",
			strerror(errno));
		return -1;
	}
	rk2020_fb_double_buffer = rk2020_fb_var.yres_virtual >= rk2020_fb_var.yres * 2;
	rk2020_fb_draw_yoffset = rk2020_fb_double_buffer &&
	                       rk2020_fb_var.yoffset < rk2020_fb_var.yres
	                         ? rk2020_fb_var.yres : 0;
	rk2020_fb_frames[0] = malloc(SCREEN_WIDTH * SCREEN_HEIGHT * sizeof(uint16_t));
	rk2020_fb_frames[1] = malloc(SCREEN_WIDTH * SCREEN_HEIGHT * sizeof(uint16_t));
	if (!rk2020_fb_frames[0] || !rk2020_fb_frames[1])
		return -1;
	rk2020_fb_thread_stop = 0;
	rk2020_fb_active = -1;
	rk2020_fb_pending = -1;
	rk2020_fb_scanout_reactivate = 1;
	memset(&sigcont_action, 0, sizeof(sigcont_action));
	sigcont_action.sa_handler = rk2020_fb_handle_sigcont;
	sigemptyset(&sigcont_action.sa_mask);
	sigcont_action.sa_flags = SA_RESTART;
	if (sigaction(SIGCONT, &sigcont_action,
	              &rk2020_fb_previous_sigcont) == 0) {
		rk2020_fb_sigcont_installed = 1;
	} else {
		fprintf(stderr,
			"RK2020 PicoArch SIGCONT scanout hook failed: %s\n",
			strerror(errno));
	}
	if (pthread_create(&rk2020_fb_thread, NULL,
	                   rk2020_fb_present_thread, NULL) != 0)
		return -1;
	rk2020_fb_thread_started = 1;
	fprintf(stderr,
		"RK2020 PicoArch framebuffer presenter: physical=%ux%u logical=%ux%u ccw double_buffer=%d\n",
		rk2020_fb_var.xres, rk2020_fb_var.yres,
		SCREEN_WIDTH, SCREEN_HEIGHT, rk2020_fb_double_buffer);
	return 0;
}

static void rk2020_fb_present(const SDL_Surface *surface)
{
	unsigned y;
	int frame;

	if (!rk2020_fb_map || !surface || !rk2020_fb_thread_started)
		return;
	pthread_mutex_lock(&rk2020_fb_mutex);
	frame = rk2020_fb_active == 0 ? 1 : 0;
	if (rk2020_fb_active < 0 && rk2020_fb_pending >= 0)
		frame = rk2020_fb_pending;
	for (y = 0; y < SCREEN_HEIGHT; y++) {
		const uint16_t *src = (const uint16_t *)
			((const uint8_t *)surface->pixels + y * surface->pitch);
		memcpy(rk2020_fb_frames[frame] + y * SCREEN_WIDTH, src,
		       SCREEN_WIDTH * sizeof(uint16_t));
	}
	rk2020_fb_pending = frame;
	pthread_cond_signal(&rk2020_fb_cond);
	pthread_mutex_unlock(&rk2020_fb_mutex);
}

static void rk2020_fb_finish(void)
{
	if (rk2020_fb_thread_started) {
		pthread_mutex_lock(&rk2020_fb_mutex);
		rk2020_fb_thread_stop = 1;
		pthread_cond_signal(&rk2020_fb_cond);
		pthread_mutex_unlock(&rk2020_fb_mutex);
		pthread_join(rk2020_fb_thread, NULL);
		rk2020_fb_thread_started = 0;
	}
	if (rk2020_fb_sigcont_installed) {
		sigaction(SIGCONT, &rk2020_fb_previous_sigcont, NULL);
		rk2020_fb_sigcont_installed = 0;
	}
	if (rk2020_fb_map && rk2020_fb_map != MAP_FAILED) {
		munmap(rk2020_fb_map, rk2020_fb_size);
	}
	if (rk2020_fb_fd >= 0) {
		close(rk2020_fb_fd);
	}
	rk2020_fb_map = NULL;
	rk2020_fb_fd = -1;
	free(rk2020_fb_frames[0]);
	free(rk2020_fb_frames[1]);
	rk2020_fb_frames[0] = NULL;
	rk2020_fb_frames[1] = NULL;
	rk2020_fb_scanout_reactivate = 1;
}

#endif
