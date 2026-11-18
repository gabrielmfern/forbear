#import,file "../forbear.jai"(C_ABI = true);
#import "Basic";
#import "Hash";
#import "Flat_Pool";
Math :: #import "Math";

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
    fb_can_draw :: can_draw;

    #program_export
    fb_update_backend :: (backend: *Backend, event: Wayland_Event) #c_call { push_context frame_context { update_backend(backend, event); } }
    #program_export
    fb_update_window :: (backend: *Backend, window: *Window, event: Wayland_Event) #c_call { push_context frame_context { update_window(backend, window, event); } }
}

#program_export
fb_create_font :: create_font;
#program_export
fb_init_font :: (font: *Font) #c_call { push_context frame_context { init_font(font); } }

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
