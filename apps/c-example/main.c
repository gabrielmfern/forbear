#include "../../c-api/forbear.h"
#include <time.h>

typedef struct timespec timespec;
timespec start;
double seconds_since_start(void) {
    timespec now;
    timespec_get(&now, TIME_UTC);
    return (double)(now.tv_sec - start.tv_sec) + (now.tv_nsec - start.tv_nsec) / 1e9;
}

void Fps_Monitor(void) {
    double *frames = FB_STATE(double);
    double *fps    = FB_STATE(double);
    double *last   = FB_STATE(double);
    *frames += 1;
    double now = seconds_since_start();
    if (now - *last >= 1) {
        *fps = *frames;
        *frames = 0;
        *last = now;
    }

    FB_ELEMENT(.width = fb_grow(1.0f), .y_justification = FB_ALIGNMENT_CENTER) {
        FB_ELEMENT(.font_size = 28, .color = fb_rgb(255.0f, 255.0f, 255.0f)) {
            FB_TEXT("forbear");
        }

        FB_ELEMENT(.width = fb_grow(1.0f));

        FB_ELEMENT(
            .background = fb_color(fb_rgb(17.0f, 19.0f, 22.0f)),
            .text_wrapping = FB_TEXT_WRAPPING_NONE,
            .min_width = 152.0f,
            .padding = fb_all_sides(8.0f),
            .color = fb_rgb(184.0f, 163.0f, 106.0f),
            .direction = FB_DIRECTION_VERTICAL,
        ) {
            FB_ELEMENT(
            ) {
                FB_TEXT("FPS:");
                FB_ELEMENT(.width = fb_grow(1.0f));
                FB_TEXT("%f", *fps);
            }
        }
    }
}

void render(void *data) {
    (void)data;

    FB_ELEMENT(
        .width         = fb_grow(1.0f),
        .height        = fb_grow(1.0f),
        .background    = fb_color(fb_rgb(28.0f, 31.0f, 35.0f)),
        .color         = fb_rgb(174.0f, 184.0f, 196.0f),
        .font_size     = 14.0f,
        .padding       = fb_all_sides(16.0f),
        .text_wrapping = FB_TEXT_WRAPPING_CHARACTER,
        .direction     = FB_DIRECTION_VERTICAL,
    ) {
        FB_SCOPE Fps_Monitor();

        FB_ELEMENT(
            .background = fb_color(fb_rgb(255.0f, 0.0f, 0.0f)),
            .width      = fb_fixed(200),
            .height     = fb_fixed(200)
        ) {
            fb_Node *node = fb_get_node(-1);
            if (fb_is_mouse_held(FB_MOUSE_BUTTON_LEFT) && fb_is_mouse_inside()) {
                node->style.background = fb_color(fb_rgb(255.0f, 255.0f, 255.0f));
            }
            if (fb_is_key_held(FB_KEY_SHIFT_LEFT)) {
                node->style.background = fb_color(fb_rgb(100.0f, 100.0f, 0.0f));
            }
        }
    }

    fb_layout();
    fb_draw((fb_Vector4){ 0.0f, 0.0f, 0.0f, 1.0f });
    fb_prepare_for_next_frame();
}

const uint8_t inter_ttf[] = {
    #embed "../../Inter.ttf"
};
int main() {
    timespec_get(&start, TIME_UTC);
    fb_Backend backend;
    fb_init_backend(&backend);
    fb_Window window;
    fb_init_window(&backend, &window, 800, 600, "C example", FB_FLOAT64_NAN, FB_FLOAT64_NAN, FB_FLOAT64_NAN, FB_FLOAT64_NAN);

    fb_Font inter = fb_create_font((fb_String){ sizeof(inter_ttf), (uint8_t *)inter_ttf });

    fb_Forbear forbear;
    fb_init_forbear(&forbear, &backend, &window, FB_BASE_STYLE(
        .font           = &inter,
        .color          = { 1.0f, 1.0f, 1.0f, 1.0f },
        .language       = FB_LANGUAGE_ENGLISH,
        .text_direction = FB_TEXT_DIRECTION_LEFT_TO_RIGHT,
    ));
    fb_init_font(&inter);

#if defined(_WIN32) || defined(__APPLE__)
    backend.render = render;
#endif

    while (window.running) {
        #if defined(_WIN32)
            fb_update_backend(&backend);
        #elif defined(__APPLE__)
            fb_update_backend(&backend);
            fb_update_window(&backend, &window);
        #elif defined(__linux__)
            while (true) {
                event := fb_next_event(&backend.connection, !fb_can_draw(window));
                if (!event.something) {
                    break;
                }
                update_backend(&backend, event);
                update_window(&backend, &window, event);
            }
        #endif

        render(0);
    }

    return 0;
}
