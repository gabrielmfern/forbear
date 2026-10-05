#import "Basic";
#import "Hash";
#import,file "../forbear.jai":

javascript_shim :: #library,no_dll "../vendor/javascript";
libnode :: #library,link_always "../vendor/libnode/linux-x64/libnode";
libstdcpp :: #system_library,link_always "libstdc++";

Javascript_Adapter :: struct {
    // see javascript.cpp
    runtime: *void;
    frame_context: #Context;
    openings_stack: [..]Element_Opening_Data;
};

Javascript_Style_Field :: enum u8 {
    BACKGROUND; COLOR; BORDER_RADIUS; BORDER_COLOR; BORDER_WIDTH; BORDER_STYLE;
    SHADOW; FONT; FONT_WEIGHT; FONT_SIZE; LINE_HEIGHT; TEXT_WRAPPING; CURSOR;
    OVERFLOW; PLACEMENT; Z_INDEX; MIN_WIDTH; MAX_WIDTH; WIDTH; MIN_HEIGHT;
    MAX_HEIGHT; HEIGHT; TRANSLATE; PADDING; MARGIN; X_JUSTIFICATION;
    Y_JUSTIFICATION; DIRECTION;
};

javascript_init :: () -> *void #c_call;
javascript_style_get_number :: (runtime_opaque: *void, style_object: *void, field: Javascript_Style_Field, result: *float64) -> bool #c_call;
javascript_style_get_string_length :: (runtime_opaque: *void, style_object: *void, field: Javascript_Style_Field) -> s64 #c_call;
javascript_style_copy_string :: (runtime_opaque: *void, style_object: *void, field: Javascript_Style_Field, result: *u8, result_count: s64) -> bool #c_call;
javascript_style_get_array_count :: (runtime_opaque: *void, style_object: *void, field: Javascript_Style_Field) -> s64 #c_call;
javascript_style_get_array_number :: (runtime_opaque: *void, style_object: *void, field: Javascript_Style_Field, index: s64, result: *float64) -> bool #c_call;
javascript_style_get_array_string_length :: (runtime_opaque: *void, style_object: *void, field: Javascript_Style_Field, index: s64) -> s64 #c_call;
javascript_style_copy_array_string :: (runtime_opaque: *void, style_object: *void, field: Javascript_Style_Field, index: s64, result: *u8, result_count: s64) -> bool #c_call;
javascript_style_get_external :: (runtime_opaque: *void, style_object: *void, field: Javascript_Style_Field) -> *void #c_call;

init_javascript_adapter :: (adapter: *Javascript_Adapter, frame_context := context) {
    adapter.frame_context = frame_context;
    adapter.runtime = javascript_init();
}

render_with_javascript_adapter :: (adapter: *Javascript_Adapter) {
}

#scope_module;

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
        array_add(*adapter.openings_stack, open_element(style, key));
    }
}

forbear_close :: (adapter: *Javascript_Adapter) #c_call {
    push_context adapter.frame_context {
        opening := pop(*adapter.openings_stack);
        close_element(opening);
    }
}

forbear_text_push :: (adapter: *Javascript_Adapter, js_style_object: *void, content_data: *u8, content_count: s64, manual_key_data: *u8, manual_key_count: s64) #c_call {
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
        opening := open_element(style, key)
        opening.node.glyphs = shape_text(opening.node.style.font, content);
        close_element(opening);
    }
}
