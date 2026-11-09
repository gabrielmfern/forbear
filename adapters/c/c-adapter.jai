#import,file "../../forbear.jai";
#import "Hash";
#import "Math";

#program_export
init_forbear :: () #c_call {
}

#program_export
open_element :: (
    style: Style,
    key_c_string: *u8,
    ctx: *void
) -> Node_Opening_Data #c_call {
    push_context ctx.(*#Context).* {
        key_string := to_string(key_c_string);
        key: u64;
        key = fnv1a_hash(key_string.data, key_string.count);
        if context.forbear.scope_key != U64_MAX {
            key = fnv1a_hash(context.forbear.scope_key, key);
        }

        return open_element(style, key);
    }
}

#program_export
close_elemnet :: (data: Node_Opening_Data, ctx: *void) #c_call {
    push_context ctx.(*#Context) {
        close_element(data);
    }
}

#program_export
stext :: (style: Style, content_c_string: *u8, key_c_string: *u8, ctx: *void) #c_call {
    push_context ctx.(*#Context) {
        key_string := to_string(key_c_string);
        key: u64;
        key = fnv1a_hash(key_string.data, key_string.count);
        if context.forbear.scope_key != U64_MAX {
            key = fnv1a_hash(context.forbear.scope_key, key);
        }

        text(style, to_string(key_c_string), to_string(content_c_string));
    }
}
#program_export
text :: (content_c_string: *u8, key_c_string: *u8, ctx: *void) #c_call {
    stext(Style.{}, content_c_string, key_c_string, ctx);
}
