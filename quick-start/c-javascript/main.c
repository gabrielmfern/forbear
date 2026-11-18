#include "forbear/forbear.h"

// Built from src/index.tsx by `npm run build`.
const fb_u8 index_js[] = {
    #embed "dist/index.js"
};

const fb_u8 inter_ttf[] = {
    #embed "Inter.ttf"
};

void render(void *data) {
    fb_render_with_javascript_adapter(data);
    fb_layout();
    fb_draw((fb_Vector4){ 0, 0, 0, 1 });
    fb_prepare_for_next_frame();
}

int main(void) {
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

    fb_Javascript_Adapter *adapter = fb_create_javascript_adapter((fb_String){ sizeof(index_js), (fb_u8 *)index_js }, "index.js");

#if defined(_WIN32) || defined(__APPLE__)
    backend.render      = render;
    backend.render_data = adapter;
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

        render(adapter);
    }

    return 0;
}
