#import,file "../forbear.jai"(C_ABI = true);
#import "Hash";
Math :: #import "Math";

jai_context: #Context;

#program_export
fb_init_forbear :: (forbear:            *Forbear,
                    program_backend:    *Backend,
                    program_window:     *Window,
                    program_base_style: Base_Style) #c_call {
    push_context jai_context {
        forbear.* = .{};
        init_forbear(forbear, program_backend, program_window, program_base_style);
    }
}

#program_export
fb_open_element :: (style: Style,
                    key:   *u8) -> Node_Opening_Data #c_call {
    push_context jai_context {
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
fb_close_elemnet :: (data: Node_Opening_Data) #c_call {
    push_context jai_context {
        close_element(data);
    }
}

#program_export
fb_stext :: (style: Style, content: *u8, key: *u8) #c_call {
    push_context jai_context {
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
fb_text :: (content: *u8, key: *u8) #c_call {
    fb_stext(Style.{}, content, key);
}
