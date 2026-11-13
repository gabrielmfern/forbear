#import "Basic";
#import "Math";
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
    difference := abs(a - b);
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
}
