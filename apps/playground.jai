#import "Basic";
#import "File";
#import "GL";
#import,file "../forbear.jai";

INTER_TTF :: #run read_entire_file(tprint("%Inter.ttf", #filepath));

main :: () {
    backend: Backend;
    window: Window;
    #if OS == .LINUX {
        init_wayland_egl_backend(*wayland_egl_backend);
        init_wayland_egl_window(*wayland_egl_backend.connection, *wayland_egl_window, 800, 600);
    } else #if OS == .MACOS {
        init_macos_gl_backend(*backend);
        init_macos_gl_window(*backend, *window, 800, 600);
    }

    inter: Font;
    init_font(*inter, INTER_TTF);

    forbear: Forbear;
    init_forbear(*forbear, *wayland_egl_backend, Base_Style.{
        font = *inter,
    });

    while window.running {
        #if OS == .LINUX {
            event, data, something := next_wayland_event(*backend.connection);
            if something {
                update_wayland_connection(*backend.connection, event, data);
                update_wayland_egl_window(*backend.connection, *window, event, data);
            }
        } else #if OS == .MACOS {
            update_macos_gl_backend(*backend);
            update_macos_gl_window(*backend, *window);
        }

        element(Style.{ 
            width = fixed(500),
            height = fixed(500),
            background = color(rgb(255, 0, 255)),
            color = rgb(255, 255, 255),
        }, #code {
            text("hello lisa");
        });

        render_and_reset_node_tree(*window, rgb(0.0, 0.0, 0.0));

        reset_temporary_storage();
    }
}
