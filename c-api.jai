#import "Basic";
#import "Compiler";
#import "File";
#import "Flat_Pool";
#import "Hash";
#import "Sort";
#import "String";
Math :: #import "Math";

#if !#exists(JAVASCRIPT) {
    ROOTS  :: string.["Forbear", "Style", "Complete_Style", "Base_Style", "Font", "Node_Opening_Data",
        "Windows_GL_Window", "Windows_GL_Backend", "Wayland_EGL_Window", "Wayland_EGL_Backend", "MacOS_GL_Window", "MacOS_GL_Backend", "Wayland_Event", "Mouse_Button", "Vector3", "Scrolling_State"];
    OPAQUE :: string.["Table", "Flat_Pool", "kbts_font", "Context"];

    Target :: struct {
        os:        Operating_System_Tag;
        cpu:       type_of(CPU);
        macro:     string;
        window:    string;
        backend:   string;
        javascript: bool;
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
            .{os = OS,       cpu = CPU,    javascript = true},
        ];

        skip_javascript := array_find(get_build_options().compile_time_command_line, "no_javascript");

        remaining := 0;
        for * targets {
            if it.os == .MACOS && OS != .MACOS continue;
            if it.javascript && skip_javascript continue;
            remaining += 1;

            it.workspace       = compiler_create_workspace(tprint("%1%2", it.os, ifx it.javascript then " JAVASCRIPT"));
            options           := get_build_options(it.workspace);
            options.os_target  = it.os;
            options.cpu_target = it.cpu;
            if it.os == OS {
                options.output_executable_name = ifx it.javascript then "forbear-javascript" else "forbear";
                options.output_path            = tprint("%.build/", #filepath);
                // TO-DO: also build a static library
                options.output_type = .DYNAMIC_LIBRARY;
            } else {
                options.output_type = .NO_OUTPUT;
            }
            set_build_options(options, it.workspace);

            compiler_begin_intercept(it.workspace);
            add_build_string(tprint("JAVASCRIPT :: %;", it.javascript), it.workspace);
            add_build_file(#file, it.workspace);
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
                        if declaration.flags & .PROGRAM_EXPORT && begins_with(declaration.name, "fb_") && declaration.expression && declaration.expression.type.type == .PROCEDURE {
                            array_add_if_unique(*target.exports, declaration);
                        }
                    }
                case .PHASE;
                    phase := cast(*Message_Phase) message;
                    if !target.javascript && phase.phase == .TYPECHECKED_ALL_WE_CAN && phase.num_items_waiting_to_typecheck == 0 {
                        quick_sort(target.roots,   (a, b) => compare_strings(a.name, b.name));
                        quick_sort(target.enums,   (a, b) => compare_strings(a.name, b.name));
                        quick_sort(target.exports, (a, b) => compare_strings(a.name, b.name));
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
        current_header_file := replace(read_entire_file(header_path), "\r\n", "\n");
        AUTO_GENERATED_BEGIN :: "// ====== BEGIN AUTO GENERATED PORTION ======\n";
        AUTO_GENERATED_END   :: "// ====== END AUTO GENERATED PORTION ======\n";

        before_auto_generated_content := slice(current_header_file,
                                               0,
                                               find_index_from_left(current_header_file, AUTO_GENERATED_BEGIN)
                                               + AUTO_GENERATED_BEGIN.count);
        append(*header.builder, before_auto_generated_content);
        for targets {
            if it.javascript continue;
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
} else {
    #insert #run,host -> string { #import "Basic"; return tprint("#import,file \"%forbear.jai\"(C_ABI = true, JAVASCRIPT_ADAPTER = JAVASCRIPT);", #filepath); };

    frame_context: #Context;
    frame_pool:  Flat_Pool;

    #program_export
    fb_init_forbear :: (forbear:            *Forbear,
                        program_backend:    *Backend,
                        program_window:     *Window,
                        program_base_style: Base_Style) #c_call {
        push_context frame_context { // at this point, it's just the default context
            forbear.* = .{};
            init_forbear(forbear, program_backend, program_window, program_base_style);

            frame_context.allocator.data = *frame_pool;
            frame_context.allocator.proc = flat_pool_allocator_proc;
        }
    }
    #program_export
    fb_init_backend :: (backend: *Backend) #c_call {
        push_context frame_context {
            backend.* = .{};
            init_backend(backend);
        }
    }
    #program_export
    fb_init_window :: (backend:    *Backend,
                       window:     *Window,
                       width:      float64,
                       height:     float64,
                       title:      *u8,
                       min_width:  float64,
                       min_height: float64,
                       max_width:  float64,
                       max_height: float64) #c_call {
        push_context frame_context {
            window.* = .{};
            init_window(backend, window, width, height, to_string(title), min_width, min_height, max_width, max_height);
        }
    }
    #if OS == .WINDOWS || OS == .MACOS {
        #program_export
        fb_update_backend :: (backend: *Backend) #c_call { push_context frame_context { update_backend(backend); } }
    }
    #if OS == .MACOS {
        #program_export
        fb_update_window :: (backend: *Backend, window: *Window) #c_call { push_context frame_context { update_window(backend, window); } }
    } else #if OS == .LINUX {
        #program_export
        fb_next_event :: (connection: *Wayland_Connection, wait: bool) -> Wayland_Event #c_call { push_context frame_context { return next_event(connection, wait); } }
        #program_export
        fb_can_draw :: (window: Window) -> bool #c_call { return can_draw(window); }

        #program_export
        fb_update_backend :: (backend: *Backend, event: Wayland_Event) #c_call { push_context frame_context { update_backend(backend, event); } }
        #program_export
        fb_update_window :: (backend: *Backend, window: *Window, event: Wayland_Event) #c_call { push_context frame_context { update_window(backend, window, event); } }
    }

    #program_export
    fb_create_font :: (memory: string) -> Font #c_call { return create_font(memory); }
    #program_export
    fb_init_font :: (font: *Font) #c_call { push_context frame_context { init_font(font); } }

    #if JAVASCRIPT {
        #program_export
        fb_create_javascript_adapter :: (source: string, source_name: *u8) -> *Javascript_Adapter #c_call {
            push_context frame_context {
                adapter := New(Javascript_Adapter,, context.forbear.persistent_allocator);
                init_adapter(adapter, frame_context.allocator, source, to_string(source_name));
                return adapter;
            }
        }
        #program_export
        fb_render_with_javascript_adapter :: (adapter: *Javascript_Adapter) #c_call { push_context frame_context { render_with_adapter(adapter); } }
    }

    #program_export
    fb_layout :: () #c_call { push_context frame_context { layout(); } }
    #program_export
    fb_draw :: (clearing_color: Vector4) #c_call { push_context frame_context { draw(clearing_color); } }

    #program_export
    fb_prepare_for_next_frame :: () #c_call {
        push_context frame_context {
            prepare_for_next_frame();
            reset_temporary_storage();
            reset(*frame_pool);
        }
    }

    #program_export
    fb_open_element :: (style: Style,
                        key:   *u8) -> Node_Opening_Data #c_call {
        push_context frame_context {
            key_string := to_string(key);
            key_hash   : u64;
            key_hash    = fnv1a_hash(key_string.data, key_string.count);
            if context.forbear.scope_key != Math.U64_MAX {
                key_hash = fnv1a_hash(context.forbear.scope_key, key_hash);
            }

            return open_element(style, key_hash);
        }
    }
    #program_export
    fb_close_element :: (data: Node_Opening_Data) #c_call { push_context frame_context { close_element(data); } }

    #program_export
    fb_open_scope :: (key: *u8) -> Node_Opening_Data #c_call { push_context frame_context { return open_scope(to_string(key)); } }
    #program_export
    fb_state :: (size: s64, initial: *void) -> *void #c_call { push_context frame_context { return state(size, initial); } }
    #program_export
    fb_frame_alloc :: (size: s64) -> *void #c_call { push_context frame_context { return alloc(size); } }
    #program_export
    fb_frame_realloc :: (memory: *void, size: s64, old_size: s64) -> *void #c_call { push_context frame_context { return realloc(memory, size, old_size); } }
    #program_export
    fb_node_alloc :: (size: s64) -> *void #c_call { push_context frame_context { return alloc(size,, node_pool()); } }
    #program_export
    fb_node_realloc :: (memory: *void, size: s64, old_size: s64) -> *void #c_call {
        push_context frame_context { return realloc(memory, size, old_size,, node_pool()); }
    }
    #program_export
    fb_close_scope :: (data: Node_Opening_Data) #c_call { push_context frame_context { close_scope(data, 0); } }

    #program_export
    fb_stext :: (style: Style, content: *u8, key: *u8) #c_call {
        push_context frame_context {
            key_string := to_string(key);
            key_hash   : u64;
            key_hash    = fnv1a_hash(key_string.data, key_string.count);
            if context.forbear.scope_key != Math.U64_MAX {
                key_hash = fnv1a_hash(context.forbear.scope_key, key_hash);
            }

            text(style, to_string(content), key_hash);
        }
    }
    #program_export
    fb_text :: (content: *u8, key: *u8) #c_call { fb_stext(Style.{}, content, key); }

    #program_export
    fb_opposite :: (direction: Direction) -> Direction #c_call { push_context frame_context { return opposite(direction); } }
    #program_export
    fb_fit :: () -> Sizing #c_call { push_context frame_context { return fit(); } }
    #program_export
    fb_fixed :: (value: float) -> Sizing #c_call { push_context frame_context { return fixed(value); } }
    #program_export
    fb_grow :: (value: float) -> Sizing #c_call { push_context frame_context { return grow(value); } }

    #program_export
    fb_all_sides :: (value: float) -> Sides #c_call { push_context frame_context { return all(value); } }
    #program_export
    fb_in_line_sides :: (value: float) -> Sides #c_call { push_context frame_context { return in_line(value); } }
    #program_export
    fb_with_in_line_sides :: (sides: Sides, value: float) -> Sides #c_call { push_context frame_context { return in_line(sides, value); } }
    #program_export
    fb_block_sides :: (value: float) -> Sides #c_call { push_context frame_context { return block(value); } }
    #program_export
    fb_with_block_sides :: (sides: Sides, value: float) -> Sides #c_call { push_context frame_context { return block(sides, value); } }
    #program_export
    fb_left_sides :: (value: float) -> Sides #c_call { push_context frame_context { return left(value); } }
    #program_export
    fb_with_left_sides :: (sides: Sides, value: float) -> Sides #c_call { push_context frame_context { return left(sides, value); } }
    #program_export
    fb_right_sides :: (value: float) -> Sides #c_call { push_context frame_context { return right(value); } }
    #program_export
    fb_with_right_sides :: (sides: Sides, value: float) -> Sides #c_call { push_context frame_context { return right(sides, value); } }
    #program_export
    fb_top_sides :: (value: float) -> Sides #c_call { push_context frame_context { return top(value); } }
    #program_export
    fb_with_top_sides :: (sides: Sides, value: float) -> Sides #c_call { push_context frame_context { return top(sides, value); } }
    #program_export
    fb_bottom_sides :: (value: float) -> Sides #c_call { push_context frame_context { return bottom(value); } }
    #program_export
    fb_with_bottom_sides :: (sides: Sides, value: float) -> Sides #c_call { push_context frame_context { return bottom(sides, value); } }

    #program_export
    fb_line_height_percentage :: (value: float) -> Line_Height #c_call { push_context frame_context { return line_height_percentage(value); } }
    #program_export
    fb_line_height_fixed :: (value: float) -> Line_Height #c_call { push_context frame_context { return line_height_fixed(value); } }

    c_easing: (t: float) -> float #c_call;
    call_c_easing :: (t: float) -> float { return c_easing(t); }
    c_use_transition :: (value: $T, duration: float, easing: (t: float) -> float #c_call) -> T {
        c_easing = easing;
        return use_transition(value, duration, call_c_easing);
    }
    #program_export
    fb_use_transition_f :: (value: float, duration: float, easing: (t: float) -> float #c_call) -> float #c_call {
        push_context frame_context { return c_use_transition(value, duration, easing); }
    }
    #program_export
    fb_use_transition_v2 :: (value: Vector2, duration: float, easing: (t: float) -> float #c_call) -> Vector2 #c_call {
        push_context frame_context { return c_use_transition(value, duration, easing); }
    }
    #program_export
    fb_use_transition_v3 :: (value: Vector3, duration: float, easing: (t: float) -> float #c_call) -> Vector3 #c_call {
        push_context frame_context { return c_use_transition(value, duration, easing); }
    }
    #program_export
    fb_use_transition_v4 :: (value: Vector4, duration: float, easing: (t: float) -> float #c_call) -> Vector4 #c_call {
        push_context frame_context { return c_use_transition(value, duration, easing); }
    }
    #program_export
    fb_use_spring_transition_f :: (target: float, config: Spring_Config(float)) -> float #c_call {
        push_context frame_context { return use_spring_transition(target, config); }
    }
    #program_export
    fb_use_spring_transition_v2 :: (target: Vector2, config: Spring_Config(Vector2)) -> Vector2 #c_call {
        push_context frame_context { return use_spring_transition(target, config); }
    }
    #program_export
    fb_use_spring_transition_v3 :: (target: Vector3, config: Spring_Config(Vector3)) -> Vector3 #c_call {
        push_context frame_context { return use_spring_transition(target, config); }
    }
    #program_export
    fb_use_spring_transition_v4 :: (target: Vector4, config: Spring_Config(Vector4)) -> Vector4 #c_call {
        push_context frame_context { return use_spring_transition(target, config); }
    }

    #program_export
    fb_schedule_scroll :: (state: *Scrolling_State, position: Vector2, animate: bool) #c_call {
        push_context frame_context { schedule_scroll(state, position, animate); }
    }
    #program_export
    fb_use_scrolling :: (state: *Scrolling_State) #c_call { push_context frame_context { use_scrolling(state); } }

    #program_export
    fb_from :: (style: Complete_Style) -> Base_Style #c_call { push_context frame_context { return from(style); } }

    #program_export
    fb_angle :: (degrees: float) -> Vector2 #c_call { push_context frame_context { return angle(degrees); } }
    #program_export
    fb_to_top :: () -> Vector2 #c_call { push_context frame_context { return to_top(); } }
    #program_export
    fb_to_bottom :: () -> Vector2 #c_call { push_context frame_context { return to_bottom(); } }
    #program_export
    fb_to_left :: () -> Vector2 #c_call { push_context frame_context { return to_left(); } }
    #program_export
    fb_to_right :: () -> Vector2 #c_call { push_context frame_context { return to_right(); } }
    #program_export
    fb_to_top_left :: () -> Vector2 #c_call { push_context frame_context { return to_top_left(); } }
    #program_export
    fb_to_top_right :: () -> Vector2 #c_call { push_context frame_context { return to_top_right(); } }
    #program_export
    fb_to_bottom_left :: () -> Vector2 #c_call { push_context frame_context { return to_bottom_left(); } }
    #program_export
    fb_to_bottom_right :: () -> Vector2 #c_call { push_context frame_context { return to_bottom_right(); } }

    #program_export
    fb_color :: (value: Vector4) -> Background #c_call { push_context frame_context { return color(value); } }
    #program_export
    fb_gradient :: (value: Linear_Gradient) -> Background #c_call { push_context frame_context { return gradient(value); } }
    #program_export
    fb_rgb :: (r: float, g: float, b: float) -> Vector4 #c_call { push_context frame_context { return rgb(r, g, b); } }
    #program_export
    fb_rgba :: (r: float, g: float, b: float, a: float) -> Vector4 #c_call { push_context frame_context { return rgba(r, g, b, a); } }

    #program_export
    fb_flow :: () -> Placement #c_call { push_context frame_context { return flow(); } }
    #program_export
    fb_fixed_placement :: (value: Vector2, corner: Corner) -> Placement #c_call { push_context frame_context { return fixed(value, corner); } }
    #program_export
    fb_relative :: (value: Vector2, corner: Corner) -> Placement #c_call { push_context frame_context { return relative(value, corner); } }

    #program_export
    fb_overwrite :: (overwritten: Style, overwriter: Style) -> Style #c_call { push_context frame_context { return overwrite(overwritten, overwriter); } }
    #program_export
    fb_complete_with :: (style: Style, base: Base_Style, out: *Complete_Style) #c_call { push_context frame_context { complete_with(style, base, out); } }

    #program_export
    fb_get_measurement :: (node_index: s64, include_scopes: bool, out: *Node_Measurement) -> bool #c_call {
        push_context frame_context {
            defined: bool;
            out.*, defined = get_measurement(node_index, include_scopes);
            return defined;
        }
    }

    #program_export
    fb_get_node :: (node_index: s64) -> *Node #c_call {
        push_context frame_context {
            if node_index == -1 return get_node();
            return get_node(node_index);
        }
    }
    #program_export
    fb_get_viewport_size :: () -> Vector2 #c_call { push_context frame_context { return get_viewport_size(); } }
    #program_export
    fb_get_delta_time :: () -> float #c_call { push_context frame_context { return get_delta_time(); } }
    #program_export
    fb_get_last_frame_time :: () -> float64 #c_call { push_context frame_context { return get_last_frame_time(); } }
    #program_export
    fb_get_preferred_theme :: () -> Preferred_Theme #c_call { push_context frame_context { return get_preferred_theme(); } }
    #program_export
    fb_set_cursor :: (cursor: Cursor) #c_call { push_context frame_context { set_cursor(cursor); } }

    #program_export
    fb_get_mouse_position :: () -> Vector2 #c_call { push_context frame_context { return get_mouse_position(); } }
    #program_export
    fb_get_scroll_delta :: () -> Vector2 #c_call { push_context frame_context { return get_scroll_delta(); } }
    #program_export
    fb_get_press_position :: (button: Mouse_Button) -> Vector2 #c_call { push_context frame_context { return get_press_position(button); } }
    #program_export
    fb_is_dragging :: (button: Mouse_Button) -> bool #c_call { push_context frame_context { return is_dragging(button); } }

    #program_export
    fb_is_mouse_inside :: () -> bool #c_call { push_context frame_context { return is_mouse_inside(); } }
    #program_export
    fb_is_mouse_held :: (button: Mouse_Button) -> bool #c_call { push_context frame_context { return is_mouse_held(button); } }
    #program_export
    fb_on_mouse_down :: (button: Mouse_Button, check_inside: bool) -> bool #c_call { push_context frame_context { return on_mouse_down(button, check_inside); } }
    #program_export
    fb_on_mouse_up :: (button: Mouse_Button, check_inside: bool) -> bool #c_call { push_context frame_context { return on_mouse_up(button, check_inside); } }
    #program_export
    fb_on_click :: (button: Mouse_Button, check_inside: bool, movement_threshold: bool) -> bool #c_call {
        push_context frame_context { return on_click(button, check_inside, movement_threshold); }
    }

    #program_export
    fb_get_clipboard_text :: () -> string #c_call { push_context frame_context { return get_clipboard_text(); } }
    #program_export
    fb_copy_to_clipboard :: (text: *u8) #c_call { push_context frame_context { copy_to_clipboard(to_string(text)); } }
    #program_export
    fb_get_text_input :: () -> string #c_call { push_context frame_context { return get_text_input(); } }

    #program_export
    fb_on_key_down :: (key: Key, on_repeat: bool) -> bool #c_call { push_context frame_context { return on_key_down(key, on_repeat); } }
    #program_export
    fb_on_key_up :: (key: Key) -> bool #c_call { push_context frame_context { return on_key_up(key); } }
    #program_export
    fb_is_key_held :: (key: Key) -> bool #c_call { push_context frame_context { return is_key_held(key); } }
}
