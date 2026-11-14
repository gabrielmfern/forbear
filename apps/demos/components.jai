BUILD_FLAGS :: "+forbear";

#import "Basic";
#import "File";
#import "Flat_Pool";
#import "GL";
#import "Random";
#import "forbear";

BACKGROUND :: #run hex("#1C1F23");
PANEL :: #run hex("#111316");
UI :: #run hex("#2C333B");
UI_HOVER :: #run hex("#38404A");
FOREGROUND :: #run hex("#AEB8C4");
MUTED :: #run hex("#6E7A87");
BRIGHT :: #run hex("#FFFFFF");
YELLOW :: #run hex("#B8A36A");

use_delta_time :: () -> float64 {
    last_frame_time := state(float64);
    now := seconds_since_init();
    delta_time := now - last_frame_time.*;
    last_frame_time.* = now;
    return delta_time;
} @hook

Frame_Monitor :: () {
    frames := state(float64);
    total := state(float64);
    last := state(float64);
    fps := state(float64);
    average := state(float64);

    delta_time := use_delta_time();

    frames.* += 1;
    now := seconds_since_init();
    total.* += delta_time;
    if now - last.* >= 0.5 {
        fps.* = frames.* / (now - last.*);
        average.* = total.* / frames.* * 1000;
        frames.* = 0;
        total.* = 0;
        last.* = now;
    }

    element(Style.{
        background = color(PANEL),
        border_radius = 6,
        padding = in_line(block(8), 12),
        color = YELLOW,
        text_wrapping = .NONE,
        min_width = 150,
        direction = .VERTICAL,
    }, #code {
        element(Style.{ width = grow() }, #code {
            text("FPS:");
            element(Style.{ width = grow() });
            text(tprint("%", cast(s64) fps.*));
        });
        element(Style.{ width = grow() }, #code {
            text("frame:");
            element(Style.{ width = grow() });
            text(tprint("% ms", formatFloat(average.*, trailing_width = 2)));
        });
    });
} @component

Task :: struct {
    text: [40]u8;
    count: s64;
    done: bool;
}
task :: (text: string) -> Task {
    task: Task;
    task.count = min(text.count, task.text.count);
    task.done = false;
    memcpy(task.text.data, text.data, task.count);
    return task;
}
Task_List :: () {
    tasks := state([..]Task);
    seeded := state(false);
    if !seeded.* {
        array_add(tasks, task("write log entry 004"));
        array_add(tasks, task("record a demo"));
        array_add(tasks, task("C bindings"));
        array_add(tasks, task("take over the world or nothing"));
        seeded.* = true;
    }

    draft := state([40]u8);
    draft_count := state(s64);
    caret_time := state(float);

    delta_time := use_delta_time();

    caret_time.* += xx delta_time;
    for byte: cast([]u8) get_text_input() {
        if byte >= 32 && draft_count.* < draft.count {
            draft.*[draft_count.*] = byte;
            draft_count.* += 1;
            caret_time.* = 0;
        }
    }
    if on_key_down(.BACKSPACE, on_repeat = true) && draft_count.* > 0 {
        draft_count.* -= 1;
        caret_time.* = 0;
    }
    if on_key_down(.ENTER) && draft_count.* > 0 {
        task: Task;
        task.count = draft_count.*;
        memcpy(task.text.data, draft.data, task.count);
        array_add(tasks, task);
        draft_count.* = 0;
    }

    done := 0;
    for tasks.* if it.done done += 1;

    element(Style.{
        width = fixed(380),
        height = grow(),
        background = color(PANEL),
        border_radius = 10,
        padding = all(16),
        direction = .VERTICAL,
    }, #code {
        element(Style.{ width = grow(), y_justification = .CENTER, margin = bottom(12) }, #code {
            text(Style.{ font_size = 20, color = BRIGHT }, "tasks");
            element(Style.{ width = grow() });
            text(Style.{ color = MUTED }, tprint("% of % done", done, tasks.count));
        });

        element(Style.{
            width = grow(),
            background = color(BACKGROUND),
            border_width = all(1),
            border_color = YELLOW,
            border_radius = 6,
            text_wrapping = .NONE,
            padding = in_line(block(10), 12),
            margin = bottom(12),
            y_justification = .CENTER,
        }, #code {
            caret_visible := cast(s64) (caret_time.* * 2) % 2 == 0;
            if draft_count.* > 0 {
                text(Style.{ color = BRIGHT }, to_string(draft.data, draft_count.*));
            }
            element(Style.{
                width = fixed(2),
                height = fixed(18),
                background = color(ifx caret_visible then BRIGHT else BACKGROUND),
                margin = left(1),
            });
            if draft_count.* == 0 {
                text(Style.{ color = MUTED }, "type a task and press enter");
            }
        });

        removed := -1;
        for * task, index: tasks.* {
            element(Style.{
                width = grow(),
                border_radius = 6,
                padding = in_line(block(8), 10),
                margin = bottom(4),
                y_justification = .CENTER,
            }, manual_key = tprint("task-%", index), #code {
                node := get_node();
                if is_mouse_inside() {
                    node.style.background = color(UI);
                    if is_mouse_held(.LEFT) node.style.background = color(UI_HOVER);
                }
                if on_click(.LEFT) task.done = !task.done;
                if on_click(.RIGHT) removed = index;

                element(Style.{
                    width = fixed(16),
                    height = fixed(16),
                    border_radius = 4,
                    border_width = all(1),
                    border_color = ifx task.done then YELLOW else MUTED,
                    background = color(ifx task.done then YELLOW else PANEL),
                    margin = right(10),
                });
                text(Style.{ color = ifx task.done then MUTED else FOREGROUND }, to_string(task.text.data, task.count));
            });
        }
        if removed != -1 array_ordered_remove_by_index(tasks, removed);

        element(Style.{ height = grow() });
        text(Style.{ color = MUTED }, "click to complete, right click to remove");
    });
} @component

Switch :: (index: s64, shuffle: bool) {
    on := state(bool);
    knob := state(float);
    pending := state(bool);
    wait := state(float);
    delta_time := use_delta_time();

    if on_key_down(.TAB) {
        pending.* = true;
        wait.* = (index / 8 + index % 8) * 0.03;
    }
    if shuffle && random_get() % 2 == 0 {
        on.* = !on.*;
    }
    if pending.* {
        wait.* -= xx delta_time;
        if wait.* <= 0 {
            on.* = !on.*;
            pending.* = false;
        }
    }

    element(Style.{
        width = grow(),
        background = color(BACKGROUND),
        border_radius = 8,
        border_width = all(1),
        border_color = BACKGROUND,
        padding = all(12),
        margin = all(4),
        x_justification = .CENTER,
    }, #code {
        node := get_node();
        if is_mouse_inside() {
            node.style.border_color = MUTED;
            if is_mouse_held(.LEFT) node.style.background = color(UI);
        }
        if on_click() on.* = !on.*;

        target := ifx on.* then 1.0 else 0.0;
        knob.* += (target - knob.*) * min(1.0, (cast(float) delta_time) * 14);

        element(Style.{
            width = fixed(44),
            height = fixed(24),
            border_radius = 12,
            background = color(UI * (1 - knob.*) + YELLOW * knob.*),
            padding = all(3),
        }, #code {
            element(Style.{
                width = fixed(18),
                height = fixed(18),
                border_radius = 9,
                background = color(BRIGHT),
                translate = .{ 20 * knob.*, 0 },
            });
        });
    });
} @component

App :: () {
    glow := state(float);
    shuffling := state(bool);
    shuffle_timer := state(float);
    delta_time := use_delta_time();
    if on_key_down(.TAB) glow.* = 1;
    glow.* = max(0.0, glow.* - cast(float) delta_time);

    shuffle := false;
    if shuffling.* {
        shuffle_timer.* += xx delta_time;
        if shuffle_timer.* >= 1 {
            shuffle_timer.* -= 1;
            shuffle = true;
        }
    }

    element(Style.{
        width = grow(),
        height = grow(),
        background = color(BACKGROUND),
        color = FOREGROUND,
        font_size = 14,
        padding = all(20),
        direction = .VERTICAL,
    }, #code {
        element(Style.{ width = grow(), y_justification = .CENTER, margin = bottom(20) }, #code {
            element(Style.{ direction = .VERTICAL }, #code {
                text(Style.{ font_size = 28, color = BRIGHT }, "forbear");
                text(Style.{ color = MUTED }, "state, components and events, all rebuilt every frame");
            });
            element(Style.{ width = grow() });
            Frame_Monitor();
        });

        element(Style.{ width = grow(), height = grow() }, #code {
            Task_List();
            element(Style.{
                width = grow(),
                height = grow(),
                background = color(PANEL),
                border_radius = 10,
                padding = all(16),
                margin = left(20),
                direction = .VERTICAL,
            }, #code {
                element(Style.{ width = grow(), y_justification = .CENTER, margin = bottom(8) }, #code {
                    text(Style.{ font_size = 20, color = BRIGHT }, "64 switches");
                    element(Style.{ width = grow() });
                    text(Style.{ color = MUTED }, "each one is a component with its own state");
                    element(Style.{
                        background = color(ifx shuffling.* then YELLOW else UI),
                        color = ifx shuffling.* then PANEL else FOREGROUND,
                        border_radius = 6,
                        padding = in_line(block(6), 10),
                        margin = left(12),
                    }, #code {
                        if is_mouse_inside() && !shuffling.* {
                            get_node().style.background = color(UI_HOVER);
                        }
                        if on_click() {
                            shuffling.* = !shuffling.*;
                            shuffle_timer.* = 0;
                        }
                        text(ifx shuffling.* then "stop" else "shuffle every second");
                    });
                });
                for row: 0..7 {
                    element(Style.{ width = grow() }, manual_key = tprint("row-%", row), #code {
                        for column: 0..7 {
                            index := row * 8 + column;
                            scope(tprint("switch-%", index), #code {
                                Switch(index, shuffle);
                            });
                        }
                    });
                }
                element(Style.{ height = grow() });
                text(Style.{ color = MUTED * (1 - glow.*) + YELLOW * glow.* }, "click one, or press TAB to flip all of them");
            });
        });
    });
} @component

frame_pool: Flat_Pool;
render :: (data: *void) {
    defer prepare_for_next_frame();

    App();

    layout();
    draw(rgb(0.0, 0.0, 0.0));

    reset_temporary_storage();
    reset(*frame_pool);
}

main :: () {
    backend: Backend;
    window: Window;
    init_backend(*backend);
    init_window(*backend, *window, 1200, 720, "forbear: state and components");

    inter := #run create_font(read_entire_file(tprint("%../../Inter.ttf", #filepath)));

    forbear: Forbear;
    init_forbear(*forbear, *window, *backend, Base_Style.{
        font = *inter,
        color = rgb(255, 255, 255),
        language = .ENGLISH,
        text_direction = .LEFT_TO_RIGHT,
    });
    init_font(*inter);

    frame_allocator: Allocator;
    frame_allocator.data = *frame_pool;
    frame_allocator.proc = flat_pool_allocator_proc;
    #if OS == .WINDOWS || OS == .MACOS {
        backend.render = render;
    }

    while window.running {
        push_allocator(frame_allocator);

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
