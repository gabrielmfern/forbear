build :: () {
    set_build_options_dc(.{do_output = false});

    w := compiler_create_workspace("tests");
    options := get_build_options(w);
    options.output_executable_name = "tests";
    options.entry_point_name = "__run_tests";
    set_build_options(options, w);

    compiler_begin_intercept(w, .SKIP_EXPRESSIONS_WITHOUT_NOTES);
    add_build_file(tprint("%calculator.jai", #filepath), w);

    tests: [..] string;
    generated := false;
    success := false;
    while true {
        message := compiler_wait_for_message();
        if message.kind == {
          case .TYPECHECKED;
            typechecked := cast(*Message_Typechecked) message;
            for typechecked.procedure_headers {
                for note: it.expression.notes {
                    if note.text == "test"  array_add(*tests, it.expression.name);
                }
            }

          case .PHASE;
            phase := cast(*Message_Phase) message;
            if phase.phase == .TYPECHECKED_ALL_WE_CAN && !generated {
                generated = true;
                builder: String_Builder;
                append(*builder, "__run_tests :: () {\n");
                for tests  print_to_builder(*builder, "    print(\"RUN  %1\\n\");\n    %1();\n    print(\"PASS %1\\n\");\n", it);
                append(*builder, "}\n");
                add_build_string(builder_to_string(*builder), w);
            }

          case .COMPLETE;
            complete := cast(*Message_Complete) message;
            success = complete.error_code == .NONE;
            break;
        }
    }
    compiler_end_intercept(w);

    if success  run_command(tprint("%tests", #filepath));
}

#run build();

#import "Basic";
#import "Compiler";
#import "Process";
