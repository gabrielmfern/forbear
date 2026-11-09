BUILD_FLAGS :: "+forbear";

#import "Basic";
#import "File";
#import "forbear";
#import "Flat_Pool";

backend: Backend;
window:  Window;
forbear: Forbear;
inter := #run create_font(read_entire_file("Inter.ttf"));

Root_Component :: () {
    text("hey");
} @component

main :: () {
    init_backend(*backend);
    init_window(*backend, *window, 1280, 728, "forbear tests", show_window = false);

    forbear: Forbear;
    init_forbear(*forbear, *window, *backend, Base_Style.{
        font      = *inter,
        color     = hex("#ECECEC"),
        font_size = 16,
    });

    init_font(*inter);

    frame_pool: Flat_Pool;
    frame_allocator: Allocator;
    frame_allocator.data = *frame_pool;
    frame_allocator.proc = flat_pool_allocator_proc;

    test_frame :: (name: string, body: Code) #expand {
        print("RUN  %\n", name);
        #insert body;

        prepare_for_next_frame();
        reset(*`frame_pool);
        // if the body of the test ran and got here, it means the asserts succeded.
        // if it had failed, the program would've exited.
        print("    PASS %\n", name);
    }
    shallow_node_check :: (index: s64, kind: Node.Kind, parent_index: s64) #expand {
        tree := context.forbear.node_tree;
        assert(tree[index].kind == kind, "kind=%", tree[index].kind);
        assert(tree[index].parent == parent_index, "parent=%", tree[index].parent);
    }

    {
        //
        // ==== compiler plugin tests ====
        //
        test_frame("compiler plugin: components should get a scope node, and its children should be inserted too", #code {
            Root_Component();

            assert(context.forbear.node_tree.count == 2, "count=%", context.forbear.node_tree.count);
            shallow_node_check(0, .SCOPE, -1);
            shallow_node_check(1, .ELEMENT, -1);
        });

        test_frame("compiler plugin: local components should get a scope node, and its children should be inserted too", #code {
            My_Component :: () {
                print("my component ran\n");
                text("My_Component did run\n");
            } @component
            My_Component();

            assert(context.forbear.node_tree.count == 2, "count=%", context.forbear.node_tree.count);
            shallow_node_check(0, .SCOPE, -1);
            shallow_node_check(1, .ELEMENT, -1);
        });

        test_frame("compiler plugin: components shuold work just fine with other local procedures", #code {
            My_Component :: () {
                print("My Component did run\n");
                text("hey");
            } @component
            calculate_something :: () -> float {
                return 151512 / 2323;
            }
            My_Component();
            assert(calculate_something() == 151512 / 2323, "calculate_something()=%", calculate_something());
            text(sprint("%", calculate_something()));

            assert(context.forbear.node_tree.count == 3, "count=%", context.forbear.node_tree.count);
            shallow_node_check(0, .SCOPE, -1);
            shallow_node_check(1, .ELEMENT, -1);
            shallow_node_check(2, .ELEMENT, -1);
        });

        test_frame("compiler plugin: components called inside #code should get a scope node, so their elements get different keys", #code {
            Child_In_Code :: () {
                Child :: () {
                    element(Style.{width = fixed(10), height = fixed(10)});
                } @component

                element(Style.{}, #code {
                    Child();
                    Child();
                });
            } @component
            Child_In_Code();

            tree := context.forbear.node_tree;
            assert(tree.count == 6, "count=%", tree.count);
            shallow_node_check(0, .SCOPE, -1);
            shallow_node_check(1, .ELEMENT, -1);
            shallow_node_check(2, .SCOPE, 1);
            shallow_node_check(3, .ELEMENT, 1);
            shallow_node_check(4, .SCOPE, 1);
            shallow_node_check(5, .ELEMENT, 1);
            assert(tree[3].key != tree[5].key, "both children have key %", tree[3].key);
        });

        test_frame("compiler plugin: local macros inside #code should keep their elements", #code {
            Child :: () {
                element(Style.{width = fixed(10), height = fixed(10)});
            } @component
            Box :: (body: Code) #expand {
                element(Style.{width = fixed(10), height = fixed(10)}, #code {
                    #insert body;
                });
            } @component

            Child();
            Box(#code {
                Child();
            });

            tree := context.forbear.node_tree;
            assert(tree.count == 6, "count=%", tree.count);
            shallow_node_check(0, .SCOPE, -1);
            shallow_node_check(1, .ELEMENT, -1);
            shallow_node_check(2, .SCOPE, -1);
            shallow_node_check(3, .ELEMENT, -1);
            shallow_node_check(4, .SCOPE, 3);
            shallow_node_check(5, .ELEMENT, 3);
        });

        test_frame("compiler plugin: components that return values should work", #code {
            Button :: () -> string {
                clicked := false;
                element(Style.{width = fixed(10), height = fixed(10)}, #code {
                    clicked = on_click();
                });
                if clicked {
                    return "hey dude, you've been clicked";
                } else {
                    return "oh no, you've not been clicked";
                }
            } @component

            click_message := Button();
            assert(click_message == "oh no, you've not been clicked", "click_message == %", click_message);

            tree := context.forbear.node_tree;
            assert(tree.count == 2, "count=%", tree.count);
            shallow_node_check(0, .SCOPE, -1);
            shallow_node_check(1, .ELEMENT, -1);
        });
    }
}