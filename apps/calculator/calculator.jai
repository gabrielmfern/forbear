MEMORY_DEBUGGING :: false;
HOT_RELOADING :: true;

#import "Basic"()(MEMORY_DEBUGGER = MEMORY_DEBUGGING);
Math :: #import "Math";
#import "File";
#import "File_Utilities";
#import "System";
#import "POSIX";
#import "String";
#import "Flat_Pool";
#import "GL";
#import,file "../../forbear.jai";

BUILD_FLAGS :: "+forbear";

#if OS == .MACOS {
    #import "Objective_C";
}

Operator :: enum {
    NONE; ADD; SUBTRACT; MULTIPLY; DIVIDE;
};
Token :: struct {
    Kind :: enum {
        NUMBER; OPERATOR;
    };

    kind: Kind;
    union {
        number: float64;
        op: Operator;
    }
};
tokens_equal :: (a: Token, b: Token) -> bool {
    if a.kind != b.kind {
        return false;
    }
    if a.kind == .NUMBER {
        return a.number == b.number;
    } else {
        return a.op == b.op;
    }
}
operator == :: tokens_equal;
ADD :: Token.{ kind = .OPERATOR, op = .ADD };
SUBTRACT :: Token.{ kind = .OPERATOR, op = .SUBTRACT };
MULTIPLY :: Token.{ kind = .OPERATOR, op = .MULTIPLY };
DIVIDE :: Token.{ kind = .OPERATOR, op = .DIVIDE };
Parse_Result :: enum {
    SUCCESS;
    TWO_NUMBERS_IN_A_ROW;
    COULD_NOT_PARSE_FLOAT;
};
parse_expression :: (expression: string, tokens: *[..]Token) -> Parse_Result {
    array_reset_keeping_memory(tokens);
    in_progress: string = ---;
    in_progress.data = expression.data;
    in_progress.count = 1;
    while in_progress.data != expression.data + expression.count {
        trimmed := trim(in_progress);
        if trimmed.count == 0 {
            in_progress.data += 1;
        } else {
            if trimmed == {
                case "+";
                    array_add(tokens, ADD);
                case "-";
                    array_add(tokens, SUBTRACT);
                case "*";
                    array_add(tokens, MULTIPLY);
                case "/";
                    array_add(tokens, DIVIDE);
                case;
                    // I have to keep accumulating in progress until the next is either an operator, or it's a space. The
                    // number might continue on after this is hit.
                    while in_progress.data + in_progress.count - 1 < expression.data + expression.count - 1 {
                        next_character := (in_progress.data + in_progress.count).*;
                        if is_any(next_character, "+-*/ ") {
                            break;
                        } else {
                            in_progress.count += 1;
                        }
                    }
                    trimmed = trim(in_progress);

                    // it must be a number at this point, so we assume so
                    number, success := string_to_float(trimmed);
                    if success {
                        if tokens.count > 0 && tokens.*[tokens.count - 1].kind == .NUMBER {
                            return .TWO_NUMBERS_IN_A_ROW;
                        }
                        array_add(tokens, Token.{ kind = .NUMBER, number = number });
                    } else {
                        return .COULD_NOT_PARSE_FLOAT;
                    }
            }
            in_progress.data += in_progress.count;
            in_progress.count = 1;
        }
    }
    return .SUCCESS;
}
parse_expression_should_handle_basic_expression :: () {
    tokens: [..]Token;
    expression := "5 + 10 - 12 / 4 * 19";
    result := parse_expression(expression, *tokens);
    assert(result == .SUCCESS);
    assert(tokens[0] == Token.{kind=.NUMBER,number=5});
    assert(tokens[1] == ADD);
    assert(tokens[2] == Token.{kind=.NUMBER,number=10});
    assert(tokens[3] == SUBTRACT);
    assert(tokens[4] == Token.{kind=.NUMBER,number=12});
    assert(tokens[5] == DIVIDE);
    assert(tokens[6] == Token.{kind=.NUMBER,number=4});
    assert(tokens[7] == MULTIPLY);
    assert(tokens[8] == Token.{kind=.NUMBER,number=19});
} @test

isnan :: Math.isnan;
FLOAT64_NAN :: Math.FLOAT64_NAN;
U64_MAX :: Math.U64_MAX;

//
// ===== program styles =====
//
#add_context inter: Font;
WIDTH :: 360;
HEIGHT :: 512;
BASE :: 16;
LARGE :: 32;
BG :: #run rgb(28, 31, 35);
BG_SECONDARY :: #run rgb(17, 19, 22);
ERROR :: #run rgb(232, 91, 91);
TRANSPARENT :: #run rgba(1.0, 1.0, 1.0, 0.0);

Button :: (body: Code) -> bool #expand {
    element(Style.{
        background = color(BG_SECONDARY),
        padding = block(10.0, 10.0),
        font_size = BASE,
        border_width = 1.0,
        border_color =
        border_radius = 4.0,
    }, #code {
        #insert body;
    });
} @component

App :: () {
    window := context.forbear.window;
    viewport := get_viewport_size();

    element(Style.{
        width = grow(),
        height = grow(),
        direction = .VERTICAL,
        text_wrapping = .NONE,
    }, #code {
        expression := state([..]u8);
        tokens := state([..]Token);
        parse_result := state(Parse_Result);

        input_index := element(Style.{
            border_width = bottom(2.0),
            background = color(BG_SECONDARY),
            padding = in_line(block(20), 15),
            y_justification = .CENTER,
            font_size = LARGE,
            width = fixed(viewport.x),
        }, #code {
            cursor_index := state(s64, 0);

            // there are also interemediate steps, like typing in a number that's not an integer through the dots "."
            //
            // since we're not really using any complicated utf8, but rather only ASCII input as there are only numbers
            // and operators, we can simply remove by index as all characters are only going to be one byte.
            text_input := get_text_input();
            if text_input.count > 0 {
                for character: text_input {
                    if is_digit(character) || is_any(character, "+-*/ .") {
                        array_insert_at(expression, character, cursor_index.*);
                        cursor_index.* += 1;
                    } else {
                        log("ignoring input character %, since it's not in the ones we defined as supporting", character);
                    }
                }
            }
            previous := max(cursor_index.* - 1, 0);
            next := min(cursor_index.* + 1, expression.count);
            by_word := is_key_held(.ALT_LEFT) || is_key_held(.ALT_RIGHT);
            #if OS == .LINUX {
                by_word = by_word || is_key_held(.CONTROL_LEFT) || is_key_held(.CONTROL_RIGHT);
            }
            previous_word_boundary :: (text: *[]u8, cursor: s64) -> s64 {
                c := cursor;
                while c > 0 && !is_digit(text.*[c - 1]) {
                    c -= 1;
                }
                while c > 0 && is_digit(text.*[c - 1]) {
                    c -= 1;
                }
                return c;
            }
            next_word_boundary :: (text: *[]u8, cursor: s64) -> s64 {
                c := cursor;
                while c < text.count && !is_digit(text.*[c]) {
                    c += 1;
                }
                while c < text.count && is_digit(text.*[c]) {
                    c += 1;
                }
                return c;
            }
            if by_word {
                previous = previous_word_boundary(expression, cursor_index.*);
                next = next_word_boundary(expression, cursor_index.*);
            }
            #if OS == .MACOS {
                if is_key_held(.SUPER_LEFT) || is_key_held(.SUPER_RIGHT) {
                    previous = previous_word_boundary(expression, 0);
                    next = next_word_boundary(expression, expression.count);
                }
            }
            removal_start, removal_end := cursor_index.*;
            if on_key_down(.BACKSPACE, true) {
                removal_start = previous;
            } else if on_key_down(.DELETE, true) {
                removal_end = next;
            } else if on_key_down(.ARROW_LEFT, true) {
                cursor_index.* = previous;
            } else if on_key_down(.ARROW_RIGHT, true) {
                cursor_index.* = next;
            } else if on_key_down(.HOME) {
                cursor_index.* = 0;
            } else if on_key_down(.END) {
                cursor_index.* = expression.count;
            }

            removed := removal_end - removal_start;
            if removed > 0 {
                for i: removal_start..expression.count - removed - 1 {
                    expression.*[i] = expression.*[i + removed];
                }
                expression.count -= removed;
                cursor_index.* = min(cursor_index.*, removal_start);
            }

            if removed > 0 || text_input.count > 0 {
                parse_result.* = parse_expression(to_string(expression.data, expression.count), tokens);
            }

            expression_index := text(to_string(expression.data, expression.count));

            expression_node := get_node(expression_index);
            expression_glyphs := expression_node.glyphs;
            font_units_to_pixel := get_font_units_to_pixel(*context.inter, LARGE);

            cursor_position: Vector2;
            if expression.count > 0 {
                if cursor_index.* == expression.count {
                    cursor_position = (expression_glyphs.array[expression.count - 1].position + expression_glyphs.array[expression.count - 1].advance) * font_units_to_pixel;
                } else {
                    cursor_position = expression_glyphs.array[cursor_index.*].position * font_units_to_pixel;
                }
            }
            input := get_node();
            cursor_position.x += input.style.padding.x.x + input.style.border_width.x.x;
            cursor_position.y += input.style.padding.y.x + input.style.border_width.y.x;

            // cursor
            element(Style.{
                placement = relative(cursor_position),
                background = color(rgb(255, 255, 255)),
                width = fixed(1.0),
                height = fixed(expression_glyphs.line_height * font_units_to_pixel),
            });

            {
                //
                // === computing and showing the results of the typed out expression ===
                //
                compute :: (left: float64, op: Operator, right: float64) -> float64 {
                    assert(op != .NONE);
                    if op == {
                        case .ADD;
                            return left + right;
                        case .SUBTRACT;
                            return left - right;
                        case .MULTIPLY;
                            return left * right;
                        case .DIVIDE;
                            return left / right;
                    }
                    log_error("looks like we added a new opreator, but didn't actually handle it");
                    return left;
                }

                value_left: float64 = FLOAT64_NAN;
                op := Operator.NONE;
                value_right: float64 = FLOAT64_NAN;
                for token: tokens.* {
                    if isnan(value_left) {
                        if token.kind == .NUMBER {
                            value_left = token.number;
                        } else {
                            // we take left to be an implicit zero when the user just types in an operator
                            value_left = 0;
                            op = token.op;
                        }
                    } else if op == .NONE {
                        assert(token.kind == .OPERATOR);
                        op = token.op;
                    } else if isnan(value_right) {
                        if token.kind == .NUMBER {
                            value_right = token.number;
                        } else {
                            op = token.op;
                        }
                        value_left = compute(value_left, op, value_right);
                        op = .NONE;
                        value_right = FLOAT64_NAN;
                    }
                }
                if !isnan(value_left) && op != .NONE && !isnan(value_right) {
                    value_left = compute(value_left, op, value_right);
                }

                input_measurement, defined := get_measurement();

                if defined {
                    element(Style.{
                        background = color(BG_SECONDARY),
                        padding = all(5.0),
                        font_size = BASE,
                    }, #code {
                        text_index := text(sprint("= %", ifx isnan(value_left) then 0.0 else value_left));
                        text_node := get_node(text_index);
                        result_node := get_node();
                        result_node.style.placement = relative(Vector2.{ viewport.x - text_node.size.x - 15.0, input_measurement.size.y - text_node.size.y - 20.0 });
                    });
                }
            }
        });

        if parse_result.* != .SUCCESS && expression.count > 0 {
            input := get_node(input_index);
            input.style.border_radius = 4.0;
            input.style.border_width = all(1.0);
            input.style.border_color = ERROR;

            message := "";
            if parse_result.* == {
                case .TWO_NUMBERS_IN_A_ROW;
                    message = "Two numbers in a row can't be calculated";
                case .COULD_NOT_PARSE_FLOAT;
                    message = "Could not parse what should be a number";
            }
            text(Style.{ color = ERROR, margin = in_line(5), font_size = 12 }, message);
        }
    });
} @component

#program_export
render :: () {
    App();

    if on_key_down(.ESCAPE) {
        context.forbear.window.running = false;
    }
}

main :: () {
    backend: Backend;
    window: Window;
    init_backend(*backend);
    init_window(*backend, *window, WIDTH, HEIGHT, "playground");
    #if OS == .LINUX {
        send_wayland_message(*backend.connection, window.xdg_toplevel_id, Xdg_Toplevel_Request_Set_Max_Size.{ width = WIDTH, height = HEIGHT });
        send_wayland_message(*backend.connection, window.xdg_toplevel_id, Xdg_Toplevel_Request_Set_Min_Size.{ width = WIDTH, height = HEIGHT });
    } else #if OS == .MACOS {
        set_size: (*void, Selector, NSSize) #c_call = xx objc_msgSend;
        set_size(window.ns_window, selector("setContentMinSize:"), .{ width = WIDTH, height = HEIGHT });
        set_size(window.ns_window, selector("setContentMaxSize:"), .{ width = WIDTH, height = HEIGHT });
    }

    context.inter = #run create_font(read_entire_file(tprint("%../Inter.ttf", #filepath)));

    forbear: Forbear;
    init_forbear(*forbear, *window, *backend, Base_Style.{
        font = *context.inter,
        color = rgb(230, 232, 235),
        font_size = 16,
    });

    init_font(*context.inter);

    frame_pool: Flat_Pool;
    frame_allocator: Allocator;
    frame_allocator.data = *frame_pool;
    frame_allocator.proc = flat_pool_allocator_proc;

    #if HOT_RELOADING {
        library_path := sprint("%calculator_library.so", path_strip_filename(get_path_of_running_executable()));
        library_modtime: Apollo_Time;
        library_version := 0;
        loaded_render: #type ();
    }

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

        #if HOT_RELOADING {
            modtime, _, exists := file_modtime_and_size(library_path);
            if exists && modtime != library_modtime {
                copy_path := tprint("/tmp/calculator_library_%.so", library_version);
                library_version += 1;
                if copy_file(library_path, copy_path) {
                    library := dlopen(temp_c_string(copy_path), RTLD_NOW);
                    if library {
                        symbol := dlsym(library, "render");
                        if symbol {
                            loaded_render = cast(#type ()) symbol;
                            library_modtime = modtime;
                        }
                    } else {
                        log_error("could not load %: %", copy_path, to_string(dlerror()));
                        exit(-1);
                    }
                }
            }
            if loaded_render {
                loaded_render();
            }
        } else {
            render();
        }

        layout();
        draw(BG);

        reset_temporary_storage();

        memory_visualizer_per_frame_update();
        reset(*frame_pool);
    }
}

#if HOT_RELOADING {
    #run {
        #import "Compiler";
        #import "Hash";
        build_options := get_build_options();
        if build_options.output_type == .EXECUTABLE {
            w := compiler_create_workspace("calculator_library");
            options := get_build_options(w);
            copy_commonly_propagated_fields(get_build_options(), *options);
            options.output_type = .DYNAMIC_LIBRARY;
            options.output_executable_name = "calculator_library";
            set_build_options(options, w);

            plugin := get_plugin();
            plugin.workspace = w;
            {
                compiler_begin_intercept(w);
                defer compiler_end_intercept(w);
                add_build_file(#file, w);

                host_hash: u64;
                while true {
                    message := compiler_wait_for_message();
                    plugin.message(plugin, message);
                    if message.kind == .FILE {
                        file := cast(*Message_File) message;
                        if !file.from_a_string && file.fully_pathed_filename != #file {
                            contents := read_entire_file(file.fully_pathed_filename);
                            host_hash += fnv1a_hash(contents.data, contents.count);
                        }
                    } else if message.kind == .TYPECHECKED {
                        typechecked := cast(*Message_Typechecked) message;
                        for typechecked.procedure_bodies if it.expression.header.name == "main" {
                            lines := split(read_entire_file(#file), "\n");
                            main_hash := FNV_64_OFFSET_BIAS;
                            block := it.expression.block;
                            for line: array_view(lines, block.l0 - 1, block.l1 - block.l0 + 1) {
                                main_hash = fnv1a_hash(line.data, line.count, main_hash);
                            }
                            host_hash += main_hash;
                        }
                    } else if message.kind == .COMPLETE {
                        break;
                    }
                }
            }

            hash_path := tprint("%/calculator_host_hash", options.intermediate_path);
            previous_hash := read_entire_file(hash_path, log_errors = false);
            if previous_hash == tprint("%", host_hash) {
                set_build_options_dc(.{do_output = false});
            } else {
                write_entire_file(hash_path, tprint("%", host_hash));
            }
        }
    }
}
