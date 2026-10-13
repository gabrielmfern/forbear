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

    fps := 0;
    frames := 0;
    last := seconds_since_init();
    previous := last;

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

        frames += 1;
        now := seconds_since_init();
        if now - last >= 1 {
            fps = frames;
            frames = 0;
            last = now;
        }

        element(Style.{
            width = grow(),
            height = grow(),
            background = color(rgb(28, 31, 35)),
            color = rgb(174, 184, 196),
            font_size = 14,
            padding = all(16),
            direction = .VERTICAL,
        }, #code {
            element(Style.{ width = grow(), y_justification = .CENTER }, #code {
                element(Style.{ font_size = 28, color = rgb(255, 255, 255) }, #code {
                    text("forbear");
                });
                element(Style.{ width = grow() });
                element(Style.{
                    background = color(rgb(17, 19, 22)),
                    text_wrapping = .NONE,
                    min_width = 152,
                    padding = all(8),
                    color = rgb(184, 163, 106),
                    direction = .VERTICAL,
                }, #code {
                    element(Style.{ width = grow() }, #code {
                        text("FPS:");
                        element(Style.{ width = grow() });
                        text(tprint("%", fps));
                    });
                });
            });

            for key: window.keys_held {
                string_key := tprint("%", key);
                text(string_key, manual_key = string_key);
            }

            element(Style.{ 
                background = color(rgb(255, 0, 0)), 
                width = fixed(200), 
                height = fixed(200) 
            }, #code {
                node := get_node();
                if is_mouse_held() && is_mouse_inside() {
                    node.style.background = color(rgb(255, 255, 255));
                }
                if is_key_held(.SHIFT_LEFT) {
                    node.style.background = color(rgb(100, 100, 0));
                }
            });
        });

        layout();
        draw_and_reset_node_tree(rgb(0.0, 0.0, 0.0));

        reset_temporary_storage();
        if MEMORY_DEBUGGING {
            memory_visualizer_per_frame_update();
        }
    }
}
