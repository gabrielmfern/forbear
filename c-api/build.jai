#import "Basic";
#import "Compiler";
#import "File";
#import "String";

ROOTS  :: string.["Forbear", "Style", "Complete_Style", "Base_Style", "Font", "Node_Opening_Data",
    "Windows_GL_Window", "Windows_GL_Backend", "Wayland_EGL_Window", "Wayland_EGL_Backend", "MacOS_GL_Window", "MacOS_GL_Backend", "Wayland_Event", "Mouse_Button", "Vector3", "Scrolling_State"];
OPAQUE :: string.["Table", "Flat_Pool", "kbts_font", "Context"];

Target :: struct {
    os:        Operating_System_Tag;
    cpu:       type_of(CPU);
    macro:     string;
    window:    string;
    backend:   string;
    workspace: Workspace;
    roots:     [..]*Type_Info_Struct;
    enums:     [..]*Type_Info_Enum;
    exports:   [..]*Code_Declaration;
    section:   string;
}

#run build();
build :: () {
    set_build_options_dc(.{do_output = false});

    targets := Target.[
        .{os = .WINDOWS, cpu = .X64,   macro = "_WIN32",    window = "Windows_GL_Window",  backend = "Windows_GL_Backend"},
        .{os = .LINUX,   cpu = .X64,   macro = "__linux__", window = "Wayland_EGL_Window", backend = "Wayland_EGL_Backend"},
        .{os = .MACOS,   cpu = .ARM64, macro = "__APPLE__", window = "MacOS_GL_Window",    backend = "MacOS_GL_Backend"},
    ];

    remaining := 0;
    for * targets {
        if it.os == .MACOS && OS != .MACOS continue;
        remaining += 1;

        it.workspace       = compiler_create_workspace(tprint("%", it.os));
        options           := get_build_options(it.workspace);
        options.os_target  = it.os;
        options.cpu_target = it.cpu;
        if it.os == OS {
            options.output_executable_name = "forbear";
            // TO-DO: also build a static library
            options.output_type = .DYNAMIC_LIBRARY;
        } else {
            options.output_type = .NO_OUTPUT;
        }
        set_build_options(options, it.workspace);

        compiler_begin_intercept(it.workspace);
        add_build_file("c-api.jai", it.workspace);
    }

    while remaining > 0 {
        message := compiler_wait_for_message();
        target: *Target;
        for * targets if it.workspace == message.workspace target = it;
        if message.kind == {
            case .TYPECHECKED;
                typechecked := cast(*Message_Typechecked) message;
                for typechecked.structs {
                    type := it.expression.defined_type;
                    if array_find(ROOTS, type.name) array_add_if_unique(*target.roots, type);
                }
                for typechecked.all if it.expression.kind == .ENUM {
                    type := (cast(*Code_Enum) it.expression).external_type;
                    if type && array_find(ROOTS, type.name) array_add_if_unique(*target.enums, type);
                }
                for typechecked.declarations {
                    declaration := it.expression;
                    if declaration.flags & .PROGRAM_EXPORT && declaration.expression && declaration.expression.type.type == .PROCEDURE {
                        array_add_if_unique(*target.exports, declaration);
                    }
                }
            case .PHASE;
                phase := cast(*Message_Phase) message;
                if phase.phase == .TYPECHECKED_ALL_WE_CAN && phase.num_items_waiting_to_typecheck == 0 {
                    header: Header;
                    print_to_builder(*header.builder, "#if defined(%)\n", target.macro);
                    append(*header.builder, "typedef struct { fb_s64 count; fb_u8 *data; } fb_String;\n");
                    for target.roots emit_struct(*header, it);
                    for target.enums emit_enum(*header, it, "");
                    print_to_builder(*header.builder, "typedef fb_% fb_Window;\ntypedef fb_% fb_Backend;\n\n",
                                     target.window, target.backend);
                    for target.exports {
                        procedure := cast(*Type_Info_Procedure) it.expression.type;
                        assert(procedure.procedure_flags & .IS_C_CALL && procedure.return_types.count <= 1,
                               "%: exported procedures must be #c_call with at most one return value", it.name);
                        assert(it.expression.kind == .PROCEDURE_HEADER,
                               "%: write the export as a procedure, not an alias, so its parameter names reach the header", it.name);
                        procedure_header := cast(*Code_Procedure_Header) it.expression;
                        arguments: [..]string;
                        for procedure.argument_types {
                            to := ifx it.type == .POINTER then (cast(*Type_Info_Pointer) it).pointer_to else null;
                            is_c_string := to && to.type == .INTEGER && to.runtime_size == 1 && !(cast(*Type_Info_Integer) to).signed;
                            argument_type := ifx is_c_string then "const char *" else c_type(*header, it, "");
                            array_add(*arguments, tprint("% %", argument_type, procedure_header.arguments[it_index].name));
                        }
                        returns := ifx procedure.return_types.count then c_type(*header, procedure.return_types[0], "") else "void";
                        print_to_builder(*header.builder, "% %(%);\n", returns, it.name,
                                         ifx arguments.count then join(..arguments, ", ") else "void");
                    }
                    append(*header.builder, "#endif\n");
                    target.section = builder_to_string(*header.builder);
                }
            case .COMPLETE;
                remaining -= 1;
        }
    }
    for targets if it.workspace compiler_end_intercept(it.workspace);

    write_autogenerated_header_portion(targets);
}

Header :: struct {
    builder:      String_Builder;
    emitted_definitions: [..]string;
}

c_type :: (h: *Header, type: *Type_Info, owner: string) -> string {
    type_name := "";
    if type.type == {
        case .VOID;   type_name = "void";
        case .BOOL;   type_name = "_Bool";
        case .FLOAT;  type_name = ifx type.runtime_size == 4 then "float" else "double";
        case .STRING; type_name = "fb_String";
        case .TYPE;   type_name = "void *";
        case .INTEGER;
            integer := cast(*Type_Info_Integer) type;
            type_name = tprint("fb_%1%2", ifx integer.signed then "s" else "u", integer.runtime_size * 8);
        case .VARIANT; type_name = c_type(h, (cast(*Type_Info_Variant) type).variant_of, owner);
        case .ENUM;    type_name = emit_enum(h, cast(*Type_Info_Enum) type, owner);
        case .STRUCT;  type_name = emit_struct(h, cast(*Type_Info_Struct) type);
        case .POINTER;
            to := (cast(*Type_Info_Pointer) type).pointer_to;
            if to.type == .STRUCT && (array_find(ROOTS, (cast(*Type_Info_Struct) to).name)
                                      || array_find(h.emitted_definitions, struct_name(h, cast(*Type_Info_Struct) to))) {
                type_name = tprint("% *", emit_struct(h, cast(*Type_Info_Struct) to));
            } else if to.type == .INTEGER || to.type == .FLOAT || to.type == .BOOL {
                type_name = tprint("% *", c_type(h, to, owner));
            } else {
                type_name = "void *";
            }
        case .ARRAY;
            array     := cast(*Type_Info_Array) type;
            element   := c_type(h, array.element_type, owner);
            resizable := array.array_type == .RESIZABLE;
            base      := replace(ifx begins_with(element, "fb_") then slice(element, 3, element.count - 3) else element, " *", "_ptr");
            name      := tprint("fb_%_%", ifx resizable then "Array" else "View", base);
            if !array_find(h.emitted_definitions, name) {
                array_add(*h.emitted_definitions, name);
                if resizable emit_struct(h, type_info(Allocator));
                print_to_builder(*h.builder, "typedef struct { fb_s64 count; % *data;% } %;\n\n",
                                 element, ifx resizable then " fb_s64 allocated; fb_Allocator allocator;" else "", name);
            }
            type_name = name;
        case .PROCEDURE;
            procedure := cast(*Type_Info_Procedure) type;
            assert(procedure.procedure_flags & .IS_C_CALL && procedure.return_types.count <= 1,
                   "c_type: procedure in % must be #c_call with at most one return value", owner);
            returns := ifx procedure.return_types.count then c_type(h, procedure.return_types[0], owner) else "void";
            arguments: [..]string;
            for procedure.argument_types array_add(*arguments, c_type(h, it, owner));
            name := replace(tprint("fb_Proc_%_%", returns, join(..arguments, "_")), " *", "_ptr");
            if !array_find(h.emitted_definitions, name) {
                array_add(*h.emitted_definitions, name);
                print_to_builder(*h.builder, "typedef % (*%)(%);\n", returns, name,
                                 ifx arguments.count then join(..arguments, ", ") else "void");
            }
            type_name = name;
        case;
            assert(false, "c_type: % in % has no C mapping", type.type, owner);
    }
    return type_name;
}

emit_enum :: (h: *Header, type: *Type_Info_Enum, owner: string) -> string {
    name := ifx type.name == "Kind" then tprint("fb_%_Kind", owner) else tprint("fb_%", type.name);
    if !array_find(h.emitted_definitions, name) {
        array_add(*h.emitted_definitions, name);

        print_to_builder(*h.builder, "typedef % %;\n", c_type(h, type.internal_type, owner), name);
        for type.names {
            print_to_builder(*h.builder,
                             "#define %_% %\n",
                             to_upper_copy(name),
                             it,
                             type.values[it_index]);
        }
        append(*h.builder, "\n");
    }
    return name;
}

field :: (h: *Header, b: *String_Builder, member: Type_Info_Struct_Member, owner: string) {
    type := member.type;
    while type.type == .VARIANT type = (cast(*Type_Info_Variant) type).variant_of;

    if member.name == "" && type.type == .STRUCT {
        inner := cast(*Type_Info_Struct) type;
        append(b, ifx inner.textual_flags & .UNION then "    union {\n" else "    struct {\n");
        for inner.members if (it.flags & (.CONSTANT | .OVERLAY)) == 0 {
            field(h, b, it, owner);
        }
        append(b, "    };\n");
        return;
    }

    dims := "";
    while type.type == .ARRAY && (cast(*Type_Info_Array) type).array_type == .FIXED {
        array := cast(*Type_Info_Array) type;
        dims   = tprint("%[%]", dims, array.array_count);
        type   = array.element_type;
    }

    if type.type == .PROCEDURE {
        procedure := cast(*Type_Info_Procedure) type;
        if procedure.procedure_flags & .IS_C_CALL && procedure.return_types.count <= 1 {
            arguments: [..]string;
            for procedure.argument_types array_add(*arguments, c_type(h, it, owner));
            returns := ifx procedure.return_types.count then c_type(h, procedure.return_types[0], owner) else "void";
            print_to_builder(b, "    % (*%)(%);\n", returns, join(member.name, dims), ifx arguments.count then join(..arguments, ", ") else "void");
            return;
        }
    }

    opaque_struct := type.type == .STRUCT && array_find(OPAQUE, (cast(*Type_Info_Struct) type).name);
    if type.type == .PROCEDURE || opaque_struct {
        print_to_builder(b, "    _Alignas(8) fb_u8 %[%];\n", join(member.name, dims), type.runtime_size);
        return;
    }
    print_to_builder(b, "    % %;\n", c_type(h, type, owner), join(member.name, dims));
}
struct_name :: (h: *Header, type: *Type_Info_Struct) -> string {
    name := tprint("fb_%", type.name);
    for type.specified_parameters {
        assert(it.type.type == .TYPE && it.offset_into_constant_storage >= 0,
               "struct_name: % has a non-type parameter '%', which has no C name yet", type.name, it.name);
        parameter := (cast(**Type_Info) *type.constant_storage[it.offset_into_constant_storage]).*;
        parameter_name := ifx parameter.type == .STRUCT then (cast(*Type_Info_Struct) parameter).name else c_type(h, parameter, type.name);
        name = tprint("%_%", name, parameter_name);
    }
    return name;
}
emit_struct :: (h: *Header, type: *Type_Info_Struct) -> string {
    name := struct_name(h, type);
    if array_find(h.emitted_definitions, name) return name;
    array_add(*h.emitted_definitions, name);
    print_to_builder(*h.builder, "typedef struct % %;\n", name, name);

    members: [..]Type_Info_Struct_Member;
    for type.members if (it.flags & (.CONSTANT | .IMPORTED | .OVERLAY)) == 0 && it.type.runtime_size > 0 array_add(*members, it);

    b: String_Builder;
    print_to_builder(*b, "struct % {\n", name);
    for members field(h, *b, it, type.name);
    print_to_builder(*b, "};\n_Static_assert(sizeof(%) == %, \"%\");\n", name, type.runtime_size, name);
    for members if it.name != "" print_to_builder(*b, "_Static_assert(FB_OFFSETOF(%, %) == %, \"%.%\");\n", name, it.name, it.offset_in_bytes, name, it.name);
    append(*b, "\n");

    append(*h.builder, builder_to_string(*b));
    return name;
}

slice :: inline (s: string, index: s64) -> string {
    return slice(s, index, s.count - index);
}
write_autogenerated_header_portion :: (targets: []Target) {
    print("write_autogenerated_header_portion begin;\n");
    header              : Header;
    header_path         := tprint("%forbear.h", #filepath);
    current_header_file := read_entire_file(header_path);
    AUTO_GENERATED_BEGIN :: "// ====== BEGIN AUTO GENERATED PORTION ======\n";
    AUTO_GENERATED_END   :: "// ====== END AUTO GENERATED PORTION ======\n";

    before_auto_generated_content := slice(current_header_file,
                                           0,
                                           find_index_from_left(current_header_file, AUTO_GENERATED_BEGIN)
                                           + AUTO_GENERATED_BEGIN.count);
    append(*header.builder, before_auto_generated_content);
    for targets {
        section := it.section;
        if !section {
            begin := tprint("#if defined(%)\n", it.macro);
            end   := "#endif\n";
            start := find_index_from_left(current_header_file, begin);
            if start == -1 continue;
            section = slice(current_header_file, start, find_index_from_left(current_header_file, end, start) + end.count - start);
        }
        if it_index > 0 append(*header.builder, "\n");
        append(*header.builder, section);
    }
    append(*header.builder, "#if !defined(_WIN32) && !defined(__linux__) && !defined(__APPLE__)\n#error \"forbear: unsupported platform\"\n#endif\n");

    after_auto_generated_content := slice(current_header_file, find_index_from_left(current_header_file, AUTO_GENERATED_END));
    append(*header.builder, after_auto_generated_content);

    write_entire_file(header_path, builder_to_string(*header.builder));
    print("write_autogenerated_header_portion end;\n");
}

