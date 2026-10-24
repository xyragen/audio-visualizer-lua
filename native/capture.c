
#include <pipewire/pipewire.h>
#include <spa/param/audio/format-utils.h>
#include <spa/param/param.h>
#include <spa/utils/result.h>
#include <stdatomic.h>
#include <stdint.h>
#include <stdlib.h>
#include <pthread.h>
#include <math.h>

#define RING_SIZE 262144
#define RING_MASK (RING_SIZE - 1)

static float ring[RING_SIZE];
static _Atomic uint32_t write_pos;
static _Atomic uint32_t read_pos;
static _Atomic int state;
static struct pw_main_loop *loop;
static struct pw_stream *stream;
static pthread_t thread;

static void on_state_changed(void *userdata, enum pw_stream_state old, enum pw_stream_state current, const char *error)
{
    if (current == PW_STREAM_STATE_STREAMING)
        atomic_store(&state, 2);
    else if (current == PW_STREAM_STATE_ERROR)
        atomic_store(&state, -1);
    else
        atomic_store(&state, 1);
}

static void on_process(void *userdata)
{
    struct pw_buffer *buffer = pw_stream_dequeue_buffer(stream);

    if (!buffer)
        return;

    struct spa_buffer *spa = buffer->buffer;

    if (spa->n_datas > 0) {
        struct spa_data *data = &spa->datas[0];

        if (data->data && data->chunk) {
            float *samples = (float *)((uint8_t *)data->data + data->chunk->offset);
            uint32_t frames = data->chunk->size / (sizeof(float) * 2);
            uint32_t w = atomic_load_explicit(&write_pos, memory_order_relaxed);
            uint32_t r = atomic_load_explicit(&read_pos, memory_order_acquire);

            for (uint32_t i = 0; i < frames; i++) {
                if ((uint32_t)(w - r) >= RING_SIZE)
                    break;

                float left = samples[i * 2];
                float right = samples[i * 2 + 1];
                float mono = (left + right) * 0.5f;

                ring[w & RING_MASK] = isfinite(mono) ? mono : 0.0f;
                w++;
            }

            atomic_store_explicit(&write_pos, w, memory_order_release);
        }
    }

    pw_stream_queue_buffer(stream, buffer);
}

static const struct pw_stream_events events = {
    PW_VERSION_STREAM_EVENTS,
    .state_changed = on_state_changed,
    .process = on_process
};

static void *run_loop(void *arg)
{
    pw_main_loop_run(loop);
    return NULL;
}

int av_start(void)
{
    pw_init(NULL, NULL);

    atomic_store(&write_pos, 0);
    atomic_store(&read_pos, 0);
    atomic_store(&state, 1);

    loop = pw_main_loop_new(NULL);

    if (!loop)
        return -1;

    struct pw_properties *props = pw_properties_new(
        PW_KEY_MEDIA_TYPE, "Audio",
        PW_KEY_MEDIA_CATEGORY, "Capture",
        PW_KEY_MEDIA_ROLE, "Music",
        PW_KEY_STREAM_CAPTURE_SINK, "true",
        NULL
    );

    stream = pw_stream_new_simple(
        pw_main_loop_get_loop(loop),
        "audio-visualizer",
        props,
        &events,
        NULL
    );

    if (!stream)
        return -2;

    struct spa_audio_info_raw info = SPA_AUDIO_INFO_RAW_INIT(
        .format = SPA_AUDIO_FORMAT_F32,
        .rate = 48000,
        .channels = 2,
        .position = {SPA_AUDIO_CHANNEL_FL, SPA_AUDIO_CHANNEL_FR}
    );

    uint8_t storage[1024];
    struct spa_pod_builder builder = SPA_POD_BUILDER_INIT(storage, sizeof(storage));
    const struct spa_pod *params[1];

    params[0] = spa_format_audio_raw_build(
        &builder,
        SPA_PARAM_EnumFormat,
        &info
    );

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

    if (result < 0)
        return -3;

    if (pthread_create(&thread, NULL, run_loop, NULL) != 0)
        return -4;

    return 0;
}

int av_read(float *output, int capacity)
{
    if (!output || capacity <= 0)
        return 0;

    uint32_t r = atomic_load_explicit(&read_pos, memory_order_relaxed);
    uint32_t w = atomic_load_explicit(&write_pos, memory_order_acquire);
    uint32_t available = w - r;
    uint32_t count = available < (uint32_t)capacity ? available : (uint32_t)capacity;

    for (uint32_t i = 0; i < count; i++)
        output[i] = ring[(r + i) & RING_MASK];

    atomic_store_explicit(&read_pos, r + count, memory_order_release);

    return (int)count;
}

int av_status(void)
{
    return atomic_load(&state);
}

void av_stop(void)
{
    if (loop)
        pw_main_loop_quit(loop);

    pthread_join(thread, NULL);

    if (stream)
        pw_stream_destroy(stream);

    if (loop)
        pw_main_loop_destroy(loop);

    stream = NULL;
    loop = NULL;

    pw_deinit();
    atomic_store(&state, 0);
}
