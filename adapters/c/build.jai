#import "Compiler";

#run build();
build :: () {
    set_build_options_dc(.{do_output = false});

    {
        w := compiler_create_workspace("dynamic library");
        options := get_build_options(w);
        options.output_executable_name = "forbear";
        options.output_type = .DYNAMIC_LIBRARY;
        set_build_options(options, w);
        add_build_file("adapters/c/c-adapter.jai", w);
    }

    // {
    //     w := compiler_create_workspace("static library");
    //     options := get_build_options(w);
    //     options.output_executable_name = "forbear";
    //     options.output_type = .STATIC_LIBRARY;
    //     set_build_options(options, w);
    //     add_build_file("adapters/c/c-adapter.jai", w);
    // }
}