#include "forbear/forbear.h"
#include <stdio.h>
#include <time.h>

struct timespec start;
double seconds_since_start(void) {
    struct timespec now;
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
        *fps    = *frames;
        *frames = 0;
        *last   = now;
    }

    FB_ELEMENT(.width = fb_grow(1.0f), .y_justification = FB_ALIGNMENT_CENTER) {
        FB_ELEMENT(.font_size = 28, .color = fb_rgb(255, 255, 255)) {
            FB_TEXT("forbear");
        }
        FB_ELEMENT(.width = fb_grow(1.0f));
        FB_ELEMENT(
            .background    = fb_color(fb_rgb(17, 19, 22)),
            .text_wrapping = FB_TEXT_WRAPPING_NONE,
            .min_width     = 152,
            .padding       = fb_all_sides(8),
            .color         = fb_rgb(184, 163, 106),
            .direction     = FB_DIRECTION_VERTICAL,
        ) {
            FB_ELEMENT(.width = fb_grow(1.0f)) {
                FB_TEXT("FPS:");
                FB_ELEMENT(.width = fb_grow(1.0f));
                char fps_text[32];
                snprintf(fps_text, sizeof(fps_text), "%.0f", *fps);
                FB_TEXT(fps_text);
            }
        }
    }
}

void Counter(void) {
    // State is stored in a 16MB static buffer with no heap allocations.
    fb_s64 *counter = FB_STATE(fb_s64);

    FB_TEXT("PLUS (+): increases the counter by one");
    FB_TEXT("MINUS (-): decreases the counter by one");
    // Since this is immediate mode, there's no need for callbacks/event handlers,
    // we can simply check for the key being down through an if-statement.
    if (fb_on_key_down(FB_KEY_PLUS, false)) {
        *counter += 1;
    } else if (fb_on_key_down(FB_KEY_MINUS, false)) {
        *counter -= 1;
    }

    FB_TEXT("LEFT CLICK in the button: increases the counter by one");
    FB_TEXT("RIGHT CLICK in the button: decreases the counter by one");
    FB_ELEMENT(
        .background    = fb_color(fb_rgb(44, 49, 56)),
        .color         = fb_rgb(230, 234, 239),
        .border_width  = fb_all_sides(1),
        .border_color  = fb_rgb(66, 73, 82),
        .border_radius = 6,
        .padding       = fb_with_in_line_sides(fb_block_sides(8), 16),
        .margin        = fb_block_sides(8),
    ) {
        fb_Node *node = fb_get_node(-1);
        if (fb_is_mouse_inside()) {
            node->style.background = fb_color(fb_rgb(56, 62, 71));
            if (fb_is_mouse_held(FB_MOUSE_BUTTON_LEFT) || fb_is_mouse_held(FB_MOUSE_BUTTON_RIGHT)) {
                node->style.background = fb_color(fb_rgb(34, 38, 44));
            }
        }

        // The children of an element go inside the block that follows FB_ELEMENT.
        FB_TEXT("Click me");

        if (fb_on_click(FB_MOUSE_BUTTON_LEFT, true, false)) {
            *counter += 1;
        } else if (fb_on_click(FB_MOUSE_BUTTON_RIGHT, true, false)) {
            *counter -= 1;
        }
    }

    char count_text[64];
    snprintf(count_text, sizeof(count_text), "Count: %lld", (long long)*counter);
    FB_TEXT(count_text, .font_size = 32);
}

void render(void *data) {
    (void)data;

    FB_ELEMENT(
        .width         = fb_grow(1.0f),
        .height        = fb_grow(1.0f),
        .background    = fb_color(fb_rgb(28, 31, 35)),
        .color         = fb_rgb(174, 184, 196),
        .font_size     = 14,
        .padding       = fb_all_sides(16),
        .text_wrapping = FB_TEXT_WRAPPING_CHARACTER,
        .direction     = FB_DIRECTION_VERTICAL,
    ) {
        // FB_SCOPE gives each component its own state.
        FB_SCOPE Fps_Monitor();
        FB_SCOPE Counter();
    }

    fb_layout();
    fb_draw((fb_Vector4){ 0, 0, 0, 1 });
    fb_prepare_for_next_frame();
}

const fb_u8 inter_ttf[] = {
    #embed "Inter.ttf"
};

int main(void) {
    timespec_get(&start, TIME_UTC);

    fb_Backend backend;
    fb_init_backend(&backend);
    fb_Window window;
    fb_init_window(&backend, &window, 800, 600, "quick start", FB_FLOAT64_NAN, FB_FLOAT64_NAN, FB_FLOAT64_NAN, FB_FLOAT64_NAN);

    fb_Font inter = fb_create_font((fb_String){ sizeof(inter_ttf), (fb_u8 *)inter_ttf });

    fb_Forbear forbear;
    fb_init_forbear(&forbear, &backend, &window, FB_BASE_STYLE(
        .font           = &inter,
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
            fb_Wayland_Event event = fb_next_event(&backend.connection, !fb_can_draw(window));
            if (!event.something) {
                break;
            }
            fb_update_backend(&backend, event);
            fb_update_window(&backend, &window, event);
        }
#endif

        render(0);
    }

    return 0;
}
