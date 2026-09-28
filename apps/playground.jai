#import "Basic";
#import "GL";
#import,file "../forbear.jai";

main :: () {
    wayland_backend: Wayland_Backend;
    init_wayland_backend(*wayland_backend);

    wayland_window: Wayland_Window;
    init_wayland_window(*wayland_backend.connection, *wayland_window, 800, 600);

    while wayland_window.running {
        event, data, something := next_wayland_event(*wayland_backend.connection);
        if something {
            update_wayland_window(*wayland_backend.connection, *wayland_window, event, data);
            update_wayland_connection(*wayland_backend.connection, event, data);
        }

        element(Style.{ });

        glViewport(0, 0, xx wayland_window.width, xx wayland_window.height);
        glEnable(GL_SCISSOR_TEST);
        glScissor(0, 0, xx (wayland_window.width / 2), xx wayland_window.height);
        glClearColor(1, 0, 1, 1);
        glClear(GL_COLOR_BUFFER_BIT);

        glFinish();

        reset_temporary_storage();
    }
}
