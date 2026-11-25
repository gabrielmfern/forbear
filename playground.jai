MEMORY_DEBUGGING :: false;

BUILD_FLAGS :: "-output_path .build +Iprof -modules";

#import "Basic"()(MEMORY_DEBUGGER = MEMORY_DEBUGGING);
#import "File";
#import "GL";
#import "forbear";

Fps_Monitor :: () {
    frames := state(float64);
    fps := state(float64);
    last := state(float64);

    frames.* += 1;
    now := seconds_since_init();
    if now - last.* >= 1 {
        fps.* = frames.*;
        frames.* = 0;
        last.* = now;
    }

    element(Style.{ width = grow(), y_justification = .CENTER }, #code {
        element(Style.{ font_size = 32 }, #code {
            text("forbear");
        });
        element(Style.{ width = grow() });
        element(Style.{
            background = color(rgb(239, 239, 239)),
            text_wrapping = .NONE,
            min_width = 152,
            padding = all(8),
            direction = .VERTICAL,
        }, #code {
            element(Style.{ width = grow() }, #code {
                text("FPS:");
                element(Style.{ width = grow() });
                text("%", fps.*);
            });
        });
    });
}

SAM_QUOTE :: "I know. It's all wrong. By rights we shouldn't ";

render :: (data: *void) {
    push_frame_allocator();
    defer prepare_for_next_frame();

    element(Style.{
        width = grow(),
        height = grow(),
        background = color(rgb(255, 255, 255)),
        color = rgb(0, 0, 0),
        font_size = 16,
        padding = all(8),
        text_wrapping = .CHARACTER,
        direction = .VERTICAL,
    }, #code {
        input := state([..]u8);

        scope(use_scrolling());
        scope(Fps_Monitor());
        element(Style.{
            background = color(rgb(255, 0, 0)),
            width = fixed(200),
            height = fixed(200)
        }, #code {
            node := get_node();
            if is_mouse_held() && is_mouse_inside() {
                node.style.background = color(rgb(0, 0, 0));
            }
            if is_key_held(.SHIFT_LEFT) {
                node.style.background = color(rgb(100, 100, 0));
            }
        });

        input_state := scope(use_input_state(
            initial_value = SAM_QUOTE,
            initial_cursor = SAM_QUOTE.count - 1,
            initial_selection_anchor = 0
        ));
        scope(Input(Style.{ width = fixed(500), text_wrapping = .WORD, height = fixed(200) }, input_state));
    });

    layout();
    draw(rgb(1.0, 1.0, 1.0));

    reset_temporary_storage();
    #if MEMORY_DEBUGGING then memory_visualizer_per_frame_update();
    #if #exists(__Iprof) then context._Iprof.update(true);
}

main :: () {
    backend: Backend;
    window: Window;
    init_backend(*backend);
    init_window(*backend, *window, 800, 600, "playground");

    inter := #run create_font(read_entire_file(tprint("%Inter.ttf", #filepath)));

    forbear: Forbear;
    frame_arena: Frame_Arena;
    init_forbear(*forbear, *frame_arena, *backend, *window, Base_Style.{
        font = *inter,
        color = rgb(0, 0, 0),
        language = .ENGLISH,
        text_direction = .LEFT_TO_RIGHT,
    });
    init_font(*inter);

    #if OS == .WINDOWS || OS == .MACOS {
        backend.render = render;
    }

    while window.running {
        push_frame_allocator();

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
        } else #if OS == .WINDOWS {
            update_backend(*backend);
        }

        render(null);
    }
}
