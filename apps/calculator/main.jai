MEMORY_DEBUGGING :: false;

#import "Basic"()(MEMORY_DEBUGGER = MEMORY_DEBUGGING);
Math :: #import "Math";
#import "File";
#import "String";
#import "Flat_Pool";
#import "GL";
#import "forbear";

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
                    // TODO: handle negative numbers, it should just parse to a negative
                    // number instead of a `-` operator token
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
HEIGHT :: 120;
BG :: #run hex("#111316");
SUCCESS :: #run hex("#6FDD6F40");
ERROR :: #run hex("#E85B5B");
TRANSPARENT :: #run hex("#01010100");

Button :: (body: Code) -> bool #expand {
    element(Style.{
        background = color(BG),
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

    expression := state([..]u8);
    tokens := state([..]Token);
    parse_result := state(Parse_Result);
    result := state(float64);

    DIGITS_SIZE :: 32;
    element(Style.{
        background = color(BG),
        padding = in_line(block(20), 15),
        direction = .VERTICAL,
        text_wrapping = .NONE,
        y_justification = .CENTER,
        font_size = DIGITS_SIZE,
        width = fixed(viewport.x),
        height = fixed(viewport.y),
    }, #code {
        input := get_node();
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
        // should_paste := false;
        // #if OS == .MACOS {
        //     should_paste = (is_key_held(.SUPER_LEFT) || is_key_held(.SUPER_RIGHT)) && on_key_down(.V);
        // } else #if OS == .LINUX {
        //     should_paste = is_key_held(.CONTROL_LEFT) && on_key_down(.V);
        // }
        // if should_paste {
        //     clipboard_text := get_clipboard_text();
        //     if clipboard_text.count > 0 {
        //         if array.count >= array.allocated {
        //             reserve := max(8, 2 * array.count);
        //             array_reserve(cast(*Resizable_Array) array, reserve, element_size);
        //         }
        //         array_insert_at(expression, clipboard_text, cursor_index.*);
        //         cursor_index.* += 1;
        //     }
        // }

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

        expression_index := text(to_string(expression.data, expression.count));

        expression_node := get_node(expression_index);
        expression_glyphs := expression_node.glyphs;
        font_units_to_pixel := get_font_units_to_pixel(*context.inter, DIGITS_SIZE);

        cursor_position: Vector2;
        if expression.count > 0 {
            if cursor_index.* == expression.count {
                cursor_position = (expression_glyphs.array[expression.count - 1].position + expression_glyphs.array[expression.count - 1].advance) * font_units_to_pixel;
            } else {
                cursor_position = expression_glyphs.array[cursor_index.*].position * font_units_to_pixel;
            }
        }
        line_height := expression_glyphs.line_height * font_units_to_pixel;
        inner_height := viewport.y - input.style.padding.y.x - input.style.padding.y.y;
        cursor_position.x += input.style.padding.x.x;
        cursor_position.y += input.style.padding.y.x + (inner_height - line_height) / 2;

        // cursor
        element(Style.{
            placement = relative(cursor_position),
            background = color(hex("#FFFFFF")),
            width = fixed(1.0),
            height = fixed(line_height),
        });

        if removed > 0 || text_input.count > 0 {
            parse_result.* = parse_expression(to_string(expression.data, expression.count), tokens);

            if parse_result.* == .SUCCESS {
                Pass :: enum {
                    DIVIDE_MULTIPLY;
                    ADD_SUBTRACT;
                };
                index := 0;
                pass: Pass = .DIVIDE_MULTIPLY;
                while index < tokens.count {
                    left: float64 = FLOAT64_NAN;
                    op: Operator = .NONE;
                    right: float64 = FLOAT64_NAN;
                    operation_size: s64 = 0;
                    while isnan(left) || op == .NONE || isnan(right) {
                        if index >= tokens.count {
                            break;
                        }
                        token := tokens.*[index];
                        if isnan(left) {
                            if token.kind == .NUMBER {
                                left = token.number;
                            } else if token.kind == .OPERATOR {
                                // operation with implicit left number, assumed to be 0
                                left = 0;
                                op = token.op;
                            }
                        } else if op == .NONE {
                            assert(token.kind == .OPERATOR);
                            op = token.op;
                        } else if isnan(right) {
                            if token.kind == .NUMBER {
                                right = token.number;
                                break;
                            } else if token.kind == .OPERATOR {
                                // takes precedence over previous operator. might be confusing?
                                op = token.op;
                            }
                        }
                        index += 1;
                        operation_size += 1;
                    }
                    if !isnan(left) && op != .NONE && !isnan(right) {
                        if pass == .DIVIDE_MULTIPLY && (op == .MULTIPLY || op == .DIVIDE) {
                            if op == .MULTIPLY {
                                tokens.*[index] = Token.{kind = .NUMBER, number = left * right};
                            } else if op == .DIVIDE {
                                tokens.*[index] = Token.{kind = .NUMBER, number = left / right};
                            }
                        } else if pass == .ADD_SUBTRACT && (op == .ADD || op == .SUBTRACT) {
                            if op == .ADD {
                                tokens.*[index] = Token.{kind = .NUMBER, number = left + right};
                            } else if op == .SUBTRACT {
                                tokens.*[index] = Token.{kind = .NUMBER, number = left - right};
                            }
                        }
                        if (pass == .DIVIDE_MULTIPLY && (op == .MULTIPLY || op == .DIVIDE))
                        || (pass == .ADD_SUBTRACT && (op == .ADD || op == .SUBTRACT)) {
                            for j : index-operation_size..tokens.count-operation_size-1{
                                tokens.*[j] = tokens.*[j + operation_size];
                            }
                            tokens.count -= operation_size;
                            index -= operation_size;
                        }
                    }
                    if pass == .DIVIDE_MULTIPLY && index >= tokens.count - 1 {
                        pass = .ADD_SUBTRACT;
                        index = 0;
                    }
                }
                result.* = 0;
                if tokens.count > 0 {
                    number_tokens := 0;
                    for token: tokens.* {
                        if token.kind == .NUMBER {
                            number_tokens += 1;
                            result.* = token.number;
                        }
                    }
                    // the operation should have been resolved to a single number
                    assert(number_tokens == 1 || number_tokens == 0);
                }
            }
        }

        input_measurement, defined := get_measurement();
        if defined {
            element(Style.{
                background = color(BG),
                padding = all(5.0),
                font_size = 12,
            }, #code {
                text_index := text(sprint("= %", result.*));
                text_node := get_node(text_index);
                result_node := get_node();
                result_node.style.placement = relative(Vector2.{
                    viewport.x - text_node.size.x - 15.0,
                    input_measurement.size.y - text_node.size.y - 20.0
                });
            });
        }

        if parse_result.* != .SUCCESS && expression.count > 0 && defined {
            // is this really useful? should we remove this?
            element(Style.{
                font_size = 12,
            }, #code {
                message := "";
                if parse_result.* == {
                    case .TWO_NUMBERS_IN_A_ROW;
                        message = "Two numbers in a row can't be calculated";
                    case .COULD_NOT_PARSE_FLOAT;
                        message = "Could not parse what should be a number";
                }

                text_node := get_node(text(Style.{
                    color = ERROR,
                    margin = in_line(5),
                    font_size = 12
                }, message));

                error_node := get_node();
                error_node.style.placement = relative(Vector2.{
                    0.0,
                    input_measurement.size.y - text_node.size.y - 5
                });
            });
        }
    });

    if on_key_down(.ESCAPE) {
        window.running = false;
    }

    if on_key_down(.ENTER) {
        copy_to_clipboard(tprint("%", result.*));
        window.running = false;
    }
} @component

frame_pool: Flat_Pool;

render :: (data: *void) {
    begin_frame();
    defer end_frame();

    App();

    layout();
    draw(BG);

    reset_temporary_storage();

    memory_visualizer_per_frame_update();
    reset(*frame_pool);
}

main :: () {
    backend: Backend;
    window: Window;
    init_backend(*backend);
    init_window(*backend, *window, WIDTH, HEIGHT, "Calculator");
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
        color = hex("#E6E8EB"),
        font_size = 16,
    });

    init_font(*context.inter);

    frame_allocator: Allocator;
    frame_allocator.data = *frame_pool;
    frame_allocator.proc = flat_pool_allocator_proc;
    backend.render = render;

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
