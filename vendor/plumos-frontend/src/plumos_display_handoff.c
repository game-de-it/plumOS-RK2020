#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <pthread.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/un.h>
#include <unistd.h>

static pthread_t server_thread;
static int server_started;
static int server_fd = -1;
static char server_path[sizeof(((struct sockaddr_un *)0)->sun_path)];

static void after_fork_child(void) {
  /* A fork child must not unlink or close the parent's broker endpoint. */
  if (server_fd >= 0) {
    close(server_fd);
  }
  server_started = 0;
  server_fd = -1;
  server_path[0] = '\0';
}

static const char *display_device(void) {
  const char *path = getenv("PLUMOS_DISPLAY_HANDOFF_DEVICE");
  return path && path[0] ? path : "/dev/dri/card0";
}

static int find_display_fd(void) {
  DIR *directory = opendir("/proc/self/fd");
  struct dirent *entry;
  int result = -1;

  if (!directory) {
    return -1;
  }
  while ((entry = readdir(directory)) != NULL) {
    char link_path[64];
    char target[256];
    char *end = NULL;
    long fd_number;
    ssize_t length;

    if (entry->d_name[0] == '.') {
      continue;
    }
    errno = 0;
    fd_number = strtol(entry->d_name, &end, 10);
    if (errno || !end || *end || fd_number < 0 || fd_number > 1048576) {
      continue;
    }
    if (snprintf(link_path, sizeof(link_path), "/proc/self/fd/%s",
                 entry->d_name) >= (int)sizeof(link_path)) {
      continue;
    }
    length = readlink(link_path, target, sizeof(target) - 1);
    if (length < 0) {
      continue;
    }
    target[length] = '\0';
    if (strcmp(target, display_device()) == 0) {
      result = (int)fd_number;
      break;
    }
  }
  closedir(directory);
  return result;
}

static void serve_client(int client) {
  char request[8];
  char byte = 'N';
  struct iovec iov;
  struct msghdr message;
  char control[CMSG_SPACE(sizeof(int))];
  int display_fd;

  if (read(client, request, sizeof(request)) <= 0) {
    return;
  }
  display_fd = find_display_fd();
  memset(&message, 0, sizeof(message));
  iov.iov_base = &byte;
  iov.iov_len = 1;
  message.msg_iov = &iov;
  message.msg_iovlen = 1;
  if (display_fd >= 0) {
    struct cmsghdr *header;
    byte = 'F';
    memset(control, 0, sizeof(control));
    message.msg_control = control;
    message.msg_controllen = sizeof(control);
    header = CMSG_FIRSTHDR(&message);
    header->cmsg_level = SOL_SOCKET;
    header->cmsg_type = SCM_RIGHTS;
    header->cmsg_len = CMSG_LEN(sizeof(int));
    memcpy(CMSG_DATA(header), &display_fd, sizeof(display_fd));
  }
  (void)sendmsg(client, &message, MSG_NOSIGNAL);
}

static void *run_server(void *unused) {
  (void)unused;
  for (;;) {
    int client = accept(server_fd, NULL, NULL);
    if (client < 0) {
      if (errno == EINTR) {
        continue;
      }
      break;
    }
    serve_client(client);
    close(client);
  }
  return NULL;
}

__attribute__((constructor)) static void start_server(void) {
  const char *runtime_root = getenv("PLUMOS_RUNTIME_ROOT");
  char directory[96];
  struct sockaddr_un address;

  if (!runtime_root || !runtime_root[0]) {
    runtime_root = "/run/plumos";
  }
  if (snprintf(directory, sizeof(directory), "%s/display-handoff",
               runtime_root) >= (int)sizeof(directory) ||
      snprintf(server_path, sizeof(server_path), "%s/%ld.sock", directory,
               (long)getpid()) >= (int)sizeof(server_path)) {
    return;
  }
  if (mkdir(runtime_root, 0755) < 0 && errno != EEXIST) {
    return;
  }
  if (mkdir(directory, 0755) < 0 && errno != EEXIST) {
    return;
  }
  server_fd = socket(AF_UNIX, SOCK_STREAM, 0);
  if (server_fd < 0) {
    return;
  }
  (void)fcntl(server_fd, F_SETFD, FD_CLOEXEC);
  memset(&address, 0, sizeof(address));
  address.sun_family = AF_UNIX;
  memcpy(address.sun_path, server_path, strlen(server_path) + 1);
  unlink(server_path);
  if (bind(server_fd, (struct sockaddr *)&address,
           offsetof(struct sockaddr_un, sun_path) + strlen(server_path) + 1) < 0 ||
      chmod(server_path, 0600) < 0 || listen(server_fd, 2) < 0 ||
      pthread_atfork(NULL, NULL, after_fork_child) != 0 ||
      pthread_create(&server_thread, NULL, run_server, NULL) != 0) {
    close(server_fd);
    server_fd = -1;
    unlink(server_path);
    return;
  }
  (void)pthread_detach(server_thread);
  server_started = 1;
}

__attribute__((destructor)) static void stop_server(void) {
  if (server_fd >= 0) {
    shutdown(server_fd, SHUT_RDWR);
    close(server_fd);
    server_fd = -1;
  }
  server_started = 0;
  if (server_path[0]) {
    unlink(server_path);
  }
}
