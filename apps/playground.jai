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
    frame_sum: float64;
    frame_max: float64;
    average_ms: float64;
    max_ms: float64;

    wave :: (seconds: float, speed: float, phase: float) -> float {
        return (Math.sin(seconds * speed + phase) + 1) / 2;
    }

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
        delta := (now - previous) * 1000;
        previous = now;
        frame_sum += delta;
        frame_max = max(frame_max, delta);
        if now - last >= 1 {
            fps = frames;
            average_ms = frame_sum / frames;
            max_ms = frame_max;
            frames = 0;
            frame_sum = 0;
            frame_max = 0;
            last = now;
        }

        seconds := cast(float) now;
        bars := 8 + cast(int) (40 * wave(seconds, 0.4, 0));
        phase := cast(float) Math.fmod_cycling(now * 2.3, Math.TAU64);

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
                    element(Style.{ width = grow() }, #code {
                        text("avg:");
                        element(Style.{ width = grow() });
                        text(tprint("% ms", formatFloat(average_ms, trailing_width = 1, zero_removal = .NO)));
                    });
                    element(Style.{ width = grow() }, #code {
                        text("max:");
                        element(Style.{ width = grow() });
                        text(tprint("% ms", formatFloat(max_ms, trailing_width = 1, zero_removal = .NO)));
                    });
                });
            });

            element(Style.{ width = grow(), height = grow(), margin = top(16) }, #code {
                element(Style.{
                    width = fixed(96 + 180 * wave(seconds, 1.1, 0)),
                    height = grow(),
                    background = color(rgb(17, 19, 22)),
                    padding = all(8),
                    direction = .VERTICAL,
                    margin = right(16),
                }, #code {
                    for folder: string.["Inbox", "Sent mail", "Drafts and notes", "Everything else"] {
                        element(Style.{
                            width = grow(),
                            background = color(rgb(44, 51, 59)),
                            color = rgb(255, 255, 255),
                            padding = all(8),
                            margin = bottom(8),
                        }, #code {
                            text(folder);
                        });
                    }
                });

                element(Style.{ width = grow(), height = grow(), margin = left(16), direction = .VERTICAL }, #code {
                    element(Style.{ width = grow(), background = color(rgb(17, 19, 22)), padding = all(12) }, #code {
                        text("Every frame, this whole window is laid out from scratch. The sidebar changes its width, so this paragraph has to wrap its words again, the cards below have to share what is left, and every bar has to find its new place. Nothing here is a transform, all of it is layout.");
                    });
                    element(Style.{ width = grow(), margin = top(16) }, #code {
                        for card, index: [2]string.[
                            string.["fit", "A node is as big as its children."],
                            string.["grow", "A node takes a share of the space that is left."],
                            string.["shrink", "A node gives space back when there is not enough."],
                        ] {
                            element(Style.{
                                width = grow(1 + 3 * wave(seconds, 0.9, index * 2.1)),
                                height = grow(),
                                background = color(rgb(44, 51, 59)),
                                padding = all(10),
                                margin = right(ifx index == 2 then 0.0 else 8.0),
                            }, #code {
                                element(Style.{ width = grow(), direction = .VERTICAL }, #code {
                                    element(Style.{ color = rgb(184, 163, 106), font_size = 18 }, #code {
                                        text(card[0]);
                                    });
                                    text(card[1]);
                                });
                            });
                        }
                    });
                    element(Style.{ height = grow() });
                    element(Style.{ margin = top(16), color = rgb(255, 255, 255), direction = .VERTICAL }, #code {
                        element(Style.{}, #code {
                            text(tprint(
                                "height(x) = 61 + 45 · sin(0.35x + %), x from 0 to %",
                                formatFloat(phase, trailing_width = 2, zero_removal = .NO),
                                bars - 1,
                            ));
                        });
                        element(Style.{}, #code {
                            text("... and while all of this layouting is happening, here's the above function graphed");
                        });
                    });
                    element(Style.{
                        width = grow(),
                        height = fixed(106),
                        margin = bottom(top(8), 16),
                        y_justification = .END,
                    }, #code {
                        for index: 0..bars - 1 {
                            element(Style.{
                                width = grow(),
                                height = fixed(61 + 45 * Math.sin(0.35 * index + phase)),
                                background = color(rgb(184, 163, 106)),
                                margin = right(ifx index == bars - 1 then 0.0 else 3.0),
                            });
                        }
                    });
                });
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
