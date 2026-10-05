#import "Compiler";
#import "BuildCpp";
#import "Check";
#import "Bindings_Generator";
#import "File";
#import "File_Utilities";
#import "Basic";
#import "String";
#import "Process";
#if OS == .LINUX #import "POSIX";

// -------- wayland protocol types generator ========
    PROTOCOLS :: string.[
        "/usr/share/wayland/wayland.xml",
        "/usr/share/wayland-protocols/stable/xdg-shell/xdg-shell.xml",
        "/usr/share/wayland-protocols/stable/linux-dmabuf/linux-dmabuf-v1.xml",
    ];

    ProtocolType :: enum {
        // s32, 4 bytes
        INT;
        // u32, 4 bytes
        UINT;
        // 4 bytes, signed 24.8 fixed point
        FIXED;
        // u32 object id, 0 means null, 4 bytes
        OBJECT;
        // u32, 4 bytes
        NEW_ID;
        // u32 lenght included, then ascii bytes, NULL byte, padded to 4
        STRING;
        // u32 byte count, then raw bytes, padded to 4
        ARRAY;
        // zero bytes, travels out of band
        FILE_DESCRIPTOR;
    }

    Arg :: struct {
        protocol_type: ProtocolType;
        name: string;
        enum_name: string;
    }

    RequestOrEvent :: struct {
        name: string;
        args: [..] Arg;
    }

    Wayland_Enum_Entry :: struct {
        name: string;
        value: string;
    }

    Wayland_Enum :: struct {
        name: string;
        bitfield: bool;
        entries: [..] Wayland_Enum_Entry;
    }

    Interface :: struct {
        name: string;
        version: string;
        requests: [..] RequestOrEvent;
        events: [..] RequestOrEvent;
        enums: [..] Wayland_Enum;
    }

    generate_wayland_bindings :: (b: *String_Builder) {
        interfaces: [..] Interface;
        for PROTOCOLS  parse(it, *interfaces);
        emit(b, interfaces);
    }

    parse :: (path: string, interfaces: *[..] Interface) {
        xml, ok := read_entire_file(path);
        assert(ok, "could not read %", path);

        iface: *Interface;
        message: *RequestOrEvent;
        current_enum: *Wayland_Enum;

        cursor := xml;
        while true {
            tag, found := next_tag(*cursor);
            if !found  break;
            if !tag.count || tag[0] == #char "?" || tag[0] == #char "!"  continue;

            name := tag_name(tag);

            if tag[0] == #char "/" {
                if name == "interface"  iface = null;
                if name == "request" || name == "event"  message = null;
                if name == "enum"  current_enum = null;
                continue;
            }

            if name == "interface" {
                array_add(interfaces, .{ name = attribute(tag, "name"), version = attribute(tag, "version") });
                iface = *interfaces.*[interfaces.count - 1];
            } else if name == "request" || name == "event" {
                list := ifx name == "request" then *iface.requests else *iface.events;
                array_add(list, .{ name = attribute(tag, "name") });
                message = *list.*[list.count - 1];
            } else if name == "arg" {
                type := attribute(tag, "type");
                if type == "new_id" && !attribute(tag, "interface").count {
                    array_add(*message.args, .{ .STRING, "interface", "" });
                    array_add(*message.args, .{ .UINT, "version", "" });
                }
                array_add(*message.args, .{ protocol_type(type), attribute(tag, "name"), attribute(tag, "enum") });
            } else if name == "enum" {
                array_add(*iface.enums, .{ name = attribute(tag, "name"), bitfield = attribute(tag, "bitfield") == "true" });
                current_enum = *iface.enums[iface.enums.count - 1];
            } else if name == "entry" {
                array_add(*current_enum.entries, .{ attribute(tag, "name"), attribute(tag, "value") });
            }
        }
    }

    next_tag :: (cursor: *string) -> string, bool {
        s := cursor.*;
        while s.count > 0 && s[0] != #char "<"  advance(*s);
        if !s.count  return "", false;
        advance(*s);
        tag := stop_at_any(s, ">");
        if tag.count == s.count  return "", false;
        advance(*s, tag.count + 1);
        cursor.* = s;
        return tag, true;
    }

    tag_name :: (tag: string) -> string {
        t := tag;
        if t[0] == #char "/"  advance(*t);
        return stop_at_any(t, " /");
    }

    attribute :: (tag: string, key: string) -> string {
        needle := tprint(" %=\"", key);
        t := tag;
        while t.count >= needle.count {
            if begins_with(t, needle) {
                advance(*t, needle.count);
                return stop_at_any(t, "\"");
            }
            advance(*t);
        }
        return "";
    }

    protocol_type :: (type: string) -> ProtocolType {
        if type == {
            case "int";    return .INT;
            case "uint";   return .UINT;
            case "fixed";  return .FIXED;
            case "object"; return .OBJECT;
            case "new_id"; return .NEW_ID;
            case "string"; return .STRING;
            case "array";  return .ARRAY;
            case "fd";     return .FILE_DESCRIPTOR;
        }
        assert(false, "unknown arg type %", type);
        return .INT;
    }

    emit :: (b: *String_Builder, interfaces: [] Interface) {
        append(b, "Fixed :: #type,distinct s32;\n");
        append(b, "Fd :: #type,distinct s32;\n\n");

        append(b, "ProtocolType :: enum {\n");
        for enum_names(ProtocolType)  print_to_builder(b, "    %;\n", it);
        append(b, "}\n\n");

        append(b, "Interface_Id :: enum u32 {\n");
        for interfaces  print_to_builder(b, "    %;\n", to_upper_copy(it.name));
        append(b, "}\n\n");

        for iface: interfaces {
            for e: iface.enums {
                print_to_builder(b, "% :: % u32 {\n", enum_type_name(iface.name, e.name), ifx e.bitfield then "enum_flags" else "enum");
                for e.entries  print_to_builder(b, "    % :: %;\n", entry_name(it.name), it.value);
                append(b, "}\n\n");
            }

            for kind, k: string.["Request", "Event"] {
                list := ifx k == 0 then iface.requests else iface.events;
                for message, opcode: list {
                    print_to_builder(b, "%_%_% :: struct {\n    OPCODE :: %;\n", pascal(iface.name), kind, pascal(message.name), opcode);
                    append(b, "    ARGS :: ProtocolType.[");
                    for message.args {
                        if it_index  append(b, ", ");
                        print_to_builder(b, ".%", it.protocol_type);
                    }
                    append(b, "];\n");
                    for message.args  print_to_builder(b, "    %: %;\n", ifx it.name == "interface" then "interface_name" else it.name, field_type(iface.name, it));
                    append(b, "}\n\n");
                }
            }
        }

        append(b, TABLE_TYPES);

        message_ids: String_Builder;
        messages: String_Builder;
        args: String_Builder;
        message_count := 0;
        arg_count := 0;

        append(b, "INTERFACES :: Interface_Info.[\n");
        for iface: interfaces {
            first_request := message_count;
            for message: iface.requests {
                print_to_builder(*message_ids, "    %_% :: %;\n", to_upper_copy(iface.name), to_upper_copy(message.name), message_count);
                print_to_builder(*messages, "    .{ %_Request_%, %, % },\n", pascal(iface.name), pascal(message.name), arg_count, message.args.count);
                for message.args  print_to_builder(*args, "    .%,\n", it.protocol_type);
                message_count += 1;
                arg_count += message.args.count;
            }
            first_event := message_count;
            for message: iface.events {
                print_to_builder(*message_ids, "    %_% :: %;\n", to_upper_copy(iface.name), to_upper_copy(message.name), message_count);
                print_to_builder(*messages, "    .{ %_Event_%, %, % },\n", pascal(iface.name), pascal(message.name), arg_count, message.args.count);
                for message.args  print_to_builder(*args, "    .%,\n", it.protocol_type);
                message_count += 1;
                arg_count += message.args.count;
            }
            print_to_builder(b, "    .{ \"%\", %, %, %, %, % },\n", iface.name, iface.version, first_request, iface.requests.count, first_event, iface.events.count);
        }
        append(b, "];\n\n");

        append(b, "Message_Id :: enum u32 {\n");
        append(b, builder_to_string(*message_ids));
        append(b, "}\n\n");

        append(b, "MESSAGES :: Message_Info.[\n");
        append(b, builder_to_string(*messages));
        append(b, "];\n\n");

        append(b, MAX_MESSAGE_STRUCT_SIZE);

        append(b, "ARGS :: ProtocolType.[\n");
        append(b, builder_to_string(*args));
        append(b, "];\n");
    }

    TABLE_TYPES :: #string END
    Interface_Info :: struct {
        name: string;
        version: u32;
        first_request: s32;
        request_count: s32;
        first_event: s32;
        event_count: s32;
    }

    Message_Info :: struct {
        type: Type;
        first_arg: s32;
        arg_count: s32;
    }

    END

    MAX_MESSAGE_STRUCT_SIZE :: #string END
    MAX_MESSAGE_STRUCT_SIZE :: #run () -> s64 {
        result := 0;
        for MESSAGES {
            size := (cast(*Type_Info) it.type).runtime_size;
            if size > result  result = size;
        }
        return result;
    }();

    END

    field_type :: (interface_name: string, arg: Arg) -> string {
        if arg.enum_name.count {
            found, iface, e := split_from_left(arg.enum_name, #char ".");
            if found  return enum_type_name(iface, e);
            return enum_type_name(interface_name, arg.enum_name);
        }
        if arg.protocol_type == {
            case .INT;    return "s32";
            case .UINT;   return "u32";
            case .FIXED;  return "Fixed";
            case .OBJECT; return "u32";
            case .NEW_ID; return "u32";
            case .STRING; return "string";
            case .ARRAY;  return "[] u8";
            case .FILE_DESCRIPTOR; return "Fd";
        }
        return "u32";
    }

    enum_type_name :: (interface_name: string, enum_name: string) -> string {
        return tprint("%_%", pascal(interface_name), pascal(enum_name));
    }

    entry_name :: (name: string) -> string {
        upper := to_upper_copy(name);
        if is_digit(upper[0])  return tprint("_%", upper);
        return upper;
    }

    pascal :: (s: string) -> string {
        result := copy_string(s);
        upper_next := true;
        for 0..result.count-1 {
            if result[it] == #char "_" { upper_next = true; continue; }
            if upper_next { result[it] = to_upper(result[it]); upper_next = false; }
        }
        return result;
    }
// ======== wayland protocol types generator ========

BINDINGS_PATH :: #run tprint("%bindings-%.jai", #filepath, OS);

#run build();

build :: () {
    build_options := get_build_options();

    debug := build_options.array_bounds_check == .ON;
    jails :: #exists(JAILS_DIAGNOSTICS_BUILD);

    set_build_options_dc(.{do_output=false});

    libnode_dir :: #ifx OS == .LINUX then "vendor/node/out/Release/lib" else "vendor/node/out/Release";
    // Executable + the shared libraries it needs at runtime, side by side.
    #if OS == .WINDOWS {
        platform :: "win32";
    } else #if OS == .LINUX {
        platform :: "linux";
    } else #if OS == .MACOS {
        platform :: "darwin";
    }
    arch :: #ifx CPU == .ARM64 then "arm64" else "x64";
    dist_dir := tprint("dist/%-%", platform, arch);

    build_javascript_ok := build_cpp_static_lib(
        "vendor/javascript",
        "javascript.cpp",
        extra = .["-std=c++20", "-fPIC", "-Ivendor/libnode/include"],
        debug = debug,
    );
    assert(build_javascript_ok, "could not compile javascript.cpp");

    regenerate_bindings := array_find(build_options.compile_time_command_line, "bindings") 
              || !file_exists(BINDINGS_PATH) 
              || !file_exists("vendor/kb_text_shape.a") 
              || !file_exists("vendor/freetype.a");
    if regenerate_bindings {
        bindings_builder: String_Builder;
        #if OS == .LINUX {
            // egl bindings
            egl_bindings_opts: Generate_Bindings_Options;
            array_add(*egl_bindings_opts.system_include_paths, ..get_default_system_include_paths());
            array_add(*egl_bindings_opts.system_libraries, Library.{ filename = "libEGL" });
            array_add(*egl_bindings_opts.extra_clang_arguments, "-DEGL_NO_X11");
            array_add(*egl_bindings_opts.path_fragments_to_treat_as_non_system_paths, "EGL/", "KHR/");
            array_add(*egl_bindings_opts.source_files, "/usr/include/EGL/egl.h", "/usr/include/EGL/eglext.h");
            egl_builder, egl_ok := generate_bindings(egl_bindings_opts);
            assert(egl_ok, "could not generate bindings");
            append_and_steal_buffers(*bindings_builder, *egl_builder);
            append(*bindings_builder, "\n#scope_export\n");
        }

        {
            // kbts bindings
            build_kb_text_shape_ok := build_cpp_static_lib("vendor/kb_text_shape", "vendor/kb_text_shape.c", extra = .["-fPIC"], debug = debug);
            assert(build_kb_text_shape_ok, "could not compile kb_text_shape");
            kbts_bindings_opts: Generate_Bindings_Options;
            array_add(*kbts_bindings_opts.system_include_paths, ..get_default_system_include_paths());
            array_add(*kbts_bindings_opts.library_search_paths, "vendor");
            array_add(*kbts_bindings_opts.libraries, .{ filename = "kb_text_shape" });
            array_add(*kbts_bindings_opts.source_files, "vendor/kb_text_shape.h");
            kbts_bindings_opts.generate_library_declarations = false;
            kbts_bindings_opts.generate_compile_time_struct_checks = false;
            kbts_bindings_opts.strip_enum_prefixes = false;
            kbts_bindings_opts.auto_detect_enum_prefixes = false;
            kbts_builder, kbts_ok := generate_bindings(kbts_bindings_opts);
            assert(kbts_ok, "could not generate kb_text_shape bindings");
            append_and_steal_buffers(*bindings_builder, *kbts_builder);
            append(*bindings_builder, "\nkb_text_shape :: #library,no_dll \"vendor/kb_text_shape\";\n");
            append(*bindings_builder, "\n#scope_export\n");
        }

        {
            // freetype bindings
            build_freetype_ok := build_cpp_static_lib(
                "vendor/freetype",
                "vendor/freetype/src/base/ftsystem.c",
                "vendor/freetype/src/base/ftinit.c",
                "vendor/freetype/src/base/ftdebug.c",
                "vendor/freetype/src/base/ftbase.c",
                "vendor/freetype/src/base/ftbbox.c",
                "vendor/freetype/src/base/ftglyph.c",
                "vendor/freetype/src/base/ftbitmap.c",
                "vendor/freetype/src/base/ftmm.c",
                "vendor/freetype/src/autofit/autofit.c",
                "vendor/freetype/src/truetype/truetype.c",
                "vendor/freetype/src/type1/type1.c",
                "vendor/freetype/src/cff/cff.c",
                "vendor/freetype/src/cid/type1cid.c",
                "vendor/freetype/src/pfr/pfr.c",
                "vendor/freetype/src/type42/type42.c",
                "vendor/freetype/src/winfonts/winfnt.c",
                "vendor/freetype/src/pcf/pcf.c",
                "vendor/freetype/src/bdf/bdf.c",
                "vendor/freetype/src/psaux/psaux.c",
                "vendor/freetype/src/psnames/psnames.c",
                "vendor/freetype/src/pshinter/pshinter.c",
                "vendor/freetype/src/sfnt/sfnt.c",
                "vendor/freetype/src/smooth/smooth.c",
                "vendor/freetype/src/raster/raster.c",
                "vendor/freetype/src/sdf/sdf.c",
                "vendor/freetype/src/svg/svg.c",
                "vendor/freetype/src/gzip/ftgzip.c",
                "vendor/freetype/src/lzw/ftlzw.c",
                extra = .["-fPIC", "-DFT2_BUILD_LIBRARY", "-Ivendor/freetype/include"],
                debug = debug,
            );
            assert(build_freetype_ok, "could not compile freetype");
            freetype_bindings_opts: Generate_Bindings_Options;
            array_add(*freetype_bindings_opts.system_include_paths, ..get_default_system_include_paths());
            array_add(*freetype_bindings_opts.include_paths, "vendor/freetype/include");
            array_add(*freetype_bindings_opts.library_search_paths, "vendor");
            array_add(*freetype_bindings_opts.libraries, .{ filename = "freetype" });
            array_add(*freetype_bindings_opts.source_files, "vendor/freetype/include/freetype/freetype.h", "vendor/freetype/include/freetype/ftmm.h");
            freetype_bindings_opts.generate_library_declarations = false;
            freetype_bindings_opts.generate_compile_time_struct_checks = false;
            freetype_bindings_opts.auto_detect_enum_prefixes = true;
            freetype_builder, freetype_ok := generate_bindings(freetype_bindings_opts);
            assert(freetype_ok, "could not generate freetype bindings");
            append_and_steal_buffers(*bindings_builder, *freetype_builder);
            append(*bindings_builder, "\nfreetype :: #library,no_dll \"vendor/freetype\";\nptrdiff_t :: s64;\n");
            append(*bindings_builder, "\n#scope_export\n");
            #if OS == .LINUX {
                generate_wayland_bindings(*bindings_builder);
            }
        }

        assert(write_entire_file(BINDINGS_PATH, *bindings_builder), "could not write %", BINDINGS_PATH);;
    }

    // w := compiler_create_workspace("Main program");
    // if !debug {
    //     set_optimization(*options, .OPTIMIZED);
    // }
    // if jails {
    //     options.output_type = .NO_OUTPUT;
    // } else {
    //     options.output_type = .DYNAMIC_LIBRARY;
    //     options.output_executable_name = "forbear";
    //     options.output_path = dist_dir;
    //     make_directory_if_it_does_not_exist(dist_dir, recursive=true);
    // }
    // set_build_options(options, w);
    // add_build_string(tprint("DEBUG :: %;", debug), w);
    // add_build_file("forbear.jai", w);

    playground := compiler_create_workspace("Playground");
    playground_options := get_build_options(playground);
    if jails {
        playground_options.output_type = .NO_OUTPUT;
    } else {
        playground_options.output_type = .EXECUTABLE;
        playground_options.output_executable_name = "playground";
        playground_options.output_path = "apps";
    }
    #if OS == .MACOS {
        playground_options.use_custom_link_command = true;
        compiler_begin_intercept(playground);
    }
    set_build_options(playground_options, playground);
    add_build_file("apps/playground.jai", playground);

    #if OS == .MACOS {
        while true {
            message := compiler_wait_for_message();
            if message.kind == .COMPLETE break;

            if message.kind == .PHASE {
                phase_message := cast(*Message_Phase) message;
                phase := phase_message.phase;
                if phase == .READY_FOR_CUSTOM_LINK_COMMAND {
                    arguments: [..] string;
                    array_add(*arguments, "clang", "-arch", #ifx CPU == .ARM64 then "arm64" else "x86_64");
                    array_add(*arguments, "-o", tprint("%/%", playground_options.output_path, playground_options.output_executable_name));
                    array_add(*arguments, "-Wl,-rpath,@loader_path");
                    array_add(*arguments, ..phase_message.compiler_generated_object_files);
                    array_add(*arguments, ..phase_message.support_object_files);
                    array_add(*arguments, ..phase_message.system_libraries);
                    array_add(*arguments, ..phase_message.user_libraries);
                    print("Running linker: %\n", get_quoted_command_string(arguments));
                    result := run_command(..arguments);
                    if result.exit_code != 0  compiler_report(tprint("link failed: %", get_quoted_command_string(arguments)));
                    compiler_custom_link_command_is_complete(playground);
                }
            }
        }

        compiler_end_intercept(playground);
    }
}
