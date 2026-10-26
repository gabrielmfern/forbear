
#import "Basic";
#import "Compiler";
#import,file "../../forbear.jai";

build :: () {
    set_build_options_dc(.{do_output = false});

    w := compiler_create_workspace("Calculator");
    options := get_build_options(w);
    copy_commonly_propagated_fields(get_build_options(), *options);
    options.output_executable_name = "Calculator";
    options.output_path = #filepath;
    set_build_options(options, w);

    plugin := get_plugin();
    plugin.workspace = w;

    compiler_begin_intercept(w);
    add_build_file(tprint("%main.jai", #filepath), w);
    while true {
        message := compiler_wait_for_message();
        plugin.message(plugin, message);
        if message.kind == .COMPLETE break;
    }
    compiler_end_intercept(w);

    #if OS == .MACOS {
        create_application("Calculator", tprint("%Calculator", #filepath));
    }
}

#run build();
