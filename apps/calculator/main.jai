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
// TO-DO: return the index under which the failure happened, and then, after that index, make the text color red
// to indicate a parsing failure.
Parse_Result :: enum { OK; TOO_MANY_PERIODS; EXPECTED_A_NUMBER; EXPECTED_A_OPERATOR; EXPECTED_A_CLOSING_PARENTHESIS; };
peek_number :: (expression: string, cursor: s64) -> float64, index_increment: s64, result: Parse_Result {
    index_increment := 0;
    while cursor + index_increment < expression.count && expression[cursor + index_increment] == #char " " {
        index_increment += 1;
    }
    number_start := cursor + index_increment;
    if number_start < expression.count && expression[number_start] == #char "-" then index_increment += 1;
    if cursor + index_increment < expression.count && is_digit(expression[cursor + index_increment]) {
        found_period := false;
        // Then, we find the end of this "number"
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
        // TO-DO: ponder if we should handle the failure of this or not. I don't think this can ever fail, given what we've already assured to this point
        return string_to_float64(number), index_increment, .OK;
    } else {
        // If the character at this point is not a digit, it means we reached the end of the expression
        // and could not find the number we expected. That indicates an improper expression was typed out
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
        // Precedence starts over inside the parenthesis: whatever operator our caller is in the
        // middle of can't reach in here, so the inner expression takes everything up to the ")"
        inner, result := parse_expression(parser, 0);
        if result == .OK {
            while cursor < expression.count && expression[cursor] == #char " " {
                cursor += 1;
            }
            if cursor < expression.count && expression[cursor] == #char ")" {
                cursor += 1;
                // No node for the parenthesis themselves, the index of what was inside is the operand
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
        // This is the point of decision of whether this left number should be use in this new binary, or if it should be yielded to the caller.
        //
        // We determine if we want to keep it here if the caller's precedence (`min_precedence`) is smaller or equal to ours. In that case we
        // create a new binary with it and instead yield the binary's index to be used as the `right` of the caller's express
        if peeked_result == .OK && OPERATOR_PRECEDENCE[peeked_op] > min_precedence {
            op, result = parse_operator(parser);
            if result != .OK || cursor >= expression.count then break;

            assert(right == -1);
            precedence := OPERATOR_PRECEDENCE[peeked_op];
            if peeked_op == .EXPONENTIATE {
                // This makes the exponentiation be right associative as it should e.g. 2^3^2 = 2^(3^2)
                precedence -= 1;
            }
            // When we call this function we want to understand if the next number should be used here, or by another binary.
            // If it's used by another binary, the right here becomes the index to that binary.
            //
            // Read above to understand how this is determined.
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
    // The last binary, that we then use to recurse outward
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
        // Assumed that this number is going to be fast to find
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
// The interface is designed for `MIN_WIDTH` x `MIN_HEIGHT`. On bigger windows, everything gets multiplied by how much
// the window grew on the axis it grew the least, and the buttons stretch to take what's left on the other axis.
#add_context ui_scale: float = 1.0;
scaled :: (value: float) -> float {
    return value * context.ui_scale;
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
    // The ones that are neither a digit nor an operator, like the parenthesis
    FUNCTION;
    OPERATOR;
}
Button :: (style: Style, contents: string, is_pressed := false, kind := Button_Kind.DIGIT) -> clicked: bool {
    background, hover, pressed: Vector4;
    if #complete kind == {
        case .DIGIT;    background, hover, pressed = BG_TERTIARY, BG_HOVER, BG_PRESSED;
        case .FUNCTION; background, hover, pressed = FN, FN_HOVER, FN_PRESSED;
        case .OPERATOR; background, hover, pressed = OP, OP_HOVER, OP_PRESSED;
    }

    clicked := false;
    element(overwrite(Style.{
        border_radius   = scaled(6.0),
        background      = color(background),
        color           = ifx kind == .OPERATOR then OP_TEXT else VECTOR4_NAN,
        font_size       = scaled(24),
        x_justification = .CENTER,
        y_justification = .CENTER,
        width           = grow(),
        height          = grow(),
    }, style), #code {
        button := get_node();
        if is_mouse_inside() {
            button.style.background = color(hover);
        }
        clicked = on_click();
        if (is_mouse_held() && is_mouse_inside()) || is_pressed {
            button.style.background = color(pressed);
        }
        text(contents);
    });
    return clicked;
} @component

previous_word_boundary :: (glyphs: []Glyph, cursor: s64) -> s64 {
    // TO-DO: this is assuming the glyphs map 1:1 to the bytes
    c := cursor;
    while c > 0 && is_space(glyphs[c - 1].utf8.Encoded[0]) { c -= 1; }
    while c > 0 {
        c -= 1;
        if glyphs[c].starts_word break;
    }
    if c > 0 {
        return glyphs[c].index_into_original_text;
    } else {
        return 0;
    }
}
next_word_boundary :: (glyphs: []Glyph, cursor: s64) -> s64 {
    // TO-DO: this is assuming the glyphs map 1:1 to the bytes
    c := cursor;
    while c < glyphs.count && is_space(glyphs[c].utf8.Encoded[0]) { c += 1; }
    if c < glyphs.count c += 1;
    while c < glyphs.count && !glyphs[c].starts_word { c += 1; }
    if c < glyphs.count {
        return glyphs[c].index_into_original_text;
    } else if c > 0 {
        return peek(glyphs).index_into_original_text + peek(glyphs).utf8.EncodedLength;
    } else {
        return 0;
    }
}
use_glyph_closest_to :: (position: Vector2) -> s64 {
    using context.input;
    glyphs                    := get_node(text_node_index).glyphs;
    text_measurement, defined := get_measurement(text_node_index);
    cursor                    := -1;
    if defined {
        font_units_to_pixel := get_font_units_to_pixel(*context.inter, get_node(text_node_index).style.font_size);
        line_height         := glyphs.line_height * font_units_to_pixel;
        closest_distance    : float;
        for glyphs.array {
            left_edge := text_measurement.position.x + it.position.x * font_units_to_pixel;
            // TO-DO: to make this work with multiple lines, we will need to have the glyphs already wrapped here,
            // but then we will also need to find the closest line, to finally compare the x coordinates
            distance := Math.abs(left_edge - position.x);
            if it_index == 0 || distance < closest_distance {
                closest_distance = distance;
                cursor           = it.index_into_original_text;
            }
            if it_index == glyphs.array.count - 1 {
                right_edge := left_edge + it.advance.x * font_units_to_pixel;
                // TO-DO: to make this work with multiple lines, we will need to have the glyphs already wrapped here,
                // but then we will also need to find the closest line, to finally compare the x coordinates
                distance := Math.abs(right_edge - position.x);
                if distance < closest_distance {
                    closest_distance = distance;
                    cursor           = it.index_into_original_text + it.utf8.EncodedLength;
                }
            }
        }
    }
    return cursor;
} @hook
Selection :: (style: Style) {
    using context.input;
    using state;
    input_measurement, defined := get_measurement();
    if defined && selection_anchor != -1 {
        start := min(selection_anchor, cursor);
        end   := max(selection_anchor, cursor);

        text_node           := get_node(text_node_index);
        glyphs              := text_node.glyphs;
        font_size           := text_node.style.font_size;
        font_units_to_pixel := get_font_units_to_pixel(*context.inter, font_size);

        // TO-DO: this is assuming the glyphs map 1:1 to the bytes
        position: Vector2;
        if glyphs.array.count > 0 {
            if start == glyphs.array.count {
                position = (peek(glyphs.array).position + peek(glyphs.array).advance) * font_units_to_pixel;
            } else {
                position = glyphs.array[start].position * font_units_to_pixel;
            }
        }
        width: float;
        if glyphs.array.count > 0 {
            if end == glyphs.array.count then width = (peek(glyphs.array).position.x + peek(glyphs.array).advance.x) * font_units_to_pixel - position.x;
            else                              width = glyphs.array[end].position.x * font_units_to_pixel - position.x;
        }
        // TO-DO: support multiline content, because we're currently only comparing against there being no wrapping
        line_height      := glyphs.line_height * font_units_to_pixel;
        input            := get_node();
        inner_height     := input_measurement.size.y - input.style.padding.y.x - input.style.padding.y.y;
        position -= scrolling_state.effective_offset;
        position.x += input.style.padding.x.x;
        position.y += input.style.padding.y.x + (inner_height - line_height) / 2;
        element(overwrite(Style.{
            // TO-DO: we should pick the default selection color per operating system.
            // We can also query it by the operating system, which sounds like the ideal solution.
            background = color(hex("#3399FF")),
            // border_radius = 4.0,
            placement = relative(position),
            width = fixed(width),
            height = fixed(line_height),
        }, style));
    }
} @component
Input_Edit :: struct {
    // This is always the start of where the change is done
    where:                   s64;
    cursor_before:           s64;
    // There's never a selection after an edit
    selection_anchor_before: s64 = -1;
    deleted_length:          s64;
    inserted_length:         s64;
    deleted_index:           s64 = -1;
    inserted_index:          s64 = -1;
}
Input_State :: struct {
    value:            [..]u8;
    // Firstly used for deleted text, secondly for inserted text on the `undo_history`
    history_storage:  [..]u8;
    edit_history:     [..]Input_Edit;
    undo_history:     [..]Input_Edit;
    cursor:           s64;
    selection_anchor: s64            = -1;
}
use_input_state :: (initial_value := "", initial_cursor := 0, initial_selection_anchor := -1) -> *Input_State {
    input_state, first_frame := state(Input_State.{
        cursor           = initial_cursor,
        selection_anchor = initial_selection_anchor,
    });
    allocator := node_pool();

    using input_state;
    value.allocator = allocator;
    if first_frame && initial_value.count > 0 {
        initial_bytes: []u8 = ---;
        initial_bytes.data  = initial_value.data;
        initial_bytes.count = initial_value.count;
        array_add(*value, ..initial_bytes);
    }
    history_storage.allocator = allocator;
    edit_history.allocator   = allocator;
    undo_history.allocator   = allocator;
    return input_state;
}
array_insert_at :: (array: *[..]$T, insertion_index: s64, to_insert: []T) {
    assert(insertion_index >= 0);
    assert(insertion_index <= array.count);

    new_count := array.count + to_insert.count;
    if new_count > array.allocated {
        reserve := max(8, 2 * new_count);
        array_reserve(cast(*Resizable_Array) array, reserve, size_of(T));
    }
    array.count = new_count;

    i := array.count - 1;
    while i >= insertion_index + to_insert.count {
        (array.data + i).* = (array.data + i - to_insert.count).*;
        i -= 1;
    }

    for to_insert {
        (array.data + insertion_index + it_index).* = it;
    }
}
array_ordered_remove_interval :: (array: *[]$T, start: s64, count: s64) {
    assert(count > 0);
    assert(count <= array.count);
    assert(start < array.count);

    for i: start..array.count - count - 1 {
        array.*[i] = array.*[i + count];
    }
    array.count -= count;
}
Input_Context :: struct {
    state:            *Input_State;
    scrolling_state:        *Scrolling_State;
    text_node_index:        s64;
    input_character_filter: #type (input: u8) -> bool = null;
};
#add_context input: Input_Context;
delete :: (a: s64, b: s64) {
    using context.input;
    using state;
    start := min(a, b);
    end   := max(a, b);
    if end > start {
        array_add(*edit_history, .{
            where                   = start,
            cursor_before           = cursor,
            selection_anchor_before = selection_anchor,
            deleted_length          = end - start,
            deleted_index           = history_storage.count,
        });
        array_add(*history_storage, ..array_view(value, start, end - start));
        array_ordered_remove_interval(*value, start, end - start);
        array_reset_keeping_memory(*undo_history);
        cursor = start;
        scroll_to_cursor(context.input);
    }
    selection_anchor = -1;
}
append :: (a: s64, b: s64, input: string) {
    using context.input;
    using state;
    start := min(a, b);
    end   := max(a, b);
    edit := Input_Edit.{
        where                   = start,
        cursor_before           = cursor,
        selection_anchor_before = selection_anchor,
        deleted_length          = end - start,
    };
    for input {
        if input_character_filter == null || input_character_filter(it) {
            // This makes sure that we only remove the selection if there's at least one character to insert
            if edit.inserted_length == 0 && edit.deleted_length > 0 {
                edit.deleted_index = history_storage.count;
                array_add(*history_storage, ..array_view(value, start, edit.deleted_length));
                array_ordered_remove_interval(*value, start, edit.deleted_length);
            }
            array_insert_at(*value, it, start + edit.inserted_length);
            edit.inserted_length += 1;
        }
    }
    if edit.inserted_length > 0 {
        // TO-DO: this should try to concatenate the changes to the previous Input_Edit, instead of adding a new one.
        array_add(*edit_history, edit);
        array_reset_keeping_memory(*undo_history);
        cursor           = start + edit.inserted_length;
        scroll_to_cursor(context.input);
        selection_anchor = -1;
    }
}
scroll_to_cursor :: (input_context: Input_Context, animate := false) {
    using input_context;
    using state;
    text_node := get_node(text_node_index);
    // TO-DO: how can we have this handling multiline text? This problem of multiline text just becomes dramatically simple in the case
    // where the width of the text node is well-known, such as when it's fixed.
    glyphs              := shape_text(text_node.style, to_string(value.data));
    font_units_to_pixel := get_font_units_to_pixel(text_node.style.font, text_node.style.font_size);
    // TO-DO: this is assuming the glyphs map 1:1 to the bytes

    cursor_x: float;
    if cursor == glyphs.array.count {
        cursor_x = (peek(glyphs.array).position.x + peek(glyphs.array).advance.x) * font_units_to_pixel;
    } else {
        cursor_x = glyphs.array[cursor].position.x * font_units_to_pixel;
    }
    schedule_scroll(scrolling_state, Vector2.{ cursor_x, 0 }, animate);
}
// To make this hook thing generic for it to be builtin into forbear we need to:
// - handle multiline text
// - we should be moving the cursor by graphemes, not by glyphs
use_input :: () {
    using context.input.state;
    shift   := is_key_held(.SHIFT_LEFT)   || is_key_held(.SHIFT_RIGHT);
    ctrl    := is_key_held(.CONTROL_LEFT) || is_key_held(.CONTROL_RIGHT);
    alt     := is_key_held(.ALT_LEFT)     || is_key_held(.ALT_RIGHT);
    super   := is_key_held(.SUPER_LEFT)   || is_key_held(.SUPER_RIGHT);
    command := #ifx OS == .MACOS then super else ctrl;
    by_word := #ifx OS == .MACOS then alt   else ctrl;
    by_line := (#ifx OS == .MACOS then super else false) || on_key_down(.HOME) || on_key_down(.END);

    glyphs := get_node(context.input.text_node_index).glyphs;

    append(cursor, ifx selection_anchor == -1 then cursor else selection_anchor, get_text_input());

    {
        //
        // === keyboard deletion and cursor movement handling ===
        //
        left  := on_key_down(.ARROW_LEFT, true)  || on_key_down(.HOME);
        right := on_key_down(.ARROW_RIGHT, true) || on_key_down(.END);

        if (left || right) && !shift && selection_anchor != -1 {
            cursor = ifx left then min(cursor, selection_anchor) else max(cursor, selection_anchor);
        }

        previous := max(cursor - 1, 0);
        next     := min(cursor + 1, value.count);
        if by_word {
            previous = previous_word_boundary(glyphs.array, cursor);
            next     = next_word_boundary(glyphs.array, cursor);
        }
        if by_line {
            // TO-DO: to support multiline text here, we need this to go to the start of the current line,
            // not to the start of the entire piece of text.
            previous = 0;
            // TO-DO: to support multiline text here, we need this to go to the end of the current line,
            // not to the start of the entire piece of text.
            next = value.count;
        }

        if left || right {
            if shift && selection_anchor == -1                       then selection_anchor = cursor;
            if shift || by_word || by_line || selection_anchor == -1 then {
                cursor = ifx left then previous else next;
                scroll_to_cursor(context.input);
            }
            if !shift                                                then selection_anchor = -1;
        }

        if command && on_key_down(.A) {
            selection_anchor = 0;
            cursor           = value.count;
            scroll_to_cursor(context.input);
        }

        backspace := on_key_down(.BACKSPACE, on_repeat = true);
        if backspace || on_key_down(.DELETE, on_repeat = true) {
            if selection_anchor != -1 then delete(cursor, selection_anchor);
            else if backspace         then delete(previous, cursor);
            else                           delete(cursor, next);
        }
    }

    if command && on_key_down(.V, on_repeat = true) {
        append(cursor, ifx selection_anchor == -1 then cursor else selection_anchor, get_clipboard_text());
    }

    if command && on_key_down(.C) && selection_anchor != -1 && value.count > 0 {
        start := min(cursor, selection_anchor);
        end   := max(cursor, selection_anchor);
        copy_to_clipboard(to_string(value.data + start, end - start));
    }

    if command && on_key_down(.X) && selection_anchor != -1 && value.count > 0 {
        start := min(cursor, selection_anchor);
        end   := max(cursor, selection_anchor);
        copy_to_clipboard(to_string(value.data + start, end - start));
        delete(cursor, selection_anchor);
        selection_anchor = -1;
    }

    if command && !shift && on_key_down(.Z, on_repeat = true) && edit_history.count > 0 {
        edit := pop(*edit_history);
        if edit.inserted_length > 0 {
            if edit.inserted_index == -1 {
                edit.inserted_index = history_storage.count;
                array_add(*history_storage, ..array_view(value, edit.where, edit.inserted_length));
            }
            array_ordered_remove_interval(*value, edit.where, edit.inserted_length);
        }
        if edit.deleted_length > 0 {
            array_insert_at(*value, edit.where, array_view(history_storage, edit.deleted_index, edit.deleted_length));
        }
        cursor = edit.cursor_before;
        scroll_to_cursor(context.input);
        selection_anchor = edit.selection_anchor_before;
        array_add(*undo_history, edit);
    }
    if command && shift && on_key_down(.Z, on_repeat = true) && undo_history.count > 0 {
        edit := pop(*undo_history);
        if edit.deleted_length > 0 {
            array_ordered_remove_interval(*value, edit.where, edit.deleted_length);
        }
        if edit.inserted_length > 0 {
            array_insert_at(*value, edit.where, array_view(history_storage, edit.inserted_index, edit.inserted_length));
        }
        cursor = edit.where + edit.inserted_length;
        scroll_to_cursor(context.input);
        selection_anchor = -1;
        array_add(*edit_history, edit);
    }

    dragging            := is_dragging(.LEFT);
    dragging_last_frame := state(false);
    if dragging {
        if !dragging_last_frame.* then selection_anchor = use_glyph_closest_to(get_press_position());
        mouse_glyph := use_glyph_closest_to(get_mouse_position());
        if mouse_glyph != -1 {
            cursor = mouse_glyph;
            scroll_to_cursor(context.input, animate = true);
        }
    }
    dragging_last_frame.* = dragging;
    if on_click() {
        mouse_glyph := use_glyph_closest_to(get_mouse_position());
        if !shift                          then selection_anchor = -1;
        else if selection_anchor == -1     then selection_anchor = cursor;
        if mouse_glyph != -1               {
            cursor = mouse_glyph;
            scroll_to_cursor(context.input, animate = true);
        }
    }
    if cursor < 0 || cursor > value.count {
        cursor = clamp(cursor, 0, value.count);
        scroll_to_cursor(context.input);
    }
    if selection_anchor > value.count then selection_anchor = value.count;
    if on_key_down(.ESCAPE) || (selection_anchor == cursor && !dragging) then selection_anchor = -1;
} @hook
Caret :: (style: Style) {
    using context.input;
    using state;
    input_measurement, defined := get_measurement();
    if defined {
        text_node           := get_node(text_node_index);
        glyphs              := text_node.glyphs;
        font_size           := text_node.style.font_size;
        font_units_to_pixel := get_font_units_to_pixel(*context.inter, font_size);

        caret_position: Vector2;
        if value.count > 0 && glyphs.array.count > 0 {
            if cursor == value.count {
                caret_position = (peek(glyphs.array).position + peek(glyphs.array).advance) * font_units_to_pixel;
            } else {
                // TO-DO: this is assuming the glyphs map 1:1 to the bytes
                caret_position = glyphs.array[cursor].position * font_units_to_pixel;
            }
        }
        // TO-DO: support multiline inputs, because we're currently only comparing against there being no wrapping in the input
        line_height      := glyphs.line_height * font_units_to_pixel;
        input            := get_node();
        inner_height     := input_measurement.size.y - input.style.padding.y.x - input.style.padding.y.y;
        caret_position.x -= scrolling_state.effective_offset.x;
        caret_position.x += input.style.padding.x.x;
        caret_position.y += input.style.padding.y.x + (inner_height - line_height) / 2;

        // TO-DO: while typing, this blinking timer should reset
        blinking := cast(s64)Math.floor(seconds_since_init() * 2) % 2 != 1;

        element(overwrite(Style.{
            placement  = relative(caret_position),
            background = ifx blinking then
                color(hex("#FFFFFF"))
            else
                color(TRANSPARENT),
            width  = fixed(scaled(1.0)),
            height = fixed(line_height),
        }, style));
    }
} @component
Input :: (input_state: *Input_State, body: Code) -> Input_Context #expand {
    viewport        := get_viewport_size();
    scrolling_state := state(Scrolling_State);
    input_context := Input_Context.{
        state                  = input_state,
        scrolling_state        = scrolling_state,
        input_character_filter = (input: u8) -> bool {
            // Since we're not really using any complicated UTF8, but rather only ASCII input as there are only numbers
            // and operators, we can simply remove by index as all characters are only going to be one byte.
            if is_digit(input) || is_operator(input) || is_any(input, " .()") {
                return true;
            } else {
                log("ignoring input character %, since it's not in the ones we defined as supporting", input);
                return false;
            }
        },
    };
    context.input = input_context;
    element(Style.{
        background      = color(BG),
        padding         = in_line(bottom(top(scaled(10)), scaled(30)), scaled(5)),
        direction       = .VERTICAL,
        text_wrapping   = .NONE,
        y_justification = .CENTER,
        font_size       = scaled(DIGITS_SIZE),
        width           = fixed(viewport.x),
        children_offset = -scrolling_state.effective_offset,
    }, #code {
        context.input.text_node_index = text(Style.{ z_index = 2, },
                                             to_string(input_state.value.data, input_state.value.count));
        Selection(Style.{});
        Caret(Style.{});
        use_scrolling(scrolling_state);
        // TO-DO: as the user types, this should scroll following the cursor
        use_input();

        #insert body;
    });
    return input_context;
} @component

reverse_number_sign :: () -> changed: bool {
    using context.input.state;
    start := value.count;
    while start > 0 && (is_digit(value[start - 1]) || value[start - 1] == #char ".") {
        start -= 1;
    }
    changed := start < value.count;
    if changed {
        before_minus := start - 2;
        while before_minus >= 0 && value[before_minus] == #char " " {
            before_minus -= 1;
        }
        is_sign :=
               start > 0
            && value[start - 1] == #char "-"
            && (before_minus < 0 || !(is_digit(value[before_minus]) || is_any(value[before_minus], ".)")));
        if is_sign then delete(start - 1, start);
        else            append(start, start, "-");
    }
    return changed;
}
// Removes what was last added by one of the buttons. The operator buttons surround the operator with spaces, so
// those go away together with the operator.
remove_last :: () {
    using context.input.state;
    start := value.count;
    while start > 0 && value[start - 1] == #char " " {
        start -= 1;
    }
    if start > 0 {
        start -= 1;
        if is_operator(value[start]) {
            while start > 0 && value[start - 1] == #char " " {
                start -= 1;
            }
        }
    }
    delete(start, value.count);
}

App :: () {
    window   := context.forbear.window;
    viewport := get_viewport_size();
    // The lower bound keeps font sizes sane on a degenerate viewport, like the one of a minimized window
    context.ui_scale    = max(min(viewport.x / MIN_WIDTH, viewport.y / MIN_HEIGHT), 0.5);

    evaluation_success := state(false);
    result             := state(float64);

    input_state        := use_input_state();

    element(Style.{
        direction  = .VERTICAL,
        background = color(BG_SECONDARY),
        width      = fixed(viewport.x),
        height     = fixed(viewport.y),
    }, #code {
        input_context := Input(input_state, #code {
            nodes: [..]Expression_Node;
            evaluation_success.* = parse_expression(to_string(input_state.value.data, input_state.value.count), *nodes) == .OK;
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

        Row :: (body: Code) #expand {
            element(Style.{width = grow(), height = grow()}, body);
        } @component
        column_style :: (span := 1.0) -> Style {
            return Style.{width = grow(span), height = grow(), margin = all(scaled(BUTTON_GAP / 2))};
        }
        element(Style.{
            direction       = .VERTICAL,
            // The other half, so that the buttons are also a full gap away from the edges
            padding         = all(scaled(BUTTON_GAP / 2)),
            width           = grow(),
            height          = grow(),
        }, #code {
            using input_state;
            Row(#code {
                if Button(column_style(2.0), "C", kind = .FUNCTION) {
                    delete(0, value.count);
                    // There's nothing to evaluate anymore, and the result is only updated when the evaluation succeeds
                    result.* = 0;
                }
                if Button(column_style(2.0), "⌫", is_pressed = is_key_held(Key.BACKSPACE), kind = .FUNCTION) {
                    remove_last();
                }
            });
            Row(#code {
                if Button(column_style(), "(", is_pressed = is_key_held(Key.PARENTHESIS_LEFT), kind = .FUNCTION) {
                    append(value.count, value.count, "(");
                }
                if Button(column_style(), ")", is_pressed = is_key_held(Key.PARENTHESIS_RIGHT), kind = .FUNCTION) {
                    append(value.count, value.count, ")");
                }
                if Button(column_style(), "+/-", kind = .FUNCTION) {
                    if reverse_number_sign() {
                        cursor = value.count;
                        scroll_to_cursor(input_context);
                    }
                }
                if Button(column_style(), "^", is_pressed = is_key_held(Key.CARET), kind = .OPERATOR) {
                    append(value.count, value.count, " ^ ");
                }
            });
            Row(#code {
                if Button(column_style(), "7", is_pressed = is_key_held(Key.DIGIT_7)) {
                    append(value.count, value.count, "7");
                }
                if Button(column_style(), "8", is_pressed = is_key_held(Key.DIGIT_8)) {
                    append(value.count, value.count, "8");
                }
                if Button(column_style(), "9", is_pressed = is_key_held(Key.DIGIT_9)) {
                    append(value.count, value.count, "9");
                }
                if Button(column_style(), "÷", is_pressed = is_key_held(Key.PLUS), kind = .OPERATOR) {
                    append(value.count, value.count, " / ");
                }
            });
            Row(#code {
                if Button(column_style(), "4", is_pressed = is_key_held(Key.DIGIT_4)) {
                    append(value.count, value.count, "4");
                }
                if Button(column_style(), "5", is_pressed = is_key_held(Key.DIGIT_5)) {
                    append(value.count, value.count, "5");
                }
                if Button(column_style(), "6", is_pressed = is_key_held(Key.DIGIT_6)) {
                    append(value.count, value.count, "6");
                }
                if Button(column_style(), "×",   is_pressed = is_key_held(Key.X)
                                              || is_key_held(Key.ASTERISK), kind = .OPERATOR) {
                    append(value.count, value.count, " * ");
                }
            });
            Row(#code {
                if Button(column_style(), "1", is_pressed = is_key_held(Key.DIGIT_1)) {
                    append(value.count, value.count, "1");
                }
                if Button(column_style(), "2", is_pressed = is_key_held(Key.DIGIT_2)) {
                    append(value.count, value.count, "2");
                }
                if Button(column_style(), "3", is_pressed = is_key_held(Key.DIGIT_3)) {
                    append(value.count, value.count, "3");
                }
                if Button(column_style(), "+", is_pressed = is_key_held(Key.PLUS), kind = .OPERATOR) {
                    append(value.count, value.count, " + ");
                }
            });
            Row(#code {
                Row(#code {
                    if Button(column_style(), "0", is_pressed = is_key_held(Key.DIGIT_0)) {
                        append(value.count, value.count, "0");
                    }
                });
                Row(#code {
                    if Button(column_style(), ".", is_pressed = is_key_held(Key.PERIOD)) {
                        append(value.count, value.count, ".");
                    }
                    if Button(column_style(), "-", is_pressed = is_key_held(Key.MINUS), kind = .OPERATOR) {
                        append(value.count, value.count, " - ");
                    }
                });
            });
        });

        if on_key_down(.ENTER) {
            stringified_result := tprint("%", result.*);
            append(0, input_state.value.count, stringified_result);
            input_state.cursor = 0;
            scroll_to_cursor(input_context);

            copy_to_clipboard(stringified_result);
        }
    });
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
    // TO-DO: we should add a native function to handle this minimum size thing
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
        font           = *context.inter,
        color          = hex("#ECECEC"),
        font_size      = 16,
        language       = .ENGLISH,
        text_direction = .LEFT_TO_RIGHT
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
