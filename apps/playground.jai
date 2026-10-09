MEMORY_DEBUGGING :: false;

#import "Basic"()(MEMORY_DEBUGGER = MEMORY_DEBUGGING);
#import "File";
#import "GL";
#import,file "../forbear.jai";

INTER_TTF :: #run read_entire_file(tprint("%Inter.ttf", #filepath));

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
        color = rgb(255, 255, 255),
    });

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

        element(Style.{ 
            padding = block(in_line(50), 30),
            background = color(rgb(255, 0, 255)),
            y_justification = .CENTER,
        }, #code {
            text("root node");
            element(Style.{
                width = fixed(60),
                height = fixed(75),
                margin = left(50),
                background = color(rgb(0, 0, 255)),
                x_justification = .CENTER,
                y_justification = .CENTER,
            }, #code {
                text("first node");
            });
            element(Style.{
                width = fixed(60),
                height = fixed(75),
                background = color(rgb(0, 255, 0)),
                x_justification = .CENTER,
                y_justification = .CENTER,
            }, #code {
                text("second node");
            });
            element(Style.{
                width = fixed(60),
                height = fixed(75),
                margin = right(50),
                background = color(rgb(255, 0, 0)),
                x_justification = .CENTER,
                y_justification = .CENTER,
            }, #code {
                text("third node");
            });
            text("hello lisa");
        });

        layout();
        draw_and_reset_node_tree(rgb(0.0, 0.0, 0.0));

        reset_temporary_storage();
        if MEMORY_DEBUGGING {
            memory_visualizer_per_frame_update();
        }
    }
}
