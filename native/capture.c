
#include <pipewire/pipewire.h>
#include <spa/param/audio/format-utils.h>
#include <spa/param/param.h>

#include <stdatomic.h>
#include <stdint.h>
#include <stdlib.h>
#include <pthread.h>
#include <math.h>
#include <string.h>

#define RING_SIZE 262144u
#define RING_MASK (RING_SIZE - 1u)

#if (RING_SIZE & (RING_SIZE - 1u)) != 0
#error "RING_SIZE must be a power of two"
#endif

enum {
    AV_STOPPED = 0,
    AV_CONNECTING = 1,
    AV_STREAMING = 2,
    AV_ERROR = -1,
    AV_STOPPING = -2
};

static float ring[RING_SIZE];

static _Atomic uint32_t write_pos;
static _Atomic uint32_t read_pos;
static _Atomic uint64_t dropped_samples;
static _Atomic int state;

static struct pw_main_loop *loop;
static struct pw_stream *stream;
static pthread_t thread;

static int pw_initialized;
static int thread_created;
static int started;

static void on_state_changed(
    void *userdata,
    enum pw_stream_state old,
    enum pw_stream_state current,
    const char *error
) {
    (void)userdata;
    (void)old;
    (void)error;

    if (current == PW_STREAM_STATE_STREAMING) {
        atomic_store(&state, AV_STREAMING);
    } else if (current == PW_STREAM_STATE_ERROR) {
        atomic_store(&state, AV_ERROR);
    } else if (atomic_load(&state) != AV_STOPPING) {
        atomic_store(&state, AV_CONNECTING);
    }
}

static void on_process(void *userdata) {
    (void)userdata;

    struct pw_stream *current_stream = stream;
    if (!current_stream)
        return;

    struct pw_buffer *buffer =
        pw_stream_dequeue_buffer(current_stream);

    if (!buffer)
        return;

    struct spa_buffer *spa = buffer->buffer;

    if (spa && spa->n_datas > 0) {
        struct spa_data *data = &spa->datas[0];
        struct spa_chunk *chunk = data->chunk;

        if (data->data && chunk && chunk->offset <= data->maxsize) {
            uint32_t offset = chunk->offset;
            uint32_t available_bytes = data->maxsize - offset;
            uint32_t bytes = chunk->size;

            if (bytes > available_bytes)
                bytes = available_bytes;

            /* interleaved stereo float32: 2 samples per frame */
            uint32_t frame_bytes = 2u * (uint32_t)sizeof(float);
            uint32_t frames = bytes / frame_bytes;

            const float *samples =
                (const float *)((const uint8_t *)data->data + offset);

            uint32_t w = atomic_load_explicit(
                &write_pos, memory_order_relaxed
            );
            uint32_t r = atomic_load_explicit(
                &read_pos, memory_order_acquire
            );

            uint32_t free_slots = RING_SIZE - (uint32_t)(w - r);

            uint32_t accepted =
                frames < free_slots ? frames : free_slots;

            for (uint32_t i = 0; i < accepted; ++i) {
                float left = samples[i * 2u];
                float right = samples[i * 2u + 1u];
                float mono = (left + right) * 0.5f;

                ring[w & RING_MASK] =
                    isfinite(mono) ? mono : 0.0f;

                ++w;
            }

            if (accepted < frames) {
                atomic_fetch_add_explicit(
                    &dropped_samples,
                    (uint64_t)(frames - accepted),
                    memory_order_relaxed
                );
            }

            atomic_store_explicit(
                &write_pos, w, memory_order_release
            );
        }
    }

    pw_stream_queue_buffer(current_stream, buffer);
}

static const struct pw_stream_events events = {
    PW_VERSION_STREAM_EVENTS,
    .state_changed = on_state_changed,
    .process = on_process
};

static void *run_loop(void *arg) {
    struct pw_main_loop *current_loop =
        (struct pw_main_loop *)arg;

    pw_main_loop_run(current_loop);
    return NULL;
}

static void cleanup(void) {
    atomic_store(&state, AV_STOPPING);

    if (loop)
        pw_main_loop_quit(loop);

    if (thread_created) {
        pthread_join(thread, NULL);
        thread_created = 0;
    }

    if (stream) {
        pw_stream_destroy(stream);
        stream = NULL;
    }

    if (loop) {
        pw_main_loop_destroy(loop);
        loop = NULL;
    }

    if (pw_initialized) {
        pw_deinit();
        pw_initialized = 0;
    }

    started = 0;
    atomic_store(&state, AV_STOPPED);
}

int av_start(void) {
    if (started)
        return 0;

    atomic_store(&write_pos, 0);
    atomic_store(&read_pos, 0);
    atomic_store(&dropped_samples, 0);
    atomic_store(&state, AV_CONNECTING);

    pw_init(NULL, NULL);
    pw_initialized = 1;

    loop = pw_main_loop_new(NULL);
    if (!loop) {
        cleanup();
        return -1;
    }

    struct pw_properties *props = pw_properties_new(
        PW_KEY_MEDIA_TYPE, "Audio",
        PW_KEY_MEDIA_CATEGORY, "Capture",
        PW_KEY_MEDIA_ROLE, "Music",
        NULL
    );

    if (!props) {
        cleanup();
        return -2;
    }

    stream = pw_stream_new_simple(
        pw_main_loop_get_loop(loop),
        "audio-visualizer",
        props,
        &events,
        NULL
    );

    if (!stream) {
        /* the stream constuctor owns prop on success
           on failure release the properties explicity */
        pw_properties_free(props);
        cleanup();
        return -3;
    }

    struct spa_audio_info_raw info = SPA_AUDIO_INFO_RAW_INIT(
        .format = SPA_AUDIO_FORMAT_F32,
        .rate = 48000,
        .channels = 2,
        .position = {
            SPA_AUDIO_CHANNEL_FL,
            SPA_AUDIO_CHANNEL_FR
        }
    );

    uint8_t storage[1024];
    struct spa_pod_builder builder =
        SPA_POD_BUILDER_INIT(storage, sizeof(storage));

    const struct spa_pod *params[1];

    params[0] = spa_format_audio_raw_build(
        &builder, SPA_PARAM_EnumFormat, &info
    );

    if (!params[0]) {
        cleanup();
        return -4;
    }

    int result = pw_stream_connect(
        stream,
        PW_DIRECTION_INPUT,
        PW_ID_ANY,
        PW_STREAM_FLAG_AUTOCONNECT |
        PW_STREAM_FLAG_MAP_BUFFERS |
        PW_STREAM_FLAG_RT_PROCESS,
        params,
        1
    );

    if (result < 0) {
        cleanup();
        return -5;
    }

    if (pthread_create(&thread, NULL, run_loop, loop) != 0) {
        cleanup();
        return -6;
    }

    thread_created = 1;
    started = 1;
    return 0;
}

int av_read(float *output, int capacity) {
    if (!output || capacity <= 0)
        return -1;

    if (!started)
        return -1;

    uint32_t r = atomic_load_explicit(
        &read_pos, memory_order_relaxed
    );
    uint32_t w = atomic_load_explicit(
        &write_pos, memory_order_acquire
    );

    uint32_t available = w - r;
    uint32_t requested = (uint32_t)capacity;
    uint32_t count =
        available < requested ? available : requested;

    for (uint32_t i = 0; i < count; ++i)
        output[i] = ring[(r + i) & RING_MASK];

    atomic_store_explicit(
        &read_pos, r + count, memory_order_release
    );

    return (int)count;
}

int av_status(void) {
    return atomic_load(&state);
}

uint64_t av_dropped(void) {
    return atomic_load(&dropped_samples);
}

void av_stop(void) {
    if (!started && !thread_created && !stream && !loop &&
        !pw_initialized) {
        atomic_store(&state, AV_STOPPED);
        return;
    }

    cleanup();
}
