#import "Basic";
#import "File";
#import "GL";
#import,file "../forbear.jai";

INTER_TTF :: #run read_entire_file(tprint("%Inter.ttf", #filepath));

main :: () {
    wayland_egl_backend: Wayland_EGL_Backend;
    init_wayland_egl_backend(*wayland_egl_backend);
    wayland_egl_window: Wayland_EGL_Window;
    init_wayland_egl_window(*wayland_egl_backend.connection, *wayland_egl_window, 800, 600);

    inter: Font;
    init_font(*inter, INTER_TTF);

    forbear: Forbear;
    init_forbear(*forbear, *wayland_egl_backend, Base_Style.{
        font = *inter,
    });

    while wayland_egl_window.running {
        event, data, something := next_wayland_event(*wayland_egl_backend.connection);
        if something {
            update_wayland_egl_window(*wayland_egl_backend.connection, *wayland_egl_window, event, data);
            update_wayland_connection(*wayland_egl_backend.connection, event, data);
        }

        element(Style.{ 
            width = fixed(500),
            height = fixed(500),
            background = color(rgb(255, 0, 255)),
            color = rgb(255, 255, 255),
        }, #code {
            text("hello lisa");
        });

        render_and_reset_node_tree(*wayland_egl_window);

        reset_temporary_storage();
    }
}
