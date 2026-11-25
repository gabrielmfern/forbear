BUILD_FLAGS :: "-output_path .build";

#import "Basic";
#import "File";
#import "forbear";

backend: Backend;
window:  Window;
forbear: Forbear;
inter := #run create_font(read_entire_file("Inter.ttf"));

#add_context suites: [..]string;
main :: () {
    init_backend(*backend);
    init_window(*backend, *window, 1280, 728, "forbear tests");

    forbear: Forbear;
    frame_arena: Frame_Arena;
    init_forbear(*forbear, *frame_arena, *backend, *window, Base_Style.{
        font      = *inter,
        color     = hex("#ECECEC"),
        font_size = 16,
    });

    init_font(*inter);

    describe :: (name: string, body: Code) #expand {
        array_add(*context.suites, name);
        defer pop(*context.suites);

        #insert body;
    }
    print_test_path :: (name: string) {
        for context.suites {
            print(it);
            print(" ");
            if it_index == context.suites.count - 1 {
                print(name);
            }
        }
    }
    test :: (name: string, body: Code) #expand {
        print("  RUN ");
        print_test_path(name);
        print("\n");

        push_frame_allocator();
        #insert body;

        prepare_for_next_frame();
        // If the body of the test ran and got here, it means the asserts succeed.
        // If it had failed, the program would've exited.
        print("  PASS ");
        print_test_path(name);
        print("\n");
    }

    shallow_node_assert :: (index: s64, kind: Node.Kind, parent_index: s64) #expand {
        tree := context.forbear.node_trees[context.forbear.frame % 2];
        assert(tree[index].kind == kind, "kind=%", tree[index].kind);
        assert(tree[index].parent == parent_index, "parent=%", tree[index].parent);
    }

    describe("scope", #code {
        test("the same component called from a macro's own body gets a different key per call", #code {
            Child :: () {
                element(Style.{width = fixed(10), height = fixed(10)});
            }
            Box :: () #expand {
                element(Style.{}, #code {
                    scope(Child());
                    scope(Child());
                });
            }
            scope(Box());

            tree := context.forbear.node_trees[context.forbear.frame % 2];
            assert(tree.count == 6, "count=%", tree.count);
            shallow_node_assert(0, .SCOPE, -1);
            shallow_node_assert(1, .ELEMENT, -1);
            shallow_node_assert(2, .SCOPE, 1);
            shallow_node_assert(3, .ELEMENT, 1);
            shallow_node_assert(4, .SCOPE, 1);
            shallow_node_assert(5, .ELEMENT, 1);
            assert(tree[3].key != tree[5].key, "both children have key %", tree[3].key);
        });
    });

    wrap_arrangement :: (content:  string,
                         wrapping: Text_Wrapping,
                         width:    float,
                         x_justification := Alignment.START) -> text_index: s64 {
        parent := open_element(
            Style.{ width = fixed(width), text_wrapping = wrapping, x_justification = x_justification },
            tprint("%-%-%-%", content, wrapping, width, x_justification),
        );
        text_index := text(Style.{}, content);
        close_element(parent);
        return text_index;
    }
    Wrapped_Line :: struct {
        text:    string;
        start_x: float;
        end_x:   float;
    }
    wrapped_lines :: (text_index: s64) -> [..]Wrapped_Line {
        node    := *context.forbear.node_trees[context.forbear.frame % 2][text_index];
        lines   : [..]Wrapped_Line;
        builder : String_Builder;
        for glyph: node.shaping_run.glyphs {
            position := node.glyph_positions[it_index];
            if it_index == 0 || position.y != node.glyph_positions[it_index - 1].y {
                if lines.count > 0  lines[lines.count - 1].text = builder_to_string(*builder);
                array_add(*lines, .{ start_x = position.x });
            }
            append(*builder, to_string(node.shaping_run.text.data + glyph.text_index, 1));
            lines[lines.count - 1].end_x = position.x + glyph.advance.x;
        }
        if lines.count > 0  lines[lines.count - 1].text = builder_to_string(*builder);
        return lines;
    }

    describe("test wrapping", #code {
        expect_lines :: (text_index: s64, expected: ..string) {
            lines := wrapped_lines(text_index);
            assert(lines.count == expected.count, "expected % lines %, got %", expected.count, expected, lines);
            for expected  assert(lines[it_index].text == it, "line %: expected \"%\", got \"%\"", it_index, it, lines[it_index].text);
        }

        //
        // ==== text wrapping tests ====
        //
        test("WORD keeps text on one line when it fits", #code {
            text_index := wrap_arrangement("a b c", .WORD, 1000);
            layout();
            expect_lines(text_index, "a b c");
        });

        test("WORD breaks after spaces when the width is too small", #code {
            text_index := wrap_arrangement("a b c", .WORD, 1);
            layout();
            expect_lines(text_index, "a ", "b ", "c");
        });

        test("WORD never breaks inside a word", #code {
            text_index := wrap_arrangement("abc def", .WORD, 1);
            layout();
            expect_lines(text_index, "abc ", "def");
        });

        test("CHARACTER breaks between any characters", #code {
            text_index := wrap_arrangement("abc", .CHARACTER, 1);
            layout();
            expect_lines(text_index, "a", "b", "c");
        });

        test("NONE never breaks on width", #code {
            text_index := wrap_arrangement("a b c", .NONE, 1);
            layout();
            expect_lines(text_index, "a b c");
        });

        test("line breaks always break, for every wrapping mode", #code {
            word      := wrap_arrangement("a\nb", .WORD, 1000);
            character := wrap_arrangement("a\nb", .CHARACTER, 1000);
            none      := wrap_arrangement("a\nb", .NONE, 1000);
            layout();
            expect_lines(word, "a", "b");
            expect_lines(character, "a", "b");
            expect_lines(none, "a", "b");
        });

        test("same text at different widths in the same frame wraps independently", #code {
            narrow := wrap_arrangement("a b c", .WORD, 1);
            wide   := wrap_arrangement("a b c", .WORD, 1000);
            layout();
            tree := context.forbear.node_trees[context.forbear.frame % 2];
            assert(tree[narrow].shaping_run.glyphs.data == tree[wide].shaping_run.glyphs.data, "expected both nodes to share the cached shaping run");
            expect_lines(narrow, "a ", "b ", "c");
            expect_lines(wide, "a b c");
        });

        test("justification aligns every wrapped line inside the node", #code {
            start  := wrap_arrangement("a bb ccc", .WORD, 1, .START);
            center := wrap_arrangement("a bb ccc", .WORD, 1, .CENTER);
            end    := wrap_arrangement("a bb ccc", .WORD, 1, .END);
            layout();
            tree := context.forbear.node_trees[context.forbear.frame % 2];
            node := tree[start];
            line_end := node.size.x / get_font_units_to_pixel(node.style.font, node.style.font_size);
            assert(wrapped_lines(start).count == 3, "expected 3 lines, got %", wrapped_lines(start));
            close :: (a: float, b: float) -> bool { return a - b < 0.01 && b - a < 0.01; }
            for line: wrapped_lines(start) {
                assert(close(line.start_x, 0), "START line \"%\" starts at %", line.text, line.start_x);
            }
            for line: wrapped_lines(center) {
                left_gap  := line.start_x;
                right_gap := line_end - line.end_x;
                assert(close(left_gap, right_gap), "CENTER line \"%\" has gaps % and %", line.text, left_gap, right_gap);
            }
            for line: wrapped_lines(end) {
                assert(close(line.end_x, line_end), "END line \"%\" ends at %, expected %", line.text, line.end_x, line_end);
            }
        });
    });

    describe("shaping cache", #code {
        CACHED :: "cached across frames";
        expected_glyphs : [..]s32;
        expected_glyphs.allocator = context.allocator;
        test("shaping text for the first time", #code {
            index := text(CACHED);
            for context.forbear.node_trees[context.forbear.frame % 2][index].shaping_run.glyphs  array_add(*expected_glyphs, it.index);
        });
        test("carrying a run over from the previous frame", #code {
            text(CACHED);
        });
        test("a run carried over twice survives new text shaped into the reused pool", #code {
            for 0..20  text("different text number % to fill the pool", it);
            index  := text(CACHED);
            glyphs := context.forbear.node_trees[context.forbear.frame % 2][index].shaping_run.glyphs;
            assert(glyphs.count == expected_glyphs.count, "expected % glyphs, got %", expected_glyphs.count, glyphs.count);
            for glyphs  assert(it.index == expected_glyphs[it_index], "glyph %: expected index %, got %", it_index, expected_glyphs[it_index], it.index);
        });
        test("line heights less than a font unit apart get their own runs", #code {
            a    := text(Style.{ line_height = line_height_percentage(1.0) }, CACHED);
            b    := text(Style.{ line_height = line_height_percentage(1.0001) }, CACHED);
            tree := context.forbear.node_trees[context.forbear.frame % 2];
            assert(tree[a].shaping_run.line_height != tree[b].shaping_run.line_height, "expected different line heights, both got %", tree[a].shaping_run.line_height);
        });
    });

    describe("node pool", #code {
        test("only the last array in a pool grows in place, and its neighbors survive", #code {
            parent := open_element(Style.{}, "node pool growth");
            first  := state([..]s64);
            second := state([..]s64);
            for 0..7  array_add(first, it);
            for 0..7  array_add(second, 100 + it);
            second_data := second.data;
            for 8..15  array_add(second, 100 + it);
            for 8..15  array_add(first, it);
            close_element(parent);
            assert(second.data == second_data, "expected the last array in the pool to grow in place");
            assert(   first.count == 16
                   && second.count == 16, "expected 16 items in each, got % and %", first.count, second.count);
            for first.*   assert(it == it_index, "first[%]: expected %, got %", it_index, it_index, it);
            for second.*  assert(it == 100 + it_index, "second[%]: expected %, got %", it_index, 100 + it_index, it);
        });
    });
}