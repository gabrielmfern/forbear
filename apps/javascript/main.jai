#import "Basic";
#import "File";
#import,file "../../forbear.jai";
#load "../../adapters/javascript.jai";

#run {
    #import "Process";
    result := run_command("npm", "run", "build", working_directory = #filepath);
    assert(result.type == .EXITED && result.exit_code == 0, "npm run build failed");
}

JAVASCRIPT_SOURCE :: #run read_entire_file(tprint("%dist/index.js", #filepath));
INTER_TTF :: #run read_entire_file(tprint("%../Inter.ttf", #filepath));

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
    });

    javascript_adapter: Javascript_Adapter;
    init_javascript_adapter(*javascript_adapter, JAVASCRIPT_SOURCE, "javascript-example");

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

        render_with_javascript_adapter(*javascript_adapter);
        draw_and_reset_node_tree(*window, rgb(0.0, 0.0, 0.0));
        reset_temporary_storage();
    }
}
