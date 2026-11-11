#import "Basic";
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
    });

    test("reverse_number_sign", #code {
        text: [..]u8;
        Main.reverse_number_sign(*text);
        assert(to_string(text.data, text.count) == "");

        array_add(*text, #char "1");
        array_add(*text, #char "2");
        array_add(*text, #char "3");
        Main.reverse_number_sign(*text);
        assert(to_string(text.data, text.count) == "-123");

        array_reset_keeping_memory(*text);
        array_add(*text, #char "-");
        array_add(*text, #char "1");
        array_add(*text, #char "2");
        array_add(*text, #char "3");
        Main.reverse_number_sign(*text);
        assert(to_string(text.data, text.count) == "123");

        array_reset_keeping_memory(*text);
        array_add(*text, #char "-");
        Main.reverse_number_sign(*text);
        assert(to_string(text.data, text.count) == "-");

        array_reset_keeping_memory(*text);
        array_add(*text, #char "1");
        array_add(*text, #char "2");
        array_add(*text, #char "3");
        array_add(*text, #char "-");
        Main.reverse_number_sign(*text);
        assert(to_string(text.data, text.count) == "123-");

        array_reset_keeping_memory(*text);
        array_add(*text, #char "1");
        array_add(*text, #char "2");
        array_add(*text, #char "3");
        array_add(*text, #char " ");
        array_add(*text, #char "-");
        Main.reverse_number_sign(*text);
        assert(to_string(text.data, text.count) == "123 -");
    });
}
