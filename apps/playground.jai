#import "Basic";
#import "File";
#import "GL";
#import,file "../forbear.jai";

INTER_TTF :: #run read_entire_file(tprint("%Inter.ttf", #filepath));

main :: () {
    backend: Backend;
    window: Window;
    #if OS == .LINUX {
        init_wayland_egl_backend(*backend);
        init_wayland_egl_window(*backend.connection, *window, 800, 600, "playground");
    } else #if OS == .MACOS {
        init_macos_gl_backend(*backend);
        init_macos_gl_window(*backend, *window, 800, 600, "playground");
    }

    inter: Font;
    init_font(*inter, INTER_TTF);

    forbear: Forbear;
    init_forbear(*forbear, *backend, Base_Style.{
        font = *inter,
        color = rgb(255, 255, 255),
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
            // width = fixed(500),
            // height = fixed(500),
            padding = block(in_line(50), 30),
            background = color(rgb(255, 0, 255)),
        }, #code {
            element(Style.{
                width = fixed(60),
                height = fixed(75),
                margin = in_line(50),
                background = color(rgb(0, 0, 255)),
            });
            element(Style.{
                width = fixed(60),
                height = fixed(75),
                background = color(rgb(0, 255, 0)),
            });
            element(Style.{
                width = fixed(60),
                height = fixed(75),
                margin = in_line(50),
                background = color(rgb(255, 0, 0)),
            });
            text("hello lisa");
        });

        layout();

        draw_and_reset_node_tree(*window, rgb(0.0, 0.0, 0.0));

        reset_temporary_storage();
    }
}
