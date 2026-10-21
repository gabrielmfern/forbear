#import "Basic";
#import "File";
#import "Flat_Pool";
#import "GL";
#import,file "../forbear.jai";

inter := #run create_font(read_entire_file(tprint("%Inter.ttf", #filepath)));

counter :: (label: string, tag: u64) {
    before := state(u64);
    if before.* == 0 {
        before.* = tag;
    }
    clicks := state(s64);
    frames := state(s64);
    frames.* += 1;

    element(Style.{ background = color(rgb(60, 66, 74)), padding = all(8) }, #code {
        if on_click() {
            clicks.* += 1;
        }
        text(tprint("%: % clicks", label, clicks.*));
    });

    after := state(u64);
    if after.* == 0 {
        after.* = tag;
    }

    ok := before.* == tag && after.* == tag;
    if !ok {
        log_error("frame %: counter % has state from another scope (before element: %, after element: %, expected %)", context.forbear.frame, label, before.*, after.*, tag);
    }
    text(tprint("    alive for % frames   %", frames.*, ifx ok then "ok" else "WRONG"));
}

main :: () {
    backend: Backend;
    window: Window;
    init_backend(*backend);
    init_window(*backend, *window, 900, 600, "scopes");

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

        scope(#code {
            element(Style.{
                width = grow(),
                height = grow(),
                background = color(rgb(28, 31, 35)),
                color = rgb(174, 184, 196),
                font_size = 14,
                padding = all(16),
                direction = .VERTICAL,
            }, #code {
                show_a := state(true);
                auto_toggle := state(true);
                rotation := state(s64);
                if auto_toggle.* && context.forbear.frame % 120 == 0 {
                    show_a.* = !show_a.*;
                }
                if auto_toggle.* && context.forbear.frame % 90 == 0 {
                    rotation.* += 1;
                }

                text(tprint("frame %   nodes %", context.forbear.frame, context.forbear.node_tree.count));
                element(Style.{ padding = all(8) }, #code {
                    element(Style.{ background = color(rgb(60, 66, 74)), padding = all(8) }, #code {
                        if on_click() {
                            show_a.* = !show_a.*;
                        }
                        text(ifx show_a.* then "hide A" else "show A");
                    });
                    element(Style.{ width = fixed(8) });
                    element(Style.{ background = color(rgb(60, 66, 74)), padding = all(8) }, #code {
                        if on_click() {
                            auto_toggle.* = !auto_toggle.*;
                        }
                        text(ifx auto_toggle.* then "auto toggle A and rotate: on" else "auto toggle A and rotate: off");
                    });
                    element(Style.{ width = fixed(8) });
                    element(Style.{ background = color(rgb(60, 66, 74)), padding = all(8) }, #code {
                        if on_click() {
                            rotation.* += 1;
                        }
                        text("rotate G H I");
                    });
                });

                text("A is conditional; B must keep its clicks and frame count when A disappears.");
                if show_a.* {
                    scope(#code counter("A", 1));
                }
                scope(#code counter("B", 2));

                text("C contains D; both are scopes directly inside a scope.");
                scope(#code {
                    counter("C", 3);
                    scope(#code counter("D", 4));
                });

                text("E and F are sibling scopes inside an element.");
                element(Style.{ padding = all(8), direction = .VERTICAL }, #code {
                    scope(#code counter("E", 5));
                    scope(#code counter("F", 6));
                });

                text("G, H and I are keyed scopes from one loop; rotating must move their clicks with them.");
                labels := string.["G", "H", "I"];
                for 0..labels.count - 1 {
                    index := (it + rotation.*) % labels.count;
                    label := labels[index];
                    scope(label, #code counter(label, cast(u64) (7 + index)));
                }
            });
        });

        layout();
        draw(rgb(0.0, 0.0, 0.0));

        reset_temporary_storage();
        reset(*frame_pool);
    }
}
