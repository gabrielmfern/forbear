MEMORY_DEBUGGING :: false;

BUILD_FLAGS :: "+forbear";

#import "Basic"()(MEMORY_DEBUGGER = MEMORY_DEBUGGING);
#import "File";
#import "Flat_Pool";
#import "GL";
#import "forbear";

Fps_Monitor :: () {
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
} @component

Counter :: () {
    // This gives us back a pointer to the counter's value. Since no initial value
    // is defined, the function just zeroes out the given type.
    //
    // State is stored in a 16MB static buffer with no heap allocations.
    counter := state(s64);

    // `text` defines a node with glyphs inside of it. It inherits style from its parent.
    text("PLUS (+): increases the counter by one");
    text("MINUS (-): decreases the counter by one");
    if on_key_down(.PLUS) {
        // Since this is immediate mode, there's no need for callbacks/event handlers,
        // we can simply check for the key being down through an if-statement.
        counter.* += 1;
    } else if on_key_down(.MINUS) {
        counter.* -= 1;
    }

    text("LEFT CLICK in the button: increases the counter by one");
    text("RIGHT CLICK in the button: decreases the counter by one");
    element(Style.{
        background = color(rgb(44, 49, 56)),
        color = rgb(230, 234, 239),
        border_width = all(1),
        border_color = rgb(66, 73, 82),
        border_radius = 6,
        padding = in_line(block(8), 16),
        margin = block(8),
    }, #code {
        node := get_node();
        if is_mouse_inside() {
            node.style.background = color(rgb(56, 62, 71));
            if is_mouse_held(.LEFT) || is_mouse_held(.RIGHT) {
                node.style.background = color(rgb(34, 38, 44));
            }
        }

        // The children of an element are defined through passing
        // around Code by the `#code` directive.
        text("Click me");

        if on_click(.LEFT) {
            counter.* += 1;
        } else if on_click(.RIGHT) {
            counter.* -= 1;
        }
    });

    text(Style.{font_size = 32}, sprint("Count: %", counter.*));
} @component
  // The `@component` is handled by a compiler plugin that's defined in the
  // `forbear.jai` as well. It goes through all calls of functions with this
  // annotation and wraps them in a `scope(#code ...)` which makes these handle
  // state properly.

App :: () {
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
        Fps_Monitor();
        Counter();
    });
} @component

main :: () {
    backend: Backend;
    window: Window;
    init_backend(*backend);
    init_window(*backend, *window, 800, 600, "quick start");

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

        App();

        layout();
        draw(rgb(0.0, 0.0, 0.0));

        reset_temporary_storage();
        if MEMORY_DEBUGGING {
            memory_visualizer_per_frame_update();
        }
        reset(*frame_pool);
    }
}
