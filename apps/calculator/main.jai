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
} else #if OS == .WINDOWS {
    #import "Windows";
}

Operator :: enum { NONE; ADD; SUBTRACT; MULTIPLY; DIVIDE; };
Token :: struct {
    Kind :: enum { NUMBER; OPERATOR; };
    kind: Kind;
    union { number: float64; op: Operator; }
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
Parse_Result :: enum { SUCCESS; TWO_NUMBERS_IN_A_ROW; COULD_NOT_PARSE_FLOAT; };
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
                    number, success := string_to_float64(trimmed);
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
MIN_WIDTH    :: 225;
MIN_HEIGHT   :: 325;
DIGITS_SIZE  :: 32;
BG           :: #run hex("#0F0F10");
BG_SECONDARY :: #run hex("#19191B");
BG_TERTIARY  :: #run hex("#262628");
BG_HOVER     :: #run hex("#313134");
BG_PRESSED   :: #run hex("#1E1E20");
OP           :: #run hex("#ECECEC");
OP_TEXT      :: #run hex("#19191B");
OP_HOVER     :: #run hex("#FFFFFF");
OP_PRESSED   :: #run hex("#CFCFD2");
ERROR        :: #run hex("#E85B5B");
TRANSPARENT  :: #run hex("#01010100");

Column :: (body: Code) #expand {
    element(Style.{width = grow(), height = grow(), x_justification = .CENTER}, body);
} @component
Row :: (body: Code) #expand {
    element(Style.{width = grow(), height = fixed(64)}, body);
} @component
Button :: (contents: string, is_operator := false) -> clicked: bool {
    clicked := false;
    element(Style.{
        border_radius = 6.0,
        background = color(ifx is_operator then OP else BG_TERTIARY),
        color = ifx is_operator then OP_TEXT else VECTOR4_NAN,
        font_size = 24,
        x_justification = .CENTER,
        y_justification = .CENTER,
        width = fixed(48.0),
        height = fixed(48.0),
    }, #code {
        button := get_node();
        if is_mouse_inside() {
            button.style.background = color(ifx is_operator then OP_HOVER else BG_HOVER);
        }
        clicked = on_click();
        if is_mouse_held() && is_mouse_inside() {
            button.style.background = color(ifx is_operator then OP_PRESSED else BG_PRESSED);
        }
        text(contents);
    });
    return clicked;
} @component

Input_State :: struct {
    contents: [..]u8;
    cursor_index: s64;
}
use_input :: (using input_state: *Input_State, text_node_index: s64, input_character_filter: #type (input: u8) -> bool = null) {
    append :: (using input_state: *Input_State, input: string, input_character_filter: #type (input: u8) -> bool) {
        if input_character_filter != null {
            for character: input {
                if input_character_filter(character) {
                    array_insert_at(*contents, character, cursor_index);
                    cursor_index += 1;
                }
            }
        } else {
            input_bytes: []u8 = ---;
            input_bytes.data = input.data;
            input_bytes.count = input.count;
            array_add(*contents, ..input_bytes);
        }
    }

    text_input := get_text_input();
    if text_input.count > 0 {
        append(input_state, text_input, input_character_filter);
    }

    {
        //
        // === clipboard paste handling ===
        //
        should_paste := false;
        #if OS == .MACOS {
            should_paste = (is_key_held(.SUPER_LEFT) || is_key_held(.SUPER_RIGHT)) && on_key_down(.V);
        } else {
            should_paste = is_key_held(.CONTROL_LEFT) && on_key_down(.V);
        }
        if should_paste {
            clipboard_text := get_clipboard_text();
            if clipboard_text.count > 0 {
                append(input_state, clipboard_text, input_character_filter);
            }
        }
    }

    removed: s64;
    {
        //
        // === keyboard deletion and cursor movement handling ===
        //
        previous := max(input_state.cursor_index - 1, 0); // TODO: we should not remove by just one byte necessarily, since, in unicode one character can be multiple bytes
        next := min(input_state.cursor_index + 1, input_state.contents.count);
        by_word := is_key_held(.ALT_LEFT) || is_key_held(.ALT_RIGHT);
        #if OS == .LINUX || OS == .WINDOWS {
            by_word = by_word || is_key_held(.CONTROL_LEFT) || is_key_held(.CONTROL_RIGHT);
        }
        // TODO: define a word boundary in a more generalized way that makes this actually work for any kind of input
        previous_word_boundary :: (text: *[]u8, cursor: s64) -> s64 {
            c := cursor;
            while c > 0 && !is_digit(text.*[c - 1]) {
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
            previous = previous_word_boundary(*input_state.contents, input_state.cursor_index);
            next = next_word_boundary(*input_state.contents, input_state.cursor_index);
        }
        #if OS == .MACOS {
            if is_key_held(.SUPER_LEFT) || is_key_held(.SUPER_RIGHT) {
                previous = previous_word_boundary(*input_state.contents, 0);
                next = next_word_boundary(*input_state.contents, input_state.contents.count);
            }
        }
        removal_start, removal_end := input_state.cursor_index;
        if on_key_down(.BACKSPACE, true) {
            removal_start = previous;
        } else if on_key_down(.DELETE, true) {
            removal_end = next;
        } else if on_key_down(.ARROW_LEFT, true) {
            input_state.cursor_index = previous;
        } else if on_key_down(.ARROW_RIGHT, true) {
            input_state.cursor_index = next;
        } else if on_key_down(.HOME) {
            input_state.cursor_index = 0;
        } else if on_key_down(.END) {
            input_state.cursor_index = input_state.contents.count;
        }

        removed = removal_end - removal_start;
        if removed > 0 {
            for i: removal_start..input_state.contents.count - removed - 1 {
                input_state.contents[i] = input_state.contents[i + removed];
            }
            input_state.contents.count -= removed;
            input_state.cursor_index = min(input_state.cursor_index, removal_start);
        }
    }

    {
        //
        // === mouse event handling ===
        //
        text_node := get_node(text_node_index);
        text_measurement, defined := get_measurement(text_node_index);
        if defined && (on_mouse_down(.LEFT) || on_mouse_down(.RIGHT)) {
            text_node_glyphs := text_node.glyphs;
            font_units_to_pixel := get_font_units_to_pixel(*context.inter, DIGITS_SIZE);
            line_height := text_node_glyphs.line_height * font_units_to_pixel;

            mouse := get_mouse_position();
            closest_distance: float;
            for text_node_glyphs.array {
                left_edge := text_measurement.position.x + it.position.x * font_units_to_pixel;
                // TOOD: to make this work with mulitple lines, we will need to have the glyphs already wrapped here,
                // but then we will also need to find the closest line, to finally compare the x coordinates
                distance := Math.abs(left_edge - mouse.x);
                if it_index == 0 || distance < closest_distance {
                    closest_distance = distance;
                    cursor_index = it_index;
                }
                if it_index == text_node_glyphs.array.count - 1 {
                    right_edge := left_edge + it.advance.x * font_units_to_pixel;
                    // TOOD: to make this work with mulitple lines, we will need to have the glyphs already wrapped here,
                    // but then we will also need to find the closest line, to finally compare the x coordinates
                    distance := Math.abs(right_edge - mouse.x);
                    if distance < closest_distance {
                        closest_distance = distance;
                        cursor_index = text_node_glyphs.array.count;
                    }
                }
            }
        }
    }
} @hook
Input_Caret :: (
    style: Style,
    using input_state: *Input_State,
    scrolling_offset: float,
    text_node_index: s64
) {
    input_measurement, defined := get_measurement();
    if defined {
        text_node := get_node(text_node_index);
        text_measurement := get_measurement(text_node_index);
        input_glyphs := text_node.glyphs;
        // TODO: should we be taking window scale into account for this conversion?
        font_units_to_pixel := get_font_units_to_pixel(*context.inter, DIGITS_SIZE);

        caret_position: Vector2;
        if contents.count > 0 {
            if cursor_index == contents.count {
                caret_position = (input_glyphs.array[contents.count - 1].position + input_glyphs.array[contents.count - 1].advance) * font_units_to_pixel;
            } else {
                caret_position = input_glyphs.array[cursor_index].position * font_units_to_pixel;
            }
        }
        line_height := input_glyphs.line_height * font_units_to_pixel;
        // TODO: support multi-line inputs, because we're currently only comparing against there being no wrapping in the input
        input := get_node();
        inner_height := input_measurement.size.y - input.style.padding.y.x - input.style.padding.y.y;
        caret_position.x -= scrolling_offset;
        caret_position.x += input.style.padding.x.x;
        caret_position.y += input.style.padding.y.x + (inner_height - line_height) / 2;

        // TODO: while typing, the blinking should reset
        blinking := cast(s64)Math.floor(seconds_since_init() * 2) % 2 != 1;

        element(overwrite(style, Style.{
            placement = relative(caret_position),
            background = ifx blinking then
                color(hex("#FFFFFF"))
            else
                color(TRANSPARENT),
            width = fixed(1.0),
            height = fixed(line_height),
        }));
    }
} @component
// TODO: There's a compiler bug with this somehow, we should report this to Jon. Apparently when this function is defined beside the use_input
// call inline, the compiler throws a warning saying not all control paths are handled, and the function body doesn't seem to run proplery,
// as in not run at all.
number_input_filter :: (input: u8) -> bool {
    // since we're not really using any complicated utf8, but rather only ASCII input as there are only numbers
    // and operators, we can simply remove by index as all characters are only going to be one byte.
    if is_digit(input) || is_any(input, "+-*/ .") {
        return true;
    } else {
        log("ignoring input character %, since it's not in the ones we defined as supporting", input);
        return false;
    }
}
Input :: (input_state: *Input_State, body: Code) #expand {
    viewport := get_viewport_size();
    element(Style.{
        background = color(BG),
        padding = in_line(bottom(top(10), 30), 5),
        direction = .VERTICAL,
        text_wrapping = .NONE,
        y_justification = .CENTER,
        font_size = DIGITS_SIZE,
        width = fixed(viewport.x),
    }, #code {
        scrolling_offset := state(float);
        scrolling_effective_offset := state(float);
        if is_mouse_inside() {
            scrolling_offset.* += get_scroll_delta().x;
        }

        text_node_index := text(to_string(input_state.contents.data, input_state.contents.count));
        use_input(input_state, text_node_index, number_input_filter);
        Input_Caret(Style.{}, input_state, scrolling_effective_offset.*, text_node_index);

        input := get_node();
        input_measurement, defined := get_measurement();
        if defined {
            scrolling_offset.* = clamp(
                scrolling_offset.*,
                0,
                max(input_measurement.content_size.x - input_measurement.size.x + input.style.padding.x.x + input.style.padding.x.x, 0.0)
            );
        }
        scrolling_effective_offset.* = spring_transition(scrolling_offset.*, .{
            stiffness = 320.0,
            damping = 32.0,
            mass = 1.0,
            current = scrolling_effective_offset,
        });
        input.children_offset.x = -scrolling_effective_offset.*;

        #insert body;
    });
} @component

reverse_number_sign :: (text: *[..]u8) -> s64 {
    number_start := -1;
    if text.count > 0 {
        number_start = text.count - 1;
        if !is_any(text.*[number_start], " /+-*") {
            while number_start > 0 && !is_any(text.*[number_start - 1], " /+-*") {
                number_start -= 1;
            }
            if number_start < text.count - 1 && is_digit(text.*[number_start]) {
                if number_start > 0 && text.*[number_start - 1] == #char "-" {
                    array_ordered_remove_by_index(text, number_start - 1);
                    number_start -= 1;
                } else {
                    array_insert_at(text, #char "-", number_start);
                }
            }
        }
    }
    return number_start;
}
test_reverse_number_sign :: () {
    text: [..]u8;
    reverse_number_sign(*text);
    assert(to_string(text.data, text.count) == "");

    array_add(*text, #char "1");
    array_add(*text, #char "2");
    array_add(*text, #char "3");
    reverse_number_sign(*text);
    assert(to_string(text.data, text.count) == "-123");

    array_reset_keeping_memory(*text);
    array_add(*text, #char "-");
    array_add(*text, #char "1");
    array_add(*text, #char "2");
    array_add(*text, #char "3");
    reverse_number_sign(*text);
    assert(to_string(text.data, text.count) == "123");

    array_reset_keeping_memory(*text);
    array_add(*text, #char "-");
    reverse_number_sign(*text);
    assert(to_string(text.data, text.count) == "-");

    array_reset_keeping_memory(*text);
    array_add(*text, #char "1");
    array_add(*text, #char "2");
    array_add(*text, #char "3");
    array_add(*text, #char "-");
    reverse_number_sign(*text);
    assert(to_string(text.data, text.count) == "123-");

    array_reset_keeping_memory(*text);
    array_add(*text, #char "1");
    array_add(*text, #char "2");
    array_add(*text, #char "3");
    array_add(*text, #char " ");
    array_add(*text, #char "-");
    reverse_number_sign(*text);
    assert(to_string(text.data, text.count) == "123 -");
} @test

App :: () {
    window := context.forbear.window;
    viewport := get_viewport_size();

    tokens := state([..]Token);
    parse_result := state(Parse_Result);
    result := state(float64);

    input_state := state(Input_State);
    // TODO: find some way that this allocator could be set automatically too
    input_state.contents.allocator = node_pool();

    element(Style.{
        direction = .VERTICAL,
        background = color(BG_SECONDARY),
        width = fixed(viewport.x),
        height = fixed(viewport.y),
    }, #code {
        Input(input_state, #code {
            parse_result.* = parse_expression(to_string(input_state.contents.data, input_state.contents.count), tokens);
            if parse_result.* == .SUCCESS {
                Pass :: enum { DIVIDE_MULTIPLY; ADD_SUBTRACT; };
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
        });

        // TODO: how can we handle this error so that it's not even shown to the user?
        // if parse_result.* != .SUCCESS && input_state.contents.count > 0 && defined {
        //     // TODO: is this really useful? should we remove this?
        //     element(Style.{
        //         font_size = 12,
        //     }, #code {
        //         message := "";
        //         if parse_result.* == {
        //             case .TWO_NUMBERS_IN_A_ROW;
        //                 message = "Two numbers in a row can't be calculated";
        //             case .COULD_NOT_PARSE_FLOAT;
        //                 message = "Could not parse what should be a number";
        //         }
        //
        //         text_node := get_node(text(Style.{
        //             color = ERROR,
        //             margin = in_line(5),
        //             font_size = 12
        //         }, message));
        //
        //         error_node := get_node();
        //         error_node.style.placement = relative(Vector2.{
        //             0.0,
        //             input_measurement.size.y - text_node.size.y - 5
        //         });
        //     });
        // }

        element(Style.{
            direction = .VERTICAL,
            y_justification = .CENTER,
            width = grow(),
            height = grow(),
        }, #code {
            Row(#code {
                Column(#code { if Button("7") {
                    array_add(*input_state.contents, #char "7");
                    input_state.cursor_index = input_state.contents.count;
                } });
                Column(#code { if Button("8") {
                    array_add(*input_state.contents, #char "8");
                    input_state.cursor_index = input_state.contents.count;
                } });
                Column(#code { if Button("9") {
                    array_add(*input_state.contents, #char "9");
                    input_state.cursor_index = input_state.contents.count;
                } });
                Column(#code { if Button("÷", is_operator = true) {
                    array_add(*input_state.contents, #char " ", #char "/", #char " ");
                    input_state.cursor_index = input_state.contents.count;
                } });
            });
            Row(#code {
                Column(#code { if Button("4") {
                    array_add(*input_state.contents, #char "4");
                    input_state.cursor_index = input_state.contents.count;
                } });
                Column(#code { if Button("5") {
                    array_add(*input_state.contents, #char "5");
                    input_state.cursor_index = input_state.contents.count;
                } });
                Column(#code { if Button("6") {
                    array_add(*input_state.contents, #char "6");
                    input_state.cursor_index = input_state.contents.count;
                } });
                Column(#code { if Button("×", is_operator = true) {
                    array_add(*input_state.contents, #char " ", #char "*", #char " ");
                    input_state.cursor_index = input_state.contents.count;
                } });
            });
            Row(#code {
                Column(#code { if Button("1") {
                    array_add(*input_state.contents, #char "1");
                    input_state.cursor_index = input_state.contents.count;
                } });
                Column(#code { if Button("2") {
                    array_add(*input_state.contents, #char "2");
                    input_state.cursor_index = input_state.contents.count;
                } });
                Column(#code { if Button("3") {
                    array_add(*input_state.contents, #char "3");
                    input_state.cursor_index = input_state.contents.count;
                } });
                Column(#code { if Button("+", is_operator = true) {
                    array_add(*input_state.contents, #char " ", #char "+", #char " ");
                    input_state.cursor_index = input_state.contents.count;
                } });
            });
            Row(#code {
                Column(#code { if Button("+/-") {
                    input_state.cursor_index = reverse_number_sign(*input_state.contents);
                } });
                Column(#code { if Button("0") {
                    array_add(*input_state.contents, #char "0");
                    input_state.cursor_index = input_state.contents.count;
                } });
                Column(#code { if Button(".") {
                    array_add(*input_state.contents, #char ".");
                    input_state.cursor_index = input_state.contents.count;
                } });
                Column(#code { if Button("-", is_operator = true) {
                    array_add(*input_state.contents, #char " ", #char "-", #char " ");
                    input_state.cursor_index = input_state.contents.count;
                } });
            });
        });
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
    defer prepare_for_next_frame();
    App();

    layout();
    draw(BG_SECONDARY);

    reset_temporary_storage();

    memory_visualizer_per_frame_update();
    reset(*frame_pool);
}

main :: () {
    backend: Backend;
    window: Window;
    init_backend(*backend);
    init_window(*backend, *window, MIN_WIDTH, MIN_HEIGHT, "Calculator");
    // TODO: we should add a native function to handle this min size thing
    // also a max size thing would be nice
    #if OS == .LINUX {
        send_wayland_message(*backend.connection, window.xdg_toplevel_id, Xdg_Toplevel_Request_Set_Min_Size.{ width = MIN_WIDTH, height = MIN_HEIGHT });
    } else #if OS == .MACOS {
        set_size: (*void, Selector, NSSize) #c_call = xx objc_msgSend;
        set_size(window.ns_window, selector("setContentMinSize:"), .{ width = MIN_WIDTH, height = MIN_HEIGHT });
    } else #if OS == .WINDOWS {
        backend.message = (data: *void, window: *Windows_GL_Window, hWnd: HWND, Msg: u32, wParam: WPARAM, lParam: LPARAM) -> result: s64, handled: bool {
            if Msg == {
                case WM_GETMINMAXINFO;
                    MINMAXINFO :: struct {
                        ptReserved: POINT;
                        ptMaxSize: POINT;
                        ptMaxPosition: POINT;
                        ptMinTrackSize: POINT;
                        ptMaxTrackSize: POINT;
                    };
                    dpi := GetDpiForWindow(hWnd);
                    window.scale = dpi / 96.0;
                    rectangle := RECT.{ right = xx (MIN_WIDTH * window.scale), bottom = xx (MIN_HEIGHT * window.scale) };
                    AdjustWindowRectExForDpi(*rectangle, WS_OVERLAPPEDWINDOW, 0, 0, dpi);
                    min_max_info := cast(*MINMAXINFO) lParam;
                    min_max_info.ptMinTrackSize = .{ rectangle.right - rectangle.left, rectangle.bottom - rectangle.top };
                    return 0, true;
            }
            return 0, false;
        }
    }

    context.inter = #run create_font(read_entire_file(tprint("%../../Inter.ttf", #filepath)));

    forbear: Forbear;
    init_forbear(*forbear, *window, *backend, Base_Style.{
        font = *context.inter,
        color = hex("#ECECEC"),
        font_size = 16,
    });

    init_font(*context.inter);

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
