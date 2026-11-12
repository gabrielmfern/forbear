#import "Basic";
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

Operator :: enum { NONE; ADD; SUBTRACT; MULTIPLY; DIVIDE; EXPONENTIATE; };
is_operator :: (char: u8) -> bool {
    return is_any(char, "+-*x/^");
}
OPERATOR_PRECEDENCE  :: s64.[0, 1, 1, 2, 2, 3];
Expression_Node_Kind :: enum {
    BINARY;
    OPEARTOR;
    NUMBER;
}
Expression_Node      :: struct {
    kind: Expression_Node_Kind;
    union {
        number: float64;
        op:     Operator;
        binary: struct {
            left:       s64;
            op:         s64;
            right:      s64;
        }
    }
};
// TODO: return the index under which the failure happened, and then, after that index, make the text color red
// to indicate a parsing failure.
Parse_Result :: enum { OK; TOO_MANY_PERIODS; EXPECTED_A_NUMBER; EXPECTED_A_OPERATOR; EXPECTED_A_CLOSING_PARENTHESIS; };
peek_number :: (expression: string, cursor: s64) -> float64, index_increment: s64, result: Parse_Result {
    index_increment := 0;
    while cursor + index_increment < expression.count && expression[cursor + index_increment] == #char " " {
        index_increment += 1;
    }
    if cursor + index_increment < expression.count && is_digit(expression[cursor + index_increment]) {
        number_start := cursor + index_increment;
        found_period := false;
        // then, we find the end of this "number"
        while cursor + index_increment <= expression.count - 1 {
            char := expression[cursor + index_increment];
            if char == #char "." {
                if found_period then return 0, index_increment, Parse_Result.TOO_MANY_PERIODS;
                found_period = true;
            }
            if !is_digit(char) && char != #char "." {
                break;
            }
            index_increment += 1;
        }

        number: string = ---;
        number.data    = expression.data + number_start;
        number.count   = cursor + index_increment - number_start;
        // TODO: ponder if we should handle the failure of this or not. I don't think this can ever fail given what we've already assured to this point
        return string_to_float64(number), index_increment, .OK;
    } else {
        // if the character at this point is not a digit, it means we reached the end of the expression
        // and could not find the number we expected. that indicates an improper expression was typed out
        return 0, index_increment, Parse_Result.EXPECTED_A_NUMBER;
    }
}
peek_opeartor :: (expression: string, cursor: s64) -> Operator, index_increment: s64, result: Parse_Result {
    index_increment := 0;
    while cursor + index_increment < expression.count && expression[cursor + index_increment] == #char " " {
        index_increment += 1;
    }
    if cursor + index_increment >= expression.count return .NONE, index_increment, Parse_Result.EXPECTED_A_OPERATOR;
    op_character := expression[cursor + index_increment];
    if is_operator(op_character) {
        op: Operator;
        if op_character == {
            case "+"; op = .ADD;
            case "-"; op = .SUBTRACT;
            case "x"; #through;
            case "*"; op = .MULTIPLY;
            case "/"; op = .DIVIDE;
            case "^"; op = .EXPONENTIATE;
        }
        index_increment += 1;
        return op, index_increment, Parse_Result.OK;
    } else {
        return .NONE, index_increment, Parse_Result.EXPECTED_A_OPERATOR;
    }
}
Parser :: struct {
    cursor:     s64;
    expression: string;
    nodes:      *[..]Expression_Node;
};
parse_number :: (using parser: *Parser) -> s64, result: Parse_Result {
    number, increment, result := peek_number(expression, cursor);
    node                      : Expression_Node;
    if result == .OK {
        cursor      = cursor + increment;
        node.kind   = .NUMBER;
        node.number = number;
    }
    array_add(nodes, node);
    return nodes.count - 1, result;
}
parse_operator :: (using parser: *Parser) -> s64, result: Parse_Result {
    op, increment, result := peek_opeartor(expression, cursor);
    node                  : Expression_Node;
    if result == .OK {
        cursor    = cursor + increment;
        node.kind = .OPEARTOR;
        node.op   = op;
    }
    array_add(nodes, node);
    return nodes.count - 1, result;
}
parse_operand :: (using parser: *Parser) -> index: s64, Parse_Result {
    while cursor < expression.count && expression[cursor] == #char " " {
        cursor += 1;
    }
    if cursor < expression.count && expression[cursor] == #char "(" {
        cursor += 1;
        // precedence starts over inside the parenthesis: whatever operator our caller is in the
        // middle of can't reach in here, so the inner expression takes everything up to the ")"
        inner, result := parse_expression(parser, 0);
        if result == .OK {
            while cursor < expression.count && expression[cursor] == #char " " {
                cursor += 1;
            }
            if cursor < expression.count && expression[cursor] == #char ")" {
                cursor += 1;
                // no node for the parenthesis themselves, the index of what was inside is the operand
                return inner, .OK;
            } else {
                return inner, .EXPECTED_A_CLOSING_PARENTHESIS;
            }
        } else {
            return inner, result;
        }
    }
    index, result := parse_number(parser);
    return index, result;
}
/*
    This produces a tree for the entire expression in such a way that the binaries that are added onto the array
    in the order in which they must be evaluated. This makes precedence work without much work and makes this quite
    simple.

    Examples:
    1 + 2 * 3 - 4 -> [0] NUMBER   1
                     [1] OPERATOR +
                     [2] NUMBER   2
                     [3] OPERATOR *
                     [4] NUMBER   3
                     [5] BINARY   left=2 op=3 right=4
                     [6] BINARY   left=0 op=1 right=5
                     [7] OPERATOR -
                     [8] NUMBER   4
                     [9] BINARY   left=6 op=7 right=8   <- root

    1 - 2 - 3     -> [0] NUMBER   1
                     [1] OPERATOR -
                     [2] NUMBER   2
                     [3] BINARY   left=0 op=1 right=2
                     [4] OPERATOR -
                     [5] NUMBER   3
                     [6] BINARY   left=3 op=4 right=5

    1 + 2 * 3     -> [0] NUMBER   1
                     [1] OPERATOR +
                     [2] NUMBER   2
                     [3] OPERATOR *
                     [4] NUMBER   3
                     [5] BINARY   left=2 op=3 right=4
                     [6] BINARY   left=0 op=1 right=5
*/
parse_expression :: (using parser: *Parser, min_precedence := 0) -> index: s64, Parse_Result {
    result: Parse_Result;
    left:   s64          = -1;
    op:     s64          = -1;
    right:  s64          = -1;
    while parser.cursor < expression.count {
        if left == -1 {
            left, result = parse_operand(parser);
            if result != .OK || cursor >= expression.count then break;
        }

        assert(op == -1);
        peeked_op, _, peeked_result := peek_opeartor(expression, cursor);
        // this is the point of decision of whether this left number should be use in this new binary, or if it should be yielded to the caller.
        //
        // we determine if we want to keep it here if the caller's precedence (min_precedence) is smaller or equal to ours, in which case we
        // create a new binary with it and instead yield the binary's index to be used as the `right` of the caller's express
        if peeked_result == .OK && OPERATOR_PRECEDENCE[peeked_op] > min_precedence {
            op, result = parse_operator(parser);
            if result != .OK || cursor >= expression.count then break;

            assert(right == -1);
            precedence := OPERATOR_PRECEDENCE[peeked_op];
            if peeked_op == .EXPONENTIATE {
                // this makes the exponentiation be right associative as it should e.g. 2^3^2 = 2^(3^2)
                precedence -= 1;
            }
            // when we call this function we want to understand if the next number should be used here, or by another binary.
            // if it's used by another binary, the right here becomes the index to that binary.
            //
            // read above to understand how this is determined.
            right, result = parse_expression(parser, precedence);
            if result != .OK then break;

            node: Expression_Node;
            node.kind         = .BINARY;
            node.binary.left  = left;
            node.binary.op    = op;
            node.binary.right = right;
            array_add(nodes, node);

            left  = nodes.count - 1;
            op    = -1;
            right = -1;
        } else {
            break;
        }
    }
    return left, result;
}
// Heavily inspired by the conversation between Jonathan Blow and Casey Muratori here https://youtu.be/fIPO4G42wYE?si=elPLn4XFm9FhO-ZS
parse_expression :: (expression: string, nodes: *[..]Expression_Node) -> Parse_Result {
    parser: Parser;
    parser.expression = expression;
    parser.nodes      = nodes;
    parser.cursor     = 0;

    root, result := parse_expression(*parser, 0);
    if result == .OK {
        while parser.cursor < expression.count && expression[parser.cursor] == #char " " {
            parser.cursor += 1;
        }
        if parser.cursor < expression.count then result = .EXPECTED_A_OPERATOR;
    }
    return result;
}
evaluate :: (nodes: [..]Expression_Node) -> float64, success: bool {
    if nodes.count == 0 then return 0, false;
    evaluate_node :: (nodes: [..]Expression_Node, node: Expression_Node) -> float64, success: bool {
        if #complete node.kind == {
            case .BINARY;
                left, right: float64;
                success: bool;

                left, success = evaluate_node(nodes, nodes[node.binary.left]);
                if !success then return 0, false;
                right, success = evaluate_node(nodes, nodes[node.binary.right]);
                if !success then return 0, false;
                if #complete nodes[node.binary.op].op == {
                    case .ADD;
                        return left + right, true;
                    case .SUBTRACT;
                        return left - right, true;
                    case .MULTIPLY;
                        return left * right, true;
                    case .DIVIDE;
                        return left / right, true;
                    case .EXPONENTIATE;
                        return Math.pow(left, right), true;
                    case .NONE;
                        return 0, false;
                }
            case .NUMBER;
                return node.number, true;
            case .OPEARTOR;
                return 0, false;
        }
    }
    // the last binary, that we then use to recurse outward
    outer_binary_or_first_number: Expression_Node;
    found_binary_or_first_number: bool;
    for <nodes {
        if it.kind == .BINARY {
            outer_binary_or_first_number = it;
            found_binary_or_first_number = true;
            break;
        }
    }
    if !found_binary_or_first_number {
        // assummed that this number is going to be fast to find
        for nodes {
            if it.kind == .NUMBER {
                outer_binary_or_first_number = it;
                found_binary_or_first_number = true;
                break;
            }
        }
    }
    if !found_binary_or_first_number {
        return 0, false;
    }
    evaluation, success := evaluate_node(nodes, outer_binary_or_first_number);
    return evaluation, success;
}

isnan       :: Math.isnan;
FLOAT64_NAN :: Math.FLOAT64_NAN;
U64_MAX     :: Math.U64_MAX;

//
// ===== program styles =====
//
#add_context inter: Font;
// The interface is designed for MIN_WIDTH x MIN_HEIGHT. On bigger windows, everything gets multiplied by how much
// the window grew on the axis it grew the least, and the buttons stretch to take what's left on the other axis.
#add_context ui_scale: float = 1.0;
scaled :: (value: float) -> float {
    return value * context.ui_scale;
}
// the same conversion the layout does for the text of the input, so that the caret lines up with the glyphs
digits_font_units_to_pixel :: () -> float {
    window_scale := cast(float) context.forbear.window.scale;
    return get_font_units_to_pixel(*context.inter, round_font_size(scaled(DIGITS_SIZE) * window_scale)) / window_scale;
}
MIN_WIDTH    :: 225;
MIN_HEIGHT   :: 445;
DIGITS_SIZE  :: 32;
BUTTON_GAP   :: 8.0;
BG           :: #run hex("#0F0F10");
BG_SECONDARY :: #run hex("#19191B");
BG_TERTIARY  :: #run hex("#262628");
BG_HOVER     :: #run hex("#313134");
BG_PRESSED   :: #run hex("#1E1E20");
FN           :: #run hex("#3A3A3D");
FN_HOVER     :: #run hex("#464649");
FN_PRESSED   :: #run hex("#2E2E30");
OP           :: #run hex("#ECECEC");
OP_TEXT      :: #run hex("#19191B");
OP_HOVER     :: #run hex("#FFFFFF");
OP_PRESSED   :: #run hex("#CFCFD2");
ERROR        :: #run hex("#E85B5B");
TRANSPARENT  :: #run hex("#01010100");

Button_Kind :: enum {
    DIGIT;
    // the ones that are neither a digit nor an operator, like the parenthesis
    FUNCTION;
    OPERATOR;
}
Button :: (contents: string, kind := Button_Kind.DIGIT) -> clicked: bool {
    background, hover, pressed: Vector4;
    if #complete kind == {
        case .DIGIT;    background, hover, pressed = BG_TERTIARY, BG_HOVER, BG_PRESSED;
        case .FUNCTION; background, hover, pressed = FN, FN_HOVER, FN_PRESSED;
        case .OPERATOR; background, hover, pressed = OP, OP_HOVER, OP_PRESSED;
    }

    clicked := false;
    element(Style.{
        border_radius   = scaled(6.0),
        background      = color(background),
        color           = ifx kind == .OPERATOR then OP_TEXT else VECTOR4_NAN,
        font_size       = scaled(24),
        x_justification = .CENTER,
        y_justification = .CENTER,
        width           = grow(),
        height          = grow(),
        cursor          = .POINTER,
    }, #code {
        button := get_node();
        if is_mouse_inside() {
            button.style.background = color(hover);
        }
        clicked = on_click();
        if is_mouse_held() && is_mouse_inside() {
            button.style.background = color(pressed);
        }
        text(contents);
    });
    return clicked;
} @component

Selection_State :: struct {
    anchor: s64 = -1;
    cursor: s64 = -1;
};
previous_word_boundary :: (glyphs: []Glyph, cursor: s64) -> s64 {
    c := cursor;
    // TODO: we should use a library that makes this work for any language, or implement something ourselves.
    while c > 0 && !is_alnum(glyphs[c - 1].utf8.Encoded[0]) c -= 1;
    while c > 0 && is_alnum(glyphs[c - 1].utf8.Encoded[0]) c -= 1;
    return c;
}
next_word_boundary :: (glyphs: []Glyph, cursor: s64) -> s64 {
    c := cursor;
    // TODO: we should use a library that makes this work for any language, or implement something ourselves.
    while c < glyphs.count && !is_alnum(glyphs[c].utf8.Encoded[0]) c += 1;
    while c < glyphs.count && is_alnum(glyphs[c].utf8.Encoded[0]) c += 1;
    return c;
}
Selection :: (state: *Selection_State) {
} @component
// Limitations:
// - does not support word boundaries for non latin languages (chinese, japenese, arabic, hebrew, etc.);
// - does not support multiline text.
use_textual_keyboard_navigation :: (glyphs: []Glyph, cursor: *s64) -> struct { previous: s64; next: s64; } {
    previous := max(cursor.* - 1, 0);
    next     := min(cursor.* + 1, glyphs.count);
    by_word  := false;
    #if OS == .MACOS {
        by_word = by_word || is_key_held(.ALT_LEFT) || is_key_held(.ALT_RIGHT);
    }
    #if OS == .LINUX || OS == .WINDOWS {
        by_word = by_word || is_key_held(.CONTROL_LEFT) || is_key_held(.CONTROL_RIGHT);
    }
    if by_word {
        previous = previous_word_boundary(glyphs, cursor.*);
        next     = next_word_boundary(glyphs, cursor.*);
    }
    #if OS == .MACOS {
        if is_key_held(.SUPER_LEFT) || is_key_held(.SUPER_RIGHT) {
            // TODO: to support multiline text here, we need this to go to the start of the current line,
            // not to the start of the entire piece of text.
            previous = 0;
            // TODO: to support multiline text here, we need this to go to the end of the current line,
            // not to the start of the entire piece of text.
            next     = glyphs.count;
        }
    }
    if on_key_down(.ARROW_LEFT, true) {
        cursor.* = previous;
    } else if on_key_down(.ARROW_RIGHT, true) {
        cursor.* = next;
    } else if on_key_down(.HOME) {
        // TODO: to support multiline text here, we need this to go to the start of the current line,
        // not to the start of the entire piece of text.
        cursor.* = 0;
    } else if on_key_down(.END) {
        // TODO: to support multiline text here, we need this to go to the end of the current line,
        // not to the start of the entire piece of text.
        cursor.* = glyphs.count;
    }
    return .{previous, next};
} @hook
use_selection :: (using state: *Selection_State, text_node_index: s64) {
    // TODO: we should be getting these glyphs out of the measurement so that we also take wrapping into account
    glyphs    := get_node(text_node_index).glyphs;

    if cursor != -1 && anchor != -1 && is_key_held(.SHIFT_LEFT) || is_key_held(.SHIFT_RIGHT) {
        use_textual_keyboard_navigation(glyphs.array, *state.cursor);
    }

    text_measurement, defined := get_measurement(text_node_index);
    if defined && (on_mouse_down(.LEFT) || on_mouse_down(.RIGHT)) {
        font_units_to_pixel := digits_font_units_to_pixel();
        line_height         := glyphs.line_height * font_units_to_pixel;

        mouse            := get_mouse_position();
        closest_distance : float;
        for glyphs.array {
            left_edge := text_measurement.position.x + it.position.x * font_units_to_pixel;
            // TOOD: to make this work with mulitple lines, we will need to have the glyphs already wrapped here,
            // but then we will also need to find the closest line, to finally compare the x coordinates
            distance := Math.abs(left_edge - mouse.x);
            if it_index == 0 || distance < closest_distance {
                closest_distance = distance;
                cursor           = it_index;
            }
            if it_index == glyphs.array.count - 1 {
                right_edge := left_edge + it.advance.x * font_units_to_pixel;
                // TOOD: to make this work with mulitple lines, we will need to have the glyphs already wrapped here,
                // but then we will also need to find the closest line, to finally compare the x coordinates
                distance := Math.abs(right_edge - mouse.x);
                if distance < closest_distance {
                    closest_distance = distance;
                    cursor           = glyphs.array.count;
                }
            }
        }
    }
} @hook
Input_State :: struct {
    contents: [..]u8;
    cursor: s64;
}
// To make this hook thing generic for it to be builtin into forbear we need to:
// - track the caret position based on glyph indices instead of bytes
// - delete by glyphs unicode ranges instead of by bytes
// - handle multiline text
// - make it generic: previous and next word boundaries should not be tied to digits
use_input :: (using input_state:      *Input_State,
              text_node_index:        s64,
              input_character_filter: #type (input: u8) -> bool = null) {

    append :: (using input_state:      *Input_State,
               input:                  string,
               input_character_filter: #type (input: u8) -> bool) {
        if input_character_filter != null {
            for character: input {
                if input_character_filter(character) {
                    array_insert_at(*contents, character, cursor);
                    cursor += 1;
                }
            }
        } else {
            input_bytes: []u8 = ---;
            input_bytes.data  = input.data;
            input_bytes.count = input.count;
            array_add(*contents, ..input_bytes);
        }
    }

    glyphs := get_node(text_node_index).glyphs;

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

    removed_bytes: s64;
    {
        //
        // === keyboard deletion and cursor movement handling ===
        //
        using use_textual_keyboard_navigation(glyphs.array, *cursor);
        removal_start, removal_end := cursor;
        if on_key_down(.BACKSPACE, true) {
            removal_start = previous;
        } else if on_key_down(.DELETE, true) {
            removal_end = next;
        }

        if glyphs.array.count > 0 && removal_start != removal_end {
            removal_start_byte, removal_end_byte := 0;
            if removal_start < glyphs.array.count removal_start_byte = glyphs.array[removal_start].index_into_original_text;
            else removal_start_byte                                  = glyphs.array[glyphs.array.count - 1].index_into_original_text + 1;
            if removal_end < glyphs.array.count removal_end_byte = glyphs.array[removal_end].index_into_original_text;
            else removal_end_byte                                = glyphs.array[glyphs.array.count - 1].index_into_original_text + 1;

            removed_bytes       = removal_end_byte - removal_start_byte;
            for i: removal_start_byte..contents.count - removed_bytes - 1 {
                contents[i] = contents[i + removed_bytes];
            }
            contents.count -= removed_bytes;
            cursor          = min(cursor, removal_start_byte);
        }
    }

    {
        //
        // === mouse event handling ===
        //
        text_measurement, defined := get_measurement(text_node_index);
        if defined && (on_mouse_down(.LEFT) || on_mouse_down(.RIGHT)) {
            font_units_to_pixel := digits_font_units_to_pixel();
            line_height         := glyphs.line_height * font_units_to_pixel;

            mouse            := get_mouse_position();
            closest_distance : float;
            for glyphs.array {
                left_edge := text_measurement.position.x + it.position.x * font_units_to_pixel;
                // TOOD: to make this work with mulitple lines, we will need to have the glyphs already wrapped here,
                // but then we will also need to find the closest line, to finally compare the x coordinates
                distance := Math.abs(left_edge - mouse.x);
                if it_index == 0 || distance < closest_distance {
                    closest_distance = distance;
                    cursor           = it_index;
                }
                if it_index == glyphs.array.count - 1 {
                    right_edge := left_edge + it.advance.x * font_units_to_pixel;
                    // TOOD: to make this work with mulitple lines, we will need to have the glyphs already wrapped here,
                    // but then we will also need to find the closest line, to finally compare the x coordinates
                    distance := Math.abs(right_edge - mouse.x);
                    if distance < closest_distance {
                        closest_distance = distance;
                        cursor           = glyphs.array.count;
                    }
                }
            }
        }
    }
} @hook
Caret :: (
    style:             Style,
    using input_state: *Input_State,
    scrolling_offset:  float,
    text_node_index:   s64
) {
    input_measurement, defined := get_measurement();
    if defined {
        text_node        := get_node(text_node_index);
        text_measurement := get_measurement(text_node_index);
        input_glyphs     := text_node.glyphs;
        font_units_to_pixel := digits_font_units_to_pixel();

        caret_position: Vector2;
        if contents.count > 0 {
            if cursor == contents.count {
                caret_position = (input_glyphs.array[contents.count - 1].position + input_glyphs.array[contents.count - 1].advance) * font_units_to_pixel;
            } else {
                caret_position = input_glyphs.array[cursor].position * font_units_to_pixel;
            }
        }
        // TODO: support multi-line inputs, because we're currently only comparing against there being no wrapping in the input
        line_height      := input_glyphs.line_height * font_units_to_pixel;
        input            := get_node();
        inner_height     := input_measurement.size.y - input.style.padding.y.x - input.style.padding.y.y;
        caret_position.x -= scrolling_offset;
        caret_position.x += input.style.padding.x.x;
        caret_position.y += input.style.padding.y.x + (inner_height - line_height) / 2;

        // TODO: while typing, this blinking timer should reset
        blinking := cast(s64)Math.floor(seconds_since_init() * 2) % 2 != 1;

        element(overwrite(style, Style.{
            placement  = relative(caret_position),
            background = ifx blinking then
                color(hex("#FFFFFF"))
            else
                color(TRANSPARENT),
            width  = fixed(scaled(1.0)),
            height = fixed(line_height),
        }));
    }
} @component
Input :: (input_state: *Input_State, body: Code) #expand {
    viewport := get_viewport_size();
    element(Style.{
        background      = color(BG),
        padding         = in_line(bottom(top(scaled(10)), scaled(30)), scaled(5)),
        direction       = .VERTICAL,
        text_wrapping   = .NONE,
        y_justification = .CENTER,
        font_size       = scaled(DIGITS_SIZE),
        width           = fixed(viewport.x),
    }, #code {
        scrolling_offset           := state(float);
        scrolling_effective_offset := state(float);
        // TODO: break this into a use_scrolling hook
        if is_mouse_inside() {
            scrolling_offset.* += get_scroll_delta().x;
        }

        text_node_index := text(to_string(input_state.contents.data, input_state.contents.count));
        Caret(Style.{}, input_state, scrolling_effective_offset.*, text_node_index);
        // TODO: as the user types, this should scroll following the cursor
        use_input(input_state, text_node_index, (input: u8) -> bool {
            // since we're not really using any complicated utf8, but rather only ASCII input as there are only numbers
            // and operators, we can simply remove by index as all characters are only going to be one byte.
            if is_digit(input) || is_operator(input) || is_any(input, " .()") {
                return true;
            } else {
                log("ignoring input character %, since it's not in the ones we defined as supporting", input);
                return false;
            }
        });

        input                      := get_node();
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
            damping   = 32.0,
            mass      = 1.0,
            current   = scrolling_effective_offset,
        });
        input.children_offset.x = -scrolling_effective_offset.*;

        #insert body;
    });
} @component

reverse_number_sign :: (text: *[..]u8) -> s64 {
    number_start := -1;
    if text.count > 0 {
        number_start = text.count - 1;
        if !is_any(text.*[number_start], " /+-*x^()") {
            while number_start > 0 && !is_any(text.*[number_start - 1], " /+-*x^()") {
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
// Removes what was last added by one of the buttons. The operator buttons surround the operator with spaces, so
// those go away together with the operator.
remove_last :: (text: *[..]u8) {
    while text.count > 0 && text.*[text.count - 1] == #char " " {
        text.count -= 1;
    }
    if text.count > 0 {
        removed := text.*[text.count - 1];
        text.count -= 1;
        if is_operator(removed) {
            while text.count > 0 && text.*[text.count - 1] == #char " " {
                text.count -= 1;
            }
        }
    }
}

App :: () {
    window   := context.forbear.window;
    viewport := get_viewport_size();
    // the lower bound keeps font sizes sane on a degenerate viewport, like the one of a minimized window
    context.ui_scale = max(min(viewport.x / MIN_WIDTH, viewport.y / MIN_HEIGHT), 0.5);

    evaluation_success := state(false);
    result             := state(float64);

    input_state := state(Input_State);
    // TODO: find some way that this allocator could be set automatically too
    input_state.contents.allocator = node_pool();

    element(Style.{
        direction  = .VERTICAL,
        background = color(BG_SECONDARY),
        width      = fixed(viewport.x),
        height     = fixed(viewport.y),
    }, #code {
        Input(input_state, #code {
            nodes: [..]Expression_Node;
            evaluation_success.* = parse_expression(to_string(input_state.contents.data, input_state.contents.count), *nodes) == .OK;
            if evaluation_success.* {
                evaluation, success := evaluate(nodes);
                result.*             = evaluation;
                evaluation_success.* = success;
            }

            input_measurement, defined := get_measurement();
            if defined {
                element(Style.{
                    background = color(BG),
                    padding    = all(scaled(5.0)),
                    font_size  = scaled(12),
                }, #code {
                    text_index  := text(sprint("= %", result.*));
                    text_node   := get_node(text_index);
                    result_node := get_node();
                    result_node.style.placement = relative(Vector2.{
                        viewport.x - text_node.size.x - scaled(15.0),
                        input_measurement.size.y - text_node.size.y - scaled(20.0)
                    });
                });
            }
        });

        // `span` is how many columns of the grid this one takes
        Column :: (body: Code, span := 1.0) #expand {
            // half of the gap on each side, so that two neighboring buttons end up a full gap apart
            element(Style.{width = grow(span), height = grow(), padding = all(scaled(BUTTON_GAP / 2))}, body);
        } @component
        Row :: (body: Code) #expand {
            element(Style.{width = grow(), height = grow()}, body);
        } @component

        element(Style.{
            direction       = .VERTICAL,
            // the other half, so that the buttons are also a full gap away from the edges
            padding         = all(scaled(BUTTON_GAP / 2)),
            width           = grow(),
            height          = grow(),
        }, #code {
            Row(#code {
                Column(#code { if Button("C", .FUNCTION) {
                    input_state.contents.count = 0;
                    input_state.cursor   = 0;
                    // there's nothing to evaluate anymore, and the result is only updated when the evaluation succeeds
                    result.* = 0;
                } }, span = 2);
                Column(#code { if Button("⌫", .FUNCTION) {
                    remove_last(*input_state.contents);
                    input_state.cursor = input_state.contents.count;
                } }, span = 2);
            });
            Row(#code {
                Column(#code { if Button("(", .FUNCTION) {
                    array_add(*input_state.contents, #char "(");
                    input_state.cursor = input_state.contents.count;
                } });
                Column(#code { if Button(")", .FUNCTION) {
                    array_add(*input_state.contents, #char ")");
                    input_state.cursor = input_state.contents.count;
                } });
                Column(#code { if Button("+/-", .FUNCTION) {
                    input_state.cursor = reverse_number_sign(*input_state.contents);
                } });
                Column(#code { if Button("^", .OPERATOR) {
                    array_add(*input_state.contents, #char " ", #char "^", #char " ");
                    input_state.cursor = input_state.contents.count;
                } });
            });
            Row(#code {
                Column(#code { if Button("7") {
                    array_add(*input_state.contents, #char "7");
                    input_state.cursor = input_state.contents.count;
                } });
                Column(#code { if Button("8") {
                    array_add(*input_state.contents, #char "8");
                    input_state.cursor = input_state.contents.count;
                } });
                Column(#code { if Button("9") {
                    array_add(*input_state.contents, #char "9");
                    input_state.cursor = input_state.contents.count;
                } });
                Column(#code { if Button("÷", .OPERATOR) {
                    array_add(*input_state.contents, #char " ", #char "/", #char " ");
                    input_state.cursor = input_state.contents.count;
                } });
            });
            Row(#code {
                Column(#code { if Button("4") {
                    array_add(*input_state.contents, #char "4");
                    input_state.cursor = input_state.contents.count;
                } });
                Column(#code { if Button("5") {
                    array_add(*input_state.contents, #char "5");
                    input_state.cursor = input_state.contents.count;
                } });
                Column(#code { if Button("6") {
                    array_add(*input_state.contents, #char "6");
                    input_state.cursor = input_state.contents.count;
                } });
                Column(#code { if Button("×", .OPERATOR) {
                    array_add(*input_state.contents, #char " ", #char "*", #char " ");
                    input_state.cursor = input_state.contents.count;
                } });
            });
            Row(#code {
                Column(#code { if Button("1") {
                    array_add(*input_state.contents, #char "1");
                    input_state.cursor = input_state.contents.count;
                } });
                Column(#code { if Button("2") {
                    array_add(*input_state.contents, #char "2");
                    input_state.cursor = input_state.contents.count;
                } });
                Column(#code { if Button("3") {
                    array_add(*input_state.contents, #char "3");
                    input_state.cursor = input_state.contents.count;
                } });
                Column(#code { if Button("+", .OPERATOR) {
                    array_add(*input_state.contents, #char " ", #char "+", #char " ");
                    input_state.cursor = input_state.contents.count;
                } });
            });
            Row(#code {
                Column(#code { if Button("0") {
                    array_add(*input_state.contents, #char "0");
                    input_state.cursor = input_state.contents.count;
                } }, span = 2);
                Column(#code { if Button(".") {
                    array_add(*input_state.contents, #char ".");
                    input_state.cursor = input_state.contents.count;
                } });
                Column(#code { if Button("-", .OPERATOR) {
                    array_add(*input_state.contents, #char " ", #char "-", #char " ");
                    input_state.cursor = input_state.contents.count;
                } });
            });
        });
    });

    if on_key_down(.ESCAPE) {
        window.running = false;
    }

    if on_key_down(.ENTER) {
        // TODO: the copied result is gone in linux because the clipboard data remains in the process until another process requests for it,
        // which means it's instantly lost as the window stops running.
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
                        ptReserved:     POINT;
                        ptMaxSize:      POINT;
                        ptMaxPosition:  POINT;
                        ptMinTrackSize: POINT;
                        ptMaxTrackSize: POINT;
                    };
                    dpi         := GetDpiForWindow(hWnd);
                    window.scale = dpi / 96.0;
                    rectangle   := RECT.{ right = xx (MIN_WIDTH * window.scale), bottom = xx (MIN_HEIGHT * window.scale) };
                    AdjustWindowRectExForDpi(*rectangle, WS_OVERLAPPEDWINDOW, 0, 0, dpi);
                    min_max_info               := cast(*MINMAXINFO) lParam;
                    min_max_info.ptMinTrackSize = .{ rectangle.right - rectangle.left, rectangle.bottom - rectangle.top };
                    return 0, true;
            }
            return 0, false;
        }
    }

    context.inter = #run create_font(read_entire_file(tprint("%../../Inter.ttf", #filepath)));

    forbear: Forbear;
    init_forbear(*forbear, *window, *backend, Base_Style.{
        font      = *context.inter,
        color     = hex("#ECECEC"),
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
