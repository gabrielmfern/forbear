#import "Basic";
Math :: #import "Math";
#import "File";
#import "forbear";
Main :: #import,file "./main.jai";

BUILD_FLAGS :: "+forbear";

test :: (name: string, body: Code) #expand {
    print("TEST %\n", name);
    #insert body;
    print("PASS\n");
}

assert_nodes :: (expected: []Main.Expression_Node, loc := #caller_location) #expand {
    assert(`nodes.count == expected.count, "nodes.count=%, expected %", `nodes.count, expected.count, loc = loc);
    for expected {
        node := `nodes[it_index];
        assert(node.kind == it.kind, "nodes[%].kind=%, expected %", it_index, node.kind, it.kind, loc = loc);
        if #complete it.kind == {
            case .NUMBER;
                assert(node.number == it.number, "nodes[%].number=%, expected %", it_index, node.number, it.number, loc = loc);
            case .OPEARTOR;
                assert(node.op == it.op, "nodes[%].op=%, expected %", it_index, node.op, it.op, loc = loc);
            case .BINARY;
                assert(
                    node.binary.left == it.binary.left && node.binary.op == it.binary.op && node.binary.right == it.binary.right,
                    "nodes[%].binary=%, expected %", it_index, node.binary, it.binary, loc = loc
                );
        }
    }
}

// Math.pow is not exact, even for whole numbers, so anything going through it can't be compared with ==
is_close :: (a: float64, b: float64) -> bool {
    difference := Math.abs(a - b);
    return difference < 0.00001;
}

main :: () {
    test("parse_expression", #code {
        nodes: [..]Main.Expression_Node;
        result: Main.Parse_Result;

        {
            result = Main.parse_expression("1", *nodes);
            assert(result == .OK);
            assert_nodes(.[
                .{kind = .NUMBER, number = 1},
            ]);

            evaluated, success := Main.evaluate(nodes);
            assert(success == true, "evaluation should succeed");
            assert(evaluated == 1.0, "evaluated=%", evaluated);

            array_reset_keeping_memory(*nodes);
        }

        {
            result = Main.parse_expression("1+2", *nodes);
            assert(result == .OK);
            assert_nodes(.[
                .{kind = .NUMBER,   number = 1},
                .{kind = .OPEARTOR, op = .ADD},
                .{kind = .NUMBER,   number = 2},
                .{kind = .BINARY,   binary = .{left = 0, op = 1, right = 2}},
            ]);

            evaluated, success := Main.evaluate(nodes);
            assert(success == true, "evaluation should succeed");
            assert(evaluated == 3.0, "evaluated=%", evaluated);

            array_reset_keeping_memory(*nodes);
        }

        {
            result = Main.parse_expression("1+2*3", *nodes);
            assert(result == .OK);
            assert_nodes(.[
                .{kind = .NUMBER,   number = 1},
                .{kind = .OPEARTOR, op = .ADD},
                .{kind = .NUMBER,   number = 2},
                .{kind = .OPEARTOR, op = .MULTIPLY},
                .{kind = .NUMBER,   number = 3},
                .{kind = .BINARY,   binary = .{left = 2, op = 3, right = 4}},
                .{kind = .BINARY,   binary = .{left = 0, op = 1, right = 5}},
            ]);

            evaluated, success := Main.evaluate(nodes);
            assert(success == true, "evaluation should succeed");
            assert(evaluated == 7.0, "evaluated=%", evaluated);

            array_reset_keeping_memory(*nodes);
        }

        {
            result = Main.parse_expression("1+2*3-7", *nodes);
            assert(result == .OK);
            assert_nodes(.[
                .{kind = .NUMBER,   number = 1},
                .{kind = .OPEARTOR, op     = .ADD},
                .{kind = .NUMBER,   number = 2},
                .{kind = .OPEARTOR, op     = .MULTIPLY},
                .{kind = .NUMBER,   number = 3},
                .{kind = .BINARY,   binary = .{left = 2, op = 3, right = 4}},
                .{kind = .BINARY,   binary = .{left = 0, op = 1, right = 5}},
                .{kind = .OPEARTOR, op     = .SUBTRACT},
                .{kind = .NUMBER,   number = 7},
                .{kind = .BINARY,   binary = .{left = 6, op = 7, right = 8}},
            ]);

            evaluated, success := Main.evaluate(nodes);
            assert(success == true, "evaluation should succeed");
            assert(evaluated == 0.0, "evaluated=%", evaluated);

            array_reset_keeping_memory(*nodes);
        }

        {
            result = Main.parse_expression("2^3", *nodes);
            assert(result == .OK);
            assert_nodes(.[
                .{kind = .NUMBER,   number = 2},
                .{kind = .OPEARTOR, op     = .EXPONENTIATE},
                .{kind = .NUMBER,   number = 3},
                .{kind = .BINARY,   binary = .{left = 0, op = 1, right = 2}},
            ]);

            evaluated, success := Main.evaluate(nodes);
            assert(success == true, "evaluation should succeed");
            assert(is_close(evaluated, 8.0), "evaluated=%", evaluated);

            array_reset_keeping_memory(*nodes);
        }

        {
            // right associative: 2^(3^2), not (2^3)^2
            result = Main.parse_expression("2^3^2", *nodes);
            assert(result == .OK);
            assert_nodes(.[
                .{kind = .NUMBER,   number = 2},
                .{kind = .OPEARTOR, op     = .EXPONENTIATE},
                .{kind = .NUMBER,   number = 3},
                .{kind = .OPEARTOR, op     = .EXPONENTIATE},
                .{kind = .NUMBER,   number = 2},
                .{kind = .BINARY,   binary = .{left = 2, op = 3, right = 4}},
                .{kind = .BINARY,   binary = .{left = 0, op = 1, right = 5}},
            ]);

            evaluated, success := Main.evaluate(nodes);
            assert(success == true, "evaluation should succeed");
            assert(is_close(evaluated, 512.0), "evaluated=%", evaluated);

            array_reset_keeping_memory(*nodes);
        }

        {
            // binds tighter than the multiplication on its left
            result = Main.parse_expression("2*3^2", *nodes);
            assert(result == .OK);
            assert_nodes(.[
                .{kind = .NUMBER,   number = 2},
                .{kind = .OPEARTOR, op     = .MULTIPLY},
                .{kind = .NUMBER,   number = 3},
                .{kind = .OPEARTOR, op     = .EXPONENTIATE},
                .{kind = .NUMBER,   number = 2},
                .{kind = .BINARY,   binary = .{left = 2, op = 3, right = 4}},
                .{kind = .BINARY,   binary = .{left = 0, op = 1, right = 5}},
            ]);

            evaluated, success := Main.evaluate(nodes);
            assert(success == true, "evaluation should succeed");
            assert(is_close(evaluated, 18.0), "evaluated=%", evaluated);

            array_reset_keeping_memory(*nodes);
        }

        {
            // being right associative must not make it swallow the multiplication on its right
            result = Main.parse_expression("2^3*4", *nodes);
            assert(result == .OK);
            assert_nodes(.[
                .{kind = .NUMBER,   number = 2},
                .{kind = .OPEARTOR, op     = .EXPONENTIATE},
                .{kind = .NUMBER,   number = 3},
                .{kind = .BINARY,   binary = .{left = 0, op = 1, right = 2}},
                .{kind = .OPEARTOR, op     = .MULTIPLY},
                .{kind = .NUMBER,   number = 4},
                .{kind = .BINARY,   binary = .{left = 3, op = 4, right = 5}},
            ]);

            evaluated, success := Main.evaluate(nodes);
            assert(success == true, "evaluation should succeed");
            assert(is_close(evaluated, 32.0), "evaluated=%", evaluated);

            array_reset_keeping_memory(*nodes);
        }

        {
            // parenthesis override the right associativity
            result = Main.parse_expression("(2^3)^2", *nodes);
            assert(result == .OK);
            assert_nodes(.[
                .{kind = .NUMBER,   number = 2},
                .{kind = .OPEARTOR, op     = .EXPONENTIATE},
                .{kind = .NUMBER,   number = 3},
                .{kind = .BINARY,   binary = .{left = 0, op = 1, right = 2}},
                .{kind = .OPEARTOR, op     = .EXPONENTIATE},
                .{kind = .NUMBER,   number = 2},
                .{kind = .BINARY,   binary = .{left = 3, op = 4, right = 5}},
            ]);

            evaluated, success := Main.evaluate(nodes);
            assert(success == true, "evaluation should succeed");
            assert(is_close(evaluated, 64.0), "evaluated=%", evaluated);

            array_reset_keeping_memory(*nodes);
        }

        {
            // parenthesis leave no node behind, what was inside is used directly as the operand
            result = Main.parse_expression("(1)", *nodes);
            assert(result == .OK);
            assert_nodes(.[
                .{kind = .NUMBER, number = 1},
            ]);

            evaluated, success := Main.evaluate(nodes);
            assert(success == true, "evaluation should succeed");
            assert(evaluated == 1.0, "evaluated=%", evaluated);

            array_reset_keeping_memory(*nodes);
        }

        {
            // the multiplication can't reach inside the parenthesis for the 2
            result = Main.parse_expression("(1+2)*3", *nodes);
            assert(result == .OK);
            assert_nodes(.[
                .{kind = .NUMBER,   number = 1},
                .{kind = .OPEARTOR, op     = .ADD},
                .{kind = .NUMBER,   number = 2},
                .{kind = .BINARY,   binary = .{left = 0, op = 1, right = 2}},
                .{kind = .OPEARTOR, op     = .MULTIPLY},
                .{kind = .NUMBER,   number = 3},
                .{kind = .BINARY,   binary = .{left = 3, op = 4, right = 5}},
            ]);

            evaluated, success := Main.evaluate(nodes);
            assert(success == true, "evaluation should succeed");
            assert(evaluated == 9.0, "evaluated=%", evaluated);

            array_reset_keeping_memory(*nodes);
        }

        {
            // precedence starts over inside the parenthesis, so the addition is taken even while in the right of a multiplication
            result = Main.parse_expression("2*(3+4)", *nodes);
            assert(result == .OK);
            assert_nodes(.[
                .{kind = .NUMBER,   number = 2},
                .{kind = .OPEARTOR, op     = .MULTIPLY},
                .{kind = .NUMBER,   number = 3},
                .{kind = .OPEARTOR, op     = .ADD},
                .{kind = .NUMBER,   number = 4},
                .{kind = .BINARY,   binary = .{left = 2, op = 3, right = 4}},
                .{kind = .BINARY,   binary = .{left = 0, op = 1, right = 5}},
            ]);

            evaluated, success := Main.evaluate(nodes);
            assert(success == true, "evaluation should succeed");
            assert(evaluated == 14.0, "evaluated=%", evaluated);

            array_reset_keeping_memory(*nodes);
        }

        {
            result = Main.parse_expression("2*(3+(4-1))", *nodes);
            assert(result == .OK);
            assert_nodes(.[
                .{kind = .NUMBER,   number = 2},
                .{kind = .OPEARTOR, op     = .MULTIPLY},
                .{kind = .NUMBER,   number = 3},
                .{kind = .OPEARTOR, op     = .ADD},
                .{kind = .NUMBER,   number = 4},
                .{kind = .OPEARTOR, op     = .SUBTRACT},
                .{kind = .NUMBER,   number = 1},
                .{kind = .BINARY,   binary = .{left = 4, op = 5, right = 6}},
                .{kind = .BINARY,   binary = .{left = 2, op = 3, right = 7}},
                .{kind = .BINARY,   binary = .{left = 0, op = 1, right = 8}},
            ]);

            evaluated, success := Main.evaluate(nodes);
            assert(success == true, "evaluation should succeed");
            assert(evaluated == 12.0, "evaluated=%", evaluated);

            array_reset_keeping_memory(*nodes);
        }

        {
            result = Main.parse_expression(" ( 1 + 2 ) * 3 ", *nodes);
            assert(result == .OK);
            assert_nodes(.[
                .{kind = .NUMBER,   number = 1},
                .{kind = .OPEARTOR, op     = .ADD},
                .{kind = .NUMBER,   number = 2},
                .{kind = .BINARY,   binary = .{left = 0, op = 1, right = 2}},
                .{kind = .OPEARTOR, op     = .MULTIPLY},
                .{kind = .NUMBER,   number = 3},
                .{kind = .BINARY,   binary = .{left = 3, op = 4, right = 5}},
            ]);

            evaluated, success := Main.evaluate(nodes);
            assert(success == true, "evaluation should succeed");
            assert(evaluated == 9.0, "evaluated=%", evaluated);

            array_reset_keeping_memory(*nodes);
        }

        {
            result = Main.parse_expression("(1+2", *nodes);
            assert(result == .EXPECTED_A_CLOSING_PARENTHESIS, "result=%", result);
            array_reset_keeping_memory(*nodes);

            // a closing parenthesis that was never opened
            result = Main.parse_expression("1+2)", *nodes);
            assert(result == .EXPECTED_A_OPERATOR, "result=%", result);
            array_reset_keeping_memory(*nodes);

            result = Main.parse_expression("()", *nodes);
            assert(result == .EXPECTED_A_NUMBER, "result=%", result);
            array_reset_keeping_memory(*nodes);

            // there is no implicit multiplication
            result = Main.parse_expression("2(3)", *nodes);
            assert(result == .EXPECTED_A_OPERATOR, "result=%", result);
            array_reset_keeping_memory(*nodes);
        }

        {
            result = Main.parse_expression("1.5", *nodes);
            assert(result == .OK);
            assert_nodes(.[
                .{kind = .NUMBER, number = 1.5},
            ]);

            evaluated, success := Main.evaluate(nodes);
            assert(success == true, "evaluation should succeed");
            assert(evaluated == 1.5, "evaluated=%", evaluated);

            array_reset_keeping_memory(*nodes);
        }

        {
            result = Main.parse_expression("1.5+2.25", *nodes);
            assert(result == .OK);
            assert_nodes(.[
                .{kind = .NUMBER,   number = 1.5},
                .{kind = .OPEARTOR, op     = .ADD},
                .{kind = .NUMBER,   number = 2.25},
                .{kind = .BINARY,   binary = .{left = 0, op = 1, right = 2}},
            ]);

            evaluated, success := Main.evaluate(nodes);
            assert(success == true, "evaluation should succeed");
            assert(evaluated == 3.75, "evaluated=%", evaluated);

            array_reset_keeping_memory(*nodes);
        }

        {
            // more than one digit on the whole part, and a whole number mixed with a decimal one
            result = Main.parse_expression("10.5/4", *nodes);
            assert(result == .OK);
            assert_nodes(.[
                .{kind = .NUMBER,   number = 10.5},
                .{kind = .OPEARTOR, op     = .DIVIDE},
                .{kind = .NUMBER,   number = 4},
                .{kind = .BINARY,   binary = .{left = 0, op = 1, right = 2}},
            ]);

            evaluated, success := Main.evaluate(nodes);
            assert(success == true, "evaluation should succeed");
            assert(evaluated == 2.625, "evaluated=%", evaluated);

            array_reset_keeping_memory(*nodes);
        }

        {
            result = Main.parse_expression("0.5*(1.5+2.5)", *nodes);
            assert(result == .OK);
            assert_nodes(.[
                .{kind = .NUMBER,   number = 0.5},
                .{kind = .OPEARTOR, op     = .MULTIPLY},
                .{kind = .NUMBER,   number = 1.5},
                .{kind = .OPEARTOR, op     = .ADD},
                .{kind = .NUMBER,   number = 2.5},
                .{kind = .BINARY,   binary = .{left = 2, op = 3, right = 4}},
                .{kind = .BINARY,   binary = .{left = 0, op = 1, right = 5}},
            ]);

            evaluated, success := Main.evaluate(nodes);
            assert(success == true, "evaluation should succeed");
            assert(evaluated == 2.0, "evaluated=%", evaluated);

            array_reset_keeping_memory(*nodes);
        }

        {
            // the decimals are still being typed
            result = Main.parse_expression("1.", *nodes);
            assert(result == .OK);
            assert_nodes(.[
                .{kind = .NUMBER, number = 1},
            ]);

            evaluated, success := Main.evaluate(nodes);
            assert(success == true, "evaluation should succeed");
            assert(evaluated == 1.0, "evaluated=%", evaluated);

            array_reset_keeping_memory(*nodes);
        }

        {
            // a number can't have spaces in the middle of it
            result = Main.parse_expression("1 . 5", *nodes);
            assert(result == .EXPECTED_A_OPERATOR, "result=%", result);
            array_reset_keeping_memory(*nodes);
        }

        {
            result = Main.parse_expression("1.2.3", *nodes);
            assert(result == .TOO_MANY_PERIODS, "result=%", result);
            array_reset_keeping_memory(*nodes);

            result = Main.parse_expression("1..2", *nodes);
            assert(result == .TOO_MANY_PERIODS, "result=%", result);
            array_reset_keeping_memory(*nodes);

            // the failure is not lost when the number is in the right of a binary, or inside parenthesis
            result = Main.parse_expression("1+2.5.2", *nodes);
            assert(result == .TOO_MANY_PERIODS, "result=%", result);
            array_reset_keeping_memory(*nodes);

            result = Main.parse_expression("(1.5.2+1)*3", *nodes);
            assert(result == .TOO_MANY_PERIODS, "result=%", result);
            array_reset_keeping_memory(*nodes);
        }

        {
            Case :: struct { expression: string; expected: float64; }
            for Case.[
                .{"-5", -5},
                .{"12+-34", -22},
                .{"12-34", -22},
                .{"12--34", 46},
                .{"12 - -34", 46},
                .{"2*-3", -6},
                .{"-1.5+1", -0.5},
                .{"(-2)^2", 4},
            ] {
                result = Main.parse_expression(it.expression, *nodes);
                assert(result == .OK, "parse_expression(\"%\")=%", it.expression, result);
                evaluated, success := Main.evaluate(nodes);
                assert(success && is_close(evaluated, it.expected), "evaluate(\"%\")=%, expected %", it.expression, evaluated, it.expected);
                array_reset_keeping_memory(*nodes);
            }

            for string.["-", "1+-", "- 1", "-(1)"] {
                result = Main.parse_expression(it, *nodes);
                assert(result == .EXPECTED_A_NUMBER, "parse_expression(\"%\")=%", it, result);
                array_reset_keeping_memory(*nodes);
            }
        }
    });

    test("reverse_number_sign", #code {
        Case :: struct { text: string; expected: string; }
        for Case.[
            .{"", ""},
            .{"5", "-5"},
            .{"123", "-123"},
            .{"-123", "123"},
            .{"1.5", "-1.5"},
            .{"12+3", "12+-3"},
            .{"12+34", "12+-34"},
            .{"12-34", "12--34"},
            .{"12 - 34", "12 - -34"},
            .{"12 + -34", "12 + 34"},
            .{"(1)-2", "(1)--2"},
            .{"(-2", "(2"},
            .{"-", "-"},
            .{"123-", "123-"},
            .{"123 -", "123 -"},
            .{"12 +", "12 +"},
        ] {
            text: [..]u8;
            array_add(*text, ..cast([]u8) it.text);
            changed := Main.reverse_number_sign(*text);
            assert(to_string(text.data, text.count) == it.expected, "reverse_number_sign(\"%\")=\"%\", expected \"%\"", it.text, to_string(text.data, text.count), it.expected);
            assert(changed == (it.text != it.expected), "reverse_number_sign(\"%\") changed=%", it.text, changed);

            Main.reverse_number_sign(*text);
            assert(to_string(text.data, text.count) == it.text, "reversing \"%\" twice gave \"%\"", it.text, to_string(text.data, text.count));
        }
    });

    test("use_input", #code {
        backend: Backend;
        window:  Window;
        forbear: Forbear;
        init_backend(*backend);
        init_window(*backend, *window, Main.MIN_WIDTH, Main.MIN_HEIGHT, "calculator tests", show_window = false);
        context.inter = #run create_font(read_entire_file(tprint("%../../Inter.ttf", #filepath)));
        init_forbear(*forbear, *window, *backend, Base_Style.{
            font      = *context.inter,
            color     = hex("#ECECEC"),
            font_size = 16,
        });
        init_font(*context.inter);
        window.keyboard_state.simulated = true;
        window.mouse_state.inside       = true;

        COMMAND :: #ifx OS == .MACOS then Key.SUPER_LEFT else Key.CONTROL_LEFT;
        WORD    :: #ifx OS == .MACOS then Key.ALT_LEFT   else Key.CONTROL_LEFT;

        Mouse :: enum { NONE; PRESS; HOLD; RELEASE; };
        Step :: struct {
            text:           string;
            key:            Key;
            held:           []Key;
            paste:          string;
            mouse:          Mouse;
            mouse_at_glyph: float;
        }
        Case :: struct {
            name:            string;
            contents:        string;
            cursor:          s64;
            anchor:          s64 = -1;
            steps:           []Step;
            expected:        string;
            expected_cursor: s64;
            expected_anchor: s64 = -1;
        }
        for Case.[
            .{name = "typing over a selection replaces it",
              contents = "12345", cursor = 3, anchor = 1, steps = .[.{text = "9"}],
              expected = "1945", expected_cursor = 2},
            .{name = "typing only rejected characters keeps the selection",
              contents = "12345", cursor = 3, anchor = 1, steps = .[.{text = "a"}],
              expected = "12345", expected_cursor = 3, expected_anchor = 1},
            .{name = "typing in the middle skips rejected characters",
              contents = "125", cursor = 2, steps = .[.{text = "3a4"}],
              expected = "12345", expected_cursor = 4},
            .{name = "pasting in the middle inserts",
              contents = "125", cursor = 2, steps = .[.{key = .V, held = .[COMMAND], paste = "34"}],
              expected = "12345", expected_cursor = 4},
            .{name = "backspace removes the selection",
              contents = "12345", cursor = 1, anchor = 4, steps = .[.{key = .BACKSPACE}],
              expected = "15", expected_cursor = 1},
            .{name = "backspace removes the character before the cursor",
              contents = "12345", cursor = 3, steps = .[.{key = .BACKSPACE}],
              expected = "1245", expected_cursor = 2},
            .{name = "delete removes the character after the cursor",
              contents = "12345", cursor = 3, steps = .[.{key = .DELETE}],
              expected = "1235", expected_cursor = 3},
            .{name = "backspace by word removes the last number",
              contents = "12 + 34", cursor = 7, steps = .[.{key = .BACKSPACE, held = .[WORD]}],
              expected = "12 + ", expected_cursor = 5},
            .{name = "shift left then shift right leaves no selection",
              contents = "12345", cursor = 3,
              steps = .[.{key = .ARROW_LEFT, held = .[.SHIFT_LEFT]}, .{key = .ARROW_RIGHT, held = .[.SHIFT_LEFT]}, .{key = .BACKSPACE}],
              expected = "1245", expected_cursor = 2},
            .{name = "select all on an empty input leaves no selection",
              contents = "", cursor = 0, steps = .[.{key = .A, held = .[COMMAND]}, .{text = "1"}],
              expected = "1", expected_cursor = 1},
            .{name = "select all",
              contents = "12345", cursor = 2, steps = .[.{key = .A, held = .[COMMAND]}],
              expected = "12345", expected_cursor = 5, expected_anchor = 0},
            .{name = "left on a selection goes to its start",
              contents = "12345", cursor = 4, anchor = 1, steps = .[.{key = .ARROW_LEFT}],
              expected = "12345", expected_cursor = 1},
            .{name = "right on a selection goes to its end",
              contents = "12345", cursor = 1, anchor = 4, steps = .[.{key = .ARROW_RIGHT}],
              expected = "12345", expected_cursor = 4},
            .{name = "left by word on a selection starts from its start",
              contents = "12 + 34 - 56", cursor = 11, anchor = 6, steps = .[.{key = .ARROW_LEFT, held = .[WORD]}],
              expected = "12 + 34 - 56", expected_cursor = 5},
            .{name = "right by word on a selection starts from its end",
              contents = "12 + 34 - 56", cursor = 0, anchor = 6, steps = .[.{key = .ARROW_RIGHT, held = .[WORD]}],
              expected = "12 + 34 - 56", expected_cursor = 7},
            .{name = "shift right extends the selection",
              contents = "12345", cursor = 1,
              steps = .[.{key = .ARROW_RIGHT, held = .[.SHIFT_LEFT]}, .{key = .ARROW_RIGHT, held = .[.SHIFT_LEFT]}],
              expected = "12345", expected_cursor = 3, expected_anchor = 1},
            .{name = "shift home selects up to the start",
              contents = "12345", cursor = 3, steps = .[.{key = .HOME, held = .[.SHIFT_LEFT]}],
              expected = "12345", expected_cursor = 0, expected_anchor = 3},
            .{name = "end on a selection goes to the end and clears it",
              contents = "12345", cursor = 1, anchor = 3, steps = .[.{key = .END}],
              expected = "12345", expected_cursor = 5},
            .{name = "dragging selects",
              contents = "12345", cursor = 5,
              steps = .[.{mouse = .PRESS, mouse_at_glyph = 1}, .{mouse = .HOLD, mouse_at_glyph = 3}, .{mouse = .RELEASE, mouse_at_glyph = 3}],
              expected = "12345", expected_cursor = 3, expected_anchor = 1},
            .{name = "a drag that ends on the starting glyph leaves no selection",
              contents = "12345", cursor = 5,
              steps = .[.{mouse = .PRESS, mouse_at_glyph = 1}, .{mouse = .HOLD, mouse_at_glyph = 1.4}, .{mouse = .RELEASE, mouse_at_glyph = 1.4}],
              expected = "12345", expected_cursor = 1},
            .{name = "a click moves the cursor and clears the selection",
              contents = "12345", cursor = 1, anchor = 4,
              steps = .[.{mouse = .PRESS, mouse_at_glyph = 2}, .{mouse = .RELEASE, mouse_at_glyph = 2}],
              expected = "12345", expected_cursor = 2},
            .{name = "a shift click extends the selection",
              contents = "12345", cursor = 1,
              steps = .[.{mouse = .PRESS, mouse_at_glyph = 4, held = .[.SHIFT_LEFT]}, .{mouse = .RELEASE, mouse_at_glyph = 4, held = .[.SHIFT_LEFT]}],
              expected = "12345", expected_cursor = 4, expected_anchor = 1},
        ] {
            input_state: Main.Input_State;
            array_add(*input_state.contents, ..cast([]u8) it.contents);
            input_state.cursor           = it.cursor;
            input_state.selection_anchor = it.anchor;

            glyph_edges: [..]float;
            mouse_y: float;
            for step_index: -1..it.steps.count - 1 {
                step := ifx step_index == -1 then Step.{} else it.steps[step_index];

                window.text = step.text;
                if step.key != 0 {
                    window.keyboard_state.events.count = 1;
                    window.keyboard_state.events[0]    = .{.PRESSED, step.key};
                }
                for step.held window.keyboard_state.held[it_index] = it;
                backend.clipboard_text = step.paste;
                if step.mouse != .NONE {
                    glyph := cast(s64) step.mouse_at_glyph;
                    window.mouse_state.position = .{
                        glyph_edges[glyph] + (step.mouse_at_glyph - glyph) * (glyph_edges[glyph + 1] - glyph_edges[glyph]),
                        mouse_y,
                    };
                }
                if step.mouse == .PRESS {
                    window.mouse_state.press_position[Mouse_Button.LEFT] = window.mouse_state.position;
                    window.mouse_state.pressed[Mouse_Button.LEFT]        = true;
                    window.mouse_state.held[Mouse_Button.LEFT]           = true;
                } else if step.mouse == .RELEASE {
                    window.mouse_state.released[Mouse_Button.LEFT] = true;
                    window.mouse_state.held[Mouse_Button.LEFT]     = false;
                }

                Main.Input(*input_state, #code {});
                layout();

                array_reset_keeping_memory(*glyph_edges);
                for node: context.forbear.node_tree if node.glyphs.array.count > 0 {
                    font_units_to_pixel := get_font_units_to_pixel(node.style.font, node.style.font_size);
                    for node.glyphs.array array_add(*glyph_edges, node.position.x + it.position.x * font_units_to_pixel);
                    last := peek(node.glyphs.array);
                    array_add(*glyph_edges, node.position.x + (last.position.x + last.advance.x) * font_units_to_pixel);
                    mouse_y = node.position.y + node.size.y / 2;
                }

                prepare_for_next_frame();
                memset(window.keyboard_state.held.data, 0, size_of(type_of(window.keyboard_state.held)));
            }

            contents := to_string(input_state.contents.data, input_state.contents.count);
            assert(
                contents == it.expected && input_state.cursor == it.expected_cursor && input_state.selection_anchor == it.expected_anchor,
                "%: got \"%\" cursor=% anchor=%, expected \"%\" cursor=% anchor=%",
                it.name, contents, input_state.cursor, input_state.selection_anchor, it.expected, it.expected_cursor, it.expected_anchor
            );
        }
    });
}
