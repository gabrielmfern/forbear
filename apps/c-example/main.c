#include "../../c-api/forbear.h"

static const uint8_t inter_ttf[] = {
#embed "../../Inter.ttf"
};

static void render(void *data) {
    (void)data;

    fb_Node_Opening_Data root = fb_open_element(FB_STYLE(
        .width         = { .kind = FB_SIZING_KIND_GROW, .grow = 1.0f },
        .height        = { .kind = FB_SIZING_KIND_GROW, .grow = 1.0f },
        .background    = { .kind = FB_BACKGROUND_KIND_COLOR, .color = { 28 / 255.0f, 31 / 255.0f, 35 / 255.0f, 1.0f } },
        .color         = { 174 / 255.0f, 184 / 255.0f, 196 / 255.0f, 1.0f },
        .font_size     = 14.0f,
        .padding       = { { 16.0f, 16.0f }, { 16.0f, 16.0f } },
        .text_wrapping = FB_TEXT_WRAPPING_CHARACTER,
        .direction     = FB_DIRECTION_VERTICAL,
    ), "root");
    fb_text("forbear", "title");
    fb_close_element(root);

    fb_layout();
    fb_draw((fb_Vector4){ 0.0f, 0.0f, 0.0f, 1.0f });
    fb_prepare_for_next_frame();
}

int main() {
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
