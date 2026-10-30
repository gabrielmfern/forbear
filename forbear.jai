#module_parameters(JAVASCRIPT_ADAPTER := false);

Vector2 :: Math.Vector2;
Vector4 :: Math.Vector4;
operator + :: Math.operator +;
operator - :: Math.operator -;
operator * :: Math.operator *;
operator / :: Math.operator /;
operator == :: Math.operator ==;

#scope_module

#import "Basic";
#import "Flat_Pool";
#import "GL";
#import "Hash";
#import "Hash_Table";
#import "Memory";
#if OS != .WINDOWS {
    #import "POSIX";
    #import "Socket";
}
#import "String";
Math :: #import "Math";

min :: Math.min;
max :: Math.max;
FLOAT32_NAN :: Math.FLOAT32_NAN;
FLOAT32_INFINITY :: Math.FLOAT32_INFINITY;
U16_MAX :: Math.U16_MAX;
U32_MAX :: Math.U32_MAX;
U64_MAX :: Math.U64_MAX;
floor :: Math.floor;
abs :: Math.abs;
isnan :: Math.isnan;
make_vector2 :: Math.make_vector2;
make_vector4 :: Math.make_vector4;

isnan :: (value: Vector2) -> bool {
    return isnan(value.x) || isnan(value.y);
}

compile_shader :: (kind: GLenum, source: string) -> u32 {
    shader := glCreateShader(kind);
    data := source.data;
    length: GLint = xx source.count;
    glShaderSource(shader, 1, *data, *length);
    glCompileShader(shader);

    status: GLint;
    glGetShaderiv(shader, GL_COMPILE_STATUS, *status);
    if !status {
        log: [1024]u8;
        log_length: GLsizei;
        glGetShaderInfoLog(shader, log.count, *log_length, log.data);
        log_error("failed to compile shader: %\n", to_string(log.data, log_length));
        exit(-1);
    }
    return shader;
}

append_text :: (source: string, destination: *string, buffer: []u8) {
    is_control_character := source.count == 1 && (source[0] < 0x20 || source[0] == 0x7f);
    if !is_control_character {
        if destination.count + source.count <= buffer.count {
            memcpy(destination.data + destination.count, source.data, source.count);
            destination.count += source.count;
        } else {
            log_error("trying to append to a buffered string of size %, which exceeds the buffer size %. dropping it entirely.", source.count, buffer.count);
        }
    }
}

#if OS == .LINUX {
    key_text :: (state: *xkb_state, key_code: u32, utf8: []u8) -> string {
        text: string;
        if xkb_state_mod_name_is_active(state, XKB_MOD_NAME_ALT.data, .XKB_STATE_MODS_EFFECTIVE) == 0 &&
            xkb_state_mod_name_is_active(state, XKB_MOD_NAME_LOGO.data, .XKB_STATE_MODS_EFFECTIVE) == 0 {
            length := xkb_state_key_get_utf8(state, key_code, utf8.data, xx utf8.count);
            if length < utf8.count {
                text = to_string(utf8.data, length);
            } else {
                log_error("we separated a % sized utf8 buffer for the key %, but it required length %. dropping it entirely.", utf8.count, key_code, length);
            }
        }
        return text;
    }
}

add_key_event :: (events: *[]Key_Event, key_event: Key_Event) {
    assert(events.count < 32 * 3);
    events.count += 1;
    events.*[events.count - 1] = key_event;
}

#scope_export

#if JAVASCRIPT_ADAPTER == true {
    #load "./adapters/javascript.jai";
}

#if OS == .LINUX {
    #load "bindings-linux.jai";

    #scope_module
    WAYLAND_DEBUGGING :: false;
    EGL_DEBUGGING :: false;
    EXIT_ON_FIRST_FRAME :: false;

    GL_FRAMEBUFFER_FLIP_Y_MESA :: 35771;

    Wayland_Message_header :: struct {
        object_id: u32;
        opcode: u16;
        size: u16;
    } #no_padding;
    MAX_WAYLAND_MESSAGE_SIZE :: 4096;
    #scope_export
    Wayland_Connection :: struct {
        fd: s32;
        polling_fd: pollfd;

        wl_pointer_id: u32;
        wl_keyboard_id: u32;
        wl_seat_id: u32;
        wl_display_id: u32;
        wl_registry_id: u32;
        wl_compositor_id: u32;
        zwp_dmabuf_id: u32;
        xdg_wm_base_id: u32;

        //
        // TODO(depessimization): I do not like that xkb allocates the structs and also does reference counting with
        // them which is quite bad.
        //
        // In the long-term, we should write our own implementation, but Wayland is already
        // taking a lot of the code here which is unfortunate because Wayland is actually most likely not going to
        // include most users.
        //
        xkb: *xkb_context;
        keymap: *xkb_keymap;
        key_state: *xkb_state;
        compose_table: *xkb_compose_table;
        compose_state: *xkb_compose_state;

        reading_buffer: [MAX_WAYLAND_MESSAGE_SIZE]u8;
        pending_reads: []u8;
        reading_fds_buffer: [8]s32;
        pending_read_fds: []s32;

        client_object_interfaces: [..]Interface_Id;
        free_client_object_interface_ids: [..]s64;
        server_object_interfaces: [..]Interface_Id;
    };
    sockaddr_un :: struct {
        sun_family: sa_family_t;
        sun_path: [100]u8;
    };
    init_wayland_connection :: (connection: *Wayland_Connection) {
        connection.fd = socket(AF_UNIX, SOCK.STREAM, 0);
        connection.polling_fd = pollfd.{ fd = connection.fd, events = POLLIN };

        runtime_directory := to_string(getenv("XDG_RUNTIME_DIR"));
        wayland_display := to_string(getenv("WAYLAND_DISPLAY"));
        if trim(wayland_display).count == 0 {
            log_error("$WAYLAND_DISPLAY is not defined, using wayland-0");
            wayland_display = "wayland-0";
        }
        path := tprint("%/%", runtime_directory, wayland_display);

        address: sockaddr_un;
        address.sun_family = AF_UNIX;
        memcpy(cast(*void) address.sun_path.data, cast(*void) path.data, path.count);
        address.sun_path[path.count] = 0;

        if connect(connection.fd, cast(*sockaddr) *address, size_of(sockaddr_un)) != 0 {
            // I once got an errno 2 here and the WAYLAND_DISPLAY env undefined when I started a tmux session in x11 and then
            // reattached to it from Wayland. In that case I was able to fix by setting the env in the rnuning tmux session
            //
            // tmux set-environment -t [SESSION_NAME] WAYLAND_DISPLAY "$WAYLAND_DISPLAY"
            // tmux set-environment -t [SESSION_NAME] XDG_RUNTIME_DIR "$XDG_RUNTIME_DIR"
            //
            log_error("connection failed: %\n", errno());
            exit(-1);
        }
        if WAYLAND_DEBUGGING {
            print("connected to %\n", path);
        }

        connection.wl_display_id = new_wayland_client_object(connection, Interface_Id.WL_DISPLAY);
        connection.wl_registry_id = new_wayland_client_object(connection, Interface_Id.WL_REGISTRY);

        connection.xkb = xkb_context_new(xkb_context_flags.XKB_CONTEXT_NO_FLAGS);

        locale := getenv("LC_ALL");
        if !locale || !locale[0] {
            locale = getenv("LC_CTYPE");
        }
        if !locale || !locale[0] {
            locale = getenv("LANG");
        }
        if !locale || !locale[0] {
            locale = "C".data;
        }
        connection.compose_table = xkb_compose_table_new_from_locale(connection.xkb, locale, .XKB_COMPOSE_COMPILE_NO_FLAGS);
        if connection.compose_table {
            connection.compose_state = xkb_compose_state_new(connection.compose_table, .XKB_COMPOSE_STATE_NO_FLAGS);
        } else {
            log_error("no compose table for locale %, dead keys and compose sequences will not work", to_string(locale));
        }

        send_wayland_message(connection, 1, Wl_Display_Request_Get_Registry.{ registry = connection.wl_registry_id });
        sync_id := new_wayland_client_object(connection, .WL_CALLBACK);
        send_wayland_message(connection, connection.wl_display_id, Wl_Display_Request_Sync.{ callback = sync_id });
        synced := false;
        while !synced {
            event := next_event(connection);
            if !event.something {
                poll(connection);
                continue;
            }

            update_wayland_connection(connection, event);
            if event.message.type == {
                case Wl_Registry_Event_Global;
                    bind_global :: (connection: *Wayland_Connection, interface_id: Interface_Id, global: Wl_Registry_Event_Global, version := U32_MAX) -> u32 {
                        id := new_wayland_client_object(connection, interface_id);
                        send_wayland_message(connection, connection.wl_registry_id, Wl_Registry_Request_Bind.{
                            name = global.name,
                            interface_name = global.interface_name,
                            version = ifx version == U32_MAX then
                                min(INTERFACES[interface_id].version, global.version)
                            else
                                min(version, global.version),
                            id = id,
                        });
                        return id;
                    }

                    global := cast(*Wl_Registry_Event_Global) event.data;
                    if global.interface_name == "wl_compositor" {
                        connection.wl_compositor_id = bind_global(connection, Interface_Id.WL_COMPOSITOR, global);
                    } else if global.interface_name == "xdg_wm_base" {
                        connection.xdg_wm_base_id = bind_global(connection, Interface_Id.XDG_WM_BASE, global);
                    } else if global.interface_name == "zwp_linux_dmabuf_v1" {
                        // version 3 of this makes it easier for us to get the buffer types back
                        connection.zwp_dmabuf_id = bind_global(connection, Interface_Id.ZWP_LINUX_DMABUF_V1, global, 3);
                    } else if global.interface_name == "wl_seat" {
                        connection.wl_seat_id = bind_global(connection, Interface_Id.WL_SEAT, global);
                    }
                case Wl_Callback_Event_Done;
                    synced = true;
            }

            reset_temporary_storage();
        }
        assert(connection.wl_compositor_id != 0, "expected wl_compositor to have been bound");
        assert(connection.xdg_wm_base_id != 0, "expected xdg_wm_base to have been bound");
        assert(connection.zwp_dmabuf_id != 0, "expected zwp_dmabuf to have been bound");
    }
    update_wayland_connection :: (connection: *Wayland_Connection, event: Wayland_Event) {
        if event.object_id == connection.wl_display_id {
            if event.message.type == {
                case Wl_Display_Event_Delete_Id;
                    delete := cast(*Wl_Display_Event_Delete_Id) event.data;
                    array_add(*connection.free_client_object_interface_ids, delete.id);
                case Wl_Display_Event_Error;
                    error := cast(*Wl_Display_Event_Error) event.data;
                    log_error(
                        "protocol error on object % (%): code %, %",
                        error.object_id,
                        connection.client_object_interfaces[error.object_id - 1],
                        error.code,
                        error.message
                    );
                    exit(-1);
            }
        } else if event.object_id == connection.xdg_wm_base_id && event.message.type == Xdg_Wm_Base_Event_Ping {
            ping := cast(*Xdg_Wm_Base_Event_Ping) event.data;
            send_wayland_message(connection, connection.xdg_wm_base_id, Xdg_Wm_Base_Request_Pong.{ping.serial});
        } else if event.object_id == connection.wl_seat_id && event.message.type == Wl_Seat_Event_Capabilities {
            capabilities := cast(*Wl_Seat_Event_Capabilities) event.data;
            if (capabilities.capabilities & .POINTER) && connection.wl_pointer_id == 0 {
                connection.wl_pointer_id = new_wayland_client_object(connection, .WL_POINTER);
                send_wayland_message(connection, connection.wl_seat_id, Wl_Seat_Request_Get_Pointer.{ id = connection.wl_pointer_id });
            }
            if (capabilities.capabilities & .KEYBOARD) && connection.wl_keyboard_id == 0 {
                connection.wl_keyboard_id = new_wayland_client_object(connection, .WL_KEYBOARD);
                send_wayland_message(connection, connection.wl_seat_id, Wl_Seat_Request_Get_Keyboard.{ id = connection.wl_keyboard_id });
            }
        } else if event.object_id == connection.wl_keyboard_id {
            if event.message.type == {
                case Wl_Keyboard_Event_Keymap;
                    keymap := cast(*Wl_Keyboard_Event_Keymap) event.data;
                    defer close(cast(s32) keymap.fd);
                    assert(keymap.format == .XKB_V1, "unsupported keymap format");
                    memory := mmap(null, keymap.size, PROT_READ, MAP_PRIVATE, cast(s32) keymap.fd, 0);
                    defer munmap(memory, keymap.size);
                    assert(memory != MAP_FAILED, "could not map the keymap");
                    if connection.key_state {
                        xkb_state_unref(connection.key_state);
                    }
                    if connection.keymap {
                        xkb_keymap_unref(connection.keymap);
                    }
                    connection.keymap = xkb_keymap_new_from_string(
                        connection.xkb,
                        memory,
                        .XKB_KEYMAP_FORMAT_TEXT_V1,
                        .XKB_KEYMAP_COMPILE_NO_FLAGS
                    );
                    connection.key_state = xkb_state_new(connection.keymap);
                case Wl_Keyboard_Event_Modifiers;
                    modifiers := cast(*Wl_Keyboard_Event_Modifiers) event.data;
                    xkb_state_update_mask(
                        connection.key_state,
                        modifiers.mods_depressed,
                        modifiers.mods_latched,
                        modifiers.mods_locked,
                        0, 0, modifiers.group
                    );
            }
        }
    }
    poll :: (connection: *Wayland_Connection, timeout_ms: s32 = 1000) {
        polling_result := poll(*connection.polling_fd, 1, timeout_ms);
        if polling_result == {
            case 0;
                log_error("Timed out while waiting for the socket to have something readable");
                exit(-1);
            case -1;
                log_error("Failed to poll the compositor's socket: %", errno());
                exit(-1);
        }
    }

    new_wayland_client_object :: (connection: *Wayland_Connection, interface_id: Interface_Id) -> u32 {
        if connection.free_client_object_interface_ids.count > 0 {
            // we reuse ids that have been deleted/freed
            id := pop(*connection.free_client_object_interface_ids);
            connection.client_object_interfaces[id - 1] = interface_id;

            return xx id;
        } else {
            array_add(*connection.client_object_interfaces, interface_id);
            return xx connection.client_object_interfaces.count;
        }
    }

    Wayland_Event :: struct {
        something: bool;
        message: Message_Info;
        data: *void;
        object_id: u32;
    };
    next_event :: (connection: *Wayland_Connection, wait := false) -> Wayland_Event {
        while connection.pending_reads.count < size_of(Wayland_Message_header) ||
        connection.pending_reads.count < (cast(*Wayland_Message_header) connection.pending_reads.data).size {
            leftover := connection.pending_reads.count;
            copy(connection.reading_buffer.data, connection.pending_reads.data, leftover);

            flags: MSG = .CMSG_CLOEXEC;
            if !wait {
                flags |= .DONTWAIT;
            }
            control: struct {
                using header: cmsghdr;
                fds: [8]s32;
            };
            iov := iovec.{
                iov_base = connection.reading_buffer.data + leftover,
                iov_len = xx (connection.reading_buffer.count - leftover)
            };
            message_header := msghdr.{
                msg_iov = *iov,
                msg_iovlen = 1,
                msg_control = *control,
                msg_controllen = size_of(type_of(control))
            };
            result := recvmsg(connection.fd, *message_header, flags);
            assert(!(message_header.msg_flags & xx MSG.CTRUNC), "control buffer too small, file descriptors were dropped");
            if result == 0 {
                log_error("compositor closed the connection");
                exit(-1);
            }
            if result == -1 {
                error_code := errno();
                if error_code == EINTR  {
                    continue;
                }
                if error_code == EAGAIN  {
                    return Wayland_Event.{};
                }
                log_error("failed to read back from socket: %\n", error_code);
                exit(-1);
            }
            if message_header.msg_controllen > 0 {
                assert(control.header.cmsg_level == SOL_SOCKET && control.header.cmsg_type == xx SCM.RIGHTS);

                new_fds_count := (cast(s64) control.header.cmsg_len - size_of(cmsghdr)) / size_of(s32);
                assert(connection.pending_read_fds.count + new_fds_count <= connection.reading_fds_buffer.count, "too many file descriptors pending");
                memcpy(*connection.reading_fds_buffer[connection.pending_read_fds.count], control.fds.data, new_fds_count * size_of(s32));
                connection.pending_read_fds.data = connection.reading_fds_buffer.data;
                connection.pending_read_fds.count += new_fds_count;
            }

            connection.pending_reads = array_view(connection.reading_buffer, 0, result + leftover);
        }

        incoming_message_header := cast(*Wayland_Message_header) connection.pending_reads.data;

        object_interface_id: Interface_Id;
        if incoming_message_header.object_id >= 0xff000000 {
            // means it's a server object id
            object_interface_id = connection.server_object_interfaces[incoming_message_header.object_id - 0xff000000];
        } else {
            object_interface_id = connection.client_object_interfaces[incoming_message_header.object_id - 1];
        }
        message_info: Message_Info = MESSAGES[
            INTERFACES[object_interface_id].first_event + incoming_message_header.opcode
        ];

        incoming_message := array_view(connection.pending_reads, size_of(Wayland_Message_header), incoming_message_header.size - size_of(Wayland_Message_header));
        connection.pending_reads.data += incoming_message_header.size;
        connection.pending_reads.count -= incoming_message_header.size;

        data := parse_wayland_message(incoming_message, message_info, *connection.pending_read_fds);

        if WAYLAND_DEBUGGING {
            print("\n");
            print("message received\n");
            print("event.type %\n", message_info.type);
            print("object interface %\n", object_interface_id);
            print("\n");
        }

        return Wayland_Event.{
            message = message_info,
            data = data,
            something = true,
            object_id = incoming_message_header.object_id,
        };
    }
    // TODO(depessimization): we should be buffering the messages and flushing them instead of sending them all one by one
    writing_buffer: [MAX_WAYLAND_MESSAGE_SIZE]u8;
    send_wayland_message :: (connection: *Wayland_Connection, object_id: u32, message: $T) {
        bytes := array_view(writing_buffer, 0, size_of(Wayland_Message_header));

        m := message;
        message_type_info := type_info(T);

        add_bytes :: (bytes: *[]u8, source: *void, count: s64) {
            old := bytes.count;
            bytes.count = old + count;
            assert(bytes.count < MAX_WAYLAND_MESSAGE_SIZE);
            memcpy(bytes.data + old, source, count);
        }

        pad_to_four :: (bytes: *[]u8) {
            while bytes.count % 4 {
                bytes.count += 1;
                assert(bytes.count < MAX_WAYLAND_MESSAGE_SIZE);
            }
        }

        fd_to_send: s32 = -1;

        for T.ARGS {
            arg_member := message_type_info.members[it_index + 2];
            source := (cast(*u8) *m) + arg_member.offset_in_bytes;
            if it == {
                case .FILE_DESCRIPTOR;
                    fd_to_send = (cast(*s32) source).*;
                case .STRING;
                    value := (cast(*string) source).*;
                    length: u32 = xx (value.count + 1);
                    add_bytes(*bytes, *length, 4);
                    add_bytes(*bytes, value.data, value.count);
                    bytes.count += 1;
                    assert(bytes.count < MAX_WAYLAND_MESSAGE_SIZE);
                    bytes[bytes.count - 1] = 0;
                    pad_to_four(*bytes);
                case .ARRAY;
                    value := (cast(*[]u8) source).*;
                    count: u32 = xx value.count;
                    add_bytes(*bytes, *count, 4);
                    add_bytes(*bytes, value.data, value.count);
                    pad_to_four(*bytes);
                case;
                    add_bytes(*bytes, source, 4);
            }
        }

        header := cast(*Wayland_Message_header) bytes.data;
        header.object_id = object_id;
        header.opcode = T.OPCODE;
        header.size = xx bytes.count;

        if WAYLAND_DEBUGGING {
            print("\n");
            print("message sent\n");
            print("event %\n", T);
            print("\n");
        }

        iov := iovec.{ bytes.data, xx bytes.count };
        msg_header: msghdr;
        msg_header.msg_iov = *iov;
        msg_header.msg_iovlen = 1;

        control: [24] u8;
        if fd_to_send != -1 {
            cmsg := cast(*cmsghdr) control.data;
            cmsg.cmsg_len = 20;
            cmsg.cmsg_level = SOL_SOCKET;
            cmsg.cmsg_type = xx SCM.RIGHTS;
            (cast(*s32) (control.data + 16)).* = fd_to_send;
            msg_header.msg_control = control.data;
            msg_header.msg_controllen = control.count;
        }

        result := sendmsg(connection.fd, *msg_header, .NOSIGNAL);

        if result == -1 {
            error_code := errno();
            if error_code == EPIPE {
                log_error("compositor closed the connection, draining what it sent before closing:");
                while true {
                    next_event(connection);
                }
            }
            log_error("could not send wayland message: %\n", error_code);
            exit(-1);
        }
        memset(writing_buffer.data, 0, bytes.count);

        assert(result == bytes.count, "incomplete message was sent. something went wrong");
    }
    parsing_buffer : [MAX_MESSAGE_STRUCT_SIZE]u8;
    parse_wayland_message :: (bytes: []u8, message_info: Message_Info, fds: *[]s32) -> *void {
        args := array_view(ARGS, message_info.first_arg, message_info.arg_count);
        message_type_info := cast(*Type_Info_Struct) message_info.type;

        untyped_message_bytes := array_view(parsing_buffer, 0, message_type_info.runtime_size);

        remainder := bytes;
        for args {
            // + 1 because we want to igonre OPCODE and ARGS
            arg_member := message_type_info.members[it_index + 2];

            arg_type_info := cast(*Type_Info) arg_member.type;
            if it == {
                case ProtocolType.FILE_DESCRIPTOR;
                    assert(fds.count > 0, "a messaged named a file descriptor that never arrived");
                    fd := fds.*[0];
                    memcpy(*untyped_message_bytes[arg_member.offset_in_bytes], *fd, size_of(s32));
                    for 0..fds.count - 2 {
                        // move all fds one index down
                        fds.*[it] = fds.*[it + 1];
                    }
                    fds.count -= 1;
                case ProtocolType.STRING;
                    value: string;
                    // we subtract one because this is a C string, with a NULL terminator
                    value.count = xx (cast(*u32) remainder.data).* - 1;
                    remainder.data += 4;

                    value.data = remainder.data;
                    remainder.data += (value.count + 4) & ~3; // account for the padding to four, and the -1 we did before
                    memcpy(
                        cast(*void) *untyped_message_bytes[arg_member.offset_in_bytes],
                        cast(*void) *value,
                        arg_type_info.runtime_size
                    );
                case ProtocolType.ARRAY;
                    value: []u8;
                    value.count = xx (cast(*u32) remainder.data).*;
                    remainder.data += 4;

                    value.data = remainder.data;
                    remainder.data += (value.count + 3) & ~3;
                    memcpy(
                        cast(*void) *untyped_message_bytes[arg_member.offset_in_bytes],
                        cast(*void) *value,
                        arg_type_info.runtime_size
                    );
                case ProtocolType.INT; #through;
                case ProtocolType.FIXED; #through;
                case ProtocolType.OBJECT; #through;
                case ProtocolType.NEW_ID; #through;
                case ProtocolType.UINT;
                    memcpy(
                        cast(*void) *untyped_message_bytes[arg_member.offset_in_bytes],
                        cast(*void) remainder.data,
                        arg_type_info.runtime_size
                    );
                    remainder.data += arg_type_info.runtime_size;
            }
        }

        return cast(*void) untyped_message_bytes.data;
    }

    Wayland_EGL_Window :: struct {
        wl_surface_id: u32;
        wl_buffer_params_id: u32;
        wl_frame_callback_id: u32;

        xdg_surface_id: u32;
        // only top level windows are supported. there are also popups
        xdg_toplevel_id: u32;

        width: s32;
        height: s32;
        // TOOD: handle scale set coming from the compositor, we have no handling here yet.
        scale: float64 = 1.0;

        text_buffer: [MAX_WAYLAND_MESSAGE_SIZE]u8;
        text: string;
        keyboard_state: Keyboard_State;

        pointer_serial: u32;
        pointer_inside: bool;
        pointer_position: Vector2;

        pointer_press_position: [MOUSE_BUTTON_COUNT]Vector2;
        pointer_pressed: [MOUSE_BUTTON_COUNT]bool;
        pointer_released: [MOUSE_BUTTON_COUNT]bool;
        pointer_held: [MOUSE_BUTTON_COUNT]bool;

        buffers: [2]Wayland_EGL_Buffer;
        current: s64;

        waiting_for_vblank: bool;
        running := true;
    };
    Wayland_EGL_Buffer :: struct {
        wl_buffer_id: u32;
        gbm_buffer_object: *gbm_bo;
        egl_image: EGLImage;
        texture: GLuint;
        fbo: GLuint;
        busy: bool;
    };
    init_window :: (backend: *Backend, window: *Wayland_EGL_Window, width: s32, height: s32, title: string) {
        window.width = width;
        window.height = height;

        init_keyboard_state(*window.keyboard_state);

        window.text.data = window.text_buffer.data;

        connection := *backend.connection;
        window.wl_surface_id = new_wayland_client_object(connection, Interface_Id.WL_SURFACE);
        send_wayland_message(connection, connection.wl_compositor_id, Wl_Compositor_Request_Create_Surface.{ id = window.wl_surface_id });
        window.xdg_surface_id = new_wayland_client_object(connection, Interface_Id.XDG_SURFACE);
        send_wayland_message(connection, connection.xdg_wm_base_id, Xdg_Wm_Base_Request_Get_Xdg_Surface.{ id = window.xdg_surface_id, surface = window.wl_surface_id });
        window.xdg_toplevel_id = new_wayland_client_object(connection, Interface_Id.XDG_TOPLEVEL);
        send_wayland_message(connection, window.xdg_surface_id, Xdg_Surface_Request_Get_Toplevel.{ id = window.xdg_toplevel_id });
        send_wayland_message(connection, window.xdg_toplevel_id, Xdg_Toplevel_Request_Set_Title.{ title = title });
        send_wayland_message(connection, window.wl_surface_id, Wl_Surface_Request_Commit.{});

        for *buffer: window.buffers {
            glGenTextures(1, *buffer.texture);
            glGenFramebuffers(1, *buffer.fbo);
            glBindFramebuffer(GL_FRAMEBUFFER, buffer.fbo);
            glFramebufferParameteri(GL_FRAMEBUFFER, GL_FRAMEBUFFER_FLIP_Y_MESA, xx GL_TRUE);
        }
    }
    can_draw :: (window: Wayland_EGL_Window) -> bool {
        return !window.waiting_for_vblank && window.buffers[window.current].wl_buffer_id != 0 && !window.buffers[window.current].busy;
    }
    update_window :: (backend: *Backend, window: *Wayland_EGL_Window, event: Wayland_Event) {
        if event.object_id == window.xdg_surface_id && event.message.type == Xdg_Surface_Event_Configure {
            configure := cast(*Xdg_Surface_Event_Configure) event.data;
            send_wayland_message(*backend.connection, window.xdg_surface_id, Xdg_Surface_Request_Ack_Configure.{ serial = configure.serial });

            for *buffer: window.buffers {
                should_create_buffer := buffer.gbm_buffer_object == null ||
                                        gbm_bo_get_width(buffer.gbm_buffer_object) != xx window.width ||
                                        gbm_bo_get_height(buffer.gbm_buffer_object) != xx window.height;

                if should_create_buffer {
                    if buffer.egl_image != null {
                        if eglDestroyImage(context.forbear.backend.egl_display, buffer.egl_image) != 1 {
                            log_error("failed to destroy previous egl image: %\n", eglGetError());
                            exit(-1);
                        }
                    }
                    if buffer.gbm_buffer_object != null {
                        gbm_bo_destroy(buffer.gbm_buffer_object);
                    }

                    buffer.gbm_buffer_object = gbm_bo_create_with_modifiers2(
                        backend.device, xx window.width, xx window.height,
                        GBM_FORMAT_ABGR8888, backend.dmabuf_modifiers.data,
                        xx backend.dmabuf_modifiers.count, xx gbm_bo_flags.USE_RENDERING
                    );
                    if buffer.gbm_buffer_object == null {
                        log_error("failed to create gbm buffer object\n");
                        exit(-1);
                    }

                    fd, offset, stride, modifier_lo, modifier_hi: s64;
                    modifier    := gbm_bo_get_modifier(buffer.gbm_buffer_object);
                    plane_count := gbm_bo_get_plane_count(buffer.gbm_buffer_object);
                    assert(plane_count == 1, "expecting the buffer to have only one plane");
                    modifier_lo = xx (modifier & 0xFFFFFFFF);
                    modifier_hi = xx (modifier >> 32);
                    fd          = xx gbm_bo_get_fd_for_plane(buffer.gbm_buffer_object, 0);
                    defer close(xx fd);
                    offset      = xx gbm_bo_get_offset(buffer.gbm_buffer_object, 0);
                    stride      = xx gbm_bo_get_stride_for_plane(buffer.gbm_buffer_object, 0);

                    attributes := EGLAttrib.[
                        EGL_WIDTH,                          xx window.width,
                        EGL_HEIGHT,                         xx window.height,
                        EGL_LINUX_DRM_FOURCC_EXT,           GBM_FORMAT_ABGR8888,
                        EGL_DMA_BUF_PLANE0_FD_EXT,          fd,
                        EGL_DMA_BUF_PLANE0_OFFSET_EXT,      offset,
                        EGL_DMA_BUF_PLANE0_PITCH_EXT,       stride,
                        EGL_DMA_BUF_PLANE0_MODIFIER_LO_EXT, modifier_lo,
                        EGL_DMA_BUF_PLANE0_MODIFIER_HI_EXT, modifier_hi,
                        EGL_NONE,
                    ];
                    buffer.egl_image = eglCreateImage(context.forbear.backend.egl_display, null, EGL_LINUX_DMA_BUF_EXT, null, attributes.data);
                    if buffer.egl_image == null {
                        log_error("failed to create frame buffer: %\n", eglGetError());
                        exit(-1);
                    }

                    glBindTexture(GL_TEXTURE_2D, buffer.texture);
                    glEGLImageTargetTexture2DOES(GL_TEXTURE_2D, buffer.egl_image);
                    glBindFramebuffer(GL_FRAMEBUFFER, buffer.fbo);
                    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, buffer.texture, 0);
                    assert(glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE);
                    window.wl_buffer_params_id = new_wayland_client_object(*backend.connection, Interface_Id.ZWP_LINUX_BUFFER_PARAMS_V1);

                    send_wayland_message(*backend.connection, backend.connection.zwp_dmabuf_id, Zwp_Linux_Dmabuf_V1_Request_Create_Params.{
                        params_id = window.wl_buffer_params_id,
                    });
                    send_wayland_message(*backend.connection, window.wl_buffer_params_id, Zwp_Linux_Buffer_Params_V1_Request_Add.{
                        fd          = xx fd,
                        plane_idx   = 0,
                        offset      = xx offset,
                        stride      = xx stride,
                        modifier_lo = xx modifier_lo,
                        modifier_hi = xx modifier_hi,
                    });

                    previous_buffer_id := buffer.wl_buffer_id;
                    buffer.wl_buffer_id = new_wayland_client_object(*backend.connection, Interface_Id.WL_BUFFER);
                    buffer.busy = false;
                    send_wayland_message(*backend.connection, window.wl_buffer_params_id, Zwp_Linux_Buffer_Params_V1_Request_Create_Immed.{
                        buffer_id = buffer.wl_buffer_id,
                        width     = window.width,
                        height    = window.height,
                        format    = GBM_FORMAT_ABGR8888,
                        flags     = 0,
                    });

                    send_wayland_message(*backend.connection, window.wl_buffer_params_id, Zwp_Linux_Buffer_Params_V1_Request_Destroy.{ });
                    window.wl_buffer_params_id = 0;

                    if previous_buffer_id != 0 {
                        send_wayland_message(*backend.connection, previous_buffer_id, Wl_Buffer_Request_Destroy.{});
                    }
                }
            }
        } else if event.object_id == window.xdg_toplevel_id {
            if event.message.type == {
                case Xdg_Toplevel_Event_Close;
                    window.waiting_for_vblank = false;
                    window.running = false;
                case Xdg_Toplevel_Event_Configure;
                    configure := cast(*Xdg_Toplevel_Event_Configure) event.data;
                    if configure.width {
                        window.width = configure.width;
                    }
                    if configure.height {
                        window.height = configure.height;
                    }
            }
        } else if event.object_id == window.wl_frame_callback_id && event.message.type == Wl_Callback_Event_Done {
            window.waiting_for_vblank = false;
            window.wl_frame_callback_id = 0;
            if EXIT_ON_FIRST_FRAME {
                window.running = false;
            }
        } else if event.object_id == window.wl_buffer_params_id && event.message.type == Zwp_Linux_Buffer_Params_V1_Event_Failed {
            log_error("compositor failed to import the dmabuf (%x%)", window.width, window.height);
            exit(-1);
        } else if event.object_id == backend.connection.wl_pointer_id {
            if event.message.type == {
                // TODO: support pointer gestures https://wayland.app/protocols/pointer-gestures-unstable-v1
                case Wl_Pointer_Event_Enter;
                    enter := cast(*Wl_Pointer_Event_Enter) event.data;
                    if window.wl_surface_id == enter.surface {
                        window.pointer_serial = enter.serial;
                        window.pointer_inside = true;

                        window.pointer_position = Vector2.{
                            cast(float) enter.surface_x,
                            cast(float) enter.surface_y,
                        } / 256.0;
                    }
                case Wl_Pointer_Event_Leave;
                    leave := cast(*Wl_Pointer_Event_Leave) event.data;
                    if window.wl_surface_id == leave.surface {
                        window.pointer_inside = false;
                    }
                case Wl_Pointer_Event_Warp;
                    warp := cast(*Wl_Pointer_Event_Warp) event.data;
                    window.pointer_position = Vector2.{
                        cast(float) warp.surface_x,
                        cast(float) warp.surface_y,
                    } / 256.0;
                case Wl_Pointer_Event_Motion;
                    motion := cast(*Wl_Pointer_Event_Motion) event.data;
                    window.pointer_position = Vector2.{
                        cast(float) motion.surface_x,
                        cast(float) motion.surface_y,
                    } / 256.0;
                case Wl_Pointer_Event_Button;
                    button := cast(*Wl_Pointer_Event_Button) event.data;
                    // 0x110 through 0x117 are the buttons defined in the enum, in the same order as these are
                    // enumerated
                    index: s64 = xx (button.button - 0x110);
                    if index >= 0 && index < window.pointer_pressed.count {
                        if button.state == .RELEASED {
                            window.pointer_released[index] = true;
                            window.pointer_held[index] = false;
                        } else if button.state == .PRESSED {
                            window.pointer_press_position[index] = window.pointer_position;
                            window.pointer_pressed[index] = true;
                            window.pointer_held[index] = true;
                        }
                    }
                // TODO: support all of the remaining pointer events:
                // - wl_pointer::axis_relative_direction
                // - wl_pointer::axis_value120
                // - wl_pointer::axis_discrete
                // - wl_pointer::axis_stop
                // - wl_pointer::axis_source
                // - wl_pointer::axis_frame
                // - wl_pointer::axis
            }
        } else if event.object_id == backend.connection.wl_keyboard_id {
            using window.keyboard_state;
            if event.message.type == {
                case Wl_Keyboard_Event_Enter;
                    enter := cast(*Wl_Keyboard_Event_Enter) event.data;
                    if enter.surface == window.wl_surface_id {
                        inside = true;
                        serial = enter.serial;

                        keys: []u32;
                        keys.data = cast(*u32) enter.keys.data;
                        keys.count = enter.keys.count / size_of(u32);
                        for code: keys {
                            xkb_key_code := code + 8;
                            symbol := xkb_state_key_get_one_sym(backend.connection.key_state, xkb_key_code);
                            if symbol > 0 {
                                key := cast(Key) symbol;
                                held[xkb_key_code] = key;
                            }
                        }
                    }
                case Wl_Keyboard_Event_Leave;
                    leave := cast(*Wl_Keyboard_Event_Leave) event.data;
                    if leave.surface == window.wl_surface_id {
                        inside = false;
                        repeating_key_code = 0;
                        xkb_compose_state_reset(backend.connection.compose_state);
                        memset(held.data, 0, size_of(type_of(held)));
                    }
                case Wl_Keyboard_Event_Repeat_Info;
                    repeat_info := cast(*Wl_Keyboard_Event_Repeat_Info) event.data;
                    repeat_rate = repeat_info.rate;
                    repeat_delay = repeat_info.delay;
                case Wl_Keyboard_Event_Modifiers;
                    for key, code: held {
                        if key != 0 {
                            new_key := cast(Key) xkb_state_key_get_one_sym(backend.connection.key_state, xx code);
                            if new_key != 0 && key != new_key {
                                // This means that this key changes with some modifier on or off, so, we need to replace the previous
                                // key it represented in favour of a new one. We also need to trigger the release and pressed key events
                                // for both keys.
                                add_key_event(*events, Key_Event.{.RELEASED, key});
                                held[code] = new_key;
                                if repeating_key_code == code {
                                    repeating_key = new_key;
                                }
                            }
                        }
                    }
                case Wl_Keyboard_Event_Key;
                    key_event := cast(*Wl_Keyboard_Event_Key) event.data;
                    xkb_key_code := key_event.key + 8;
                    if key_event.state == .RELEASED {
                        key := held[xkb_key_code];
                        if key != 0 {
                            add_key_event(*events, Key_Event.{.RELEASED, key});
                            held[xkb_key_code] = 0;
                            if xkb_key_code == repeating_key_code {
                                repeating_key_code = 0;
                            }
                        }
                    } else if key_event.state == .PRESSED {
                        // TODO: go back to using the virtual key instead of the logical key here.
                        //
                        // For users to check if a logical key is pressed, they should look into input instead,
                        // which is the more cross-platform safe way of doing things.
                        symbol := xkb_state_key_get_one_sym(backend.connection.key_state, xkb_key_code);
                        if symbol > 0 {
                            key := cast(Key) symbol;
                            add_key_event(*events, Key_Event.{.PRESSED, key});
                            held[xkb_key_code] = key;

                            utf8: [64]u8;
                            compose_handled := false;
                            compose := backend.connection.compose_state;
                            if compose {
                                if xkb_compose_state_feed(compose, symbol) == .XKB_COMPOSE_FEED_ACCEPTED {
                                    status := xkb_compose_state_get_status(compose);
                                    if status == .XKB_COMPOSE_COMPOSING {
                                        compose_handled = true;
                                    } else if status == .XKB_COMPOSE_COMPOSED {
                                        length := xkb_compose_state_get_utf8(compose, utf8.data, utf8.count);
                                        append_text(to_string(utf8.data, length), *window.text, window.text_buffer);
                                        xkb_compose_state_reset(compose);
                                        compose_handled = true;
                                    } else if status == .XKB_COMPOSE_CANCELLED {
                                        xkb_compose_state_reset(compose);
                                        compose_handled = true;
                                    }
                                }
                            }
                            if !compose_handled {
                                append_text(key_text(backend.connection.key_state, xkb_key_code, utf8), *window.text, window.text_buffer);
                            }
                            if repeat_rate > 0 && xkb_keymap_key_repeats(backend.connection.keymap, xkb_key_code) {
                                repeating_key = key;
                                repeating_key_code = xkb_key_code;
                                next_repeat = seconds_since_init() + (cast(float)repeat_delay) / 1000.0;
                            }
                        }
                    } else if key_event.state == .REPEATED {
                        key := held[xkb_key_code];
                        if key != 0 {
                            add_key_event(*events, Key_Event.{.REPEATED, key});
                            utf8: [64]u8;
                            append_text(key_text(backend.connection.key_state, xkb_key_code, utf8), *window.text, window.text_buffer);
                        }
                    }
            }
        }

        for *buffer: window.buffers {
            if event.object_id == buffer.wl_buffer_id && event.message.type == Wl_Buffer_Event_Release {
                buffer.busy = false;
            }
        }
    }

    Atlas_Entry :: struct {
        uv_min: Vector2;
        uv_max: Vector2;
    };

    Wayland_EGL_Backend :: struct {
        egl_display: EGLDisplay;
        egl_context: EGLContext;

        dri_fd: s32;
        device: *gbm_device;

        dmabuf_modifiers: [..]u64;

        connection: Wayland_Connection;
    };
    glEGLImageTargetTexture2DOES: (target: GLenum, image: *void) #c_call;
    GBM_FORMAT_ABGR8888 :: 0x34324241;
    DRM_FORMAT_MOD_INVALID :: 0x00ffffffffffffff;
    init_backend :: (backend: *Wayland_EGL_Backend) {
        init_wayland_connection(*backend.connection);

        // TODO: this is hardcoded device, it can be wrong, and it can possibly not be the one the compositor is
        // using. we should use the version 4 of zwp_dmabuf which introduces a feedback event that tells us which
        // device the compositor is using
        backend.dri_fd = open("/dev/dri/renderD128", O_RDWR | O_CLOEXEC);
        if backend.dri_fd == -1 {
            log_error("could not open /dev/dri/renderD128: %\n", errno());
            exit(-1);
        }
        backend.device = gbm_create_device(backend.dri_fd);
        if backend.device == null {
            log_error("could not create the gbm device\n");
            exit(-1);
        }
        backend.egl_display = eglGetPlatformDisplay(EGL_PLATFORM_GBM_KHR, backend.device, null);
        major: s32;
        minor: s32;
        if eglInitialize(backend.egl_display, *major, *minor) != 1 {
            log_error("could not initialize egl");
            exit(-1);
        }
        if eglBindAPI(EGL_OPENGL_API) != 1 {
            log_error("could not bind opengl through egl");
            exit(-1);
        }
        egl_context_attributes := EGLint.[
            EGL_CONTEXT_MAJOR_VERSION, 3,
            EGL_CONTEXT_MINOR_VERSION, 3,
            EGL_CONTEXT_OPENGL_PROFILE_MASK, EGL_CONTEXT_OPENGL_CORE_PROFILE_BIT,
            EGL_NONE
        ];
        backend.egl_context = eglCreateContext(backend.egl_display, null, null, egl_context_attributes.data);
        eglMakeCurrent(backend.egl_display, null, null, backend.egl_context);
        gl_load(*gl, xx eglGetProcAddress);

        if EGL_DEBUGGING {
            print("loaded OpenGL %.%\n", gl_version_major, gl_version_minor);
            print("opengl renderer %\n", to_string(glGetString(GL_RENDERER)));
        }

        glEGLImageTargetTexture2DOES = xx eglGetProcAddress("glEGLImageTargetTexture2DOES");
        if glEGLImageTargetTexture2DOES == null {
            log_error("glEGLImageTargetTexture2DOES is not supported\n");
            exit(-1);
        }

        sync_id := new_wayland_client_object(*backend.connection, .WL_CALLBACK);
        send_wayland_message(*backend.connection, backend.connection.wl_display_id, Wl_Display_Request_Sync.{ callback = sync_id });
        synced := false;
        while !synced {
            event := next_event(*backend.connection);
            if !event.something {
                poll(*backend.connection);
                continue;
            }

            update_wayland_connection(*backend.connection, event);
            if event.message.type == {
                case Zwp_Linux_Dmabuf_V1_Event_Modifier;
                    m := cast(*Zwp_Linux_Dmabuf_V1_Event_Modifier) event.data;
                    modifier := ((cast(u64) m.modifier_hi) << 32) | m.modifier_lo;
                    if m.format == GBM_FORMAT_ABGR8888 &&
                    gbm_device_get_format_modifier_plane_count(backend.device, GBM_FORMAT_ABGR8888, modifier) == 1 {
                        array_add(*backend.dmabuf_modifiers, modifier);
                    }
                case Wl_Callback_Event_Done;
                    synced = true;
            }

            reset_temporary_storage();
        }
        if backend.dmabuf_modifiers.count == 0 {
            log_error("the compositor doesn't accept ABGR8888 dmabufs or all modifiers require more than one plane, so forbear can't render to it.\n");
            // TODO(long-term): should we be falling back to other formats and support them in these kinds of cases?
            exit(-1);
        }
    }
    update_backend :: (backend: *Wayland_EGL_Backend, event: Wayland_Event) {
        update_wayland_connection(*backend.connection, event);
    }

    Backend :: Wayland_EGL_Backend;
    Window :: Wayland_EGL_Window;
} else #if OS == .MACOS {
    #load "bindings-darwin.jai";
    #import "Objective_C";
    #import "Objective_C/AppKit";
    #import "Process";
    #import "File";
    #import "File_Utilities";

    MacOS_GL_Window :: struct {
        width: float64;
        height: float64;
        scale: float64;

        ns_window: *NSWindow;
        view: *NSView;

        text_buffer: [256]u8;
        text: string;

        keyboard_state: Keyboard_State;

        pointer_inside: bool;
        pointer_position: Vector2;

        pointer_press_position: [MOUSE_BUTTON_COUNT]Vector2;
        pointer_pressed: [MOUSE_BUTTON_COUNT]bool;
        pointer_released: [MOUSE_BUTTON_COUNT]bool;
        pointer_held: [MOUSE_BUTTON_COUNT]bool;

        running := true;
    };
    init_window :: (backend: *MacOS_GL_Backend, window: *MacOS_GL_Window, width: float64, height: float64, title: string) {
        rectangle := NSRect.{ size = .{ width = width, height = height } };

        backend.pasteboard = NSPasteboard.generalPasteboard();
        window.ns_window = NSWindow.initWithContentRect(
            objc_alloc(NSWindow),
            rectangle,
            NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable,
            NSBackingStoreBuffered,
            NO,
            NSScreen.mainScreen()
        );
        NSWindow.setReleasedWhenClosed(window.ns_window, NO);
        NSWindow.setTitle(window.ns_window, title);
        NSWindow.center(window.ns_window);
        NSWindow.makeKeyAndOrderFront(window.ns_window, null);

        window.view = NSWindow.contentView(window.ns_window);
        NSView.setWantsBestResolutionOpenGLSurface(window.view, YES);
        NSOpenGLContext.setView(backend.gl_context, window.view);
        backend.attached_view = window.view;

        frame := NSView.frame(window.view);
        backing := NSView.convertRectToBacking(window.view, frame);
        window.width = backing.size.width;
        window.height = backing.size.height;
        window.scale = backing.size.width / frame.size.width;

        window.text.data = window.text_buffer.data;

        init_keyboard_state(*window.keyboard_state);
    }
    update_window :: (backend: *MacOS_GL_Backend, window: *MacOS_GL_Window) {
        is_visible: (*void, Selector) -> BOOL #c_call = xx objc_msgSend;
        if !is_visible(window.ns_window, selector("isVisible")) {
            window.running = false;
        }

        frame := NSView.frame(window.view);
        backing := NSView.convertRectToBacking(window.view, frame);
        if backing.size.width != window.width || backing.size.height != window.height {
            window.width = backing.size.width;
            window.height = backing.size.height;
            window.scale = backing.size.width / frame.size.width;
            NSOpenGLContext.update(backend.gl_context);
        }
        if NSApplication.keyWindow(backend.app) != window.ns_window {
            memset(window.keyboard_state.held.data, 0, size_of(type_of(window.keyboard_state.held)));
        }
    }

    MacOS_GL_Backend :: struct {
        app: *NSApplication;
        pixel_format: *NSOpenGLPixelFormat;
        gl_context: *NSOpenGLContext;

        pasteboard: *NSPasteboard;
        clipboard_change_count: NSInteger = -1;
        clipboard_text_buffer: string;
        clipboard_text: string;

        attached_view: *NSView;
    };
    init_backend :: (backend: *MacOS_GL_Backend) {
        init_objective_c();
        init_app_kit();
        backend.app = NSApplication.sharedApplication();
        NSApplication.setActivationPolicy(backend.app, NSApplicationActivationPolicyRegular);
        NSApplication.finishLaunching(backend.app);
        NSApplication.activateIgnoringOtherApps(backend.app, YES);

        attributes := NSOpenGLPixelFormatAttribute.[
            NSOpenGLPFADoubleBuffer,
            NSOpenGLPFAAccelerated,
            NSOpenGLPFAColorSize, 24,
            NSOpenGLPFAAlphaSize, 8,
            NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion4_1Core,
            0,
        ];
        backend.pixel_format = NSOpenGLPixelFormat.initWithAttributes(objc_alloc(NSOpenGLPixelFormat), attributes.data);
        backend.gl_context = NSOpenGLContext.initWithFormat(objc_alloc(NSOpenGLContext), backend.pixel_format, null);
        NSOpenGLContext.makeCurrentContext(backend.gl_context);
        gl_load(*gl);
    }
    update_backend :: (backend: *MacOS_GL_Backend) {
        pool := objc_init(objc_alloc(NSAutoreleasePool));
        defer NSAutoreleasePool.drain(pool);
        window := context.forbear.window;
        using window.keyboard_state;
        frame := NSView.frame(window.view);
        location := NSWindow.mouseLocationOutsideOfEventStream(window.ns_window);

        window.pointer_inside = location.x >= 0 && location.y >= 0 &&
                                location.x < frame.size.width && location.y < frame.size.height;
        window.pointer_position = Vector2.{ xx location.x, xx (frame.size.height - location.y) };

        change_count: (*void, Selector) -> NSInteger #c_call = xx objc_msgSend;
        count := change_count(backend.pasteboard, selector("changeCount"));
        if count != backend.clipboard_change_count {
            backend.clipboard_text.count = 0;
            backend.clipboard_change_count = count;
            nsstring := backend.pasteboard.stringForType(backend.pasteboard, NSPasteboardTypeString);
            if nsstring != null {
                utf8 := to_string(NSString.UTF8String(nsstring));
                if utf8.count > backend.clipboard_text_buffer.count {
                    backend.clipboard_text_buffer.data = realloc(
                        backend.clipboard_text_buffer.data,
                        utf8.count,
                        backend.clipboard_text_buffer.count,,
                        context.forbear.persistent_allocator
                    );
                    backend.clipboard_text_buffer.count = utf8.count;
                }
                memcpy(backend.clipboard_text_buffer.data, utf8.data, utf8.count);

                backend.clipboard_text.data = backend.clipboard_text_buffer.data;
                backend.clipboard_text.count = utf8.count;
            }
        }

        while true {
            event := NSApplication.nextEventMatchingMask(backend.app, NSEventMaskAny, NSDate.distantPast(), NSDefaultRunLoopMode, YES);
            if event {
                event_type := NSEvent.type(event);
                if event_type == {
                    case NSEventTypeRightMouseDown; #through;
                    case NSEventTypeLeftMouseDown; #through;
                    case NSEventTypeOtherMouseDown;
                        button := NSEvent.buttonNumber(event);
                        if window.pointer_inside {
                            if button < MOUSE_BUTTON_COUNT {
                                window.pointer_press_position[button] = window.pointer_position;
                                window.pointer_pressed[button] = true;
                                window.pointer_held[button] = true;
                            } else {
                                log_error("received a button that's bigger than what we expected to receive. in theory this can go to 31 button, but we only have LEFT, RIGHT, MIDDLE, BACK and FORWARD. button: %", button);
                            }
                        }
                        backend.app.sendEvent(backend.app, event);
                    case NSEventTypeLeftMouseUp; #through;
                    case NSEventTypeRightMouseUp; #through;
                    case NSEventTypeOtherMouseUp;
                        button := NSEvent.buttonNumber(event);
                        if button < MOUSE_BUTTON_COUNT {
                            window.pointer_released[button] = true;
                            window.pointer_held[button] = false;
                        } else {
                            log_error("received a button that's bigger than what we expected to receive. in theory this can go to 31 button, but we only have LEFT, RIGHT, MIDDLE, BACK and FORWARD. button: %", button);
                        }
                        backend.app.sendEvent(backend.app, event);
                    case NSEventTypeKeyDown;
                        code := NSEvent.keyCode(event);
                        key: Key = xx code;
                        if !NSEvent.isARepeat(event) {
                            add_key_event(*events, Key_Event.{.PRESSED, key});
                            held[code] = key;
                        } else {
                            add_key_event(*events, Key_Event.{.REPEATED, key});
                        }
                        if !(NSEvent.modifierFlags(event) & .NSEventModifierFlagCommand) {
                            characters := NSEvent.characters(event);
                            if characters {
                                text := to_string(NSString.UTF8String(characters));
                                // TODO(bug): this is currently accepting the text version of stuff like CTRL, which doensn't make any sense.
                                // We should be using NSTextInputClient instead.
                                if text.count != 3 || text[0] == 0xEF && text[1] >= 0x9C && text[1] <= 0xA3 {
                                    append_text(text, *window.text, window.text_buffer);
                                }
                            }
                        }
                    case NSEventTypeKeyUp;
                        code := NSEvent.keyCode(event);
                        add_key_event(*events, Key_Event.{.RELEASED, xx code});
                        held[code] = 0;
                    case NSEventTypeFlagsChanged;
                        code := NSEvent.keyCode(event);
                        key: Key = xx code;
                        flag: NSEventModifierFlags;
                        if key == {
                            case .SHIFT_LEFT; #through;
                            case .SHIFT_RIGHT;
                                flag = .NSEventModifierFlagShift;
                            case .CONTROL_LEFT; #through;
                            case .CONTROL_RIGHT;
                                flag = .NSEventModifierFlagControl;
                            case .ALT_LEFT; #through;
                            case .ALT_RIGHT;
                                flag = .NSEventModifierFlagOption;
                            case .SUPER_LEFT; #through;
                            case .SUPER_RIGHT;
                                flag = .NSEventModifierFlagCommand;
                            case .CAPS_LOCK;
                                flag = .NSEventModifierFlagCapsLock;
                            case .FUNCTION;
                                flag = .NSEventModifierFlagFunction;
                        }
                        if held[code] != 0 {
                            add_key_event(*events, Key_Event.{.RELEASED, key});
                            held[code] = 0;
                        } else if NSEvent.modifierFlags(event) & flag {
                            add_key_event(*events, Key_Event.{.PRESSED, key});
                            held[code] = key;
                        }
                        backend.app.sendEvent(backend.app, event);
                    case;
                        backend.app.sendEvent(backend.app, event);
                }
            } else {
                break;
            }
        }
    }

    Backend :: MacOS_GL_Backend;
    Window :: MacOS_GL_Window;

    create_application :: (name: string, executable: string) {
        app := tprint("%/%.app", get_working_directory(), name);
        make_directory_if_it_does_not_exist(tprint("%/Contents/MacOS", app), recursive = true);
        bundled := tprint("%/Contents/MacOS/%", app, name);
        copy_file(executable, bundled);
        chmod(temp_c_string(bundled), 0x1ED);
        write_entire_file(
            tprint("%/Contents/Info.plist", app),
            tprint(#string PLIST
                <?xml version="1.0" encoding="UTF-8"?>
                <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
                <plist version="1.0">
                <dict>
                <key>CFBundleExecutable</key><string>%1</string>
                <key>CFBundleIdentifier</key><string>com.forbear.%1</string>
                <key>CFBundleName</key><string>%1</string>
                <key>CFBundlePackageType</key><string>APPL</string>
                <key>NSHighResolutionCapable</key><true/>
                </dict>
                </plist>
                PLIST,
            name)
        );
        run_command("codesign", "--force", "--deep", "-s", "-", app);
    }
} else #if OS == .WINDOWS {
    #load "bindings-win32.jai";
    #import "Windows";
    #import "Windows_Utf8";
    #import "Unicode";
    user32 :: #library,system "user32";
    kernel32 :: #library,system "kernel32";

    AdjustWindowRectExForDpi :: (rect: *RECT, style: u32, menu: BOOL, extended_style: u32, dpi: u32) -> BOOL #foreign user32;
    DiscardVirtualMemory :: (VirtualAddress: *void, Size: SIZE_T) -> DWORD #foreign kernel32;
    GetDpiForWindow :: (hwnd: HWND) -> u32 #foreign user32;
    GetWindowLongPtrW :: (hwnd: HWND, index: s32) -> s64 #foreign user32;
    SetProcessDpiAwarenessContext :: (value: HANDLE) -> BOOL #foreign user32;
    SetProcessWorkingSetSize :: (hProcess: HANDLE, dwMinimumWorkingSetSize: SIZE_T, dwMaximumWorkingSetSize: SIZE_T) -> BOOL #foreign kernel32;
    TRACKMOUSEEVENT :: struct {
        cbSize: DWORD;
        dwFlags: DWORD;
        hwndTrack: HWND;
        dwHoverTime: DWORD;
    };
    TrackMouseEvent :: (lpEventTrack: *TRACKMOUSEEVENT) -> BOOL #foreign user32;
    ToUnicodeEx :: (wVirtKey: u32, wScanCode: u32, lpKeyState: *u8, pwszBuff: *u16, cchBuff: s32, wFlags: u32, dwhkl: *void) -> s32 #foreign user32;
    GetKeyboardState :: (lpKeyState: *u8) -> BOOL #foreign user32;
    GetKeyboardLayout :: (idThread: DWORD) -> *void #foreign user32;
    MapVirtualKeyW :: (uCode: u32, uMapType: u32) -> u32 #foreign user32;
    SetTimer :: (hWnd: HWND, nIDEvent: u64, uElapse: u32, lpTimerFunc: *void) -> u64 #foreign user32;
    KillTimer :: (hWnd: HWND, uIDEvent: u64) -> BOOL #foreign user32;
    WaitMessage :: () -> BOOL #foreign user32;
    IsIconic :: (hWnd: HWND) -> BOOL #foreign user32;
    GetMessageTime :: () -> s32 #foreign user32;

    MODAL_TAKEOVER_TIMER :: 1;

    MAPVK_VSC_TO_VK_EX :: 3;
    GWLP_USERDATA :: -21;
    TME_LEAVE :: 0x00000002;
    WM_MOUSELEAVE :: 0x02A3;
    WM_ENTERMENULOOP :: 0x0211;
    WM_EXITMENULOOP :: 0x0212;
    WM_CAPTURECHANGED :: 0x0215;

    Windows_GL_Backend :: struct {
        message: (window: *Windows_GL_Window, hWnd: HWND, Msg: u32, wParam: WPARAM, lParam: LPARAM) -> s64;
        render: (data: *void);
        render_data: *void;
        wndproc_context: *#Context;
    };
    init_backend :: (using backend: *Windows_GL_Backend) {
        wndproc_context = *context;

        timeBeginPeriod(1);
        DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 :: cast(HANDLE) -4;
        SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);

        class: WNDCLASSEXW;
        class.cbSize = size_of(WNDCLASSEXW);
        class.style = CS_OWNDC;
        class.lpfnWndProc = wndproc;
        class.hInstance = GetModuleHandleW(null);
        class.hCursor = LoadCursorW(null, xx IDC_ARROW);
        class.lpszClassName = utf8_to_wide("forbear",, temp);
        RegisterClassExW(*class);
    }
    wndproc :: (hwnd: HWND, message: u32, wparam: WPARAM, lparam: LPARAM) -> s64 #c_call {
        result: s64;
        if message != WM_NCCREATE {
            window := cast(*Windows_GL_Window) GetWindowLongPtrW(hwnd, GWLP_USERDATA);
            if window != null {
                push_context window.backend.wndproc_context.* {
                    if window.backend.message != null {
                        window.backend.message(window, hwnd, message, wparam, lparam);
                    }
                    is_high_surrogate :: (unit: u16) -> bool {
                        return unit >= 0xD800 && unit <= 0xDBFF;
                    }
                    is_low_surrogate :: (unit: u16) -> bool {
                        return unit >= 0xDC00 && unit <= 0xDFFF;
                    }
                    utf16_to_code_point :: (units: []u16, count: s32) -> u32 {
                        assert(units.count >= 2);
                        code_point: u32;
                        if count == 1 && !is_high_surrogate(units[0]) && !is_low_surrogate(units[0]) {
                            code_point = units[0];
                        } else if count == 2 && is_high_surrogate(units[0]) && is_low_surrogate(units[1]) {
                            code_point = 0x10000 + ((cast(u32) units[0] - 0xD800) << 10) + (units[1] - 0xDC00);
                        }
                        return code_point;
                    }
                    if message == {
                        case WM_CLOSE;
                            window.running = false;
                        case WM_SYSCOMMAND;
                            if (wparam & 0xFFF0) != SC_KEYMENU || lparam != 0 {
                                result = DefWindowProcW(hwnd, message, wparam, lparam);
                            }
                        case WM_SIZE;
                            if wparam != SIZE_MINIMIZED {
                                window.width = cast(float64)(lparam & 0xFFFF);
                                window.height = cast(float64)((lparam >> 16) & 0xFFFF);
                                if window.backend.render != null {
                                    window.backend.render(window.backend.render_data);
                                }
                            }
                        case WM_MOVE;
                            if window.backend.render != null {
                                window.backend.render(window.backend.render_data);
                            }
                        case WM_ENTERMENULOOP; #through;
                        case WM_ENTERSIZEMOVE;
                            SetTimer(hwnd, MODAL_TAKEOVER_TIMER, 1, null);
                        case WM_EXITMENULOOP; #through;
                        case WM_EXITSIZEMOVE;
                            KillTimer(hwnd, MODAL_TAKEOVER_TIMER);
                        case WM_TIMER;
                            if wparam == MODAL_TAKEOVER_TIMER && window.backend.render {
                                window.backend.render(window.backend.render_data);
                            }
                        case WM_MOUSEMOVE;
                            if window.mouse_state.inside == false {
                                window.mouse_state.inside = true;
                                track := TRACKMOUSEEVENT.{
                                    cbSize = size_of(TRACKMOUSEEVENT),
                                    dwFlags = TME_LEAVE,
                                    hwndTrack = hwnd,
                                };
                                TrackMouseEvent(*track);
                            }
                            window.mouse_state.position = Vector2.{
                                cast(float) cast,trunc(s16) (lparam & 0xFFFF),
                                cast(float) cast,trunc(s16) ((lparam >> 16) & 0xFFFF),
                            } / cast(float) window.scale;
                        case WM_MOUSELEAVE;
                            window.mouse_state.inside = false;
                        case WM_KILLFOCUS;
                            memset(window.keyboard_state.held.data, 0, size_of(type_of(window.keyboard_state.held)));
                        case WM_CAPTURECHANGED;
                            memset(window.mouse_state.held.data, 0, size_of(type_of(window.mouse_state.held)));
                        // TODO: handle double click events
                        case WM_LBUTTONDOWN; #through;
                        case WM_RBUTTONDOWN; #through;
                        case WM_MBUTTONDOWN; #through;
                        case WM_XBUTTONDOWN;
                            button: Mouse_Button = xx ((message - WM_LBUTTONDOWN) / 3);
                            if button == .BACK && ((wparam >> 16) & 0xFFFF) == 2 {
                                button = .FORWARD;
                            }
                            mouse_press(*window.mouse_state, button, Vector2.{
                                cast(float) cast,trunc(s16) (lparam & 0xFFFF),
                                cast(float) cast,trunc(s16) ((lparam >> 16) & 0xFFFF),
                            } / cast(float) window.scale);
                            SetCapture(hwnd);
                            if message == WM_XBUTTONDOWN {
                                result = 1;
                            }
                        case WM_LBUTTONUP; #through;
                        case WM_RBUTTONUP; #through;
                        case WM_MBUTTONUP; #through;
                        case WM_XBUTTONUP;
                            button: Mouse_Button = xx ((message - WM_LBUTTONUP) / 3);
                            if button == .BACK && ((wparam >> 16) & 0xFFFF) == 2 {
                                button = .FORWARD;
                            }
                            mouse_release(*window.mouse_state, button);
                            any_held := false;
                            for window.mouse_state.held {
                                if it {
                                    any_held = true;
                                    break;
                                }
                            }
                            if !any_held {
                                ReleaseCapture();
                            }
                            if message == WM_XBUTTONUP {
                                result = 1;
                            }
                        case WM_CHAR;
                            using window.keyboard_state;
                            unit := cast(u16) wparam;
                            code_point: u32;
                            if is_high_surrogate(unit) {
                                high_surrogate = unit;
                            } else if is_low_surrogate(unit) {
                                if is_high_surrogate(high_surrogate) {
                                    code_point = utf16_to_code_point(u16.[high_surrogate, unit], 2);
                                }
                                high_surrogate = 0;
                            } else {
                                code_point = unit;
                            }
                            if code_point != 0 {
                                bytes: [4]u8;
                                utf8 := string.{ data = bytes.data };
                                character_utf32_to_utf8(code_point, *utf8);
                                append_text(utf8, *window.text, window.text_buffer);
                            }
                        case WM_SYSCHAR;
                            // text typed while Alt is held
                            if wparam == #char " " {
                                result = DefWindowProcW(hwnd, message, wparam, lparam);
                            }
                        case WM_SYSKEYDOWN; #through;
                        case WM_KEYDOWN;
                            using window.keyboard_state;
                            if wparam != VK_PROCESSKEY && wparam != VK_PACKET { // ignores keys typed during an IME compose event
                                repeated := (lparam >> 30) & 1;
                                scancode := cast(u32) ((lparam >> 16) & 0xFF);
                                extended := (lparam >> 24) & 1;
                                index    := scancode | (extended << 8);
                                altgr_control := false;
                                if wparam == VK_CONTROL && extended == 0 {
                                    next: MSG;
                                    altgr_control = PeekMessageW(*next, null, 0, 0, PM_NOREMOVE) != 0 &&
                                        (next.message == WM_KEYDOWN || next.message == WM_SYSKEYDOWN) &&
                                        next.wParam == VK_MENU &&
                                        ((next.lParam >> 24) & 1) == 1 &&
                                        next.time == GetMessageTime();
                                }
                                if altgr_control {
                                } else if repeated && held[index] != 0 {
                                    add_key_event(*events, Key_Event.{ .REPEATED, held[index] });
                                } else {
                                    key: Key = 0;
                                    if wparam == {
                                        case VK_ESCAPE;  key = .ESCAPE;
                                        case VK_RETURN;  key = .ENTER;
                                        case VK_TAB;     key = .TAB;
                                        case VK_BACK;    key = .BACKSPACE;
                                        case VK_DELETE;  key = .DELETE;
                                        case VK_INSERT;  key = .INSERT;
                                        case VK_LEFT;    key = .ARROW_LEFT;
                                        case VK_RIGHT;   key = .ARROW_RIGHT;
                                        case VK_UP;      key = .ARROW_UP;
                                        case VK_DOWN;    key = .ARROW_DOWN;
                                        case VK_HOME;    key = .HOME;
                                        case VK_END;     key = .END;
                                        case VK_PRIOR;   key = .PAGE_UP;
                                        case VK_NEXT;    key = .PAGE_DOWN;
                                        case VK_F1;      key = .F1;
                                        case VK_F2;      key = .F2;
                                        case VK_F3;      key = .F3;
                                        case VK_F4;      key = .F4;
                                        case VK_F5;      key = .F5;
                                        case VK_F6;      key = .F6;
                                        case VK_F7;      key = .F7;
                                        case VK_F8;      key = .F8;
                                        case VK_F9;      key = .F9;
                                        case VK_F10;     key = .F10;
                                        case VK_F11;     key = .F11;
                                        case VK_F12;     key = .F12;
                                        case VK_SHIFT;   #through;
                                        case VK_CONTROL; #through;
                                        case VK_MENU;
                                            vk := MapVirtualKeyW(scancode | cast(u32) (ifx extended then 0xE000 else 0), MAPVK_VSC_TO_VK_EX);
                                            if vk == {
                                                case VK_LSHIFT;   key = .SHIFT_LEFT;
                                                case VK_RSHIFT;   key = .SHIFT_RIGHT;
                                                case VK_LCONTROL; key = .CONTROL_LEFT;
                                                case VK_RCONTROL; key = .CONTROL_RIGHT;
                                                case VK_LMENU;    key = .ALT_LEFT;
                                                case VK_RMENU;    key = .ALT_RIGHT;
                                            }
                                        case VK_LWIN;    key = .SUPER_LEFT;
                                        case VK_RWIN;    key = .SUPER_RIGHT;
                                        case VK_CAPITAL; key = .CAPS_LOCK;
                                    }
                                    if key == 0 {
                                        // the key could not be found, meaning it's not in the named ones, so we're going to write ti as a character instead
                                        state: [256]u8;
                                        GetKeyboardState(state.data);
                                        if !(state[VK_MENU] & 0x80) {
                                            state[VK_CONTROL] = 0;
                                            state[VK_LCONTROL] = 0;
                                            state[VK_RCONTROL] = 0;
                                        }
                                        units: [4]u16;
                                        count := ToUnicodeEx(xx wparam, scancode, state.data, units.data, units.count, 0x4, GetKeyboardLayout(0));
                                        code_point := utf16_to_code_point(units, count);
                                        if (code_point >= #char "A" && code_point <= #char "Z")
                                        || (code_point >= 0xC0 && code_point <= 0xDE && code_point != 0xD7) {
                                            // lowercases all of the LATIN-1 uppercase characters
                                            //
                                            // TODO: should we use some builtin function that has a wider reach than this?
                                            code_point += 32;
                                        }
                                        key = xx code_point;
                                    }
                                    if key != 0 {
                                        held[index] = key;
                                        add_key_event(*events, Key_Event.{ .PRESSED, key });
                                    }
                                }
                            }
                            if message == WM_SYSKEYDOWN {
                                result = DefWindowProcW(hwnd, message, wparam, lparam);
                            }
                        case WM_DPICHANGED;
                            window.scale = cast(float64) (wparam & 0xFFFF) / 96.0;
                            suggested := cast(*RECT) lparam;
                            SetWindowPos(hwnd, null, suggested.left, suggested.top,
                                suggested.right - suggested.left, suggested.bottom - suggested.top,
                                SWP_NOZORDER | SWP_NOACTIVATE);
                        case WM_KEYUP; #through;
                        case WM_SYSKEYUP;
                            using window.keyboard_state;
                            scancode := cast(u32) ((lparam >> 16) & 0xFF);
                            extended := cast(u32) ((lparam >> 24) & 1);
                            index := scancode | (extended << 8);
                            key := held[index];
                            if key != 0 {
                                add_key_event(*events, .{.RELEASED, key});
                                held[index] = 0;
                            }
                            if message == WM_SYSKEYUP {
                                result = DefWindowProcW(hwnd, message, wparam, lparam);
                            }
                        case;
                            result = DefWindowProcW(hwnd, message, wparam, lparam);
                    }
                }
            } else {
                result = DefWindowProcW(hwnd, message, wparam, lparam);
            }
        } else {
            // lpCreateParams is the first field of CREATESTRUCTW
            create_params := (cast(**void) lparam).*;
            SetWindowLongPtrW(hwnd, GWLP_USERDATA, xx create_params);
            result = DefWindowProcW(hwnd, message, wparam, lparam);
        }
        return result;
    }
    update_backend :: (backend: *Backend) {
        backend.wndproc_context = *context;
        window := context.forbear.window;
        while true {
            message: MSG;
            while PeekMessageW(*message, null, 0, 0, PM_REMOVE) {
                TranslateMessage(*message);
                DispatchMessageW(*message);
            }
            if !window.running || !IsIconic(window.hwnd) {
                break;
            }
            WaitMessage();
        }
    }

    Windows_GL_Window :: struct {
        hwnd: HWND;
        hdc: HDC;
        backend: *Windows_GL_Backend;

        width: float64;
        height: float64;
        scale: float64;

        text_buffer: [256]u8;
        text: string;

        keyboard_state: Keyboard_State;
        mouse_state: Mouse_State;

        running := true;
    };
    init_window :: (backend: *Windows_GL_Backend, window: *Windows_GL_Window, width: float64, height: float64, title: string) {
        window.text.data = window.text_buffer.data;
        window.backend = backend;
        init_keyboard_state(*window.keyboard_state);

        style :: WS_OVERLAPPEDWINDOW;
        window.hwnd = CreateWindowExW(
            0,
            utf8_to_wide("forbear",, temp),
            utf8_to_wide(title,, temp),
            style,
            CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT,
            null, null, GetModuleHandleW(null), window
        );

        dpi := GetDpiForWindow(window.hwnd);
        window.scale = dpi / 96.0;
        rectangle := RECT.{ right = xx (width * window.scale), bottom = xx (height * window.scale) };
        AdjustWindowRectExForDpi(*rectangle, style, 0, 0, dpi);
        SetWindowPos(window.hwnd, null, 0, 0, rectangle.right - rectangle.left, rectangle.bottom - rectangle.top, SWP_NOMOVE | SWP_NOZORDER);
        ShowWindow(window.hwnd, SW_SHOW);

        _, window.hdc = wgl_create_context(window.hwnd, null, 3, 3);
        gl_load(*gl);
        if gl.wglSwapIntervalEXT {
            gl.wglSwapIntervalEXT(1);
        }

        client: RECT;
        GetClientRect(window.hwnd, *client);
        window.width = xx client.right;
        window.height = xx client.bottom;
    }

    Backend :: Windows_GL_Backend;
    Window :: Windows_GL_Window;
}

Direction :: enum u8 { HORIZONTAL; VERTICAL; };
DIRECTIONS :: Direction.[.HORIZONTAL, .VERTICAL];
opposite :: (direction: Direction) -> Direction {
    if #complete direction == {
    case .HORIZONTAL;
        return .VERTICAL;
    case .VERTICAL;
        return .HORIZONTAL;
    }
}

Sizing :: struct {
    Kind :: enum u8 {
        FIT; FIXED; GROW;
    };

    kind: Kind;

    union {
        fixed: float;
        // A ratio with respect to the opposite axis.
        ratio: float;
        // Grows to fill available space, taking a proportional share based on the factor. A factor of 2.0 claims twice the space
        // of 1.0.
        grow: float;
    }
};
fit :: () -> Sizing {
    return Sizing.{ kind = .FIT };
}
fixed :: (value: float) -> Sizing {
    return Sizing.{ kind = .FIXED, fixed = value };
}
grow :: (value := 1.0) -> Sizing {
    return Sizing.{ kind = .GROW, grow = value };
}

Shadow :: struct {
    offset: Sides;
    blur_radius: float;
    spread: float;
    color: Vector4;
};

Alignment :: enum u8 { START; CENTER; END; };

// Will modify the min size of layout boxes that wrap text accordingly
// character => largest character
// word => largest word
// none => all in one line
Text_Wrapping :: enum u8 {
    // Uses a simple greedy algorithm to break on word boundaries
    WORD;
    CHARACTER;
    NONE;
};

Overflow :: enum u8 { VISIBLE; WRAP; };

Sides :: struct {
    x: Vector2;
    y: Vector2;
};
get :: (sides: Sides, direction: Direction) -> Vector2 {
    if direction == .HORIZONTAL {
        return sides.x;
    } else {
        return sides.y;
    }
}
all :: (value: float) -> Sides {
    return Sides.{
        x = make_vector2(value),
        y = make_vector2(value),
    };
}
in_line :: (value: float) -> Sides {
    return Sides.{
        x = make_vector2(value),
        y = make_vector2(0.0),
    };
}
in_line :: (sides: Sides, value: float) -> Sides {
    return Sides.{
        x = make_vector2(value),
        y = sides.y
    };
}
block :: (value: float) -> Sides {
    return Sides.{
        x = make_vector2(0.0),
        y = make_vector2(value),
    };
}
block :: (sides: Sides, value: float) -> Sides {
    return Sides.{
        x = sides.x,
        y = make_vector2(value),
    };
}
left :: (value: float) -> Sides {
    return Sides.{
        x = Vector2.{ x = value, y = 0.0 },
        y = make_vector2(0.0),
    };
}
left :: (sides: Sides, value: float) -> Sides {
    return Sides.{
        x = Vector2.{ x = value, y = sides.x.y },
        y = sides.y,
    };
}
right :: (value: float) -> Sides {
    return Sides.{
        x = Vector2.{ x = 0.0, y = value },
        y = make_vector2(0.0),
    };
}
right :: (sides: Sides, value: float) -> Sides {
    return Sides.{
        x = Vector2.{ x = sides.x.x, y = value },
        y = sides.y,
    };
}
top :: (value: float) -> Sides {
    return Sides.{
        x = make_vector2(0.0),
        y = Vector2.{ x = value, y = 0.0 },
    };
}
top :: (sides: Sides, value: float) -> Sides {
    return Sides.{
        x = sides.x,
        y = Vector2.{ x = value, y = sides.y.y },
    };
}
bottom :: (value: float) -> Sides {
    return Sides.{
        x = make_vector2(0.0),
        y = Vector2.{ x = 0.0, y = value },
    };
}
bottom :: (sides: Sides, value: float) -> Sides {
    return Sides.{
        x = sides.x,
        y = Vector2.{ x = sides.y.x, y = value },
    };
}
Padding :: Sides;
Margin :: Sides;
Border_Width :: Sides;

Cursor :: enum u8 { DEFAULT; TEXT; POINTER; };

Border_Style :: enum u32 { SOLID; DASHED; };

// -1 in values means it should be inferred by forbear
Complete_Style :: struct {
    background: Background;

    color: Vector4;
    border_radius: float;
    border_color: Vector4;
    border_width: Border_Width;
    border_style: Border_Style;

    shadow: Shadow;

    font: *Font;

    // Will do nothing if the font is not a variable font. If you don't have a variable font, you should use different fonts
    // for different weights.
    font_weight: u16;
    font_size: float;
    line_height: float;
    text_wrapping: Text_Wrapping;
    cursor: Cursor;

    overflow: Overflow;
    placement: Placement;
    z_index: u16 = U16_MAX;

    min_width: float = FLOAT32_NAN;
    max_width: float = FLOAT32_NAN;
    width: Sizing;
    max_height: float = FLOAT32_NAN;
    min_height: float = FLOAT32_NAN;
    height: Sizing;

    translate: Vector2;

    padding: Padding;
    margin: Margin;

    direction: Direction;
    x_justification: Alignment;
    y_justification: Alignment;
};

Base_Style :: struct {
    font: *Font;
    color: Vector4 = Vector4.{ 1.0, 1.0, 1.0, 1.0 };
    font_size: float = 16.0;
    font_weight: u16 = 600;
    line_height: float = 1.0;
    text_wrapping: Text_Wrapping = .WORD;
    cursor: Cursor = .DEFAULT;
};

from :: (style: Complete_Style) -> Base_Style {
    return Base_Style.{
        font = style.font,
        color = style.color,
        font_size = style.font_size,
        font_weight = style.font_weight,
        line_height = style.line_height,
        text_wrapping = style.text_wrapping,
        cursor = style.cursor,
    };
}

Gradient_Stop :: struct {
    color: Vector4;
    // Position along the gradient in the [0, 1] range.
    position: float;
} #no_padding;
angle :: (degrees: float) -> Vector2 {
    radians := degrees * Math.PI / 180.0;
    return Vector2.{ x = Math.sin(radians), y = -Math.cos(radians)};
}
to_top :: () -> Vector2 {
    return Vector2.{ x = 0, y = -1 };
}
to_bottom :: () -> Vector2 {
    return Vector2.{ x = 0, y = 1 };
}
to_left :: () -> Vector2 {
    return Vector2.{ x = -1, y = 0 };
}
to_right :: () -> Vector2 {
    return Vector2.{ x = 1, y = 0 };
}
to_top_left :: () -> Vector2 {
    return Vector2.{ x = xx -Math.SQRTH, y = xx -Math.SQRTH };
}
to_top_right :: () -> Vector2 {
    return Vector2.{ x = xx Math.SQRTH, y = xx -Math.SQRTH };
}
to_bottom_left :: () -> Vector2 {
    return Vector2.{ x = xx -Math.SQRTH, y = xx Math.SQRTH };
}
to_bottom_right :: () -> Vector2 {
    return Vector2.{ x = xx Math.SQRTH, y = xx Math.SQRTH };
}
Linear_Gradient :: struct {
    // Stops define where each color sits along the gradient; positions are expected to be monotonically increasing within the
    // [0, 1] range.
    stops: []Gradient_Stop;
    // Which way the gradient flows. Defaults to left-to-right.
    direction: Vector2;
};

Background :: struct {
    Kind :: enum u8 {
        COLOR;
        // IMAGE;
        GRADIENT;
    };

    kind: Kind;
    union {
        // image: *Graphics.Image,
        color: Vector4;
        // A linear gradient across the element. Defaults to flowing left-to-right; set `direction` to change which way it runs.
        // See `Linear_Gradient`.
        gradient: Linear_Gradient;
    }
};
rgb :: (r: float, g: float, b: float) -> Vector4 {
    return Vector4.{r / 255.0, g / 255.0, b / 255.0, 1.0};
}
rgba :: (r: float, g: float, b: float) -> Vector4 {
    return rgb(r, g, b);
}
rgba :: (r: float, g: float, b: float, a: float) -> Vector4 {
    return Vector4.{r / 255.0, g / 255.0, b / 255.0, a};
}
hex :: ($code: string) -> Vector4 {
    COLOR :: #run -> Vector4 {
        digits := code;
        if digits.count > 0 && digits[0] == #char "#" then advance(*digits);
        assert(digits.count == 6 || digits.count == 8, "hex: expected #RRGGBB or #RRGGBBAA, got \"%\"", code);
        channels := Vector4.{w = 1};
        for i: 0..digits.count / 2 - 1 {
            value := 0;
            for j: 0..1 {
                c := digits[i * 2 + j];
                if c >= #char "0" && c <= #char "9" value = value * 16 + c - #char "0";
                else if c >= #char "a" && c <= #char "f" value = value * 16 + c - #char "a" + 10;
                else if c >= #char "A" && c <= #char "F" value = value * 16 + c - #char "A" + 10;
                else assert(false, "hex: '%' is not a hexadecimal digit in \"%\"", string.{1, *digits[i * 2 + j]}, code);
            }
            channels.component[i] = value / 255.0;
        }
        return channels;
    };
    return COLOR;
}
color :: (value: Vector4) -> Background {
    return Background.{ kind = .COLOR, color = value };
}
gradient :: (value: Linear_Gradient) -> Background {
    return Background.{ kind = .GRADIENT, gradient = value };
}

Placement :: struct {
    Kind :: enum u8 { FLOW; FIXED; RELATIVE; };

    kind: Kind;
    union {
        fixed: Vector2;
        relative: Vector2;
    }
};
flow :: () -> Placement {
    return Placement.{ kind = .FLOW };
}
fixed :: (value: Vector2) -> Placement {
    return Placement.{ kind = .FIXED, fixed = value };
}
relative :: (value: Vector2) -> Placement {
    return Placement.{ kind = .RELATIVE, relative = value };
}

UNSET :: 0xFF;
VECTOR2_NAN :: Vector2.{ x = FLOAT32_NAN, y = FLOAT32_NAN };
VECTOR4_NAN :: Vector4.{ x = FLOAT32_NAN, y = FLOAT32_NAN, z = FLOAT32_NAN, w = FLOAT32_NAN };
SIDES_NAN :: Sides.{ x = VECTOR2_NAN, y = VECTOR2_NAN };
Style :: struct {
    background: Background = Background.{ kind = UNSET };

    color: Vector4 = VECTOR4_NAN;
    border_radius: float = FLOAT32_NAN;
    border_color: Vector4 = VECTOR4_NAN;
    border_width: Border_Width = SIDES_NAN;
    border_style: Border_Style = UNSET;

    shadow: Shadow = Shadow.{
        offset = SIDES_NAN,
        blur_radius = FLOAT32_NAN,
        spread = FLOAT32_NAN,
        color = VECTOR4_NAN,
    };

    font: *Font;
    font_weight: u16 = 0;
    font_size: float = FLOAT32_NAN;
    line_height: float = FLOAT32_NAN;
    text_wrapping: Text_Wrapping = UNSET;

    cursor: Cursor = UNSET;

    // TODO: use this. we're currently not using this for anything I think this can wrap, without having to flow with text.
    // Flowing with text is meant for text decorations and such, which can be done with a text builder API
    overflow: Overflow = UNSET;
    placement: Placement = Placement.{ kind = UNSET };
    z_index: u16 = U16_MAX;

    min_width: float = FLOAT32_NAN;
    max_width: float = FLOAT32_NAN;
    width: Sizing = Sizing.{ kind = UNSET };
    min_height: float = FLOAT32_NAN;
    max_height: float = FLOAT32_NAN;
    height: Sizing = Sizing.{ kind = UNSET };

    translate: Vector2 = VECTOR2_NAN;

    padding: Padding = SIDES_NAN;
    margin: Margin = SIDES_NAN;

    x_justification: Alignment = UNSET;
    y_justification: Alignment = UNSET;
    direction: Direction = UNSET;
};

overwrite :: (style: Style, other: Style) -> Style {
    result := style;

    if result.background.kind == xx UNSET  result.background = other.background;

    if isnan(result.color.x)  result.color = other.color;
    if isnan(result.border_radius)  result.border_radius = other.border_radius;
    if isnan(result.border_color.x)  result.border_color = other.border_color;
    if isnan(result.border_width.x.x)  result.border_width = other.border_width;
    if result.border_style == xx UNSET  result.border_style = other.border_style;

    if isnan(result.shadow.blur_radius)  result.shadow = other.shadow;

    if result.font == null  result.font = other.font;
    if result.font_weight == 0  result.font_weight = other.font_weight;
    if isnan(result.font_size)  result.font_size = other.font_size;
    if isnan(result.line_height)  result.line_height = other.line_height;
    if result.text_wrapping == xx UNSET  result.text_wrapping = other.text_wrapping;
    if result.cursor == xx UNSET  result.cursor = other.cursor;

    if result.overflow == xx UNSET  result.overflow = other.overflow;
    if result.placement.kind == xx UNSET  result.placement = other.placement;
    if result.z_index == U16_MAX  result.z_index = other.z_index;

    if isnan(result.min_width)  result.min_width = other.min_width;
    if isnan(result.max_width)  result.max_width = other.max_width;
    if result.width.kind == xx UNSET  result.width = other.width;
    if isnan(result.min_height)  result.min_height = other.min_height;
    if isnan(result.max_height)  result.max_height = other.max_height;
    if result.height.kind == xx UNSET  result.height = other.height;

    if isnan(result.translate.x)  result.translate = other.translate;

    if isnan(result.padding.x.x)  result.padding = other.padding;
    if isnan(result.margin.x.x)  result.margin = other.margin;

    if result.x_justification == xx UNSET  result.x_justification = other.x_justification;
    if result.y_justification == xx UNSET  result.y_justification = other.y_justification;
    if result.direction == xx UNSET  result.direction = other.direction;

    return result;
}

complete_with :: (style: Style, base: Base_Style, out: *Complete_Style) {
    out.background = ifx style.background.kind == xx UNSET then Background.{ kind = .COLOR, color = make_vector4(0.0) } else style.background;

    out.color = ifx isnan(style.color.x) then base.color else style.color;

    out.border_radius = ifx isnan(style.border_radius) then 0.0 else style.border_radius;
    out.border_color = ifx isnan(style.border_color.x) then make_vector4(0.0) else style.border_color;
    out.border_width = ifx isnan(style.border_width.x.x) then all(0.0) else style.border_width;
    out.border_style = ifx style.border_style == xx UNSET then .SOLID else style.border_style;

    out.shadow = style.shadow;

    out.font = ifx style.font == null then base.font else style.font;
    out.font_weight = ifx style.font_weight == 0 then base.font_weight else style.font_weight;
    out.font_size = ifx isnan(style.font_size) then base.font_size else style.font_size;
    out.line_height = ifx isnan(style.line_height) then base.line_height else style.line_height;
    out.text_wrapping = ifx style.text_wrapping == xx UNSET then base.text_wrapping else style.text_wrapping;
    out.cursor = ifx style.cursor == xx UNSET then base.cursor else style.cursor;

    out.overflow = ifx style.overflow == xx UNSET then .VISIBLE else style.overflow;
    out.placement = ifx style.placement.kind == xx UNSET then Placement.{ kind = .FLOW } else style.placement;
    out.z_index = style.z_index;

    out.min_width = style.min_width;
    out.max_width = style.max_width;
    out.width = ifx style.width.kind == xx UNSET then Sizing.{ kind = .FIT } else style.width;

    out.min_height = style.min_height;
    out.max_height = style.max_height;
    out.height = ifx style.height.kind == xx UNSET then Sizing.{ kind = .FIT } else style.height;

    out.translate = ifx isnan(style.translate.x) then make_vector2(0.0) else style.translate;

    out.padding = ifx isnan(style.padding.x.x) then all(0.0) else style.padding;
    out.margin = ifx isnan(style.margin.x.x) then all(0.0) else style.margin;

    out.direction = ifx style.direction == xx UNSET then .HORIZONTAL else style.direction;
    out.x_justification = ifx style.x_justification == xx UNSET then .START else style.x_justification;
    out.y_justification = ifx style.y_justification == xx UNSET then .START else style.y_justification;
}

Pool_Slot :: struct {
    pool: Flat_Pool;
    allocator: Allocator;
    last_frame: s64;
    used: bool;
};
Node :: struct {
    Kind :: enum {
        ELEMENT; SCOPE;
    }
    kind: Kind = .ELEMENT;

    size: Vector2;
    position: Vector2;
    min_size: Vector2;
    max_size: Vector2 = Vector2.{FLOAT32_INFINITY, FLOAT32_INFINITY};
    z: u16;

    first_child: s64 = -1;
    last_child: s64 = -1;
    next_sibling: s64 = -1;
    previous_sibling: s64 = -1;
    parent: s64 = -1;
    glyphs: Glyphs;

    style: Complete_Style;

    content_size: Vector2;
    // TODO: should we have this? this feels like the wrong solution to the problem, there should be a user-accessible way of
    // changing the offset of the children without a specific property for it
    //
    // Generally used for scrolling. This is added to the position of the children of this node
    children_offset: Vector2;

    // Clip rect inherited from ancestors that have constrained size with overflowing children. Format: [x, y, width, height].
    // If NAN, no clipping is applied.
    clipping_rectangle: Vector4 = VECTOR4_NAN;
    state_offset: s64;
    state_size: s64;
    pool_slot: s64 = -1;
    key: u64;

    tree: *Node_Tree;
};
Node_Measurement :: struct {
    size: Vector2 = VECTOR2_NAN;
    position: Vector2 = VECTOR2_NAN;
    clipping_rectangle: Vector4 = VECTOR4_NAN;
    state_offset: s64;
    state_size: s64;
    pool_slot: s64 = -1;
    key: u64 = U64_MAX;
}
get_measurement :: (node_index: s64 = -1) -> measurement: Node_Measurement, defined: bool {
    using context.forbear;
    measurement_index := ifx node_index == -1 then parent_index else node_index;
    if measurement_index != -1 {
        if measurement_index < measurements.count && measurements[measurement_index].key == scope_key {
            return measurements[measurement_index], true;
        } else {
            //
            // I don't think we should sort these measurements by keys because that would be making the normal case
            // slower in favour of a case that should be rare as I expect things to be.
            //
            // TODO(depessimization): we should store a contiguous array of the keys of the previous frame's node tree's keys
            // TOOD(depessimization): we should store the previous_index in open_element(), then look up based on that here.
            // There, if the indices don't match, we should iterate to find the index
            for measurement_by_index: measurements {
                if measurement_by_index.key == scope_key {
                    return measurement_by_index, true;
                }
            }
            return Node_Measurement.{}, false;
        }
    } else {
        return Node_Measurement.{}, false;
    }
}
node_pool :: () -> Allocator {
    using context.forbear;
    assert(parent_index != -1, "node_pool() must be called from inside an element");
    node := *node_tree[parent_index];
    pool_slot := node.pool_slot;
    if pool_slot == -1 {
        measurement, defined := get_measurement();
        if defined {
            pool_slot = measurement.pool_slot;
        }
    }
    if pool_slot == -1 {
        for *slot: pool_slots {
            if !slot.used {
                pool_slot = it_index;
                if slot.pool.memory_base == null {
                    init(*slot.pool, 64 * 1024 * 1024);
                    slot.allocator.proc = flat_pool_allocator_proc;
                    slot.allocator.data = *slot.pool;
                }
                slot.used = true;
                break;
            }
        }
    }
    if pool_slot == -1 {
        log_error(#string END
There are no more pool slots available (256). This means one of three things:
1) you have a bug in your using more pool than you need;
2) you're abusing pools, and you should not;
3) we should increase our pool count to more than 256.

Please get in touch with us to judge which one it is.
        END);
        exit(-1);
    }
    node.pool_slot = pool_slot;
    pool_slots[node.pool_slot].last_frame = frame;
    return pool_slots[node.pool_slot].allocator;
}
state :: ($T: Type, initial: T) -> *T {
    using context.forbear;

    assert(parent_index != -1, "state(initial: $T) must be called from inside an element");
    node := *node_tree[parent_index];
    if node.state_size == 0 {
        node.state_offset = state_used;
    }
    assert(node.state_offset + node.state_size == state_used, "call state() before any child element that uses state");
    size := (size_of(T) + 7) & ~7;
    if state_used + size > state_buffers.*[0].count {
        log_error("state buffer is full: % bytes used, % more requested", state_used, size);
        exit(-1);
    }

    result := cast(*T) *state_buffers.*[state_current][state_used];
    result.* = initial;
    is_resizable :: (T: Type) -> bool {
        info := cast(*Type_Info) T;
        return info.type == .ARRAY && (cast(*Type_Info_Array) info).array_type == .RESIZABLE;
    }
    #if #run is_resizable(T) {
        result.allocator = node_pool();
    }
    measurement, defined := get_measurement();
    if defined && node.state_size + size <= measurement.state_size {
        memcpy(result, *state_buffers.*[1 - state_current][measurement.state_offset + node.state_size], size_of(T));
    }
    node.state_size += size;
    state_used += size;
    return result;
}
state :: (initial: $T) -> *T {
    return state(T, initial);
}
state :: ($T: Type) -> *T {
    initial: T;
    return state(T, initial);
}
// beware that this pointer might be come invalid if you define one more element
get_node :: (node_index: s64) -> *Node {
    using context.forbear;
    return *node_tree[node_index];
}
// beware that this pointer might be come invalid if you define one more element
get_node :: () -> *Node {
    using context.forbear;
    if parent_index != -1 {
        return *node_tree[parent_index];
    } else {
        return null;
    }
}
is_mouse_inside :: () -> bool {
    using context.forbear;
    measurement, defined := get_measurement();
    return defined && window.mouse_state.inside &&
        window.mouse_state.position.x >= measurement.position.x &&
        window.mouse_state.position.y >= measurement.position.y &&
        window.mouse_state.position.x <= measurement.position.x + measurement.size.x &&
        window.mouse_state.position.y <= measurement.position.y + measurement.size.y;
}
Mouse_State :: struct {
    inside: bool;
    position: Vector2;

    press_position: [MOUSE_BUTTON_COUNT]Vector2;
    pressed: [MOUSE_BUTTON_COUNT]bool;
    released: [MOUSE_BUTTON_COUNT]bool;
    held: [MOUSE_BUTTON_COUNT]bool;
};
mouse_press :: (using state: *Mouse_State, button: Mouse_Button, new_position: Vector2) {
    position = new_position;
    press_position[button] = new_position;
    pressed[button] = true;
    held[button] = true;
}
mouse_release :: (using state: *Mouse_State, button: Mouse_Button) {
    released[button] = true;
    held[button] = false;
}
Keyboard_State :: struct {
    #if OS == .LINUX {
        serial: u32;
        inside: bool;

        // The Wayland protocol does not handle keys repeating and their rates, they
        // just inform you how they should be repeated.
        //
        // There is no alternative to this in Linux, so we have to handle it ourselves.
        repeating_key: Key;
        repeating_key_code: u32;
        next_repeat: float64;
        // in characters per second
        repeat_rate: s32;
        // in milliseconds
        repeat_delay: s32;
    } else #if OS == .WINDOWS {
        // used in WM_CHAR since Windows inputs utf16 piece by piece and
        // we want to convert to utf8
        high_surrogate: u16;
    }
    events_buffer: [32 * 3]Key_Event;
    events: []Key_Event;
    #if OS == .LINUX        held: [768 + 8]Key;
    else #if OS == .MACOS   held: [128]Key;
    else                    held: [512]Key;
};
init_keyboard_state :: (using state: *Keyboard_State) {
    events.data = events_buffer.data;
    events.count = 0;
}
Key_Event :: struct {
    Kind :: enum {
        REPEATED; RELEASED; PRESSED;
    };

    kind: Kind;
    key: Key;
}
Key :: enum u32 {
    // printable keys are their Unicode code point: cast(Key) #char "+"
    A :: #char "a"; B :: #char "b"; C :: #char "c"; D :: #char "d"; E :: #char "e"; F :: #char "f";
    G :: #char "g"; H :: #char "h"; I :: #char "i"; J :: #char "j"; K :: #char "k"; L :: #char "l";
    M :: #char "m"; N :: #char "n"; O :: #char "o"; P :: #char "p"; Q :: #char "q"; R :: #char "r";
    S :: #char "s"; T :: #char "t"; U :: #char "u"; V :: #char "v"; W :: #char "w"; X :: #char "x";
    Y :: #char "y"; Z :: #char "z";

    DIGIT_0 :: #char "0"; DIGIT_1 :: #char "1"; DIGIT_2 :: #char "2"; DIGIT_3 :: #char "3"; DIGIT_4 :: #char "4";
    DIGIT_5 :: #char "5"; DIGIT_6 :: #char "6"; DIGIT_7 :: #char "7"; DIGIT_8 :: #char "8"; DIGIT_9 :: #char "9";

    SPACE :: #char " ";
    EXCLAMATION :: #char "!";
    QUOTE :: #char "\"";
    HASH :: #char "#";
    DOLLAR :: #char "$";
    PERCENT :: #char "%";
    AMPERSAND :: #char "&";
    APOSTROPHE :: #char "'";
    PARENTHESIS_LEFT :: #char "(";
    PARENTHESIS_RIGHT :: #char ")";
    ASTERISK :: #char "*";
    PLUS :: #char "+";
    COMMA :: #char ",";
    MINUS :: #char "-";
    PERIOD :: #char ".";
    SLASH :: #char "/";
    COLON :: #char ":";
    SEMICOLON :: #char ";";
    LESS :: #char "<";
    EQUAL :: #char "=";
    GREATER :: #char ">";
    QUESTION :: #char "?";
    AT :: #char "@";
    BRACKET_LEFT :: #char "[";
    BACKSLASH :: #char "\\";
    BRACKET_RIGHT :: #char "]";
    CARET :: #char "^";
    UNDERSCORE :: #char "_";
    GRAVE :: #char "`";
    BRACE_LEFT :: #char "{";
    PIPE :: #char "|";
    BRACE_RIGHT :: #char "}";
    TILDE :: #char "~";

    ESCAPE :: 0x110000;  // first value above the Unicode range
    ENTER;
    TAB;
    BACKSPACE;
    DELETE;
    INSERT;
    ARROW_LEFT; ARROW_RIGHT; ARROW_UP; ARROW_DOWN;
    HOME; END; PAGE_UP; PAGE_DOWN;
    F1; F2; F3; F4; F5; F6; F7; F8; F9; F10; F11; F12;
    SHIFT_LEFT; SHIFT_RIGHT; CONTROL_LEFT; CONTROL_RIGHT;
    ALT_LEFT; ALT_RIGHT; SUPER_LEFT; SUPER_RIGHT;
    CAPS_LOCK;
}
MOUSE_BUTTON_COUNT :: #run enum_highest_value(Mouse_Button) + 1;
Mouse_Button :: enum {
    #if OS == .LINUX {
        LEFT;
        RIGHT;
        MIDDLE;
        SIDE;
        EXTRA;
        FORWARD;
        BACK;
        TASK;
    } else {
        LEFT;
        RIGHT;
        MIDDLE;
        BACK;
        FORWARD;
    }
};
get_viewport_size :: () -> Vector2 {
    using context.forbear;
    return Vector2.{cast(float)window.width, cast(float)window.height} / (cast(float)window.scale);
}
is_mouse_held :: (button := Mouse_Button.LEFT) -> bool {
    using context.forbear;
    return window.mouse_state.held[button] && window.mouse_state.inside;
}
on_click :: (button := Mouse_Button.LEFT) -> bool {
    using context.forbear;
    if on_mouse_up(button) {
        measurement, defined := get_measurement();
        assert(defined, "the measurement should exist if is_mouse_inside is true");
        press_position := window.mouse_state.press_position[button];
        return press_position.x >= measurement.position.x &&
               press_position.y >= measurement.position.y &&
               press_position.x <= measurement.position.x + measurement.size.x &&
               press_position.y <= measurement.position.y + measurement.size.y;
    } else {
        return false;
    }
}
get_clipboard_text :: () -> string {
    using context.forbear;
    #if OS == .MACOS {
        return backend.clipboard_text;
    } else {
        return "";
    }
}
copy_to_clipboard :: (text: string) {
    using context.forbear;
    // TOOD: implment this for wayland
    #if OS == .MACOS {
        pool := objc_init(objc_alloc(NSAutoreleasePool));
        defer NSAutoreleasePool.drain(pool);

        // TODO(depessimization): this also applies in other places where we use Apple's APIs, but we should be looking
        // for ways to minimize the amount of stupid heap allocations Apple forces us to do. This is kind of impossible
        // because of Objective C, though.
        nsstring := NSString.initWithBytes(objc_alloc(NSString), text.data, xx text.count, NSUTF8StringEncoding);
        defer release(nsstring);
        backend.clipboard_change_count = backend.pasteboard.clearContents(backend.pasteboard);
        backend.pasteboard.setString(backend.pasteboard, nsstring, NSPasteboardTypeString);

        if text.count > backend.clipboard_text_buffer.count {
            backend.clipboard_text_buffer.data = realloc(
                backend.clipboard_text_buffer.data,
                text.count,
                backend.clipboard_text_buffer.count,,
                persistent_allocator
            );
            backend.clipboard_text_buffer.count = text.count;
        }
        memcpy(backend.clipboard_text_buffer.data, text.data, text.count);
        backend.clipboard_text.data = backend.clipboard_text_buffer.data;
        backend.clipboard_text.count = text.count;
    }
}
get_text_input :: () -> string {
    using context.forbear;
    return window.text;
}
on_key_down :: (code_point: u32, on_repeat := false) -> bool {
    return on_key_down(cast(Key) code_point, on_repeat);
}
on_key_down :: (key: Key, on_repeat := false) -> bool {
    using context.forbear.window.keyboard_state;
    for event: events {
        if (event.kind == .PRESSED || (on_repeat && event.kind == .REPEATED))
         && event.key == key {
            return true;
        }
    }
    return false;
}
on_key_up :: (code_point: u32) -> bool {
    return on_key_up(cast(Key) code_point);
}
on_key_up :: (key: Key) -> bool {
    using context.forbear.window.keyboard_state;
    for event: events {
        if event.kind == .RELEASED && event.key == key {
            return true;
        }
    }
    return false;
}
is_key_held :: (key: Key) -> bool {
    using context.forbear;
    #if OS == .LINUX {
        if key == {
            // TODO(depessimization): for all modifiers here we're lookgin them up by name when we should instead store the index of the modifier and just look it up
            case .SHIFT_LEFT; #through;
            case .SHIFT_RIGHT;
                return xkb_state_mod_name_is_active(backend.connection.key_state, XKB_MOD_NAME_SHIFT.data, .XKB_STATE_MODS_EFFECTIVE) == 1;
            case .ALT_LEFT; #through;
            case .ALT_RIGHT;
                return xkb_state_mod_name_is_active(backend.connection.key_state, XKB_MOD_NAME_ALT.data, .XKB_STATE_MODS_EFFECTIVE) == 1;
            case .CONTROL_LEFT; #through;
            case .CONTROL_RIGHT;
                return xkb_state_mod_name_is_active(backend.connection.key_state, XKB_MOD_NAME_CTRL.data, .XKB_STATE_MODS_EFFECTIVE) == 1;
            case .SUPER_LEFT; #through;
            case .SUPER_RIGHT;
                return xkb_state_mod_name_is_active(backend.connection.key_state, XKB_MOD_NAME_LOGO.data, .XKB_STATE_MODS_EFFECTIVE) == 1;
        }
    }

    using window.keyboard_state;
    for held {
        if it == key {
            return true;
        }
    }
    return false;
}
// TOOD: scrolling events
on_mouse_down :: (button := Mouse_Button.LEFT) -> bool {
    using context.forbear;
    return window.mouse_state.pressed[button] && is_mouse_inside();
}
on_mouse_up :: (button := Mouse_Button.LEFT) -> bool {
    using context.forbear;
    return window.mouse_state.released[button] && is_mouse_inside();
}
get_justification :: (node: *Node, direction: Direction) -> Alignment #expand {
    if direction == Direction.HORIZONTAL {
        return node.style.x_justification;
    } else {
        return node.style.y_justification;
    }
}
get_preferred_size :: (node: *Node, direction: Direction) -> Sizing #expand {
    if direction == Direction.HORIZONTAL {
        return node.style.width;
    } else {
        return node.style.height;
    }
}
should_fit_min :: (node: *Node, direction: Direction) -> bool #expand {
    if direction == .HORIZONTAL {
        return isnan(node.style.min_width) && node.style.width.kind != .FIXED;
    } else {
        return isnan(node.style.min_height) && node.style.height.kind != .FIXED;
    }
}
clamp :: (v: *Vector2, a: Vector2, b: Vector2) #expand {
    v.x = clamp(v.x, a.x, b.x);
    v.y = clamp(v.y, a.y, b.y);
}
add :: (vector: *Vector2, direction: Direction, increment: float) #expand {
    if direction == Direction.HORIZONTAL {
        vector.x += increment;
    } else {
        vector.y += increment;
    }
}
get :: (vector: Vector2, direction: Direction) -> float #expand {
    if direction == Direction.HORIZONTAL {
        return vector.x;
    } else {
        return vector.y;
    }
}
set :: (vector: *Vector2, direction: Direction, value: float) #expand {
    if direction == Direction.HORIZONTAL {
        vector.x = value;
    } else {
        vector.y = value;
    }
}
outer_size :: (node: Node, direction: Direction) -> float {
    margin := get(node.style.margin, direction);
    return get(node.size, direction) + margin.x + margin.y;

}
inner_size :: (node: Node, direction: Direction) -> float {
    return get(node.size, direction) - fitting_base(node, direction);
}
fitting_base :: (node: Node, direction: Direction) -> float {
    padding_axis := get(node.style.padding, direction);
    padding := padding_axis.x + padding_axis.y;
    border_axis := get(node.style.border_width, direction);
    border := border_axis.x + border_axis.y;
    return padding + border;
}

Node_Tree :: [..]Node;
append_to_node_tree :: (node_tree: *Node_Tree, parent_index: s64 = -1) -> pointer: *Node, index: s64 {
    push_allocator(context.forbear.persistent_allocator);

    index := node_tree.count;
    node := Node.{
        parent = parent_index,
        tree = node_tree,
    };
    if parent_index != -1 {
        parent := *node_tree.*[parent_index];
        if parent.last_child != -1 {
            node_tree.*[parent.last_child].next_sibling = index;
        }
        node.previous_sibling = parent.last_child;
        if parent.first_child == -1 {
            parent.first_child = index;
        }
        parent.last_child = index;
    }
    array_add(node_tree, node);
    return *node_tree.*[index], index;
}

Element_Opening_Data :: struct {
    parent_index: s64;
    scope_key: u64;
    base_style: Base_Style;
    node_index: s64;
};
// intermediary API that's used from adapters, such as the javascript one. when in jai, use `element`
open_element :: (style: Style, key: u64) -> previous_stack_state: Element_Opening_Data {
    element_ancestor_index := context.forbear.parent_index;
    previous_parent_index := context.forbear.parent_index;
    while element_ancestor_index != -1 && context.forbear.node_tree[element_ancestor_index].kind == .SCOPE {
        element_ancestor_index = context.forbear.node_tree[element_ancestor_index].parent;
    }

    node, index := append_to_node_tree(*context.forbear.node_tree, element_ancestor_index);
    previous_base_style := context.forbear.base_style;
    complete_with(style, context.forbear.base_style, *node.style);
    context.forbear.base_style = from(node.style);
    if style.z_index < U16_MAX {
        node.z = style.z_index;
    } else if element_ancestor_index != -1 {
        node.z = context.forbear.node_tree[element_ancestor_index].z;
    }
    node.key = key;
    if node.style.width.kind == {
        // we don't handle FIT or GROW since the node already has the right width by default
        case Sizing.Kind.FIXED;
            node.size.x = node.style.width.fixed;
    }
    if node.style.height.kind == {
        // we don't handle FIT or GROW since the node already has the right width by default
        case Sizing.Kind.FIXED;
            node.size.y = node.style.height.fixed;
    }
    if !isnan(node.style.min_width) {
        node.min_size.x = node.style.min_width;
    } else if node.style.width.kind == .FIXED {
        node.min_size.x = node.style.width.fixed;
    }
    if !isnan(node.style.min_height) {
        node.min_size.y = node.style.min_height;
    } else if node.style.height.kind == .FIXED {
        node.min_size.y = node.style.height.fixed;
    }
    if !isnan(node.style.max_width) {
        node.max_size.x = node.style.max_width;
    } else if node.style.width.kind == .FIXED {
        node.max_size.x = node.style.width.fixed;
    }
    if !isnan(node.style.max_height) {
        node.max_size.y = node.style.max_height;
    } else if node.style.height.kind == .FIXED {
        node.max_size.y = node.style.height.fixed;
    }

    node.size.x = clamp(node.size.x, node.min_size.x, node.max_size.x);
    node.size.y = clamp(node.size.y, node.min_size.y, node.max_size.y);

    previous_scope_key := context.forbear.scope_key;
    context.forbear.parent_index = index;
    context.forbear.scope_key = node.key;

    if node.style.width.kind == Sizing.Kind.FIT {
        node.size.x = fitting_base(node, Direction.HORIZONTAL);
    }
    if node.style.width.kind != Sizing.Kind.FIXED && isnan(node.style.min_width) {
        node.min_size.x = fitting_base(node, Direction.HORIZONTAL);
    }
    if node.style.height.kind == Sizing.Kind.FIT {
        node.size.y = fitting_base(node, Direction.VERTICAL);
    }
    if node.style.height.kind != Sizing.Kind.FIXED && isnan(node.style.min_height) {
        node.min_size.y = fitting_base(node, Direction.VERTICAL);
    }
    // if (isNodeActive()) {
    //     setCursor(result.ptr.style.cursor);
    // }

    return Element_Opening_Data.{
        base_style = previous_base_style,
        scope_key = previous_scope_key,
        parent_index = previous_parent_index,
        node_index = index,
    };
}
close_element :: (using data: Element_Opening_Data) {
    node := *context.forbear.node_tree[node_index];
    node.size.x = clamp(node.size.x, node.min_size.x, node.max_size.x);
    node.size.y = clamp(node.size.y, node.min_size.y, node.max_size.y);

    measurement, defined := get_measurement();
    assert(!defined || node.state_size == measurement.state_size, "element called state() a different number of times than last frame");

    context.forbear.parent_index = parent_index;
    context.forbear.scope_key = scope_key;
    context.forbear.base_style = base_style;
}
// API used when building UIs straight from jai
element :: (
    style := Style.{},
    manual_key := "",
    body: Code = #code {},
    location := #caller_location
) -> s64 #expand {
    key: u64;
    if manual_key.count > 0 {
        key = fnv1a_hash(manual_key.data, manual_key.count);
    } else {
        key = fnv1a_hash(*location, size_of(Source_Code_Location));
    }
    if context.forbear.scope_key != U64_MAX {
        key = fnv1a_hash(context.forbear.scope_key, key);
    }

    opening := open_element(style, key);
    #insert body;
    close_element(opening);
    return opening.node_index;
}
element :: (body: Code, location := #caller_location) -> s64 #expand {
    return element(body = body, location = location);
}
element :: (style: Style, body: Code, location := #caller_location) -> s64 #expand {
    return element(style = style, manual_key = "", body = body, location = location);
}
scope :: (manual_key := "", $body := #code {}, location := #caller_location) -> body.type #expand {
    key: u64;
    if manual_key.count > 0 {
        key = fnv1a_hash(manual_key.data, manual_key.count);
    } else {
        key = fnv1a_hash(*location, size_of(Source_Code_Location));
    }
    if context.forbear.scope_key != U64_MAX {
        key = fnv1a_hash(context.forbear.scope_key, key);
    }

    parent_index := context.forbear.parent_index;
    index := context.forbear.node_tree.count;
    previous_parent_index := parent_index;
    previous_scope_key := context.forbear.scope_key;
    {
        node := Node.{
            parent = parent_index,
            tree = *context.forbear.node_tree,
        };
        node.kind = .SCOPE;
        node.key = key;
        array_add(*context.forbear.node_tree, node,, allocator = context.forbear.persistent_allocator);
        context.forbear.parent_index = index;
        context.forbear.scope_key = key;
    }
    defer {
        measurement, defined := get_measurement();
        assert(!defined || context.forbear.node_tree[index].state_size == measurement.state_size, "scope called state() a different number of times than last frame");

        context.forbear.parent_index = previous_parent_index;
        context.forbear.scope_key = previous_scope_key;
    }

    #if body.type == void {
        #insert body;
    } else {
        return #insert body;
    }
}
scope :: ($body: Code, location := #caller_location) -> body.type #expand {
    return scope("", body, location);
}

Glyph :: struct {
    index: s32;
    utf8: kbts_encode_utf8;

    // all of these are in points units, that means they do not account for the font size, but they do account for the font weight.
    position: Vector2;
    // Meant for the recalculation of the glyphs position if that's required at some other layouting step
    advance: Vector2;
    // Meant for the recalculation of the glyphs position if that's required at some other layouting step
    offset: Vector2;
};
Glyphs :: struct {
    hash: u64;
    length: s32;
    array: [..]Glyph;
    pre_break_indices: [..]s64;

    //
    // all of the properties bellow are in font point units. this means they do not account for the font size, but they do account
    // for the font weight.
    //

    // Distance from line top to the shared baseline
    ascent: float;
    line_height: float;
    min_size: Vector2;
    max_size: Vector2;
};
Glyph_Atlas_Entry :: struct {
    bearing: Vector2;
    size:    Vector2;
    uv_min:  Vector2;
    uv_max:  Vector2;
};
// Shaping_Cache :: struct {
//     slots: [4096]Glyphs;
//     arena: Flat_Pool;
// };
Font :: struct {
    memory: string;

    raster_face: FT_Face;
    shaping_font: *kbts_font;
    key: u16;

    // kept track of so that this can be set during kbts text shaping
    weight: u16 = U16_MAX;

    // prev_cache: Shaping_Cache;
    // next_cache: Shaping_Cache;
};
create_font :: (memory: string) -> Font {
    #import "File";

    font: Font;
    font.memory = memory;
    return font;
}
// TOOD: handle errors for all of the freetype calls
init_font :: (using font: *Font) {
    if context.forbear.freetype_library == null {
        FT_Init_FreeType(*context.forbear.freetype_library);
        // TODO: implement subpixel font rendering and auto enable in lower DPI
        // environments to match browser behavior.
        //
        // FT_Library_SetLcdFilter(freetype_library, FT_LCD_FILTER_DEFAULT);
    }
    if context.forbear.shaping_context == null {
        context.forbear.shaping_context = kbts_CreateShapeContext(null, null);
    }
    FT_New_Memory_Face(context.forbear.freetype_library, memory.data, xx memory.count, 0, *raster_face);
    // TODO: judege if we should support more than unicode here
    assert(raster_face.charmap.encoding == FT_Encoding.UNICODE);
    font.key = context.forbear.font_counter;
    context.forbear.font_counter += 1;
    shaping_font = kbts_ShapePushFontFromMemory(context.forbear.shaping_context, memory.data, xx memory.count, 0);
}
Raster_Glyph :: struct {
    // might be null
    bitmap: string;
    left: s32;
    top: s32;
    width: u32;
    height: u32;
    pitch: s32;
};
set_weight :: (font: *Font, weight: u16) {
    // TODO: cache that this was already set so that we can avoid work
    mm: *FT_MM_Var;
    err := FT_Get_MM_Var(font.raster_face, *mm);
    if err == xx FT_Err.Invalid_Argument {
        log_error("cannot set weight - font does not support multiple masters. this is most likely not a variable font, doing nothing.");
        return;
    }
    defer FT_Done_MM_Var(context.forbear.freetype_library, mm);

    coords := NewArray(xx mm.num_axis, FT_Fixed);
    defer free(coords.data);
    FT_Get_Var_Design_Coordinates(font.raster_face, mm.num_axis, coords.data);

    for i: 0..mm.*.num_axis - 1 {
        a := *mm.*.axis[i];
        w: u64 = #char "w";
        g: u64 = #char "g";
        h: u64 = #char "h";
        t: u64 = #char "t";
        wght := (w << 24) | (g << 16) | (h << 8) | t;
        if a.tag == wght {
            coords[i] = xx clamp(cast(s64)weight * 65536, xx a.minimum, xx a.maximum);
            break;
        }
    }
    FT_Set_Var_Design_Coordinates(font.raster_face, mm.num_axis, coords.data);
    font.weight = weight;
}
set_font_size :: (font: *Font, size: u16) {
    // TODO: cache that this was already set so that we can avoid work
    FT_Set_Pixel_Sizes(font.raster_face, size, size);
}
round_font_size :: (size: float) -> u16 #expand {
   assert(size <= 0xFFFF, "font sizes need to be packed to u16");
   return xx floor(size + 0.5);
}
get_font_units_to_pixel :: (font: *Font, rounded_font_size: u16) -> float {
    using context.forbear;
    return (cast(float) rounded_font_size) / (cast(float) font.raster_face.units_per_EM);
}
font_raster_glyph :: (font: *Font, glyph_index: u16) -> Raster_Glyph {
    FT_Load_Glyph(font.raster_face, xx glyph_index, FT_LOAD_RENDER);
    glyph := font.raster_face.glyph;
    // FT_LOAD_RENDER already renders the glyph
    // FT_Render_Glyph(glyph, FT_Render_Mode.NORMAL);
    raster_glyph: Raster_Glyph;
    if glyph.bitmap.buffer != null {
        raster_glyph.bitmap.data = glyph.bitmap.buffer;
        raster_glyph.bitmap.count = xx (abs(glyph.bitmap.pitch) * xx glyph.bitmap.rows);
    }
    raster_glyph.width = glyph.bitmap.width;
    raster_glyph.height = glyph.bitmap.rows;
    raster_glyph.left = glyph.bitmap_left;
    raster_glyph.top = glyph.bitmap_top;
    raster_glyph.pitch = glyph.bitmap.pitch;
    return raster_glyph;
}
shape_text :: (font: *Font, text_wrapping: Text_Wrapping, content: string) -> Glyphs {
    // TODO(next): cache these shaped glyphs arrays for the given text so that we can reuse it in between frames
    glyphs: Glyphs;
    glyphs.line_height = cast(float) font.raster_face.height;
    glyphs.ascent = cast(float) font.raster_face.ascender;

    // TODO(next): pass the language and direction down as styles
    kbts_ShapeBegin(
        context.forbear.shaping_context,
        xx kbts_direction_enum.KBTS_DIRECTION_LTR,
        xx kbts_language_enum.KBTS_LANGUAGE_DONT_KNOW
    );
    WGHT : u32 : 0x77676874;
    if font.weight != U16_MAX {
        kbts_ShapePushGlobalVariation(context.forbear.shaping_context, WGHT, cast(float) font.weight);
    }
    kbts_ShapeUtf8(
        context.forbear.shaping_context,
        content.data,
        xx content.count,
        xx kbts_user_id_generation_mode_enum.KBTS_USER_ID_GENERATION_MODE_CODEPOINT_INDEX
    );
    if font.weight != U16_MAX {
        kbts_ShapePopGlobalVariation(context.forbear.shaping_context, WGHT);
    }
    kbts_ShapeEnd(context.forbear.shaping_context);

    run: kbts_run;
    pen: Vector2;
    // the advance local to this word
    word_advance: Vector2;
    while (kbts_ShapeRun(context.forbear.shaping_context, *run) != 0) {
        shaping_glyph: *kbts_glyph;
        while (kbts_GlyphIteratorNext(*run.Glyphs, *shaping_glyph) != 0) {
            shape_codepoint: kbts_shape_codepoint;
            if kbts_ShapeGetShapeCodepoint(context.forbear.shaping_context, shaping_glyph.UserIdOrCodepointIndex, *shape_codepoint) == 0 {
                log_error("Could not get original codeopint for glyph with user id %", shaping_glyph.UserIdOrCodepointIndex);
                continue;
            }

            utf8_encoded := kbts_EncodeUtf8(shape_codepoint.Codepoint);

            advance := Vector2.{ xx shaping_glyph.AdvanceX, xx shaping_glyph.AdvanceY };
            offset := Vector2.{ xx shaping_glyph.OffsetX, xx shaping_glyph.OffsetY };
            utf8: string;
            utf8.data = utf8_encoded.Encoded.data;
            utf8.count = utf8_encoded.EncodedLength;
            is_linebreak := starts_with(utf8, "\n");
            if is_linebreak {
                advance.x = -pen.x;
                advance.y += glyphs.line_height;
                array_add(*glyphs.pre_break_indices, glyphs.array.count);
            } else {
                glyph: Glyph;
                glyph.index = xx shaping_glyph.Id;
                glyph.advance = advance;
                glyph.offset = offset;
                glyph.position = pen + glyph.offset;
                glyph.utf8 = utf8_encoded;
                array_add(*glyphs.array, glyph);
            }

            pen += advance;
            glyphs.max_size.x = max(glyphs.max_size.x, pen.x);
            if text_wrapping == .WORD {
                if starts_with(utf8, " ") || is_linebreak {
                    word_advance = Vector2.{};
                    glyphs.max_size.y += glyphs.line_height;
                } else {
                    word_advance += advance;
                }
                glyphs.min_size.x = max(glyphs.min_size.x, word_advance.x);
            } else if text_wrapping == .CHARACTER {
                glyphs.min_size.x = max(glyphs.min_size.x, advance.x);
                glyphs.max_size.y += glyphs.line_height;
            } else if text_wrapping == .NONE {
                glyphs.min_size.x = max(glyphs.min_size.x, pen.x);
            }
        }
    }
    glyphs.min_size.y = pen.y + glyphs.line_height;
    glyphs.max_size.y = max(glyphs.min_size.y, glyphs.max_size.y);

    return glyphs;
}
free_font :: (font: *Font) {
    FT_Done_Face(font.raster_face);
}
text :: (style := Style.{}, content := "", manual_key := "", location := #caller_location) -> s64 #expand {
    return element(style, manual_key, #code {
        node := *context.forbear.node_tree[context.forbear.node_tree.count - 1];
        rounded_font_size := round_font_size(node.style.font_size * (cast(float) context.forbear.window.scale));
        set_weight(node.style.font, node.style.font_weight);
        set_font_size(node.style.font, rounded_font_size);
        node.glyphs = shape_text(node.style.font, node.style.text_wrapping, content);
        font_units_to_point := get_font_units_to_pixel(node.style.font, rounded_font_size) / (cast(float) context.forbear.window.scale);
        node.size = Vector2.{node.glyphs.max_size.x, node.glyphs.min_size.y} * font_units_to_point;
        node.min_size = node.glyphs.min_size * font_units_to_point;
        node.max_size = node.glyphs.max_size * font_units_to_point;

        if node.parent != -1 {
            parent := context.forbear.node_tree[node.parent];
            if parent.style.cursor == .DEFAULT {
                node.style.cursor = .TEXT;
            }
            node.style.x_justification = parent.style.x_justification;
            node.style.y_justification = parent.style.y_justification;
        }
    }, location);
}
text :: (content: string, manual_key := "", location := #caller_location) -> s64 #expand {
    return text(Style.{}, content, "", location);
}
Glyph_Atlas :: struct {
    // TODO: change this based on the render API that's selected. currently we only support OpenGL, though.
    texture: u32;
    table: Table(u64, Glyph_Atlas_Entry);

    cursor_x: s32;
    cursor_y: s32;
    row_height: s32;

    PADDING :: 1;
    SIZE :: 1024;
};
glyph_atlas_key :: (font: *Font, glyph_index: u16, size: u16, weight: u16) -> u64 {
    key := (cast(u64) font.key) << 48;
    key |= (cast(u64) glyph_index) << 32;
    key |= (cast(u64) size) << 16;
    key |= (cast(u64) weight);
    return key;
}
glyph_atlas_place :: (glyph_atlas: *Glyph_Atlas, width: s32, height: s32) -> x: s32, y: s32, ok: bool {
    using glyph_atlas;
    if cursor_x + width + PADDING > SIZE {
        cursor_x = 0;
        cursor_y += row_height + PADDING;
        row_height = 0;
    }
    if cursor_y + height + PADDING > SIZE {
        return 0, 0, false;
    }

    x, y := cursor_x, cursor_y;
    cursor_x += width + PADDING;
    row_height = max(row_height, height);
    return x, y, true;
}

static_state_buffers: [2][16 * 1024 * 1024]u8 #align 16;
Forbear :: struct {
    node_tree: Node_Tree;
    measurements: [..]Node_Measurement;

    frame: s64;
    persistent_allocator: Allocator;

    parent_index: s64 = -1;
    state_buffers := *static_state_buffers;
    pool_slots: [256]Pool_Slot;
    scope_key: u64 = U64_MAX;
    base_style: Base_Style;
    font_counter: u16;
    state_current: s64;
    state_used: s64;
    freetype_library: FT_Library;
    shaping_context: *kbts_shape_context;

    shader_program: u32;
    shader_vao: u32;
    node_vbo: u32;
    glyph_atlas: Glyph_Atlas;

    // TODO: we're going to have to change this once we support multiple windows
    window: *Window;
    backend: *Backend;
};
#add_context forbear: *Forbear;
init_forbear :: (
    forbear: *Forbear,
    program_window: *Window,
    // TOOD: currently we're defining the specific backend names to be just one here, but in the long-term we will include
    // multiple backends for each operating system, not one, so we need to handle that in a better way.
    program_backend: *Backend,
    program_base_style: Base_Style,
) {
    using forbear;
    context.forbear = forbear;

    forbear.window = program_window;
    forbear.persistent_allocator = context.allocator;
    forbear.glyph_atlas.table.allocator = forbear.persistent_allocator;

    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);

    //
    // ==== node rendering setup ====
    //
    glGenVertexArrays(1, *shader_vao);
    glBindVertexArray(shader_vao);
    glGenBuffers(1, *node_vbo);
    glBindBuffer(GL_ARRAY_BUFFER, node_vbo);

    stride :: size_of(Draw_Instance);
    // position
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, stride, cast(*void) 0);
    glVertexAttribDivisor(0, 1);

    // size
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, stride, cast(*void) 8);
    glVertexAttribDivisor(1, 1);

    // color
    glEnableVertexAttribArray(2);
    glVertexAttribPointer(2, 4, GL_FLOAT, GL_FALSE, stride, cast(*void) 16);
    glVertexAttribDivisor(2, 1);

    // border_width
    glEnableVertexAttribArray(3);
    glVertexAttribPointer(3, 4, GL_FLOAT, GL_FALSE, stride, cast(*void) 32);
    glVertexAttribDivisor(3, 1);

    // border_color
    glEnableVertexAttribArray(4);
    glVertexAttribPointer(4, 4, GL_FLOAT, GL_FALSE, stride, cast(*void) 48);
    glVertexAttribDivisor(4, 1);

    // border_radius
    glEnableVertexAttribArray(5);
    glVertexAttribPointer(5, 1, GL_FLOAT, GL_FALSE, stride, cast(*void) 64);
    glVertexAttribDivisor(5, 1);

    // uv_min
    glEnableVertexAttribArray(6);
    glVertexAttribPointer(6, 2, GL_FLOAT, GL_FALSE, stride, cast(*void) 68);
    glVertexAttribDivisor(6, 1);

    // uv_max
    glEnableVertexAttribArray(7);
    glVertexAttribPointer(7, 2, GL_FLOAT, GL_FALSE, stride, cast(*void) 76);
    glVertexAttribDivisor(7, 1);

    // kind
    glEnableVertexAttribArray(8);
    glVertexAttribIPointer(8, 1, GL_UNSIGNED_INT, stride, cast(*void) 84);
    glVertexAttribDivisor(8, 1);

    //
    // === node shaders ===
    //
    vertex_shader := compile_shader(GL_VERTEX_SHADER, #string GLSL
        #version 330 core
        layout(location = 0) in vec2 position;
        layout(location = 1) in vec2 size;
        layout(location = 2) in vec4 color;
        layout(location = 3) in vec4 border_width;
        layout(location = 4) in vec4 border_color;
        layout(location = 5) in float border_radius;
        layout(location = 6) in vec2 uv_min;
        layout(location = 7) in vec2 uv_max;
        layout(location = 8) in uint kind;

        uniform vec2 viewport;

        out vec2 v_position;
        out vec2 v_size;
        out vec4 v_color;
        out vec4 v_border_width;
        out vec4 v_border_color;
        out float v_border_radius;
        out vec2 v_uv;
        flat out uint v_kind;

        const vec2 corners[6] = vec2[](
          vec2(0, 0), vec2(1, 0), vec2(0, 1),
          vec2(0, 1), vec2(1, 0), vec2(1, 1)
        );

        void main() {
            vec2 corner = corners[gl_VertexID];
            v_position = corner * size.xy;
            v_size = size.xy;
            v_color = vec4(color.rgb * color.a, color.a);
            v_border_width = border_width;
            v_border_color = vec4(border_color.rgb * border_color.a, border_color.a);
            v_border_radius = border_radius;
            v_uv = mix(uv_min, uv_max, corner);
            v_kind = kind;

            gl_Position = vec4((position.xy + corner * size.xy) / viewport * 2.0 - 1.0, 0.0, 1.0);
            gl_Position.y = -gl_Position.y;
        }
GLSL);
    defer glDeleteShader(vertex_shader);
    fragment_shader := compile_shader(GL_FRAGMENT_SHADER, #string GLSL
        #version 330 core

        in vec2 v_position;
        in vec2 v_size;
        in vec4 v_color;
        in vec4 v_border_width;
        in vec4 v_border_color;
        in float v_border_radius;
        in vec2 v_uv;
        flat in uint v_kind;

        uniform sampler2D atlas;

        out vec4 out_color;

        void main() {
            if (v_kind == 1u) {
                out_color = v_color;

                vec2 p = v_position - v_size / 2.0;
                vec2 q = abs(p);
                vec2 circle_center = v_size / 2.0 - v_border_radius;

                float horizontal_width = p.x < 0.0 ? v_border_width.x : v_border_width.y;
                float vertical_width = p.y < 0.0 ? v_border_width.z : v_border_width.w;

                float ellipse_radius_a = max(v_border_radius - horizontal_width, 0);
                float ellipse_radius_b = max(v_border_radius - vertical_width, 0);

                vec2 d = q - circle_center;
                float outer_border_distance = length(d) - v_border_radius;
                float outer_border_coverage = clamp(0.5 - outer_border_distance / fwidth(outer_border_distance), 0.0, 1.0);

                vec2 e = vec2(0.0);
                if (ellipse_radius_a != 0 && ellipse_radius_b != 0) {
                    e = d / vec2(ellipse_radius_a, ellipse_radius_b);
                }
                float inner_border_distance = length(e) - 1;
                float inner_border_coverage = clamp(0.5 - inner_border_distance / fwidth(inner_border_distance), 0.0, 1.0);

                if (d.x > 0.0 && d.y > 0.0) {
                    if (ellipse_radius_a != 0 && ellipse_radius_b != 0) {
                        out_color = mix(v_border_color, v_color, inner_border_coverage);
                    } else {
                        out_color = v_border_color;
                    }

                    out_color *= outer_border_coverage;
                } else {
                    float to_left = v_position.x;
                    float to_top = v_position.y;
                    float to_right = v_size.x - v_position.x;
                    float to_bottom = v_size.y - v_position.y;
                    if (to_left <= v_border_width.x || to_right <= v_border_width.y ||
                        to_top <= v_border_width.z || to_bottom <= v_border_width.w) {
                        out_color = v_border_color;
                    }
                }
            } else if (v_kind == 2u) {
                // TODO: handle subpixel rendering
                out_color = v_color * texture(atlas, v_uv).r;
            }
        }
GLSL);
    defer glDeleteShader(fragment_shader);

    shader_program = glCreateProgram();
    glAttachShader(shader_program, vertex_shader);
    glAttachShader(shader_program, fragment_shader);
    glLinkProgram(shader_program);

    status: GLint;
    glGetProgramiv(shader_program, GL_LINK_STATUS, *status);
    if !status {
        log: [1024]u8;
        log_length: GLsizei;
        glGetProgramInfoLog(shader_program, log.count, *log_length, log.data);
        log_error("failed to link program: %\n", to_string(log.data, log_length));
        exit(-1);
    }

    glGenTextures(1, *glyph_atlas.texture);
    glBindTexture(GL_TEXTURE_2D, glyph_atlas.texture);
    // TOOD: keep track of whether subpixel rendering is enabled to create the texture atlas here accordingly
    glTexImage2D(GL_TEXTURE_2D, 0, xx GL_R8, Glyph_Atlas.SIZE, Glyph_Atlas.SIZE, 0, GL_RED, GL_UNSIGNED_BYTE, null);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

    backend = program_backend;
    base_style = program_base_style;
}

//
// ======== frame lifecycle functions ========
//

// layouting is completely dependent on the fact that the children are appended in in the order of parent -> children, if
// we ever change that, layouting completely changes too, at least in the way it traverses things, but the core algorithms
// will remain.
//
// heavily inspired by Clay distrubuted under the zlib/libpng license:
// - https://github.com/nicbarker/clay
// - https://www.clay.com/
// - https://www.youtube.com/watch?v=by9lQvpvMIc
layout :: () {
    using context.forbear;
    if node_tree.count > 0 {
        fit_child :: (node: *Node, child: *Node, fit_direction: Direction) {
            preferred_size := get_preferred_size(node, fit_direction);
            child_margin_vector := get(child.style.margin, fit_direction);
            child_margins := child_margin_vector.x + child_margin_vector.y;

            child_size := get(child.size, fit_direction);
            child_min_size := get(child.min_size, fit_direction);
            child_size_contribution := child_margins + child_size;
            child_min_size_contribution := child_margins + ifx fit_direction == .VERTICAL && preferred_size.kind != .GROW then
                max(child_size, child_min_size)
            else
                child_min_size;

            should_accumulate := preferred_size.kind == .FIT || preferred_size.kind == .GROW;

            if node.style.direction == fit_direction {
                if preferred_size.kind == .FIT {
                    add(*node.size, fit_direction, child_size_contribution);
                } else if preferred_size.kind == .GROW {
                    // TODO: ensure the max and min sizes here
                    if fit_direction == .HORIZONTAL {
                        node.size.x = max(node.size.x, child_size_contribution + fitting_base(node, .HORIZONTAL));
                    } else {
                        node.size.y = max(node.size.y, child_size_contribution + fitting_base(node, .VERTICAL));
                    }
                }
                if should_fit_min(node, fit_direction) {
                    add(*node.min_size, fit_direction, child_min_size_contribution);
                }
            } else {
                // cross axis fitting
                if should_accumulate {
                    // TODO: ensure the max and min sizes here
                    set(
                        *node.size,
                        fit_direction,
                        max(
                            child_size_contribution + fitting_base(node, fit_direction),
                            get(node.size, fit_direction)
                        )
                    );
                }
                if should_fit_min(node, fit_direction) {
                    set(*node.min_size, fit_direction, max(
                        child_min_size_contribution + fitting_base(node, fit_direction),
                        get(node.min_size, fit_direction),
                    ));
                }
            }
        }

        {
            //
            // ==== fitting nodes ====
            //
            for <*node: node_tree if node.kind == .ELEMENT && node.first_child != -1 && node.glyphs.array.count == 0 {
                if node.style.width.kind == .FIT {
                    node.size.x = fitting_base(node, .HORIZONTAL);
                }
                if isnan(node.style.min_width) && node.style.width.kind != .FIXED {
                    node.min_size.x = fitting_base(node, .HORIZONTAL);
                }
                if node.style.height.kind == .FIT {
                    node.size.y = fitting_base(node, .VERTICAL);
                }
                if isnan(node.style.min_height) && node.style.height.kind != .FIXED {
                    node.min_size.y = fitting_base(node, .VERTICAL);
                }
                child_index := node.first_child;
                while child_index != -1 {
                    child := *node_tree[child_index];
                    defer child_index = child.next_sibling;
                    if child.style.placement.kind == .FLOW &&
                    (node.style.width.kind == .FIT || node.style.width.kind == .GROW ||
                    should_fit_min(node, .HORIZONTAL) || node.style.height.kind == .FIT ||
                    node.style.height.kind == .GROW || should_fit_min(node, .VERTICAL)) {
                        fit_child(node, child, .HORIZONTAL);
                        fit_child(node, child, .VERTICAL);
                    }
                }
                clamp(*node.size, node.min_size, node.max_size);
            }
        }

        EPSILON :: 0.001;
        approximately_equal :: (a: float, b: float) -> bool {
            return abs(a - b) < EPSILON;
        }

        {
            //
            // ==== growing and shrinking nodes ====
            //
            changing: [..]*Node;
            for *node: node_tree if node.kind == .ELEMENT {
                if node.parent == -1 {
                    if node.style.width.kind == .GROW {
                        node.size.x = (cast(float) window.width) / (cast(float) window.scale);
                    }
                    if node.style.height.kind == .GROW {
                        node.size.y = (cast(float) window.height) / (cast(float) window.scale);
                    }
                }
                if node.first_child != -1 && node.glyphs.array.count == 0 {
                    array_reset_keeping_memory(*changing);
                    layout_direction := node.style.direction;
                    opposite_direction := opposite(layout_direction);
                    // this value is only the initial one, it's modified during the iteration over the children that follows
                    remaining := inner_size(node, layout_direction);

                    // this grows the children of this node. we need to do three visits here:
                    // 1) grow the children on the opposite axis of the layout direction (Style.direction)
                    // 2) iteratively grow the children equally in the layout direciton
                    // 3) iteratively shrink the children equally in the layout direction
                    child_index := node.first_child;
                    {
                        //
                        // === growing the children ===
                        //
                        while child_index != -1 {
                            child := *node_tree[child_index];
                            defer child_index = child.next_sibling;

                            child.min_size = min(child.min_size, child.max_size);

                            {
                                //
                                // == cross-axis growth ==
                                //
                                child_opposite_margin := get(child.style.margin, opposite_direction);
                                available := get(node.size, opposite_direction)
                                    - fitting_base(node, opposite_direction)
                                    - child_opposite_margin.x - child_opposite_margin.y;
                                preferred_size := get_preferred_size(child, opposite_direction);
                                size := get(child.size, opposite_direction);
                                min_size := get(child.min_size, opposite_direction);
                                max_size := get(child.max_size, opposite_direction);
                                if preferred_size.kind == .GROW ||
                                    (child.style.placement.kind == .FLOW &&
                                    size > available && min_size < size) {
                                    set(*child.size, opposite_direction, clamp(
                                        available, min_size, max_size
                                    ));
                                }
                            }

                            preferred_size := get_preferred_size(child, layout_direction);
                            child_margin := get(child.style.margin, layout_direction);

                            if (child.style.placement.kind == .RELATIVE || child.style.placement.kind == .FIXED)
                                && preferred_size.kind == .GROW {
                                // growing child that's placed RELATIVE or FIXED will have a size based on the parent solely without considering its
                                // siblings.
                                available := inner_size(node, layout_direction) - child_margin.x - child_margin.y;
                                set(*child.size, layout_direction, clamp(
                                    available,
                                    get(child.min_size, layout_direction),
                                    get(child.max_size, layout_direction),
                                ));
                            } else if child.style.placement.kind == .FLOW {
                                if preferred_size.kind == .GROW && preferred_size.grow > 0.0 {
                                    // we reset the size of the node to 0 so that the division is fair later
                                    set(*child.size, layout_direction, 0);
                                    if get(child.max_size, layout_direction) > 0 {
                                        array_add(*changing, child);
                                    }
                                }
                                remaining -= outer_size(child, layout_direction);
                            }
                        }

                        child_index = node.first_child;
                        // grow the children equally in the layout direciton
                        while remaining > EPSILON && changing.count > 0 {
                            total_factor: float = 0.0;
                            max_to_add: float = FLOAT32_INFINITY;
                            index: s64 = 0;
                            while index < changing.count {
                                child := changing[index];
                                max_size := get(child.max_size, layout_direction);
                                size := get(child.size, layout_direction);
                                if approximately_equal(size, max_size) {
                                    array_unordered_remove_by_index(*changing, index);
                                    // since the remove moves another child over to this same index, we go to the next iteration with the same index
                                    continue;
                                }
                                preferred_size := get_preferred_size(child, layout_direction);
                                total_factor += preferred_size.grow;
                                max_to_add = min(max_to_add, (max_size - size) / preferred_size.grow);

                                index += 1;
                            }

                            if changing.count > 0 && total_factor > 0 {
                                to_add := min(max_to_add, remaining / total_factor);
                                if to_add > 0.0 {
                                    remaining_before_loop := remaining;
                                    for child: changing {
                                        preferred_size := get_preferred_size(child, layout_direction);
                                        size := get(child.size, layout_direction);
                                        min_size := get(child.min_size, layout_direction);
                                        max_size := get(child.max_size, layout_direction);
                                        clamp_addendum := clamp(size + to_add * preferred_size.grow, min_size, max_size) - size;
                                        add(*child.size, layout_direction, clamp_addendum);
                                        remaining -= clamp_addendum;
                                    }
                                    if approximately_equal(remaining, remaining_before_loop) {
                                        // this means there's a max size constraint that doesn't let more size be added to any of the children
                                        break;
                                    }
                                } else {
                                    break;
                                }
                            } else if total_factor == 0 {
                                break;
                            }
                        }
                    }


                    if remaining < -EPSILON {
                        //
                        // === nodes shrinking ===
                        //
                        // we shrink children so that nodes don't overflow the parent, but fit to the largest size possible that's bigger than
                        // their minimum size
                        array_reset_keeping_memory(*changing);
                        child_index = node.first_child;
                        while child_index != -1 {
                            child := *node_tree[child_index];
                            defer child_index = child.next_sibling;
                            if child.style.placement.kind == .FLOW &&
                                get(child.size, layout_direction) > get(child.min_size, layout_direction) {
                                array_add(*changing, child);
                            }
                        }
                        while remaining < -EPSILON && changing.count > 0 {
                            largest := get(changing[0].size, layout_direction);
                            second_largest: float = 0.0;
                            index := 0;
                            while index < changing.count {
                                child := changing[index];
                                size := get(child.size, layout_direction);
                                min_size := get(child.min_size, layout_direction);
                                if approximately_equal(size, min_size) {
                                    array_unordered_remove_by_index(*changing, index);
                                    if index == 0 && changing.count > 0 {
                                        largest = get(changing[0].size, layout_direction);
                                    }
                                    // since the remove moves another child over to this same index, we go to the next iteration with the same index
                                    continue;
                                }
                                if size > largest {
                                    largest = size;
                                } else if size > second_largest {
                                    second_largest = size;
                                }
                                index += 1;
                            }
                            if changing.count > 0 {
                                to_subtract := min(
                                    largest - second_largest,
                                    -remaining / cast(float)changing.count,
                                );
                                if to_subtract == 0 {
                                    to_subtract = -remaining / cast(float)changing.count;
                                }
                                remaining_before_loop := remaining;
                                for child: changing {
                                    old_size := get(child.size, layout_direction);
                                    if approximately_equal(old_size, largest) {
                                        min_size := get(child.min_size, layout_direction);
                                        clamped_reduction := max(old_size - to_subtract, min_size) - old_size;
                                        add(*child.size, layout_direction, clamped_reduction);
                                        remaining -= clamped_reduction;
                                    }
                                }
                                if approximately_equal(remaining, remaining_before_loop) {
                                    break;
                                }
                            } else {
                                break;
                            }
                        }
                    }
                }
            }
        }

        {
            //
            // ==== wrapping glyphs ====
            //
            for <*node: node_tree if node.kind == .ELEMENT {
                rounded_font_size := round_font_size(node.style.font_size * (cast(float) window.scale));
                font_units_to_point := get_font_units_to_pixel(node.style.font, rounded_font_size) / (cast(float) window.scale);
                base := Vector2.{
                    node.style.border_width.x.x + node.style.padding.x.x,
                    node.style.border_width.y.x + node.style.padding.y.x,
                } / font_units_to_point;

                if node.glyphs.array.count > 0 && node.style.text_wrapping != .NONE {
                    using node.glyphs;

                    Line :: struct {
                        start: s64;
                        end: s64;
                    }
                    lines: [..]Line;
                    line_end := (node.size.x - fitting_base(node, .HORIZONTAL)) / font_units_to_point;
                    pen: Vector2;
                    line_start_index: s64 = 0;

                    break_cursor: s64 = 0;

                    if node.style.text_wrapping == {
                        case .CHARACTER;
                            for *glyph: array {
                                while break_cursor < pre_break_indices.count &&
                                    pre_break_indices[break_cursor] == it_index {
                                    defer break_cursor += 1;
                                    if it_index > line_start_index {
                                        array_add(*lines, Line.{
                                            start = line_start_index,
                                            end = it_index - 1,
                                        });
                                    }
                                    line_start_index = it_index;
                                    pen.x = 0.0;
                                    pen.y += line_height;
                                }

                                if pen.x + glyph.advance.x > line_end && it_index > line_start_index {
                                    array_add(*lines, .{
                                        start = line_start_index,
                                        end = it_index - 1,
                                    });
                                    line_start_index = it_index;
                                    pen.x = 0.0;
                                    pen.y += line_height;
                                }

                                glyph.position = base + pen + glyph.offset;
                                pen += glyph.advance;
                            }
                        case .WORD;
                            Space :: struct {
                                index: s64 = -1;
                                position: Vector2;
                            }
                            last_space: Space;
                            for *glyph: array {
                                while break_cursor < pre_break_indices.count &&
                                pre_break_indices[break_cursor] == it_index {
                                    defer break_cursor += 1;
                                    if it_index > line_start_index {
                                        array_add(*lines, Line.{
                                            start = line_start_index,
                                            end = it_index - 1,
                                        });
                                    }
                                    line_start_index = it_index;
                                    pen.x = 0.0;
                                    pen.y += line_height;
                                    last_space = Space.{};
                                }

                                if pen.x + glyph.advance.x > line_end && last_space.index != -1 {
                                    first_word_glyph := array[last_space.index + 1];
                                    array_add(*lines, Line.{
                                        start = line_start_index,
                                        end = last_space.index,
                                    });
                                    line_start_index = last_space.index + 1;
                                    pen.x = 0.0;
                                    pen.y += line_height;

                                    for reverse_index: (last_space.index + 1)..(it_index - 1) {
                                        reverse_glyph := *array[reverse_index];
                                        reverse_glyph.position.x -= first_word_glyph.position.x - base.x;
                                        reverse_glyph.position.y += line_height;

                                        pen += reverse_glyph.advance;
                                    }
                                    last_space = Space.{};
                                }

                                glyph.position = base + pen + glyph.offset;
                                pen += glyph.advance;
                                if starts_with(to_string(glyph.utf8.Encoded), " ") {
                                    last_space = Space.{
                                        index = it_index,
                                        position = glyph.position,
                                    };
                                }
                            }
                    }

                    while break_cursor < pre_break_indices.count {
                        pen.y += line_height;
                        break_cursor += 1;
                    }

                    if array.count > 0 {
                        if lines.count > 0 {
                            last_line := lines[lines.count - 1];
                            if last_line.end != array.count - 1 {
                                array_add(*lines, Line.{
                                    start = last_line.end + 1,
                                    end = array.count - 1,
                                });
                            }
                        } else {
                            array_add(*lines, Line.{
                                start = 0,
                                end = array.count - 1,
                            });
                        }
                    }
                    for line: lines {
                        start_x := array[line.start].position.x;
                        end_x := array[line.end].position.x + array[line.end].advance.x;

                        width := end_x - start_x;
                        line_glyphs := array_view(array, line.start, line.end + 1);
                        for *glyph: line_glyphs {
                            if node.style.x_justification == {
                                case .START;
                                case .CENTER;
                                    glyph.position.x += (line_end - width) / 2.0;
                                case .END;
                                    glyph.position.x += line_end - width;
                            }
                        }
                    }
                    node.size.y = (pen.y + line_height) * font_units_to_point;
                }
            }
        }

        {
            //
            // ==== refit heights ====
            //
            for <*node: node_tree if node.kind == .ELEMENT {
                if node.first_child != -1 && node.glyphs.array.count == 0 {
                    if node.style.height.kind == .FIT {
                        node.size.y = fitting_base(node, .VERTICAL);
                    }
                    if isnan(node.style.min_height) && node.style.height.kind != .FIXED {
                        node.min_size.y = fitting_base(node, .VERTICAL);
                    }
                    child_index := node.first_child;
                    while child_index != -1 {
                        child := *node_tree[child_index];
                        defer child_index = child.next_sibling;
                        if child.style.placement.kind == .FLOW && (node.style.height.kind == .FIT || node.style.height.kind == .GROW || should_fit_min(node, .VERTICAL)) {
                            fit_child(node, child, .VERTICAL);
                        }
                    }
                }
            }
        }

        {
            //
            // ==== regrowing nodes veritcally ====
            //
            changing: [..]*Node;
            for *node: node_tree if node.kind == .ELEMENT {
                if node.parent == -1 {
                    if node.style.height.kind == .GROW {
                        node.size.y = (cast(float) window.height) / (cast(float) window.scale);
                    }
                }
                if node.first_child != -1 && node.glyphs.array.count == 0 {
                    array_reset_keeping_memory(*changing);
                    layout_direction := node.style.direction;
                    opposite_direction := opposite(layout_direction);
                    // this value is only the initial one, it's modified during the iteration over the children that follows
                    remaining := inner_size(node, layout_direction);

                    // this grows the children of this node. we need to do three visits here:
                    // 1) grow the children on the opposite axis of the layout direction (Style.direction)
                    // 2) iteratively grow the children equally in the layout direciton
                    // 3) iteratively shrink the children equally in the layout direction
                    child_index := node.first_child;
                    {
                        //
                        // === growing the children ===
                        //
                        while child_index != -1 {
                            child := *node_tree[child_index];
                            defer child_index = child.next_sibling;

                            child.min_size = min(child.min_size, child.max_size);

                            if opposite_direction == .VERTICAL {
                                //
                                // == cross-axis growth ==
                                //
                                child_opposite_margin := get(child.style.margin, opposite_direction);
                                available := get(node.size, opposite_direction)
                                    - fitting_base(node, opposite_direction)
                                    - child_opposite_margin.x - child_opposite_margin.y;
                                preferred_size := get_preferred_size(child, opposite_direction);
                                size := get(child.size, opposite_direction);
                                min_size := get(child.min_size, opposite_direction);
                                max_size := get(child.max_size, opposite_direction);
                                if preferred_size.kind == .GROW ||
                                    (child.style.placement.kind == .FLOW &&
                                    size > available && min_size < size) {
                                    set(*child.size, opposite_direction, clamp(
                                        available, min_size, max_size
                                    ));
                                }
                            }

                            if layout_direction == .VERTICAL {
                                preferred_size := get_preferred_size(child, layout_direction);
                                child_margin := get(child.style.margin, layout_direction);

                                if (child.style.placement.kind == .RELATIVE || child.style.placement.kind == .FIXED)
                                    && preferred_size.kind == .GROW {
                                    // growing child that's placed RELATIVE or FIXED will have a size based on the parent solely without considering its
                                    // siblings.
                                    available := inner_size(node, layout_direction) - child_margin.x - child_margin.y;
                                    set(*child.size, layout_direction, clamp(
                                        available,
                                        get(child.min_size, layout_direction),
                                        get(child.max_size, layout_direction),
                                    ));
                                } else if child.style.placement.kind == .FLOW {
                                    if preferred_size.kind == .GROW && preferred_size.grow > 0.0 {
                                        // we reset the size of the node to 0 so that the division is fair later
                                        set(*child.size, layout_direction, 0);
                                        if get(child.max_size, layout_direction) > 0 {
                                            array_add(*changing, child);
                                        }
                                    }
                                    remaining -= outer_size(child, layout_direction);
                                }
                            }
                        }

                        if layout_direction == .VERTICAL {
                            child_index = node.first_child;
                            // grow the children equally in the layout direciton
                            while remaining > EPSILON && changing.count > 0 {
                                total_factor: float = 0.0;
                                max_to_add: float = FLOAT32_INFINITY;
                                index: s64 = 0;
                                while index < changing.count {
                                    child := changing[index];
                                    max_size := get(child.max_size, layout_direction);
                                    size := get(child.size, layout_direction);
                                    if approximately_equal(size, max_size) {
                                        array_unordered_remove_by_index(*changing, index);
                                        // since the remove moves another child over to this same index, we go to the next iteration with the same index
                                        continue;
                                    }
                                    preferred_size := get_preferred_size(child, layout_direction);
                                    total_factor += preferred_size.grow;
                                    max_to_add = min(max_to_add, (max_size - size) / preferred_size.grow);

                                    index += 1;
                                }

                                if changing.count > 0 && total_factor > 0 {
                                    to_add := min(max_to_add, remaining / total_factor);
                                    if to_add > 0.0 {
                                        remaining_before_loop := remaining;
                                        for child: changing {
                                            preferred_size := get_preferred_size(child, layout_direction);
                                            size := get(child.size, layout_direction);
                                            min_size := get(child.min_size, layout_direction);
                                            max_size := get(child.max_size, layout_direction);
                                            clamp_addendum := clamp(size + to_add * preferred_size.grow, min_size, max_size) - size;
                                            add(*child.size, layout_direction, clamp_addendum);
                                            remaining -= clamp_addendum;
                                        }
                                        if approximately_equal(remaining, remaining_before_loop) {
                                            // this means there's a max size constraint that doesn't let more size be added to any of the children
                                            break;
                                        }
                                    } else {
                                        break;
                                    }
                                } else if total_factor == 0 {
                                    break;
                                }
                            }
                        }
                    }
                    // TODO: should we shrink nodes here again? if we indeed decide to do this, the min sizes for
                    // wrapped text should also change, otherwise this will reduce the wrapped text's height again after
                    // it wrapped and increased.
                }
            }
        }

        {
            //
            // === place nodes and justifying them in both directions ===
            //
            for *node: node_tree if node.kind == .ELEMENT {
                if node.parent == -1 {
                    if node.style.placement.kind == {
                        case .FLOW;
                            node.position = node.style.translate;
                            node.position.x += node.style.margin.x.x;
                            node.position.y += node.style.margin.y.x;
                        case .FIXED;
                            node.position = node.style.placement.fixed + node.style.translate;
                        case .RELATIVE;
                            node.position = node.style.placement.relative + node.style.translate;
                            node.position.x += node.style.margin.x.x;
                            node.position.y += node.style.margin.y.x;
                    }
                }
                if node.first_child != -1 {
                    base := node.position + Vector2.{
                        node.style.border_width.x.x + node.style.padding.x.x,
                        node.style.border_width.y.x + node.style.padding.y.x,
                    };

                    // TODO: when the direction is horizontal, we should also handle node overflow wrapping here.
                    pen := base;
                    direction := node.style.direction;
                    opposite_direction := opposite(node.style.direction);

                    child_index := node.first_child;
                    while child_index != -1 {
                        child := *node_tree[child_index];
                        if child.style.placement.kind == {
                            case .FIXED;
                                child.position = child.style.placement.fixed + child.style.translate;
                            case .RELATIVE;
                                child.position = node.position + child.style.placement.relative + child.style.translate;
                            case .FLOW;
                                margin := get(child.style.margin, direction);
                                add(*pen, direction, margin.x);
                                child.position = pen + child.style.translate + node.children_offset;
                                add(*pen, direction, get(child.size, direction) + margin.y);
                        }
                        child_index = child.next_sibling;
                    }

                    content_size := get(pen, direction) - get(base, direction);
                    available := get(node.size, direction) - fitting_base(node, direction);
                    justification := get_justification(node, direction);
                    offset: float;
                    if justification == {
                        case .CENTER;
                            offset = (available - content_size) / 2.0;
                        case .END;
                            offset = available - content_size;
                    };

                    available_opposite := get(node.size, opposite_direction) - fitting_base(node, opposite_direction);
                    justification_opposite := get_justification(node, opposite_direction);
                    child_index = node.first_child;
                    while child_index != -1 {
                        child := *node_tree[child_index];
                        if child.style.placement.kind == .FLOW {
                            if justification_opposite == {
                                case .CENTER;
                                    add(*child.position, opposite_direction, (available_opposite - get(child.size, opposite_direction)) / 2.0);
                                case .END;
                                    add(*child.position, opposite_direction, available_opposite - get(child.size, opposite_direction));
                            };
                            add(*child.position, direction, offset);
                        }
                        child_index = child.next_sibling;
                    }
                }
            }
        }
    }
}

Draw_Instance :: struct {
    Draw_Instance_Kind :: enum u32 {
        NODE :: 1;
        GLYPH :: 2;
    };

    position: Vector2;
    size: Vector2;
    color: Vector4;

    // node
    border_width: Vector4;
    border_color: Vector4;
    border_radius: float;

    // glyph
    uv_min:  Vector2;
    uv_max:  Vector2;

    kind: Draw_Instance_Kind;
    z: u16;
};
draw :: (clearing_color := Vector4.{1.0, 1.0, 1.0, 1.0}) {
    using context.forbear;
    #if OS == .LINUX {
        glBindFramebuffer(GL_FRAMEBUFFER, window.buffers[window.current].fbo);
    } else #if OS == .MACOS {
        if backend.attached_view != window.view {
            NSOpenGLContext.setView(backend.gl_context, window.view);
            backend.attached_view = window.view;
        }
    }

    glViewport(0, 0, xx window.width, xx window.height);
    glClearColor(clearing_color.x, clearing_color.y, clearing_color.z, clearing_color.w);
    glClear(GL_COLOR_BUFFER_BIT);

    z_buckets: [..]u32;
    instance_count: s64;
    array_reserve(*z_buckets, node_tree.count);
    for node: node_tree if node.kind == .ELEMENT {
        if node.z >= z_buckets.count {
            array_resize(*z_buckets, node.z + 1);
        }
        z_buckets[node.z] += xx (1 + node.glyphs.array.count);
        instance_count += 1 + node.glyphs.array.count;
    }

    draw_instances := NewArray(instance_count, Draw_Instance, false);

    offset: u32;
    for *start: z_buckets {
        count := start.*;
        start.* = xx offset;
        offset += count;
    }
    assert(offset == draw_instances.count);
    for node: node_tree if node.kind == .ELEMENT {
        instance: Draw_Instance;
        {
            using instance;
            kind = .NODE;
            z = node.z;
            position = node.position;
            size = node.size;
            // TODO: write out the instance gathering for the other types of backgrounds
            if node.style.background.kind == .COLOR {
                color = node.style.background.color;
            }
            border_width = Vector4.{
                node.style.border_width.x.x, // left
                node.style.border_width.x.y, // right
                node.style.border_width.y.x, // top
                node.style.border_width.y.y  // bottom
            };
            border_color = node.style.border_color;
            border_radius = min(node.style.border_radius, min(node.size.x, node.size.y));
        }
        draw_instances[z_buckets[instance.z]] = instance;
        z_buckets[instance.z] += 1;

        if node.glyphs.array.count != 0 {
            rounded_font_size := round_font_size(node.style.font_size * (cast(float) window.scale));
            font_units_to_point := get_font_units_to_pixel(node.style.font, rounded_font_size) / (cast(float) window.scale);

            for glyph: node.glyphs.array {
                atlas_key := glyph_atlas_key(node.style.font, xx glyph.index, rounded_font_size, node.style.font_weight);
                entry := table_find_pointer(*glyph_atlas.table, atlas_key);
                if entry == null {
                    set_weight(node.style.font, node.style.font_weight);
                    set_font_size(node.style.font, rounded_font_size);
                    // there's no entry in the atlas for this glyph configuration
                    raster := font_raster_glyph(node.style.font, xx glyph.index);
                    x, y, ok := glyph_atlas_place(*glyph_atlas, xx raster.width, xx raster.height);
                    if !ok {
                        log_error("the atlas is full, glyph index % will not be rendered", glyph.index);
                        // TODO: pick how to handle the full atlas in a way that works as the user would prefer
                    }

                    if raster.bitmap.data != null {
                        glBindTexture(GL_TEXTURE_2D, glyph_atlas.texture);
                        glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
                        glPixelStorei(GL_UNPACK_ROW_LENGTH, raster.pitch);
                        glTexSubImage2D(GL_TEXTURE_2D, 0, x, y, raster.width, raster.height, GL_RED, GL_UNSIGNED_BYTE, raster.bitmap.data);
                        glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
                    }

                    new_entry: Glyph_Atlas_Entry;
                    new_entry.bearing = .{ xx raster.left, xx -raster.top };
                    new_entry.size    = .{ xx raster.width, xx raster.height };
                    new_entry.uv_min  = .{
                        x = x / (cast(float) Glyph_Atlas.SIZE),
                        y = y / (cast(float) Glyph_Atlas.SIZE)
                    };
                    new_entry.uv_max  = .{
                        x = ((cast(float)x) + (cast(float)raster.width)) / (cast(float) Glyph_Atlas.SIZE),
                        y = ((cast(float)y) + (cast(float)raster.height)) / (cast(float) Glyph_Atlas.SIZE)
                    };
                    entry = table_add(*glyph_atlas.table, atlas_key, new_entry);
                }

                instance: Draw_Instance;
                scale := cast(float) window.scale;
                {
                    using instance;
                    kind = .GLYPH;
                    z = node.z;
                    position = node.position + (Vector2.{0.0, node.glyphs.ascent} + glyph.position) * font_units_to_point;
                    size = entry.size / scale;
                    position += entry.bearing / scale;
                    position.x = floor(position.x * scale + 0.5) / scale;
                    position.y = floor(position.y * scale + 0.5) / scale;
                    color = node.style.color;

                    uv_min = entry.uv_min;
                    uv_max = entry.uv_max;
                }
                draw_instances[z_buckets[instance.z]] = instance;
                z_buckets[instance.z] += 1;
            }
        }
    }

    viewport_size := get_viewport_size();

    glUseProgram(shader_program);
    glUniform2f(glGetUniformLocation(shader_program, "viewport"), viewport_size.x, viewport_size.y);
    glBindVertexArray(shader_vao);
    glBindBuffer(GL_ARRAY_BUFFER, node_vbo);
    glBufferData(GL_ARRAY_BUFFER, draw_instances.count * size_of(Draw_Instance), draw_instances.data, GL_STREAM_DRAW);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, glyph_atlas.texture);
    glDrawArraysInstanced(GL_TRIANGLES, 0, 6, xx draw_instances.count);

    #if OS == .LINUX {
        glFlush();

        send_wayland_message(*backend.connection, window.wl_surface_id, Wl_Surface_Request_Attach.{ buffer = window.buffers[window.current].wl_buffer_id, x = 0, y = 0 });
        send_wayland_message(*backend.connection, window.wl_surface_id, Wl_Surface_Request_Damage_Buffer.{ x = 0, y = 0, width = window.width, height = window.height });
        window.wl_frame_callback_id = new_wayland_client_object(*backend.connection, .WL_CALLBACK);
        send_wayland_message(*backend.connection, window.wl_surface_id, Wl_Surface_Request_Frame.{
            callback = window.wl_frame_callback_id,
        });
        window.waiting_for_vblank = true;
        window.buffers[window.current].busy = true;
        send_wayland_message(*backend.connection, window.wl_surface_id, Wl_Surface_Request_Commit.{});
        window.current = (window.current + 1) % 2;
    } else #if OS == .MACOS {
        NSOpenGLContext.flushBuffer(backend.gl_context);
    } else #if OS == .WINDOWS {
        SwapBuffers(window.hdc);
        if frame == 3 {
            SetProcessWorkingSetSize(GetCurrentProcess(), U64_MAX, U64_MAX);
        }
    }
}

begin_frame :: () {
    using context.forbear;

    {
        push_allocator(persistent_allocator);
        array_resize(*measurements, node_tree.count, false);
        for node: node_tree {
            // we can't just copy the entire Node_Tree with a mempcy here because it points into frame allocated data
            // that was allocated in the frame pool. besides, in what I was able to measure, this copy tends to be more
            // performant than if we were to copy the entire Node_Tree with memcpy.
            measurements[it_index] = Node_Measurement.{
                size = node.size,
                position = node.position,
                clipping_rectangle = node.clipping_rectangle,
                state_offset = node.state_offset,
                state_size = node.state_size,
                pool_slot = node.pool_slot,
                key = node.key,
            };
        }
    }

    for *slot: pool_slots {
        if slot.used && slot.last_frame != frame {
            if slot.pool.current_point != slot.pool.memory_base {
                #if OS == .WINDOWS {
                    DiscardVirtualMemory(slot.pool.memory_base, cast(u64) ((slot.pool.current_point - slot.pool.memory_base + 4095) & ~4095));
                } else {
                    madvise(slot.pool.memory_base, cast(u64) (slot.pool.current_point - slot.pool.memory_base), MADV_DONTNEED);
                }
            }
            reset(*slot.pool);
            slot.used = false;
        }
    }

    #if OS == .LINUX {
        using window.keyboard_state;
        if repeating_key_code != 0 {
            now := seconds_since_init();
            while now >= next_repeat {
                add_key_event(*events, Key_Event.{.REPEATED, repeating_key});
                utf8: [64]u8;
                append_text(key_text(backend.connection.key_state, repeating_key_code, utf8), *window.text, window.text_buffer);
                next_repeat += 1.0 / repeat_rate;
            }
        }
    }
    state_current = 1 - state_current;
    state_used = 0;
    array_reset_keeping_memory(*node_tree);

    frame += 1;
}

end_frame :: () {
    using context.forbear;
    window.keyboard_state.events.count = 0;
    window.text.count = 0;
    memset(*window.mouse_state.released, 0, size_of(type_of(window.mouse_state.released)));
    memset(*window.mouse_state.pressed, 0, size_of(type_of(window.mouse_state.pressed)));
}

#scope_export

// This introduces a compiler plugin so that users can do +forbear in their compiliation command,
// and automatically get scope(#code Function(...)) for all of their components or hooks. The proper
// name is `@scope`, but there's also the two aliases `@component` or @hook` for what people
// might prefer.
#import "Compiler";
get_plugin :: () -> *Metaprogram_Plugin {
    using plugin := New(Metaprogram_Plugin);
    message = (plugin: *Metaprogram_Plugin, message: *Message) {
        if message.kind == .TYPECHECKED {
            typechecked := cast(*Message_Typechecked) message;
            for typechecked.procedure_bodies {
                body := it.expression;
                if !(body.body_flags & .ALREADY_MODIFIED) {
                    modified := false;
                    for sub: it.subexpressions if sub.kind == .PROCEDURE_CALL {
                        call := cast(*Code_Procedure_Call) sub;
                        callee := call.resolved_procedure_expression;
                        if callee && callee.kind == .PROCEDURE_HEADER {
                            header := cast(*Code_Procedure_Header) callee;
                            for note: header.notes if note.text == "scope" || note.text == "hook" || note.text == "component" {
                                inner_call := New(Code_Procedure_Call);
                                inner_call.* = call.*;
                                inner_call.resolved_procedure_expression = null;
                                inner_call.macro_expansion_block = null;

                                code := New(Code_Directive_Code);
                                code.kind = .DIRECTIVE_CODE;
                                code.location = call.location;
                                code.expression = inner_call;

                                ident := New(Code_Ident);
                                ident.kind = .IDENT;
                                ident.location = call.location;
                                ident.name = "scope";

                                arguments: [..]Code_Argument;
                                array_add(*arguments, .{expression = code});

                                call.procedure_expression = ident;
                                call.resolved_procedure_expression = null;
                                call.overloads = null;
                                call.arguments_unsorted = arguments;
                                call.arguments_sorted = .[];
                                call.macro_expansion_block = null;

                                modified = true;
                            }
                        }
                    }
                    if modified {
                        compiler_modify_procedure(message.workspace, body);
                    }
                }
            }
        }
    }
    return plugin;
}
