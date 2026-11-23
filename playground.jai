MEMORY_DEBUGGING :: false;

BUILD_FLAGS :: "-output_path .build +forbear";

#import "Basic"()(MEMORY_DEBUGGER = MEMORY_DEBUGGING);
#import "File";
#import "Flat_Pool";
#import "GL";
#import "forbear";

frame_pool: Flat_Pool;

Fps_Monitor :: () {
    frames   := state(float64);
    fps      := state(float64);
    last     := state(float64);

    frames.* += 1;
    now      := seconds_since_init();
    if now - last.* >= 1 {
        fps.*    = frames.*;
        frames.* = 0;
        last.*   = now;
    }

    element(Style.{ width = grow(), y_justification = .CENTER }, #code {
        element(Style.{ font_size = 28, color = rgb(255, 255, 255) }, #code {
            text("forbear");
        });
        element(Style.{ width = grow() });
        element(Style.{
            background    = color(rgb(17, 19, 22)),
            text_wrapping = .NONE,
            min_width     = 152,
            padding       = all(8),
            color         = rgb(184, 163, 106),
            direction     = .VERTICAL,
        }, #code {
            element(Style.{ width = grow() }, #code {
                text("FPS:");
                element(Style.{ width = grow() });
                text("%", fps.*);
            });
        });
    });
} @component

render :: (data: *void) {
    defer prepare_for_next_frame();

    element(Style.{
        width           = grow(),
        height          = grow(),
        background      = color(rgb(28, 31, 35)),
        color           = rgb(174, 184, 196),
        font_size       = 14,
        padding         = all(16),
        text_wrapping   = .CHARACTER,
        direction       = .VERTICAL,
    }, #code {
        use_scrolling();

        input := state([..]u8);

        Fps_Monitor();

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

        frame_input := get_text_input();
        if frame_input.count > 0 {
            print("frame_input: %\n", frame_input);
            array_add(input, ..(cast([] u8) frame_input));
            print("input: %\n", to_string(input.data, input.count));
        }
        text("this was the input text until now: '%'", to_string(input.data, input.count));

        if on_paste() {
            get_clipboard_text();
            print("pasting, this should happen");
        }

        for key: context.forbear.window.keyboard_state.held {
            if key != 0 {
                string_key := sprint("%", key);
                text(string_key, key = string_key);
            }
        }

        for label: string.["a", "b"] {
            element(Style.{}, key = label, #code {
                count := state(0);
                if on_click() {
                    count.* += 1;
                }
                text("% %", label, count.*);
            });
        }

        text(Style.{ text_wrapping = .WORD }, #string END
Sam: Tá tudo errado. Por direito, a gente nem devia estar aqui. Mas estamos. É tipo nas grandes histórias, Sr. Frodo. Aquelas que realmente importavam. Cheias de escuridão e perigo, eram elas, e às vezes você nem queria saber o final. Porque como o final poderia ser feliz? Como o mundo poderia voltar a ser como era, depois de tanta coisa ruim? Mas no fim, é só uma coisa passageira, essa sombra. Até a escuridão tem que passar. Um novo dia vai chegar. E quando o sol brilhar, vai brilhar mais forte. Essas eram as histórias que ficavam com você. Que significavam alguma coisa. Mesmo que você fosse pequeno demais pra entender o porquê. Mas eu acho, Sr. Frodo, que eu entendo. Eu sei agora. O povo nessas histórias tinha várias chances de voltar atrás, mas não voltava. Porque eles estavam se agarrando a alguma coisa.

Frodo: O que a gente tá se agarrando, Sam?

Sam: Que existe um pouco de bondade nesse mundo, Sr. Frodo. E que vale a pena lutar por ela.
END);
    });

    layout();
    draw(rgb(0.0, 0.0, 0.0));

    reset_temporary_storage();
    if MEMORY_DEBUGGING {
        memory_visualizer_per_frame_update();
    }
    reset(*frame_pool);
}

main :: () {
    backend: Backend;
    window: Window;
    init_backend(*backend);
    init_window(*backend, *window, 800, 600, "playground");

    inter := #run create_font(read_entire_file(tprint("%Inter.ttf", #filepath)));

    forbear: Forbear;
    init_forbear(*forbear, *backend, *window, Base_Style.{
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
