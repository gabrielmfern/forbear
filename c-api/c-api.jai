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
