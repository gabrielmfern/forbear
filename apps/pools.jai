#import "Basic";
#import "File";
#import "Flat_Pool";
#import "GL";
#import "String";
POSIX :: #import "POSIX";
#import,file "../forbear.jai";


main :: () {
    backend: Backend;
    window: Window;
    init_backend(*backend);
    init_window(*backend, *window, 900, 600, "pools");

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
        } else #if OS == .MACOS {
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
            direction = .VERTICAL,
        }, #code {
            show_b := state(true);
            swapped := state(false);

            slots_in_use := 0;
            for forbear.pool_slots {
                if it.used {
                    slots_in_use += 1;
                }
            }
            resident_mb := 0;
            #if OS == .LINUX {
                statm: [128]u8;
                fd := POSIX.open("/proc/self/statm", POSIX.O_RDONLY);
                read_count := POSIX.read(fd, statm.data, statm.count);
                POSIX.close(fd);
                parts := split(string.{ data = statm.data, count = read_count }, " ");
                resident_pages := string_to_int(parts[1]);
                resident_mb = resident_pages * 4096 / (1024 * 1024);
            }
            text(tprint("frame %   slots in use: %   resident memory: % MB", context.forbear.frame, slots_in_use, resident_mb));

            element(Style.{ padding = all(8) }, #code {
                element(Style.{ background = color(rgb(60, 66, 74)), padding = all(8) }, #code {
                    if on_click() {
                        show_b.* = !show_b.*;
                    }
                    text(ifx show_b.* then "hide B" else "show B");
                });
                element(Style.{ width = fixed(8) });
                element(Style.{ background = color(rgb(60, 66, 74)), padding = all(8) }, #code {
                    if on_click() {
                        swapped.* = !swapped.*;
                    }
                    text("swap A and B");
                });
            });

            labels := string.["A", "B"];
            if swapped.* {
                labels = string.["B", "A"];
            }
            for label: labels {
                if label == "A" || show_b.* {
                    element(Style.{
                        width = grow(),
                        background = color(rgb(17, 19, 22)),
                        padding = all(12),
                        direction = .VERTICAL,
                    }, manual_key = label, #code {
                        evens := state([..]s64);
                        evens.allocator = node_pool();
                        odds := state([..]s64);
                        odds.allocator = node_pool();

                        broken := 0;
                        for evens.* {
                            if it != it_index * 2 {
                                broken += 1;
                            }
                        }
                        for odds.* {
                            if it != it_index * 2 + 1 {
                                broken += 1;
                            }
                        }

                        slot := get_node().pool_slot;
                        pool := *forbear.pool_slots[slot].pool;
                        text(tprint(
                            "%: slot %   % evens   % odds   % KB in pool   %",
                            label, slot, evens.count, odds.count,
                            (pool.current_point - pool.memory_base) / 1024,
                            ifx broken > 0 then tprint("CORRUPT (% wrong)", broken) else "ok",
                        ));

                        element(Style.{ padding = all(4) }, #code {
                            for amount: s64.[1, 1000, 1000000] {
                                element(Style.{ background = color(rgb(60, 66, 74)), padding = all(8) }, manual_key = tprint("%", amount), #code {
                                    if on_click() {
                                        for 1..amount {
                                            array_add(evens, evens.count * 2);
                                            array_add(odds, odds.count * 2 + 1);
                                        }
                                    }
                                    text(tprint("add %", amount));
                                });
                                element(Style.{ width = fixed(8) }, manual_key = tprint("gap %", amount));
                            }
                        });
                    });
                }
            }
        });

        layout();
        draw(rgb(0.0, 0.0, 0.0));

        reset_temporary_storage();
        reset(*frame_pool);
    }
}
