// SPDX-License-Identifier: MIT

#include <alsa/asoundlib.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static void configure_alsa(void) {
  const char *root;
  char path[512];

  if (getenv("ALSA_CONFIG_PATH") && getenv("ALSA_CONFIG_PATH")[0]) {
    return;
  }
  root = getenv("PLUMOS_ROOT");
  if (!root || !root[0]) {
    root = "/mnt/plumos";
  }
  snprintf(path, sizeof(path), "%s/config/alsa/alsa.conf", root);
  if (access(path, R_OK) != 0) {
    snprintf(path, sizeof(path), "%s/factory-defaults/alsa/alsa.conf", root);
  }
  if (access(path, R_OK) == 0) {
    setenv("ALSA_CONFIG_PATH", path, 0);
  }
}

static snd_mixer_elem_t *find_element(snd_mixer_t *mixer, const char *name) {
  snd_mixer_selem_id_t *id;

  snd_mixer_selem_id_alloca(&id);
  snd_mixer_selem_id_set_index(id, 0);
  snd_mixer_selem_id_set_name(id, name);
  return snd_mixer_find_selem(mixer, id);
}

static int set_playback_volume_max(snd_mixer_t *mixer) {
  snd_mixer_elem_t *element = find_element(mixer, "Playback");
  long minimum;
  long maximum;

  if (!element || !snd_mixer_selem_has_playback_volume(element)) {
    return -ENOENT;
  }
  if (snd_mixer_selem_get_playback_volume_range(element, &minimum, &maximum) <
      0) {
    return -EIO;
  }
  (void)minimum;
  return snd_mixer_selem_set_playback_volume_all(element, maximum) < 0
             ? -EIO
             : 0;
}

static int set_route_enum(snd_mixer_t *mixer, const char *route) {
  snd_mixer_elem_t *element = find_element(mixer, "Playback Path");
  unsigned int count;
  unsigned int index;

  if (!element || !snd_mixer_selem_is_enumerated(element)) {
    return -ENOENT;
  }
  count = snd_mixer_selem_get_enum_items(element);
  for (index = 0; index < count; index++) {
    char name[64] = "";

    if (snd_mixer_selem_get_enum_item_name(element, index, sizeof(name), name) <
        0) {
      continue;
    }
    if (strcmp(name, route) == 0) {
      return snd_mixer_selem_set_enum_item(
                 element, SND_MIXER_SCHN_FRONT_LEFT, index) < 0
                 ? -EIO
                 : 0;
    }
  }
  return -ENOENT;
}

static int headphone_connected(void) {
  const char *path = getenv("PLUMOS_RK817_HEADPHONE_GPIO");
  FILE *file;
  int value = 0;

  if (!path || !path[0]) {
    path = "/sys/class/gpio/gpio86/value";
  }
  file = fopen(path, "r");
  if (!file) {
    return 0;
  }
  if (fscanf(file, "%d", &value) != 1) {
    value = 0;
  }
  fclose(file);
  return value == 1;
}

static int initialize_rk2020_audio(snd_mixer_t *mixer, const char **route) {
  const char *override = getenv("PLUMOS_RK817_ROUTE");
  int result;

  if (override &&
      (strcmp(override, "SPK") == 0 || strcmp(override, "HP") == 0)) {
    *route = override;
  } else {
    *route = headphone_connected() ? "HP" : "SPK";
  }
  result = set_playback_volume_max(mixer);
  if (result < 0) {
    return result;
  }
  return set_route_enum(mixer, *route);
}

static int reapply_route_switch(snd_mixer_t *mixer, const char *name,
                                int nudge) {
  snd_mixer_elem_t *element = find_element(mixer, name);
  int saved[SND_MIXER_SCHN_LAST + 1];
  int present[SND_MIXER_SCHN_LAST + 1];
  int channel;

  if (!element || !snd_mixer_selem_has_playback_switch(element)) {
    return -ENOENT;
  }
  memset(present, 0, sizeof(present));
  for (channel = 0; channel <= SND_MIXER_SCHN_LAST; channel++) {
    snd_mixer_selem_channel_id_t id =
        (snd_mixer_selem_channel_id_t)channel;
    if (!snd_mixer_selem_has_playback_channel(element, id) ||
        snd_mixer_selem_get_playback_switch(element, id, &saved[channel]) < 0) {
      continue;
    }
    present[channel] = 1;
    if (nudge && saved[channel] &&
        snd_mixer_selem_set_playback_switch(element, id, 0) < 0) {
      return -EIO;
    }
  }
  for (channel = 0; channel <= SND_MIXER_SCHN_LAST; channel++) {
    if (present[channel] &&
        snd_mixer_selem_set_playback_switch(
            element, (snd_mixer_selem_channel_id_t)channel,
            saved[channel]) < 0) {
      return -EIO;
    }
  }
  return 0;
}

static int reapply_route_enum(snd_mixer_t *mixer, const char *name,
                              int nudge) {
  snd_mixer_elem_t *element = find_element(mixer, name);
  unsigned int saved;

  if (!element || !snd_mixer_selem_is_enumerated(element)) {
    return -ENOENT;
  }
  if (snd_mixer_selem_get_enum_item(element, SND_MIXER_SCHN_FRONT_LEFT,
                                    &saved) < 0) {
    return -EIO;
  }
  /* RK817 Playback Path item 0 is OFF.  Toggle it only on rearm so the
   * codec route is rebuilt after resume, then restore the selected route. */
  if (nudge && saved != 0 &&
      snd_mixer_selem_set_enum_item(element, SND_MIXER_SCHN_FRONT_LEFT, 0) <
          0) {
    return -EIO;
  }
  if (snd_mixer_selem_set_enum_item(element, SND_MIXER_SCHN_FRONT_LEFT,
                                    saved) < 0) {
    return -EIO;
  }
  return 0;
}

static int reapply_rk2020_routes(snd_mixer_t *mixer, int nudge) {
  const char *names[] = {"Speaker", "Headphone"};
  int found = 0;
  size_t index;

  for (index = 0; index < sizeof(names) / sizeof(names[0]); index++) {
    int result = reapply_route_switch(mixer, names[index], nudge);
    if (result == 0) {
      found++;
    } else if (result != -ENOENT) {
      return result;
    }
  }
  {
    int result = reapply_route_enum(mixer, "Playback Path", nudge);
    if (result == 0) {
      found++;
    } else if (result != -ENOENT) {
      return result;
    }
  }
  if (!found) {
    fprintf(stderr, "rk817-resume: RK2020 route controls unavailable\n");
    return -ENOENT;
  }
  return 0;
}

int main(int argc, char **argv) {
  const char *action = argc > 1 ? argv[1] : "arm";
  const char *card = getenv("PLUMOS_RK817_ALSA_CARD");
  const char *route = NULL;
  snd_mixer_t *mixer = NULL;
  int result;

  if (strcmp(action, "init") != 0 && strcmp(action, "arm") != 0 &&
      strcmp(action, "rearm") != 0 &&
      strcmp(action, "route-speaker") != 0 &&
      strcmp(action, "route-headphone") != 0) {
    fprintf(stderr,
            "usage: %s [init|arm|rearm|route-speaker|route-headphone]\n",
            argv[0]);
    return 2;
  }
  if (!card || !card[0]) {
    card = "default";
  }
  configure_alsa();
  result = snd_mixer_open(&mixer, 0);
  if (result >= 0) {
    result = snd_mixer_attach(mixer, card);
  }
  if (result >= 0) {
    result = snd_mixer_selem_register(mixer, NULL, NULL);
  }
  if (result >= 0) {
    result = snd_mixer_load(mixer);
  }
  if (result < 0) {
    fprintf(stderr, "rk817-resume: mixer open failed card=%s error=%s\n", card,
            snd_strerror(result));
    if (mixer) {
      snd_mixer_close(mixer);
    }
    return 1;
  }
  if (strcmp(action, "init") == 0) {
    result = initialize_rk2020_audio(mixer, &route);
  } else if (strcmp(action, "route-speaker") == 0) {
    route = "SPK";
    result = set_route_enum(mixer, route);
  } else if (strcmp(action, "route-headphone") == 0) {
    route = "HP";
    result = set_route_enum(mixer, route);
  } else {
    result = reapply_rk2020_routes(mixer, strcmp(action, "rearm") == 0);
  }
  snd_mixer_close(mixer);
  if (result < 0) {
    fprintf(stderr, "rk817-resume: action failed action=%s error=%s\n", action,
            snd_strerror(result));
    return 1;
  }
  if (route) {
    printf("rk817_resume=result-ok action=%s card=%s route=%s "
           "playback=%s\n",
           action, card, route,
           strcmp(action, "init") == 0 ? "max" : "unchanged");
  } else {
    printf("rk817_resume=result-ok action=%s card=%s "
           "routes=Speaker,Headphone,Playback_Path\n",
           action, card);
  }
  return 0;
}
