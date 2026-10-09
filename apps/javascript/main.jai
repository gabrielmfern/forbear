#import "Basic";
#import "File";
#import,file "../../forbear.jai"(JAVASCRIPT_ADAPTER = true);

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
        init_backend(*backend);
        init_window(*backend.connection, *window, 800, 600, "playground");
    } else #if OS == .MACOS {
        init_backend(*backend);
        init_window(*backend, *window, 800, 600, "playground");
    }

    inter: Font;
    init_font(*inter, INTER_TTF);

    forbear: Forbear;
    init_forbear(*forbear, *window, *backend, Base_Style.{
        font = *inter,
    });

    javascript_adapter: Javascript_Adapter;
    init_adapter(*javascript_adapter, JAVASCRIPT_SOURCE, "javascript-example");

    while window.running {
        #if OS == .LINUX {
            while true {
                event := next_event(*backend.connection, !can_draw(window));
                if !event.something {
                    break;
                }
                update_backend(*backend, event);
                update_window(*backend, *window, event);
            }
        } else #if OS == .MACOS {
            update_backend(*backend);
            update_window(*backend, *window);
        }

        render_with_adapter(*javascript_adapter);
        layout();
        draw_and_reset_node_tree(rgb(0.0, 0.0, 0.0));
        reset_temporary_storage();
    }
}
