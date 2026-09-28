#import "Basic";
#import "GL";
#import,file "../forbear.jai";

main :: () {
    wayland_egl_backend: Wayland_EGL_Backend;
    init_wayland_egl_backend(*wayland_egl_backend);

    wayland_egl_window: Wayland_EGL_Window;
    init_wayland_window(*wayland_egl_backend.connection, *wayland_egl_window, 800, 600);

    init_forbear(wayland_egl_backend);

    while wayland_egl_window.running {
        event, data, something := next_wayland_event(*wayland_egl_backend.connection);
        if something {
            update_wayland_egl_window(*wayland_egl_backend.connection, *wayland_egl_window, event, data);
            update_wayland_connection(*wayland_egl_backend.connection, event, data);
        }

        element(Style.{ });

        glViewport(0, 0, xx wayland_egl_window.width, xx wayland_egl_window.height);
        glEnable(GL_SCISSOR_TEST);
        glScissor(0, 0, xx (wayland_egl_window.width / 2), xx wayland_egl_window.height);
        glClearColor(1, 0, 1, 1);
        glClear(GL_COLOR_BUFFER_BIT);

        glFinish();

        reset_temporary_storage();
    }
}
