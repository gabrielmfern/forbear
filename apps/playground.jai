MEMORY_DEBUGGING :: false;

BUILD_FLAGS :: "+forbear";

#import "Basic"()(MEMORY_DEBUGGER = MEMORY_DEBUGGING);
#import "File";
#import "Flat_Pool";
#import "GL";
#import "forbear";

main :: () {
    backend: Backend;
    window: Window;
    init_backend(*backend);
    init_window(*backend, *window, 800, 600, "playground");

    inter := #run create_font(read_entire_file(tprint("%Inter.ttf", #filepath)));

    forbear: Forbear;
    init_forbear(*forbear, *window, *backend, Base_Style.{
        font = *inter,
        color = rgb(255, 255, 255),
    });
    init_font(*inter);

    frame_pool: Flat_Pool;
    frame_allocator: Allocator;
    frame_allocator.data = *frame_pool;
    frame_allocator.proc = flat_pool_allocator_proc;

    while window.running {
        push_allocator(frame_allocator);
        prepare_frame();

        #if OS == .LINUX {
            while true {
                event := next_event(*backend.connection, !can_draw(window));
                if !event.something {
                    break;
                }
                update_backend(*backend, event);
                update_window(*backend, *window, event);
            }
        } else #if OS == .MACOS || OS == .WINDOWS {
            update_backend(*backend);
            update_window(*backend, *window);
        }

        element(Style.{
            width = grow(),
            height = grow(),
            background = color(rgb(28, 31, 35)),
            color = rgb(174, 184, 196),
            font_size = 14,
            padding = all(16),
            text_wrapping = .CHARACTER,
            direction = .VERTICAL,
        }, #code {
            frames := state(cast(float64)0.0);
            fps := state(cast(float64)0.0);
            last := state(cast(float64)0.0);

            frames.* += 1;
            now := seconds_since_init();
            if now - last.* >= 1 {
                fps.* = frames.*;
                frames.* = 0;
                last.* = now;
            }

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
                        text(tprint("%", fps.*));
                    });
                });
            });

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

            input := state([..]u8);

            frame_input := get_text_input();
            if frame_input.count > 0 {
                print("frame_input: %\n", frame_input);
                array_add(input, ..(cast([] u8) frame_input));
                print("input: %\n", to_string(input.data, input.count));
            }
            text(sprint("this was the input text until now: '%'", to_string(input.data, input.count)));

            for key: window.keys_held {
                string_key := sprint("%", key);
                text(string_key, manual_key = string_key);
            }

            for label: string.["a", "b"] {
                element(Style.{}, manual_key = label, #code {
                    count := state(0);
                    if on_click() {
                        count.* += 1;
                    }
                    text(tprint("% %", label, count.*));
                });
            }
        });

        layout();
        draw(rgb(0.0, 0.0, 0.0));

        reset_temporary_storage();
        if MEMORY_DEBUGGING {
            memory_visualizer_per_frame_update();
        }
        reset(*frame_pool);
    }
}
