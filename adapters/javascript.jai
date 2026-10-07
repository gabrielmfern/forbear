#import "Basic";
#import "Hash";
U64_MAX: u64 : 0xffff_ffff_ffff_ffff;

#run {
    #import "File";
    #import "File_Utilities";
    #import "Compiler";
    #import "BuildCpp";

    options := get_build_options();
    dest_dir := options.output_path;
    if !dest_dir.count {
        dest_dir = ".";
    }
    node_root := tprint("%/../vendor/node", #filepath);
    #if OS == .LINUX {
        src  := tprint("%/out/Release/lib/libnode.so.137", node_root);
        dest := tprint("%/libnode.so.137", dest_dir);
        copy := tprint("%/out/Release/lib/libnode.so", node_root);
        if !file_exists(copy) {
            copy_file(src, copy);
        }
    } else #if OS == .MACOS {
        src  := tprint("%/out/Release/lib/libnode.dylib", node_root);
        dest := tprint("%/libnode.dylib", dest_dir);
    }
    assert(file_exists(src), "libnode is missing; build vendor/node with --shared");
    if !file_exists(dest) {
        copy_file(src, dest);
    }

    build_cpp_static_lib(
        tprint("%/javascript", #filepath),
        tprint("%/javascript.cpp", #filepath),
        extra = .[
            "-std=c++20", "-fno-rtti", "-fno-exceptions", "-fPIC",
            tprint("-I%/src", node_root),
            tprint("-I%/deps/v8/include", node_root),
            tprint("-I%/deps/uv/include", node_root),
        ],
        debug = true,
    );
}

libm :: #library,system,link_always "libm";
libstdcpp :: #library,system,link_always "libstdc++";
libnode :: #library,link_always "../vendor/node/out/Release/lib/libnode";
javascript_shim :: #library,no_dll "./javascript";

Javascript_Adapter :: struct {
    // see javascript.cpp
    runtime: *void;
    frame_context: #Context;
    openings_stack: [..]Element_Opening_Data;
};

init_javascript_adapter :: (
    adapter: *Javascript_Adapter, 
    main_javascript_source: string, 
    main_javascript_source_name: string, 
) {
    adapter.frame_context = context;
    adapter.runtime = javascript_init(
        adapter,
        main_javascript_source.data, 
        main_javascript_source.count, 
        main_javascript_source_name.data, 
        main_javascript_source_name.count
    );
    if adapter.runtime == null {
        log_error("could not initliaze javascript runtime\n");
        exit(-1);
    }
}

render_with_javascript_adapter :: (adapter: *Javascript_Adapter) {
    // is there any data about the frame we should include here?
    javascript_render(adapter.runtime);
}

#scope_module;

Javascript_Style_Field :: enum u8 {
    BACKGROUND; COLOR; BORDER_RADIUS; BORDER_COLOR; BORDER_WIDTH; BORDER_STYLE;
    SHADOW; FONT; FONT_WEIGHT; FONT_SIZE; LINE_HEIGHT; TEXT_WRAPPING; CURSOR;
    OVERFLOW; PLACEMENT; Z_INDEX; MIN_WIDTH; MAX_WIDTH; WIDTH; MIN_HEIGHT;
    MAX_HEIGHT; HEIGHT; TRANSLATE; PADDING; MARGIN; X_JUSTIFICATION;
    Y_JUSTIFICATION; DIRECTION;
};

javascript_init :: (adapter: *void, source_data: *u8, source_count: s64, source_name_data: *u8, source_name_count: s64) -> *void #c_call #foreign javascript_shim;
javascript_render :: (runtime_opaque: *void) -> void #c_call #foreign javascript_shim;
javascript_style_get_number :: (runtime_opaque: *void, style_object: *void, field: Javascript_Style_Field, result: *float64) -> bool #c_call #foreign javascript_shim;
javascript_style_get_string_length :: (runtime_opaque: *void, style_object: *void, field: Javascript_Style_Field) -> s64 #c_call #foreign javascript_shim;
javascript_style_copy_string :: (runtime_opaque: *void, style_object: *void, field: Javascript_Style_Field, result: *u8, result_count: s64) -> bool #c_call #foreign javascript_shim;
javascript_style_get_array_count :: (runtime_opaque: *void, style_object: *void, field: Javascript_Style_Field) -> s64 #c_call #foreign javascript_shim;
javascript_style_get_array_number :: (runtime_opaque: *void, style_object: *void, field: Javascript_Style_Field, index: s64, result: *float64) -> bool #c_call #foreign javascript_shim;
javascript_style_get_array_string_length :: (runtime_opaque: *void, style_object: *void, field: Javascript_Style_Field, index: s64) -> s64 #c_call #foreign javascript_shim;
javascript_style_copy_array_string :: (runtime_opaque: *void, style_object: *void, field: Javascript_Style_Field, index: s64, result: *u8, result_count: s64) -> bool #c_call #foreign javascript_shim;
javascript_style_get_external :: (runtime_opaque: *void, style_object: *void, field: Javascript_Style_Field) -> *void #c_call #foreign javascript_shim;

// a little annoying that we have to jump through these hoops, but since Style
// is quite complicated and us making it C_ABI compatible would mean a lot of
// effort and change in the entire codebase, we do this conversion from Jai
// instead of C++. This means we need these helpers from C++ since Jai can't
// really do v8/node calls, and I don't want to use napi, since this is the
// same thing.
style_from :: (adapter: *Javascript_Adapter, js_style_object: *void) -> Style {
    result: Style;
    number: float64;

    if javascript_style_get_number(adapter.runtime, js_style_object, .BORDER_RADIUS, *number) {
        result.border_radius = cast(float) number;
    }
    if javascript_style_get_number(adapter.runtime, js_style_object, .FONT_WEIGHT, *number) {
        result.font_weight = cast(u16) number;
    }
    if javascript_style_get_number(adapter.runtime, js_style_object, .FONT_SIZE, *number) {
        result.font_size = cast(float) number;
    }
    if javascript_style_get_number(adapter.runtime, js_style_object, .LINE_HEIGHT, *number) {
        result.line_height = cast(float) number;
    }
    if javascript_style_get_number(adapter.runtime, js_style_object, .Z_INDEX, *number) {
        result.z_index = cast(u16) number;
    }
    if javascript_style_get_number(adapter.runtime, js_style_object, .MIN_WIDTH, *number) {
        result.min_width = cast(float) number;
    }
    if javascript_style_get_number(adapter.runtime, js_style_object, .MAX_WIDTH, *number) {
        result.max_width = cast(float) number;
    }
    if javascript_style_get_number(adapter.runtime, js_style_object, .MIN_HEIGHT, *number) {
        result.min_height = cast(float) number;
    }
    if javascript_style_get_number(adapter.runtime, js_style_object, .MAX_HEIGHT, *number) {
        result.max_height = cast(float) number;
    }

    if javascript_style_get_array_count(adapter.runtime, js_style_object, .COLOR) == 4 &&
        javascript_style_get_array_number(adapter.runtime, js_style_object, .COLOR, 0, *number) {
        result.color.x = cast(float) number;
        if javascript_style_get_array_number(adapter.runtime, js_style_object, .COLOR, 1, *number) {
            result.color.y = cast(float) number;
        }
        if javascript_style_get_array_number(adapter.runtime, js_style_object, .COLOR, 2, *number) {
            result.color.z = cast(float) number;
        }
        if javascript_style_get_array_number(adapter.runtime, js_style_object, .COLOR, 3, *number) {
            result.color.w = cast(float) number;
        }
    }

    if javascript_style_get_array_count(adapter.runtime, js_style_object, .BORDER_COLOR) == 4 &&
        javascript_style_get_array_number(adapter.runtime, js_style_object, .BORDER_COLOR, 0, *number) {
        result.border_color.x = cast(float) number;
        if javascript_style_get_array_number(adapter.runtime, js_style_object, .BORDER_COLOR, 1, *number) {
            result.border_color.y = cast(float) number;
        }
        if javascript_style_get_array_number(adapter.runtime, js_style_object, .BORDER_COLOR, 2, *number) {
            result.border_color.z = cast(float) number;
        }
        if javascript_style_get_array_number(adapter.runtime, js_style_object, .BORDER_COLOR, 3, *number) {
            result.border_color.w = cast(float) number;
        }
    }

    if javascript_style_get_array_count(adapter.runtime, js_style_object, .BORDER_WIDTH) == 4 &&
        javascript_style_get_array_number(adapter.runtime, js_style_object, .BORDER_WIDTH, 0, *number) {
        result.border_width.x.x = cast(float) number;
        if javascript_style_get_array_number(adapter.runtime, js_style_object, .BORDER_WIDTH, 1, *number) {
            result.border_width.x.y = cast(float) number;
        }
        if javascript_style_get_array_number(adapter.runtime, js_style_object, .BORDER_WIDTH, 2, *number) {
            result.border_width.y.x = cast(float) number;
        }
        if javascript_style_get_array_number(adapter.runtime, js_style_object, .BORDER_WIDTH, 3, *number) {
            result.border_width.y.y = cast(float) number;
        }
    }

    if javascript_style_get_array_count(adapter.runtime, js_style_object, .SHADOW) == 10 &&
        javascript_style_get_array_number(adapter.runtime, js_style_object, .SHADOW, 0, *number) {
        result.shadow.offset.x.x = cast(float) number;
        if javascript_style_get_array_number(adapter.runtime, js_style_object, .SHADOW, 1, *number) result.shadow.offset.x.y = cast(float) number;
        if javascript_style_get_array_number(adapter.runtime, js_style_object, .SHADOW, 2, *number) result.shadow.offset.y.x = cast(float) number;
        if javascript_style_get_array_number(adapter.runtime, js_style_object, .SHADOW, 3, *number) result.shadow.offset.y.y = cast(float) number;
        if javascript_style_get_array_number(adapter.runtime, js_style_object, .SHADOW, 4, *number) result.shadow.blur_radius = cast(float) number;
        if javascript_style_get_array_number(adapter.runtime, js_style_object, .SHADOW, 5, *number) result.shadow.spread = cast(float) number;
        if javascript_style_get_array_number(adapter.runtime, js_style_object, .SHADOW, 6, *number) result.shadow.color.x = cast(float) number;
        if javascript_style_get_array_number(adapter.runtime, js_style_object, .SHADOW, 7, *number) result.shadow.color.y = cast(float) number;
        if javascript_style_get_array_number(adapter.runtime, js_style_object, .SHADOW, 8, *number) result.shadow.color.z = cast(float) number;
        if javascript_style_get_array_number(adapter.runtime, js_style_object, .SHADOW, 9, *number) result.shadow.color.w = cast(float) number;
    }

    if javascript_style_get_array_count(adapter.runtime, js_style_object, .TRANSLATE) == 2 &&
        javascript_style_get_array_number(adapter.runtime, js_style_object, .TRANSLATE, 0, *number) {
        result.translate.x = cast(float) number;
        if javascript_style_get_array_number(adapter.runtime, js_style_object, .TRANSLATE, 1, *number) result.translate.y = cast(float) number;
    }

    if javascript_style_get_array_count(adapter.runtime, js_style_object, .PADDING) == 4 &&
        javascript_style_get_array_number(adapter.runtime, js_style_object, .PADDING, 0, *number) {
        result.padding.x.x = cast(float) number;
        if javascript_style_get_array_number(adapter.runtime, js_style_object, .PADDING, 1, *number) result.padding.x.y = cast(float) number;
        if javascript_style_get_array_number(adapter.runtime, js_style_object, .PADDING, 2, *number) result.padding.y.x = cast(float) number;
        if javascript_style_get_array_number(adapter.runtime, js_style_object, .PADDING, 3, *number) result.padding.y.y = cast(float) number;
    }

    if javascript_style_get_array_count(adapter.runtime, js_style_object, .MARGIN) == 4 &&
        javascript_style_get_array_number(adapter.runtime, js_style_object, .MARGIN, 0, *number) {
        result.margin.x.x = cast(float) number;
        if javascript_style_get_array_number(adapter.runtime, js_style_object, .MARGIN, 1, *number) result.margin.x.y = cast(float) number;
        if javascript_style_get_array_number(adapter.runtime, js_style_object, .MARGIN, 2, *number) result.margin.y.x = cast(float) number;
        if javascript_style_get_array_number(adapter.runtime, js_style_object, .MARGIN, 3, *number) result.margin.y.y = cast(float) number;
    }

    string_buffer: [16]u8;
    string_count := javascript_style_get_string_length(adapter.runtime, js_style_object, .BORDER_STYLE);
    if string_count <= string_buffer.count && javascript_style_copy_string(adapter.runtime, js_style_object, .BORDER_STYLE, string_buffer.data, string_count) {
        value := string.{ data = string_buffer.data, count = string_count };
        if value == "solid" result.border_style = .SOLID;
        if value == "dashed" result.border_style = .DASHED;
    }

    string_count = javascript_style_get_string_length(adapter.runtime, js_style_object, .TEXT_WRAPPING);
    if string_count <= string_buffer.count && javascript_style_copy_string(adapter.runtime, js_style_object, .TEXT_WRAPPING, string_buffer.data, string_count) {
        value := string.{ data = string_buffer.data, count = string_count };
        if value == "word" result.text_wrapping = .WORD;
        if value == "character" result.text_wrapping = .CHARACTER;
        if value == "none" result.text_wrapping = .NONE;
    }

    string_count = javascript_style_get_string_length(adapter.runtime, js_style_object, .CURSOR);
    if string_count <= string_buffer.count && javascript_style_copy_string(adapter.runtime, js_style_object, .CURSOR, string_buffer.data, string_count) {
        value := string.{ data = string_buffer.data, count = string_count };
        if value == "default" result.cursor = .DEFAULT;
        if value == "text" result.cursor = .TEXT;
        if value == "pointer" result.cursor = .POINTER;
    }

    string_count = javascript_style_get_string_length(adapter.runtime, js_style_object, .OVERFLOW);
    if string_count <= string_buffer.count && javascript_style_copy_string(adapter.runtime, js_style_object, .OVERFLOW, string_buffer.data, string_count) {
        value := string.{ data = string_buffer.data, count = string_count };
        if value == "visible" result.overflow = .VISIBLE;
        if value == "wrap" result.overflow = .WRAP;
    }

    string_count = javascript_style_get_string_length(adapter.runtime, js_style_object, .X_JUSTIFICATION);
    if string_count <= string_buffer.count && javascript_style_copy_string(adapter.runtime, js_style_object, .X_JUSTIFICATION, string_buffer.data, string_count) {
        value := string.{ data = string_buffer.data, count = string_count };
        if value == "start" result.x_justification = .START;
        if value == "center" result.x_justification = .CENTER;
        if value == "end" result.x_justification = .END;
    }

    string_count = javascript_style_get_string_length(adapter.runtime, js_style_object, .Y_JUSTIFICATION);
    if string_count <= string_buffer.count && javascript_style_copy_string(adapter.runtime, js_style_object, .Y_JUSTIFICATION, string_buffer.data, string_count) {
        value := string.{ data = string_buffer.data, count = string_count };
        if value == "start" result.y_justification = .START;
        if value == "center" result.y_justification = .CENTER;
        if value == "end" result.y_justification = .END;
    }

    string_count = javascript_style_get_string_length(adapter.runtime, js_style_object, .DIRECTION);
    if string_count <= string_buffer.count && javascript_style_copy_string(adapter.runtime, js_style_object, .DIRECTION, string_buffer.data, string_count) {
        value := string.{ data = string_buffer.data, count = string_count };
        if value == "horizontal" result.direction = .HORIZONTAL;
        if value == "vertical" result.direction = .VERTICAL;
    }

    array_count := javascript_style_get_array_count(adapter.runtime, js_style_object, .PLACEMENT);
    string_count = javascript_style_get_array_string_length(adapter.runtime, js_style_object, .PLACEMENT, 0);
    if string_count <= string_buffer.count && javascript_style_copy_array_string(adapter.runtime, js_style_object, .PLACEMENT, 0, string_buffer.data, string_count) {
        value := string.{ data = string_buffer.data, count = string_count };
        if array_count == 1 && value == "flow" {
            result.placement.kind = .FLOW;
        } else if array_count == 3 && value == "fixed" && javascript_style_get_array_number(adapter.runtime, js_style_object, .PLACEMENT, 1, *number) {
            result.placement.kind = .FIXED;
            result.placement.fixed.x = cast(float) number;
            if javascript_style_get_array_number(adapter.runtime, js_style_object, .PLACEMENT, 2, *number) result.placement.fixed.y = cast(float) number;
        } else if array_count == 3 && value == "relative" && javascript_style_get_array_number(adapter.runtime, js_style_object, .PLACEMENT, 1, *number) {
            result.placement.kind = .RELATIVE;
            result.placement.relative.x = cast(float) number;
            if javascript_style_get_array_number(adapter.runtime, js_style_object, .PLACEMENT, 2, *number) result.placement.relative.y = cast(float) number;
        }
    }

    array_count = javascript_style_get_array_count(adapter.runtime, js_style_object, .WIDTH);
    string_count = javascript_style_get_array_string_length(adapter.runtime, js_style_object, .WIDTH, 0);
    if string_count <= string_buffer.count && javascript_style_copy_array_string(adapter.runtime, js_style_object, .WIDTH, 0, string_buffer.data, string_count) {
        value := string.{ data = string_buffer.data, count = string_count };
        if array_count == 1 && value == "fit" {
            result.width.kind = .FIT;
        } else if array_count == 2 && value == "fixed" && javascript_style_get_array_number(adapter.runtime, js_style_object, .WIDTH, 1, *number) {
            result.width = fixed(cast(float) number);
        } else if array_count == 2 && value == "ratio" && javascript_style_get_array_number(adapter.runtime, js_style_object, .WIDTH, 1, *number) {
            result.width = ratio(cast(float) number);
        } else if array_count == 2 && value == "grow" && javascript_style_get_array_number(adapter.runtime, js_style_object, .WIDTH, 1, *number) {
            result.width = grow(cast(float) number);
        }
    }

    array_count = javascript_style_get_array_count(adapter.runtime, js_style_object, .HEIGHT);
    string_count = javascript_style_get_array_string_length(adapter.runtime, js_style_object, .HEIGHT, 0);
    if string_count <= string_buffer.count && javascript_style_copy_array_string(adapter.runtime, js_style_object, .HEIGHT, 0, string_buffer.data, string_count) {
        value := string.{ data = string_buffer.data, count = string_count };
        if array_count == 1 && value == "fit" {
            result.height.kind = .FIT;
        } else if array_count == 2 && value == "fixed" && javascript_style_get_array_number(adapter.runtime, js_style_object, .HEIGHT, 1, *number) {
            result.height = fixed(cast(float) number);
        } else if array_count == 2 && value == "ratio" && javascript_style_get_array_number(adapter.runtime, js_style_object, .HEIGHT, 1, *number) {
            result.height = ratio(cast(float) number);
        } else if array_count == 2 && value == "grow" && javascript_style_get_array_number(adapter.runtime, js_style_object, .HEIGHT, 1, *number) {
            result.height = grow(cast(float) number);
        }
    }

    background_count := javascript_style_get_array_count(adapter.runtime, js_style_object, .BACKGROUND);
    string_count = javascript_style_get_array_string_length(adapter.runtime, js_style_object, .BACKGROUND, 0);
    if background_count == 5 && string_count == 5 && javascript_style_copy_array_string(adapter.runtime, js_style_object, .BACKGROUND, 0, string_buffer.data, string_count) {
        kind := string.{ data = string_buffer.data, count = 5 };
        if kind == "color" && javascript_style_get_array_number(adapter.runtime, js_style_object, .BACKGROUND, 1, *number) {
            result.background.kind = .COLOR;
            result.background.color.x = cast(float) number;
            if javascript_style_get_array_number(adapter.runtime, js_style_object, .BACKGROUND, 2, *number) result.background.color.y = cast(float) number;
            if javascript_style_get_array_number(adapter.runtime, js_style_object, .BACKGROUND, 3, *number) result.background.color.z = cast(float) number;
            if javascript_style_get_array_number(adapter.runtime, js_style_object, .BACKGROUND, 4, *number) result.background.color.w = cast(float) number;
        }
    } else if background_count >= 3 && (background_count - 3) % 5 == 0 && string_count == 8 && javascript_style_copy_array_string(adapter.runtime, js_style_object, .BACKGROUND, 0, string_buffer.data, string_count) {
        kind := string.{ data = string_buffer.data, count = 8 };
        if kind == "gradient" &&
            javascript_style_get_array_number(adapter.runtime, js_style_object, .BACKGROUND, 1, *number) {
            result.background.kind = .GRADIENT;
            result.background.gradient.direction.x = cast(float) number;
            if javascript_style_get_array_number(adapter.runtime, js_style_object, .BACKGROUND, 2, *number) {
                result.background.gradient.direction.y = cast(float) number;
                stops: [..]Gradient_Stop;
                for 0..(background_count - 3) / 5 - 1 {
                    index := 3 + it * 5;
                    stop: Gradient_Stop;
                    if !javascript_style_get_array_number(adapter.runtime, js_style_object, .BACKGROUND, index, *number) break;
                    stop.color.x = cast(float) number;
                    if !javascript_style_get_array_number(adapter.runtime, js_style_object, .BACKGROUND, index + 1, *number) break;
                    stop.color.y = cast(float) number;
                    if !javascript_style_get_array_number(adapter.runtime, js_style_object, .BACKGROUND, index + 2, *number) break;
                    stop.color.z = cast(float) number;
                    if !javascript_style_get_array_number(adapter.runtime, js_style_object, .BACKGROUND, index + 3, *number) break;
                    stop.color.w = cast(float) number;
                    if !javascript_style_get_array_number(adapter.runtime, js_style_object, .BACKGROUND, index + 4, *number) break;
                    stop.position = cast(float) number;
                    array_add(*stops, stop);
                }
                result.background.gradient.stops = stops;
            }
        }
    }

    result.font = cast(*Font) javascript_style_get_external(adapter.runtime, js_style_object, .FONT);
    return result;
}

#program_export
forbear_open :: (adapter: *Javascript_Adapter, js_style_object: *void, manual_key_data: *u8, manual_key_count: s64) #c_call {
    push_context adapter.frame_context {
        key: u64;
        key = fnv1a_hash(manual_key_data, manual_key_count);
        if context.forbear.scope_key != U64_MAX {
            key = fnv1a_hash(context.forbear.scope_key, key);
        }
        if context.forbear.parent_index != -1 {
            key = fnv1a_hash(cast(u64) context.forbear.parent_index, key);
        }
        style := style_from(adapter, js_style_object);
        array_add(*adapter.openings_stack, open_element(style, key));
    }
}

#program_export
forbear_close :: (adapter: *Javascript_Adapter) #c_call {
    push_context adapter.frame_context {
        opening := pop(*adapter.openings_stack);
        close_element(opening);
    }
}

#program_export
forbear_text :: (adapter: *Javascript_Adapter, js_style_object: *void, content_data: *u8, content_count: s64, manual_key_data: *u8, manual_key_count: s64) #c_call {
    push_context adapter.frame_context {
        content: string;
        content.data = content_data;
        content.count = content_count;
        key: u64;
        key = fnv1a_hash(manual_key_data, manual_key_count);
        if context.forbear.scope_key != U64_MAX {
            key = fnv1a_hash(context.forbear.scope_key, key);
        }
        if context.forbear.parent_index != -1 {
            key = fnv1a_hash(cast(u64) context.forbear.parent_index, key);
        }
        style := style_from(adapter, js_style_object);
        opening := open_element(style, key);
        opening.node.glyphs = shape_text(opening.node.style.font, content);
        close_element(opening);
    }
}
