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
#import "POSIX";
#import "Socket";
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

add_key :: (array: *[]Key, key: Key) {
    for array.* {
        if it == key {
            return;
        }
    }
    assert(array.count < 32);
    array.count += 1;
    array.*[array.count - 1] = key;
}

#scope_export

#if JAVASCRIPT_ADAPTER == true {
    #load "./adapters/javascript.jai";
}

#if OS == .LINUX {
    #scope_module
    #load "bindings-linux.jai";

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
        repeating_key: Key;
        repeating_key_code: u32;
        next_repeat: float64;
        // in characters per second
        keyboard_repeat_rate: s32;
        // in milliseconds
        keyboard_repeat_delay: s32;

        keyboard_serial: u32;
        keyboard_inside: bool;
        keys_buffer: [32 * 4]Key;
        keys_pressed: []Key;
        keys_released: []Key;
        keys_held: []Key;
        keys_repeated: []Key;

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

        window.keys_pressed.data = window.keys_buffer.data;
        window.keys_released.data = window.keys_buffer.data + 32;
        window.keys_held.data = window.keys_buffer.data + 64;
        window.keys_repeated.data = window.keys_buffer.data + 96;

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
            if event.message.type == {
                case Wl_Keyboard_Event_Enter;
                    enter := cast(*Wl_Keyboard_Event_Enter) event.data;
                    if enter.surface == window.wl_surface_id {
                        window.keyboard_inside = true;
                        window.keyboard_serial = enter.serial;
                        keys: []u32;
                        keys.data = cast(*u32) enter.keys.data;
                        keys.count = enter.keys.count / size_of(u32);
                        for key: keys {
                            xkb_key := key + 8;
                            symbols: *xkb_keysym_t;
                            if xkb_keymap_key_get_syms_by_level(
                                backend.connection.keymap,
                                xkb_key,
                                xkb_state_key_get_layout(backend.connection.key_state, xkb_key),
                                0,
                                *symbols
                            ) > 0 {
                                key := cast(Key) symbols.*;
                                add_key(*window.keys_held, key);
                            }
                        }
                        // HANDLE: enter.keys
                    }
                case Wl_Keyboard_Event_Leave;
                    leave := cast(*Wl_Keyboard_Event_Leave) event.data;
                    if leave.surface == window.wl_surface_id {
                        window.keyboard_inside = false;
                        window.repeating_key_code = 0;
                        window.keys_held.count = 0;
                        xkb_compose_state_reset(backend.connection.compose_state);
                    }
                case Wl_Keyboard_Event_Repeat_Info;
                    repeat_info := cast(*Wl_Keyboard_Event_Repeat_Info) event.data;
                    window.keyboard_repeat_rate = repeat_info.rate;
                    window.keyboard_repeat_delay = repeat_info.delay;
                case Wl_Keyboard_Event_Modifiers;
                    update_held_keys_from_modifiers :: (
                        modifier: *u8,
                        key: Key,
                        backend: *Backend,
                        window: *Window,
                    ) {
                        active := xkb_state_mod_name_is_active(backend.connection.key_state, modifier, .XKB_STATE_MODS_EFFECTIVE) == 1;
                        held: bool;
                        for window.keys_held {
                            if it == key {
                                held = true;
                                break;
                            }
                        }
                        if active && !held {
                            add_key(*window.keys_pressed, key);
                            add_key(*window.keys_held, key);
                        } else if !active && held {
                            add_key(*window.keys_released, key);
                            for window.keys_held {
                                if it == key {
                                    array_unordered_remove_by_index(*window.keys_held, it_index);
                                    break;
                                }
                            }
                        }
                    }
                    update_held_keys_from_modifiers(XKB_MOD_NAME_SHIFT.data, .SHIFT_LEFT, backend, window);
                    update_held_keys_from_modifiers(XKB_MOD_NAME_SHIFT.data, .SHIFT_RIGHT, backend, window);
                    update_held_keys_from_modifiers(XKB_MOD_NAME_CTRL.data, .CONTROL_LEFT, backend, window);
                    update_held_keys_from_modifiers(XKB_MOD_NAME_CTRL.data, .CONTROL_RIGHT, backend, window);
                    update_held_keys_from_modifiers(XKB_MOD_NAME_ALT.data, .ALT_LEFT, backend, window);
                    update_held_keys_from_modifiers(XKB_MOD_NAME_ALT.data, .ALT_RIGHT, backend, window);
                    update_held_keys_from_modifiers(XKB_MOD_NAME_LOGO.data, .SUPER_LEFT, backend, window);
                    update_held_keys_from_modifiers(XKB_MOD_NAME_LOGO.data, .SUPER_RIGHT, backend, window);
                case Wl_Keyboard_Event_Key;
                    key_event := cast(*Wl_Keyboard_Event_Key) event.data;
                    xkb_key_code := key_event.key + 8;
                    symbols: *xkb_keysym_t;
                    if xkb_keymap_key_get_syms_by_level(
                        backend.connection.keymap,
                        xkb_key_code,
                        xkb_state_key_get_layout(backend.connection.key_state, xkb_key_code),
                        0,
                        *symbols
                    ) > 0 {
                        key := cast(Key) symbols.*;
                        utf8: [64]u8;
                        text: string;
                        if xkb_state_mod_name_is_active(backend.connection.key_state, XKB_MOD_NAME_ALT.data, .XKB_STATE_MODS_EFFECTIVE) == 0 &&
                            xkb_state_mod_name_is_active(backend.connection.key_state, XKB_MOD_NAME_LOGO.data, .XKB_STATE_MODS_EFFECTIVE) == 0 {
                            length := xkb_state_key_get_utf8(backend.connection.key_state, xkb_key_code, utf8.data, xx utf8.count);
                            if length < utf8.count {
                                text = to_string(utf8.data, length);
                            } else {
                                log_error("we separated a % sized utf8 buffer for the key %, but it required length %. dropping it entirely.", utf8.count, xkb_key_code, length);
                            }
                        }

                        if key_event.state == .RELEASED {
                            add_key(*window.keys_released, key);
                            for window.keys_held {
                                if it == key {
                                    array_unordered_remove_by_index(*window.keys_held, it_index);
                                    break;
                                }
                            }
                            if xkb_key_code == window.repeating_key_code {
                                window.repeating_key_code = 0;
                            }
                        } else if key_event.state == .PRESSED {
                            add_key(*window.keys_pressed, key);
                            add_key(*window.keys_held, key);

                            compose_handled := false;
                            compose := backend.connection.compose_state;
                            if compose {
                                symbol := xkb_state_key_get_one_sym(backend.connection.key_state, xkb_key_code);
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
                                utf8: [64]u8;
                                append_text(text, *window.text, window.text_buffer);
                            }
                            if window.keyboard_repeat_rate > 0 && xkb_keymap_key_repeats(backend.connection.keymap, xkb_key_code) {
                                window.repeating_key = key;
                                window.repeating_key_code = xkb_key_code;
                                window.next_repeat = seconds_since_init() + (cast(float)window.keyboard_repeat_delay) / 1000.0;
                            }
                        } else if key_event.state == .REPEATED {
                            add_key(*window.keys_repeated, key);
                            utf8: [64]u8;
                            append_text(text, *window.text, window.text_buffer);
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

    MacOS_GL_Window :: struct {
        width: float64;
        height: float64;
        scale: float64;

        ns_window: *NSWindow;
        view: *NSView;

        text_buffer: [256]u8;
        text: string;

        keys_buffer: [32 * 4]Key;
        keys_repeated: []Key;
        keys_pressed: []Key;
        keys_released: []Key;
        keys_held: []Key;

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

        window.keys_pressed.data = window.keys_buffer.data;
        window.keys_released.data = window.keys_buffer.data + 32;
        window.keys_held.data = window.keys_buffer.data + 64;
        window.keys_repeated.data = window.keys_buffer.data + 96;
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
            window.keys_held.count = 0;
        }

        update_held_keys_from_modifiers :: (
            flags: NSEventModifierFlags,
            modifier: NSEventModifierFlags,
            key: Key,
            window: *Window,
        ) {
            active := flags & modifier;
            held: bool;
            for window.keys_held {
                if it == key {
                    held = true;
                    break;
                }
            }
            if active && !held {
                add_key(*window.keys_pressed, key);
                add_key(*window.keys_held, key);
            } else if !active && held {
                add_key(*window.keys_released, key);
                for window.keys_held {
                    if it == key {
                        array_unordered_remove_by_index(*window.keys_held, it_index);
                        break;
                    }
                }
            }
        }

        flags: NSEventModifierFlags = xx objc_msgSend_typed(class(NSEvent), sel_registerName("modifierFlags".data));

        // these constants come from IOLLEvent.h
        update_held_keys_from_modifiers(flags, NSEventModifierFlagControl, Key.CONTROL_LEFT, window);
        update_held_keys_from_modifiers(flags, NSEventModifierFlagControl, Key.CONTROL_RIGHT, window);
        update_held_keys_from_modifiers(flags, NSEventModifierFlagShift, Key.SHIFT_LEFT, window);
        update_held_keys_from_modifiers(flags, NSEventModifierFlagShift, Key.SHIFT_RIGHT, window);
        update_held_keys_from_modifiers(flags, NSEventModifierFlagOption, Key.ALT_LEFT, window);
        update_held_keys_from_modifiers(flags, NSEventModifierFlagOption, Key.ALT_RIGHT, window);
        update_held_keys_from_modifiers(flags, NSEventModifierFlagCommand, Key.SUPER_LEFT, window);
        update_held_keys_from_modifiers(flags, NSEventModifierFlagCommand, Key.SUPER_RIGHT, window);
        update_held_keys_from_modifiers(flags, xx NSEventModifierFlagFunction, Key.FUNCTION, window);
    }

    MacOS_GL_Backend :: struct {
        app: *NSApplication;
        pixel_format: *NSOpenGLPixelFormat;
        gl_context: *NSOpenGLContext;

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
        window := context.forbear.window;
        frame := NSView.frame(window.view);
        location := NSWindow.mouseLocationOutsideOfEventStream(window.ns_window);
        window.pointer_inside = location.x >= 0 && location.y >= 0 &&
                                location.x < frame.size.width && location.y < frame.size.height;
        window.pointer_position = Vector2.{ xx location.x, xx (frame.size.height - location.y) };
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
                        key: Key = xx NSEvent.keyCode(event);
                        if !NSEvent.isARepeat(event) {
                            add_key(*window.keys_pressed, key);
                            add_key(*window.keys_held, key);
                        } else {
                            add_key(*window.keys_repeated, key);
                        }
                        if !(NSEvent.modifierFlags(event) & .NSEventModifierFlagCommand) {
                            characters := NSEvent.characters(event);
                            if characters {
                                text := to_string(NSString.UTF8String(characters));
                                if text.count != 3 || text[0] == 0xEF && text[1] >= 0x9C && text[1] <= 0xA3 {
                                    append_text(text, *window.text, window.text_buffer);
                                }
                            }
                        }
                    case NSEventTypeKeyUp;
                        key: Key = xx NSEvent.keyCode(event);
                        add_key(*window.keys_released, key);
                        for window.keys_held {
                            if it == key {
                                array_unordered_remove_by_index(*window.keys_held, it_index);
                                break;
                            }
                        }
                    case;
                        backend.app.sendEvent(backend.app, event);
                }
            } else {
                break;
            }
        }
        NSAutoreleasePool.drain(pool);
    }

    Backend :: MacOS_GL_Backend;
    Window :: MacOS_GL_Window;
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
pool_slots: [256]Pool_Slot;
Element :: struct {
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
    // Generally used for scrolling. This is added to the position of the children of this element
    children_offset: Vector2;

    // Clip rect inherited from ancestors that have constrained size with overflowing children. Format: [x, y, width, height].
    // If NAN, no clipping is applied.
    clipping_rectangle: Vector4 = VECTOR4_NAN;
    state_offset: s64;
    state_size: s64;
    pool_slot: s64 = -1;
    key: u64;

    tree: *Element_Tree;
};
Element_Measurement :: struct {
    size: Vector2 = VECTOR2_NAN;
    position: Vector2 = VECTOR2_NAN;
    clipping_rectangle: Vector4 = VECTOR4_NAN;
    state_offset: s64;
    state_size: s64;
    pool_slot: s64 = -1;
    key: u64 = U64_MAX;
}
get_measurement :: (element_index: s64 = -1) -> measurement: Element_Measurement, defined: bool {
    using context.forbear;
    measurement_index := ifx element_index == -1 then parent_index else element_index;
    if measurement_index != -1 {
        if measurement_index < measurements.count && measurements[measurement_index].key == scope_key {
            return measurements[measurement_index], true;
        } else {
            //
            // I don't think we should sort these measurements by keys because that would be making the normal case
            // slower in favour of a case that should be rare as I expect things to be.
            //
            // TODO: to improve the performance of this, we should store a contiguous array of the keys of the previous
            // frame's element tree's keys
            //
            for measurement_by_index: measurements {
                if measurement_by_index.key == scope_key {
                    return measurement_by_index, true;
                }
            }
            return Element_Measurement.{}, false;
        }
    } else {
        return Element_Measurement.{}, false;
    }
}
element_pool :: () -> Allocator {
    using context.forbear;
    assert(parent_index != -1, "element_pool() must be called from inside an element");
    element := *element_tree[parent_index];
    pool_slot := element.pool_slot;
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
    element.pool_slot = pool_slot;
    pool_slots[element.pool_slot].last_frame = frame;
    return pool_slots[element.pool_slot].allocator;
}
state :: ($T: Type, initial: T) -> *T {
    using context.forbear;

    assert(parent_index != -1, "state(initial: $T) must be called from inside an element");
    element := *element_tree[parent_index];
    if element.state_size == 0 {
        element.state_offset = state_used;
    }
    assert(element.state_offset + element.state_size == state_used, "call state() before any child element that uses state");
    size := (size_of(T) + 7) & ~7;
    if state_used + size > state_buffers[0].count {
        log_error("state buffer is full: % bytes used, % more requested", state_used, size);
        exit(-1);
    }

    result := cast(*T) *state_buffers[state_current][state_used];
    result.* = initial;
    is_resizable :: (T: Type) -> bool {
        info := cast(*Type_Info) T;
        return info.type == .ARRAY && (cast(*Type_Info_Array) info).array_type == .RESIZABLE;
    }
    #if #run is_resizable(T) {
        result.allocator = element_pool();
    }
    measurement, defined := get_measurement();
    if defined && element.state_size + size <= measurement.state_size {
        memcpy(result, *state_buffers[1 - state_current][measurement.state_offset + element.state_size], size_of(T));
    }
    element.state_size += size;
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
get_element :: () -> *Element {
    using context.forbear;
    if parent_index != -1 {
        return *element_tree[parent_index];
    } else {
        return null;
    }
}
is_mouse_inside :: () -> bool {
    using context.forbear;
    measurement, defined := get_measurement();
    return defined && window.pointer_inside &&
        window.pointer_position.x >= measurement.position.x &&
        window.pointer_position.y >= measurement.position.y &&
        window.pointer_position.x <= measurement.position.x + measurement.size.x &&
        window.pointer_position.y <= measurement.position.y + measurement.size.y;
}
Key :: enum {
    #if OS == .LINUX {
        A :: XKB_KEY_a;
        B :: XKB_KEY_b;
        C :: XKB_KEY_c;
        D :: XKB_KEY_d;
        E :: XKB_KEY_e;
        F :: XKB_KEY_f;
        G :: XKB_KEY_g;
        H :: XKB_KEY_h;
        I :: XKB_KEY_i;
        J :: XKB_KEY_j;
        K :: XKB_KEY_k;
        L :: XKB_KEY_l;
        M :: XKB_KEY_m;
        N :: XKB_KEY_n;
        O :: XKB_KEY_o;
        P :: XKB_KEY_p;
        Q :: XKB_KEY_q;
        R :: XKB_KEY_r;
        S :: XKB_KEY_s;
        T :: XKB_KEY_t;
        U :: XKB_KEY_u;
        V :: XKB_KEY_v;
        W :: XKB_KEY_w;
        X :: XKB_KEY_x;
        Y :: XKB_KEY_y;
        Z :: XKB_KEY_z;

        DIGIT_0 :: XKB_KEY_0;
        DIGIT_1 :: XKB_KEY_1;
        DIGIT_2 :: XKB_KEY_2;
        DIGIT_3 :: XKB_KEY_3;
        DIGIT_4 :: XKB_KEY_4;
        DIGIT_5 :: XKB_KEY_5;
        DIGIT_6 :: XKB_KEY_6;
        DIGIT_7 :: XKB_KEY_7;
        DIGIT_8 :: XKB_KEY_8;
        DIGIT_9 :: XKB_KEY_9;

        F1 :: XKB_KEY_F1;
        F2 :: XKB_KEY_F2;
        F3 :: XKB_KEY_F3;
        F4 :: XKB_KEY_F4;
        F5 :: XKB_KEY_F5;
        F6 :: XKB_KEY_F6;
        F7 :: XKB_KEY_F7;
        F8 :: XKB_KEY_F8;
        F9 :: XKB_KEY_F9;
        F10 :: XKB_KEY_F10;
        F11 :: XKB_KEY_F11;
        F12 :: XKB_KEY_F12;

        SHIFT_LEFT :: XKB_KEY_Shift_L;
        SHIFT_RIGHT :: XKB_KEY_Shift_R;
        SHIFT_LOCK :: XKB_KEY_Shift_Lock;
        CONTROL_LEFT :: XKB_KEY_Control_L;
        CONTROL_RIGHT :: XKB_KEY_Control_R;
        ALT_LEFT :: XKB_KEY_Alt_L;
        ALT_RIGHT :: XKB_KEY_Alt_R;
        SUPER_LEFT :: XKB_KEY_Super_L;
        SUPER_RIGHT :: XKB_KEY_Super_R;
        CAPS_LOCK :: XKB_KEY_Caps_Lock;

        ARROW_LEFT :: XKB_KEY_Left;
        ARROW_RIGHT :: XKB_KEY_Right;
        ARROW_UP :: XKB_KEY_Up;
        ARROW_DOWN :: XKB_KEY_Down;
        HOME :: XKB_KEY_Home;
        END :: XKB_KEY_End;
        PAGE_UP :: XKB_KEY_Page_Up;
        PAGE_DOWN :: XKB_KEY_Page_Down;

        TAB :: XKB_KEY_Tab;
        ESCAPE :: XKB_KEY_Escape;
        ENTER :: XKB_KEY_Return;
        SPACE :: XKB_KEY_space;
        BACKSPACE :: XKB_KEY_BackSpace;
        DELETE :: XKB_KEY_Delete;
        INSERT :: XKB_KEY_Insert;

        MINUS :: XKB_KEY_minus;
        EQUAL :: XKB_KEY_equal;
        BRACKET_LEFT :: XKB_KEY_bracketleft;
        BRACKET_RIGHT :: XKB_KEY_bracketright;
        BACKSLASH :: XKB_KEY_backslash;
        SEMICOLON :: XKB_KEY_semicolon;
        APOSTROPHE :: XKB_KEY_apostrophe;
        GRAVE :: XKB_KEY_grave;
        COMMA :: XKB_KEY_comma;
        PERIOD :: XKB_KEY_period;
        SLASH :: XKB_KEY_slash;

        NOSYMBOL :: XKB_KEY_NoSymbol;
        VOIDSYMBOL :: XKB_KEY_VoidSymbol;
        LINEFEED :: XKB_KEY_Linefeed;
        CLEAR :: XKB_KEY_Clear;
        PAUSE :: XKB_KEY_Pause;
        SCROLL_LOCK :: XKB_KEY_Scroll_Lock;
        SYS_REQ :: XKB_KEY_Sys_Req;
        MULTI_KEY :: XKB_KEY_Multi_key;
        CODEINPUT :: XKB_KEY_Codeinput;
        SINGLECANDIDATE :: XKB_KEY_SingleCandidate;
        MULTIPLECANDIDATE :: XKB_KEY_MultipleCandidate;
        PREVIOUSCANDIDATE :: XKB_KEY_PreviousCandidate;
        KANJI :: XKB_KEY_Kanji;
        MUHENKAN :: XKB_KEY_Muhenkan;
        HENKAN_MODE :: XKB_KEY_Henkan_Mode;
        HENKAN :: XKB_KEY_Henkan;
        ROMAJI :: XKB_KEY_Romaji;
        HIRAGANA :: XKB_KEY_Hiragana;
        KATAKANA :: XKB_KEY_Katakana;
        HIRAGANA_KATAKANA :: XKB_KEY_Hiragana_Katakana;
        ZENKAKU :: XKB_KEY_Zenkaku;
        HANKAKU :: XKB_KEY_Hankaku;
        ZENKAKU_HANKAKU :: XKB_KEY_Zenkaku_Hankaku;
        TOUROKU :: XKB_KEY_Touroku;
        MASSYO :: XKB_KEY_Massyo;
        KANA_LOCK :: XKB_KEY_Kana_Lock;
        KANA_SHIFT :: XKB_KEY_Kana_Shift;
        EISU_SHIFT :: XKB_KEY_Eisu_Shift;
        EISU_TOGGLE :: XKB_KEY_Eisu_toggle;
        KANJI_BANGOU :: XKB_KEY_Kanji_Bangou;
        ZEN_KOHO :: XKB_KEY_Zen_Koho;
        MAE_KOHO :: XKB_KEY_Mae_Koho;
        PRIOR :: XKB_KEY_Prior;
        NEXT :: XKB_KEY_Next;
        BEGIN :: XKB_KEY_Begin;
        SELECT :: XKB_KEY_Select;
        PRINT :: XKB_KEY_Print;
        EXECUTE :: XKB_KEY_Execute;
        UNDO :: XKB_KEY_Undo;
        REDO :: XKB_KEY_Redo;
        MENU :: XKB_KEY_Menu;
        FIND :: XKB_KEY_Find;
        CANCEL :: XKB_KEY_Cancel;
        HELP :: XKB_KEY_Help;
        BREAK :: XKB_KEY_Break;
        ISO_GROUP_SHIFT :: XKB_KEY_ISO_Group_Shift;
        MODE_SWITCH :: XKB_KEY_Mode_switch;
        SCRIPT_SWITCH :: XKB_KEY_script_switch;
        NUM_LOCK :: XKB_KEY_Num_Lock;
        KP_SPACE :: XKB_KEY_KP_Space;
        KP_TAB :: XKB_KEY_KP_Tab;
        KP_ENTER :: XKB_KEY_KP_Enter;
        KP_F1 :: XKB_KEY_KP_F1;
        KP_F2 :: XKB_KEY_KP_F2;
        KP_F3 :: XKB_KEY_KP_F3;
        KP_F4 :: XKB_KEY_KP_F4;
        KP_HOME :: XKB_KEY_KP_Home;
        KP_LEFT :: XKB_KEY_KP_Left;
        KP_UP :: XKB_KEY_KP_Up;
        KP_RIGHT :: XKB_KEY_KP_Right;
        KP_DOWN :: XKB_KEY_KP_Down;
        KP_PRIOR :: XKB_KEY_KP_Prior;
        KP_PAGE_UP :: XKB_KEY_KP_Page_Up;
        KP_NEXT :: XKB_KEY_KP_Next;
        KP_PAGE_DOWN :: XKB_KEY_KP_Page_Down;
        KP_END :: XKB_KEY_KP_End;
        KP_BEGIN :: XKB_KEY_KP_Begin;
        KP_INSERT :: XKB_KEY_KP_Insert;
        KP_DELETE :: XKB_KEY_KP_Delete;
        KP_EQUAL :: XKB_KEY_KP_Equal;
        KP_MULTIPLY :: XKB_KEY_KP_Multiply;
        KP_ADD :: XKB_KEY_KP_Add;
        KP_SEPARATOR :: XKB_KEY_KP_Separator;
        KP_SUBTRACT :: XKB_KEY_KP_Subtract;
        KP_DECIMAL :: XKB_KEY_KP_Decimal;
        KP_DIVIDE :: XKB_KEY_KP_Divide;
        KP_0 :: XKB_KEY_KP_0;
        KP_1 :: XKB_KEY_KP_1;
        KP_2 :: XKB_KEY_KP_2;
        KP_3 :: XKB_KEY_KP_3;
        KP_4 :: XKB_KEY_KP_4;
        KP_5 :: XKB_KEY_KP_5;
        KP_6 :: XKB_KEY_KP_6;
        KP_7 :: XKB_KEY_KP_7;
        KP_8 :: XKB_KEY_KP_8;
        KP_9 :: XKB_KEY_KP_9;
        L1 :: XKB_KEY_L1;
        L2 :: XKB_KEY_L2;
        F13 :: XKB_KEY_F13;
        L3 :: XKB_KEY_L3;
        F14 :: XKB_KEY_F14;
        L4 :: XKB_KEY_L4;
        F15 :: XKB_KEY_F15;
        L5 :: XKB_KEY_L5;
        F16 :: XKB_KEY_F16;
        L6 :: XKB_KEY_L6;
        F17 :: XKB_KEY_F17;
        L7 :: XKB_KEY_L7;
        F18 :: XKB_KEY_F18;
        L8 :: XKB_KEY_L8;
        F19 :: XKB_KEY_F19;
        L9 :: XKB_KEY_L9;
        F20 :: XKB_KEY_F20;
        L10 :: XKB_KEY_L10;
        F21 :: XKB_KEY_F21;
        R1 :: XKB_KEY_R1;
        F22 :: XKB_KEY_F22;
        R2 :: XKB_KEY_R2;
        F23 :: XKB_KEY_F23;
        R3 :: XKB_KEY_R3;
        F24 :: XKB_KEY_F24;
        R4 :: XKB_KEY_R4;
        F25 :: XKB_KEY_F25;
        R5 :: XKB_KEY_R5;
        F26 :: XKB_KEY_F26;
        R6 :: XKB_KEY_R6;
        F27 :: XKB_KEY_F27;
        R7 :: XKB_KEY_R7;
        F28 :: XKB_KEY_F28;
        R8 :: XKB_KEY_R8;
        F29 :: XKB_KEY_F29;
        R9 :: XKB_KEY_R9;
        F30 :: XKB_KEY_F30;
        R10 :: XKB_KEY_R10;
        F31 :: XKB_KEY_F31;
        R11 :: XKB_KEY_R11;
        F32 :: XKB_KEY_F32;
        R12 :: XKB_KEY_R12;
        F33 :: XKB_KEY_F33;
        R13 :: XKB_KEY_R13;
        F34 :: XKB_KEY_F34;
        R14 :: XKB_KEY_R14;
        F35 :: XKB_KEY_F35;
        R15 :: XKB_KEY_R15;
        META_L :: XKB_KEY_Meta_L;
        META_R :: XKB_KEY_Meta_R;
        HYPER_L :: XKB_KEY_Hyper_L;
        HYPER_R :: XKB_KEY_Hyper_R;
        ISO_LOCK :: XKB_KEY_ISO_Lock;
        ISO_LEVEL2_LATCH :: XKB_KEY_ISO_Level2_Latch;
        ISO_LEVEL3_SHIFT :: XKB_KEY_ISO_Level3_Shift;
        ISO_LEVEL3_LATCH :: XKB_KEY_ISO_Level3_Latch;
        ISO_LEVEL3_LOCK :: XKB_KEY_ISO_Level3_Lock;
        ISO_LEVEL5_SHIFT :: XKB_KEY_ISO_Level5_Shift;
        ISO_LEVEL5_LATCH :: XKB_KEY_ISO_Level5_Latch;
        ISO_LEVEL5_LOCK :: XKB_KEY_ISO_Level5_Lock;
        ISO_GROUP_LATCH :: XKB_KEY_ISO_Group_Latch;
        ISO_GROUP_LOCK :: XKB_KEY_ISO_Group_Lock;
        ISO_NEXT_GROUP :: XKB_KEY_ISO_Next_Group;
        ISO_NEXT_GROUP_LOCK :: XKB_KEY_ISO_Next_Group_Lock;
        ISO_PREV_GROUP :: XKB_KEY_ISO_Prev_Group;
        ISO_PREV_GROUP_LOCK :: XKB_KEY_ISO_Prev_Group_Lock;
        ISO_FIRST_GROUP :: XKB_KEY_ISO_First_Group;
        ISO_FIRST_GROUP_LOCK :: XKB_KEY_ISO_First_Group_Lock;
        ISO_LAST_GROUP :: XKB_KEY_ISO_Last_Group;
        ISO_LAST_GROUP_LOCK :: XKB_KEY_ISO_Last_Group_Lock;
        ISO_LEFT_TAB :: XKB_KEY_ISO_Left_Tab;
        ISO_MOVE_LINE_UP :: XKB_KEY_ISO_Move_Line_Up;
        ISO_MOVE_LINE_DOWN :: XKB_KEY_ISO_Move_Line_Down;
        ISO_PARTIAL_LINE_UP :: XKB_KEY_ISO_Partial_Line_Up;
        ISO_PARTIAL_LINE_DOWN :: XKB_KEY_ISO_Partial_Line_Down;
        ISO_PARTIAL_SPACE_LEFT :: XKB_KEY_ISO_Partial_Space_Left;
        ISO_PARTIAL_SPACE_RIGHT :: XKB_KEY_ISO_Partial_Space_Right;
        ISO_SET_MARGIN_LEFT :: XKB_KEY_ISO_Set_Margin_Left;
        ISO_SET_MARGIN_RIGHT :: XKB_KEY_ISO_Set_Margin_Right;
        ISO_RELEASE_MARGIN_LEFT :: XKB_KEY_ISO_Release_Margin_Left;
        ISO_RELEASE_MARGIN_RIGHT :: XKB_KEY_ISO_Release_Margin_Right;
        ISO_RELEASE_BOTH_MARGINS :: XKB_KEY_ISO_Release_Both_Margins;
        ISO_FAST_CURSOR_LEFT :: XKB_KEY_ISO_Fast_Cursor_Left;
        ISO_FAST_CURSOR_RIGHT :: XKB_KEY_ISO_Fast_Cursor_Right;
        ISO_FAST_CURSOR_UP :: XKB_KEY_ISO_Fast_Cursor_Up;
        ISO_FAST_CURSOR_DOWN :: XKB_KEY_ISO_Fast_Cursor_Down;
        ISO_CONTINUOUS_UNDERLINE :: XKB_KEY_ISO_Continuous_Underline;
        ISO_DISCONTINUOUS_UNDERLINE :: XKB_KEY_ISO_Discontinuous_Underline;
        ISO_EMPHASIZE :: XKB_KEY_ISO_Emphasize;
        ISO_CENTER_OBJECT :: XKB_KEY_ISO_Center_Object;
        ISO_ENTER :: XKB_KEY_ISO_Enter;
        DEAD_GRAVE :: XKB_KEY_dead_grave;
        DEAD_ACUTE :: XKB_KEY_dead_acute;
        DEAD_CIRCUMFLEX :: XKB_KEY_dead_circumflex;
        DEAD_TILDE :: XKB_KEY_dead_tilde;
        DEAD_PERISPOMENI :: XKB_KEY_dead_perispomeni;
        DEAD_MACRON :: XKB_KEY_dead_macron;
        DEAD_BREVE :: XKB_KEY_dead_breve;
        DEAD_ABOVEDOT :: XKB_KEY_dead_abovedot;
        DEAD_DIAERESIS :: XKB_KEY_dead_diaeresis;
        DEAD_ABOVERING :: XKB_KEY_dead_abovering;
        DEAD_DOUBLEACUTE :: XKB_KEY_dead_doubleacute;
        DEAD_CARON :: XKB_KEY_dead_caron;
        DEAD_CEDILLA :: XKB_KEY_dead_cedilla;
        DEAD_OGONEK :: XKB_KEY_dead_ogonek;
        DEAD_IOTA :: XKB_KEY_dead_iota;
        DEAD_VOICED_SOUND :: XKB_KEY_dead_voiced_sound;
        DEAD_SEMIVOICED_SOUND :: XKB_KEY_dead_semivoiced_sound;
        DEAD_BELOWDOT :: XKB_KEY_dead_belowdot;
        DEAD_HOOK :: XKB_KEY_dead_hook;
        DEAD_HORN :: XKB_KEY_dead_horn;
        DEAD_STROKE :: XKB_KEY_dead_stroke;
        DEAD_ABOVECOMMA :: XKB_KEY_dead_abovecomma;
        DEAD_PSILI :: XKB_KEY_dead_psili;
        DEAD_ABOVEREVERSEDCOMMA :: XKB_KEY_dead_abovereversedcomma;
        DEAD_DASIA :: XKB_KEY_dead_dasia;
        DEAD_DOUBLEGRAVE :: XKB_KEY_dead_doublegrave;
        DEAD_BELOWRING :: XKB_KEY_dead_belowring;
        DEAD_BELOWMACRON :: XKB_KEY_dead_belowmacron;
        DEAD_BELOWCIRCUMFLEX :: XKB_KEY_dead_belowcircumflex;
        DEAD_BELOWTILDE :: XKB_KEY_dead_belowtilde;
        DEAD_BELOWBREVE :: XKB_KEY_dead_belowbreve;
        DEAD_BELOWDIAERESIS :: XKB_KEY_dead_belowdiaeresis;
        DEAD_INVERTEDBREVE :: XKB_KEY_dead_invertedbreve;
        DEAD_BELOWCOMMA :: XKB_KEY_dead_belowcomma;
        DEAD_CURRENCY :: XKB_KEY_dead_currency;
        DEAD_LOWLINE :: XKB_KEY_dead_lowline;
        DEAD_ABOVEVERTICALLINE :: XKB_KEY_dead_aboveverticalline;
        DEAD_BELOWVERTICALLINE :: XKB_KEY_dead_belowverticalline;
        DEAD_LONGSOLIDUSOVERLAY :: XKB_KEY_dead_longsolidusoverlay;
        DEAD_A :: XKB_KEY_dead_a;
        CAPITAL_DEAD_A :: XKB_KEY_dead_A;
        DEAD_E :: XKB_KEY_dead_e;
        CAPITAL_DEAD_E :: XKB_KEY_dead_E;
        DEAD_I :: XKB_KEY_dead_i;
        CAPITAL_DEAD_I :: XKB_KEY_dead_I;
        DEAD_O :: XKB_KEY_dead_o;
        CAPITAL_DEAD_O :: XKB_KEY_dead_O;
        DEAD_U :: XKB_KEY_dead_u;
        CAPITAL_DEAD_U :: XKB_KEY_dead_U;
        DEAD_SMALL_SCHWA :: XKB_KEY_dead_small_schwa;
        DEAD_SCHWA :: XKB_KEY_dead_schwa;
        DEAD_CAPITAL_SCHWA :: XKB_KEY_dead_capital_schwa;
        CAPITAL_DEAD_SCHWA :: XKB_KEY_dead_SCHWA;
        DEAD_GREEK :: XKB_KEY_dead_greek;
        DEAD_HAMZA :: XKB_KEY_dead_hamza;
        DEAD_APOSTROPHE :: XKB_KEY_dead_apostrophe;
        FIRST_VIRTUAL_SCREEN :: XKB_KEY_First_Virtual_Screen;
        PREV_VIRTUAL_SCREEN :: XKB_KEY_Prev_Virtual_Screen;
        NEXT_VIRTUAL_SCREEN :: XKB_KEY_Next_Virtual_Screen;
        LAST_VIRTUAL_SCREEN :: XKB_KEY_Last_Virtual_Screen;
        TERMINATE_SERVER :: XKB_KEY_Terminate_Server;
        ACCESSX_ENABLE :: XKB_KEY_AccessX_Enable;
        ACCESSX_FEEDBACK_ENABLE :: XKB_KEY_AccessX_Feedback_Enable;
        REPEATKEYS_ENABLE :: XKB_KEY_RepeatKeys_Enable;
        SLOWKEYS_ENABLE :: XKB_KEY_SlowKeys_Enable;
        BOUNCEKEYS_ENABLE :: XKB_KEY_BounceKeys_Enable;
        STICKYKEYS_ENABLE :: XKB_KEY_StickyKeys_Enable;
        MOUSEKEYS_ENABLE :: XKB_KEY_MouseKeys_Enable;
        MOUSEKEYS_ACCEL_ENABLE :: XKB_KEY_MouseKeys_Accel_Enable;
        OVERLAY1_ENABLE :: XKB_KEY_Overlay1_Enable;
        OVERLAY2_ENABLE :: XKB_KEY_Overlay2_Enable;
        AUDIBLEBELL_ENABLE :: XKB_KEY_AudibleBell_Enable;
        POINTER_LEFT :: XKB_KEY_Pointer_Left;
        POINTER_RIGHT :: XKB_KEY_Pointer_Right;
        POINTER_UP :: XKB_KEY_Pointer_Up;
        POINTER_DOWN :: XKB_KEY_Pointer_Down;
        POINTER_UPLEFT :: XKB_KEY_Pointer_UpLeft;
        POINTER_UPRIGHT :: XKB_KEY_Pointer_UpRight;
        POINTER_DOWNLEFT :: XKB_KEY_Pointer_DownLeft;
        POINTER_DOWNRIGHT :: XKB_KEY_Pointer_DownRight;
        POINTER_BUTTON_DFLT :: XKB_KEY_Pointer_Button_Dflt;
        POINTER_BUTTON1 :: XKB_KEY_Pointer_Button1;
        POINTER_BUTTON2 :: XKB_KEY_Pointer_Button2;
        POINTER_BUTTON3 :: XKB_KEY_Pointer_Button3;
        POINTER_BUTTON4 :: XKB_KEY_Pointer_Button4;
        POINTER_BUTTON5 :: XKB_KEY_Pointer_Button5;
        POINTER_DBLCLICK_DFLT :: XKB_KEY_Pointer_DblClick_Dflt;
        POINTER_DBLCLICK1 :: XKB_KEY_Pointer_DblClick1;
        POINTER_DBLCLICK2 :: XKB_KEY_Pointer_DblClick2;
        POINTER_DBLCLICK3 :: XKB_KEY_Pointer_DblClick3;
        POINTER_DBLCLICK4 :: XKB_KEY_Pointer_DblClick4;
        POINTER_DBLCLICK5 :: XKB_KEY_Pointer_DblClick5;
        POINTER_DRAG_DFLT :: XKB_KEY_Pointer_Drag_Dflt;
        POINTER_DRAG1 :: XKB_KEY_Pointer_Drag1;
        POINTER_DRAG2 :: XKB_KEY_Pointer_Drag2;
        POINTER_DRAG3 :: XKB_KEY_Pointer_Drag3;
        POINTER_DRAG4 :: XKB_KEY_Pointer_Drag4;
        POINTER_DRAG5 :: XKB_KEY_Pointer_Drag5;
        POINTER_ENABLEKEYS :: XKB_KEY_Pointer_EnableKeys;
        POINTER_ACCELERATE :: XKB_KEY_Pointer_Accelerate;
        POINTER_DFLTBTNNEXT :: XKB_KEY_Pointer_DfltBtnNext;
        POINTER_DFLTBTNPREV :: XKB_KEY_Pointer_DfltBtnPrev;
        CH :: XKB_KEY_ch;
        TITLE_CH :: XKB_KEY_Ch;
        CAPITAL_CH :: XKB_KEY_CH;
        C_H :: XKB_KEY_c_h;
        TITLE_C_H :: XKB_KEY_C_h;
        CAPITAL_C_H :: XKB_KEY_C_H;
        KEY_3270_DUPLICATE :: XKB_KEY_3270_Duplicate;
        KEY_3270_FIELDMARK :: XKB_KEY_3270_FieldMark;
        KEY_3270_RIGHT2 :: XKB_KEY_3270_Right2;
        KEY_3270_LEFT2 :: XKB_KEY_3270_Left2;
        KEY_3270_BACKTAB :: XKB_KEY_3270_BackTab;
        KEY_3270_ERASEEOF :: XKB_KEY_3270_EraseEOF;
        KEY_3270_ERASEINPUT :: XKB_KEY_3270_EraseInput;
        KEY_3270_RESET :: XKB_KEY_3270_Reset;
        KEY_3270_QUIT :: XKB_KEY_3270_Quit;
        KEY_3270_PA1 :: XKB_KEY_3270_PA1;
        KEY_3270_PA2 :: XKB_KEY_3270_PA2;
        KEY_3270_PA3 :: XKB_KEY_3270_PA3;
        KEY_3270_TEST :: XKB_KEY_3270_Test;
        KEY_3270_ATTN :: XKB_KEY_3270_Attn;
        KEY_3270_CURSORBLINK :: XKB_KEY_3270_CursorBlink;
        KEY_3270_ALTCURSOR :: XKB_KEY_3270_AltCursor;
        KEY_3270_KEYCLICK :: XKB_KEY_3270_KeyClick;
        KEY_3270_JUMP :: XKB_KEY_3270_Jump;
        KEY_3270_IDENT :: XKB_KEY_3270_Ident;
        KEY_3270_RULE :: XKB_KEY_3270_Rule;
        KEY_3270_COPY :: XKB_KEY_3270_Copy;
        KEY_3270_PLAY :: XKB_KEY_3270_Play;
        KEY_3270_SETUP :: XKB_KEY_3270_Setup;
        KEY_3270_RECORD :: XKB_KEY_3270_Record;
        KEY_3270_CHANGESCREEN :: XKB_KEY_3270_ChangeScreen;
        KEY_3270_DELETEWORD :: XKB_KEY_3270_DeleteWord;
        KEY_3270_EXSELECT :: XKB_KEY_3270_ExSelect;
        KEY_3270_CURSORSELECT :: XKB_KEY_3270_CursorSelect;
        KEY_3270_PRINTSCREEN :: XKB_KEY_3270_PrintScreen;
        KEY_3270_ENTER :: XKB_KEY_3270_Enter;
        EXCLAM :: XKB_KEY_exclam;
        QUOTEDBL :: XKB_KEY_quotedbl;
        NUMBERSIGN :: XKB_KEY_numbersign;
        DOLLAR :: XKB_KEY_dollar;
        PERCENT :: XKB_KEY_percent;
        AMPERSAND :: XKB_KEY_ampersand;
        QUOTERIGHT :: XKB_KEY_quoteright;
        PARENLEFT :: XKB_KEY_parenleft;
        PARENRIGHT :: XKB_KEY_parenright;
        ASTERISK :: XKB_KEY_asterisk;
        PLUS :: XKB_KEY_plus;
        COLON :: XKB_KEY_colon;
        LESS :: XKB_KEY_less;
        GREATER :: XKB_KEY_greater;
        QUESTION :: XKB_KEY_question;
        AT :: XKB_KEY_at;
        CAPITAL_A :: XKB_KEY_A;
        CAPITAL_B :: XKB_KEY_B;
        CAPITAL_C :: XKB_KEY_C;
        CAPITAL_D :: XKB_KEY_D;
        CAPITAL_E :: XKB_KEY_E;
        CAPITAL_F :: XKB_KEY_F;
        CAPITAL_G :: XKB_KEY_G;
        CAPITAL_H :: XKB_KEY_H;
        CAPITAL_I :: XKB_KEY_I;
        CAPITAL_J :: XKB_KEY_J;
        CAPITAL_K :: XKB_KEY_K;
        CAPITAL_L :: XKB_KEY_L;
        CAPITAL_M :: XKB_KEY_M;
        CAPITAL_N :: XKB_KEY_N;
        CAPITAL_O :: XKB_KEY_O;
        CAPITAL_P :: XKB_KEY_P;
        CAPITAL_Q :: XKB_KEY_Q;
        CAPITAL_R :: XKB_KEY_R;
        CAPITAL_S :: XKB_KEY_S;
        CAPITAL_T :: XKB_KEY_T;
        CAPITAL_U :: XKB_KEY_U;
        CAPITAL_V :: XKB_KEY_V;
        CAPITAL_W :: XKB_KEY_W;
        CAPITAL_X :: XKB_KEY_X;
        CAPITAL_Y :: XKB_KEY_Y;
        CAPITAL_Z :: XKB_KEY_Z;
        ASCIICIRCUM :: XKB_KEY_asciicircum;
        UNDERSCORE :: XKB_KEY_underscore;
        QUOTELEFT :: XKB_KEY_quoteleft;
        BRACELEFT :: XKB_KEY_braceleft;
        BAR :: XKB_KEY_bar;
        BRACERIGHT :: XKB_KEY_braceright;
        ASCIITILDE :: XKB_KEY_asciitilde;
        NOBREAKSPACE :: XKB_KEY_nobreakspace;
        EXCLAMDOWN :: XKB_KEY_exclamdown;
        CENT :: XKB_KEY_cent;
        STERLING :: XKB_KEY_sterling;
        CURRENCY :: XKB_KEY_currency;
        YEN :: XKB_KEY_yen;
        BROKENBAR :: XKB_KEY_brokenbar;
        SECTION :: XKB_KEY_section;
        DIAERESIS :: XKB_KEY_diaeresis;
        COPYRIGHT :: XKB_KEY_copyright;
        ORDFEMININE :: XKB_KEY_ordfeminine;
        GUILLEMOTLEFT :: XKB_KEY_guillemotleft;
        GUILLEMETLEFT :: XKB_KEY_guillemetleft;
        NOTSIGN :: XKB_KEY_notsign;
        HYPHEN :: XKB_KEY_hyphen;
        REGISTERED :: XKB_KEY_registered;
        MACRON :: XKB_KEY_macron;
        DEGREE :: XKB_KEY_degree;
        PLUSMINUS :: XKB_KEY_plusminus;
        TWOSUPERIOR :: XKB_KEY_twosuperior;
        THREESUPERIOR :: XKB_KEY_threesuperior;
        ACUTE :: XKB_KEY_acute;
        MU :: XKB_KEY_mu;
        PARAGRAPH :: XKB_KEY_paragraph;
        PERIODCENTERED :: XKB_KEY_periodcentered;
        CEDILLA :: XKB_KEY_cedilla;
        ONESUPERIOR :: XKB_KEY_onesuperior;
        MASCULINE :: XKB_KEY_masculine;
        ORDMASCULINE :: XKB_KEY_ordmasculine;
        GUILLEMOTRIGHT :: XKB_KEY_guillemotright;
        GUILLEMETRIGHT :: XKB_KEY_guillemetright;
        ONEQUARTER :: XKB_KEY_onequarter;
        ONEHALF :: XKB_KEY_onehalf;
        THREEQUARTERS :: XKB_KEY_threequarters;
        QUESTIONDOWN :: XKB_KEY_questiondown;
        CAPITAL_AGRAVE :: XKB_KEY_Agrave;
        CAPITAL_AACUTE :: XKB_KEY_Aacute;
        CAPITAL_ACIRCUMFLEX :: XKB_KEY_Acircumflex;
        CAPITAL_ATILDE :: XKB_KEY_Atilde;
        CAPITAL_ADIAERESIS :: XKB_KEY_Adiaeresis;
        CAPITAL_ARING :: XKB_KEY_Aring;
        CAPITAL_AE :: XKB_KEY_AE;
        CAPITAL_CCEDILLA :: XKB_KEY_Ccedilla;
        CAPITAL_EGRAVE :: XKB_KEY_Egrave;
        CAPITAL_EACUTE :: XKB_KEY_Eacute;
        CAPITAL_ECIRCUMFLEX :: XKB_KEY_Ecircumflex;
        CAPITAL_EDIAERESIS :: XKB_KEY_Ediaeresis;
        CAPITAL_IGRAVE :: XKB_KEY_Igrave;
        CAPITAL_IACUTE :: XKB_KEY_Iacute;
        CAPITAL_ICIRCUMFLEX :: XKB_KEY_Icircumflex;
        CAPITAL_IDIAERESIS :: XKB_KEY_Idiaeresis;
        CAPITAL_ETH :: XKB_KEY_ETH;
        TITLE_ETH :: XKB_KEY_Eth;
        CAPITAL_NTILDE :: XKB_KEY_Ntilde;
        CAPITAL_OGRAVE :: XKB_KEY_Ograve;
        CAPITAL_OACUTE :: XKB_KEY_Oacute;
        CAPITAL_OCIRCUMFLEX :: XKB_KEY_Ocircumflex;
        CAPITAL_OTILDE :: XKB_KEY_Otilde;
        CAPITAL_ODIAERESIS :: XKB_KEY_Odiaeresis;
        MULTIPLY :: XKB_KEY_multiply;
        CAPITAL_OSLASH :: XKB_KEY_Oslash;
        CAPITAL_OOBLIQUE :: XKB_KEY_Ooblique;
        CAPITAL_UGRAVE :: XKB_KEY_Ugrave;
        CAPITAL_UACUTE :: XKB_KEY_Uacute;
        CAPITAL_UCIRCUMFLEX :: XKB_KEY_Ucircumflex;
        CAPITAL_UDIAERESIS :: XKB_KEY_Udiaeresis;
        CAPITAL_YACUTE :: XKB_KEY_Yacute;
        CAPITAL_THORN :: XKB_KEY_THORN;
        TITLE_THORN :: XKB_KEY_Thorn;
        SSHARP :: XKB_KEY_ssharp;
        AGRAVE :: XKB_KEY_agrave;
        AACUTE :: XKB_KEY_aacute;
        ACIRCUMFLEX :: XKB_KEY_acircumflex;
        ATILDE :: XKB_KEY_atilde;
        ADIAERESIS :: XKB_KEY_adiaeresis;
        ARING :: XKB_KEY_aring;
        AE :: XKB_KEY_ae;
        CCEDILLA :: XKB_KEY_ccedilla;
        EGRAVE :: XKB_KEY_egrave;
        EACUTE :: XKB_KEY_eacute;
        ECIRCUMFLEX :: XKB_KEY_ecircumflex;
        EDIAERESIS :: XKB_KEY_ediaeresis;
        IGRAVE :: XKB_KEY_igrave;
        IACUTE :: XKB_KEY_iacute;
        ICIRCUMFLEX :: XKB_KEY_icircumflex;
        IDIAERESIS :: XKB_KEY_idiaeresis;
        ETH :: XKB_KEY_eth;
        NTILDE :: XKB_KEY_ntilde;
        OGRAVE :: XKB_KEY_ograve;
        OACUTE :: XKB_KEY_oacute;
        OCIRCUMFLEX :: XKB_KEY_ocircumflex;
        OTILDE :: XKB_KEY_otilde;
        ODIAERESIS :: XKB_KEY_odiaeresis;
        DIVISION :: XKB_KEY_division;
        OSLASH :: XKB_KEY_oslash;
        OOBLIQUE :: XKB_KEY_ooblique;
        UGRAVE :: XKB_KEY_ugrave;
        UACUTE :: XKB_KEY_uacute;
        UCIRCUMFLEX :: XKB_KEY_ucircumflex;
        UDIAERESIS :: XKB_KEY_udiaeresis;
        YACUTE :: XKB_KEY_yacute;
        THORN :: XKB_KEY_thorn;
        YDIAERESIS :: XKB_KEY_ydiaeresis;
        CAPITAL_AOGONEK :: XKB_KEY_Aogonek;
        BREVE :: XKB_KEY_breve;
        CAPITAL_LSTROKE :: XKB_KEY_Lstroke;
        CAPITAL_LCARON :: XKB_KEY_Lcaron;
        CAPITAL_SACUTE :: XKB_KEY_Sacute;
        CAPITAL_SCARON :: XKB_KEY_Scaron;
        CAPITAL_SCEDILLA :: XKB_KEY_Scedilla;
        CAPITAL_TCARON :: XKB_KEY_Tcaron;
        CAPITAL_ZACUTE :: XKB_KEY_Zacute;
        CAPITAL_ZCARON :: XKB_KEY_Zcaron;
        CAPITAL_ZABOVEDOT :: XKB_KEY_Zabovedot;
        AOGONEK :: XKB_KEY_aogonek;
        OGONEK :: XKB_KEY_ogonek;
        LSTROKE :: XKB_KEY_lstroke;
        LCARON :: XKB_KEY_lcaron;
        SACUTE :: XKB_KEY_sacute;
        CARON :: XKB_KEY_caron;
        SCARON :: XKB_KEY_scaron;
        SCEDILLA :: XKB_KEY_scedilla;
        TCARON :: XKB_KEY_tcaron;
        ZACUTE :: XKB_KEY_zacute;
        DOUBLEACUTE :: XKB_KEY_doubleacute;
        ZCARON :: XKB_KEY_zcaron;
        ZABOVEDOT :: XKB_KEY_zabovedot;
        CAPITAL_RACUTE :: XKB_KEY_Racute;
        CAPITAL_ABREVE :: XKB_KEY_Abreve;
        CAPITAL_LACUTE :: XKB_KEY_Lacute;
        CAPITAL_CACUTE :: XKB_KEY_Cacute;
        CAPITAL_CCARON :: XKB_KEY_Ccaron;
        CAPITAL_EOGONEK :: XKB_KEY_Eogonek;
        CAPITAL_ECARON :: XKB_KEY_Ecaron;
        CAPITAL_DCARON :: XKB_KEY_Dcaron;
        CAPITAL_DSTROKE :: XKB_KEY_Dstroke;
        CAPITAL_NACUTE :: XKB_KEY_Nacute;
        CAPITAL_NCARON :: XKB_KEY_Ncaron;
        CAPITAL_ODOUBLEACUTE :: XKB_KEY_Odoubleacute;
        CAPITAL_RCARON :: XKB_KEY_Rcaron;
        CAPITAL_URING :: XKB_KEY_Uring;
        CAPITAL_UDOUBLEACUTE :: XKB_KEY_Udoubleacute;
        CAPITAL_TCEDILLA :: XKB_KEY_Tcedilla;
        RACUTE :: XKB_KEY_racute;
        ABREVE :: XKB_KEY_abreve;
        LACUTE :: XKB_KEY_lacute;
        CACUTE :: XKB_KEY_cacute;
        CCARON :: XKB_KEY_ccaron;
        EOGONEK :: XKB_KEY_eogonek;
        ECARON :: XKB_KEY_ecaron;
        DCARON :: XKB_KEY_dcaron;
        DSTROKE :: XKB_KEY_dstroke;
        NACUTE :: XKB_KEY_nacute;
        NCARON :: XKB_KEY_ncaron;
        ODOUBLEACUTE :: XKB_KEY_odoubleacute;
        RCARON :: XKB_KEY_rcaron;
        URING :: XKB_KEY_uring;
        UDOUBLEACUTE :: XKB_KEY_udoubleacute;
        TCEDILLA :: XKB_KEY_tcedilla;
        ABOVEDOT :: XKB_KEY_abovedot;
        CAPITAL_HSTROKE :: XKB_KEY_Hstroke;
        CAPITAL_HCIRCUMFLEX :: XKB_KEY_Hcircumflex;
        IABOVEDOT :: XKB_KEY_Iabovedot;
        CAPITAL_GBREVE :: XKB_KEY_Gbreve;
        CAPITAL_JCIRCUMFLEX :: XKB_KEY_Jcircumflex;
        HSTROKE :: XKB_KEY_hstroke;
        HCIRCUMFLEX :: XKB_KEY_hcircumflex;
        IDOTLESS :: XKB_KEY_idotless;
        GBREVE :: XKB_KEY_gbreve;
        JCIRCUMFLEX :: XKB_KEY_jcircumflex;
        CAPITAL_CABOVEDOT :: XKB_KEY_Cabovedot;
        CAPITAL_CCIRCUMFLEX :: XKB_KEY_Ccircumflex;
        CAPITAL_GABOVEDOT :: XKB_KEY_Gabovedot;
        CAPITAL_GCIRCUMFLEX :: XKB_KEY_Gcircumflex;
        CAPITAL_UBREVE :: XKB_KEY_Ubreve;
        CAPITAL_SCIRCUMFLEX :: XKB_KEY_Scircumflex;
        CABOVEDOT :: XKB_KEY_cabovedot;
        CCIRCUMFLEX :: XKB_KEY_ccircumflex;
        GABOVEDOT :: XKB_KEY_gabovedot;
        GCIRCUMFLEX :: XKB_KEY_gcircumflex;
        UBREVE :: XKB_KEY_ubreve;
        SCIRCUMFLEX :: XKB_KEY_scircumflex;
        KRA :: XKB_KEY_kra;
        KAPPA :: XKB_KEY_kappa;
        CAPITAL_RCEDILLA :: XKB_KEY_Rcedilla;
        CAPITAL_ITILDE :: XKB_KEY_Itilde;
        CAPITAL_LCEDILLA :: XKB_KEY_Lcedilla;
        CAPITAL_EMACRON :: XKB_KEY_Emacron;
        CAPITAL_GCEDILLA :: XKB_KEY_Gcedilla;
        CAPITAL_TSLASH :: XKB_KEY_Tslash;
        RCEDILLA :: XKB_KEY_rcedilla;
        ITILDE :: XKB_KEY_itilde;
        LCEDILLA :: XKB_KEY_lcedilla;
        EMACRON :: XKB_KEY_emacron;
        GCEDILLA :: XKB_KEY_gcedilla;
        TSLASH :: XKB_KEY_tslash;
        CAPITAL_ENG :: XKB_KEY_ENG;
        ENG :: XKB_KEY_eng;
        CAPITAL_AMACRON :: XKB_KEY_Amacron;
        CAPITAL_IOGONEK :: XKB_KEY_Iogonek;
        CAPITAL_EABOVEDOT :: XKB_KEY_Eabovedot;
        CAPITAL_IMACRON :: XKB_KEY_Imacron;
        CAPITAL_NCEDILLA :: XKB_KEY_Ncedilla;
        CAPITAL_OMACRON :: XKB_KEY_Omacron;
        CAPITAL_KCEDILLA :: XKB_KEY_Kcedilla;
        CAPITAL_UOGONEK :: XKB_KEY_Uogonek;
        CAPITAL_UTILDE :: XKB_KEY_Utilde;
        CAPITAL_UMACRON :: XKB_KEY_Umacron;
        AMACRON :: XKB_KEY_amacron;
        IOGONEK :: XKB_KEY_iogonek;
        EABOVEDOT :: XKB_KEY_eabovedot;
        IMACRON :: XKB_KEY_imacron;
        NCEDILLA :: XKB_KEY_ncedilla;
        OMACRON :: XKB_KEY_omacron;
        KCEDILLA :: XKB_KEY_kcedilla;
        UOGONEK :: XKB_KEY_uogonek;
        UTILDE :: XKB_KEY_utilde;
        UMACRON :: XKB_KEY_umacron;
        CAPITAL_WCIRCUMFLEX :: XKB_KEY_Wcircumflex;
        WCIRCUMFLEX :: XKB_KEY_wcircumflex;
        CAPITAL_YCIRCUMFLEX :: XKB_KEY_Ycircumflex;
        YCIRCUMFLEX :: XKB_KEY_ycircumflex;
        CAPITAL_BABOVEDOT :: XKB_KEY_Babovedot;
        BABOVEDOT :: XKB_KEY_babovedot;
        CAPITAL_DABOVEDOT :: XKB_KEY_Dabovedot;
        DABOVEDOT :: XKB_KEY_dabovedot;
        CAPITAL_FABOVEDOT :: XKB_KEY_Fabovedot;
        FABOVEDOT :: XKB_KEY_fabovedot;
        CAPITAL_MABOVEDOT :: XKB_KEY_Mabovedot;
        MABOVEDOT :: XKB_KEY_mabovedot;
        CAPITAL_PABOVEDOT :: XKB_KEY_Pabovedot;
        PABOVEDOT :: XKB_KEY_pabovedot;
        CAPITAL_SABOVEDOT :: XKB_KEY_Sabovedot;
        SABOVEDOT :: XKB_KEY_sabovedot;
        CAPITAL_TABOVEDOT :: XKB_KEY_Tabovedot;
        TABOVEDOT :: XKB_KEY_tabovedot;
        CAPITAL_WGRAVE :: XKB_KEY_Wgrave;
        WGRAVE :: XKB_KEY_wgrave;
        CAPITAL_WACUTE :: XKB_KEY_Wacute;
        WACUTE :: XKB_KEY_wacute;
        CAPITAL_WDIAERESIS :: XKB_KEY_Wdiaeresis;
        WDIAERESIS :: XKB_KEY_wdiaeresis;
        CAPITAL_YGRAVE :: XKB_KEY_Ygrave;
        YGRAVE :: XKB_KEY_ygrave;
        CAPITAL_OE :: XKB_KEY_OE;
        OE :: XKB_KEY_oe;
        CAPITAL_YDIAERESIS :: XKB_KEY_Ydiaeresis;
        OVERLINE :: XKB_KEY_overline;
        KANA_FULLSTOP :: XKB_KEY_kana_fullstop;
        KANA_OPENINGBRACKET :: XKB_KEY_kana_openingbracket;
        KANA_CLOSINGBRACKET :: XKB_KEY_kana_closingbracket;
        KANA_COMMA :: XKB_KEY_kana_comma;
        KANA_CONJUNCTIVE :: XKB_KEY_kana_conjunctive;
        KANA_MIDDLEDOT :: XKB_KEY_kana_middledot;
        KANA_WO :: XKB_KEY_kana_WO;
        KANA_A :: XKB_KEY_kana_a;
        KANA_I :: XKB_KEY_kana_i;
        KANA_U :: XKB_KEY_kana_u;
        KANA_E :: XKB_KEY_kana_e;
        KANA_O :: XKB_KEY_kana_o;
        KANA_YA :: XKB_KEY_kana_ya;
        KANA_YU :: XKB_KEY_kana_yu;
        KANA_YO :: XKB_KEY_kana_yo;
        KANA_TSU :: XKB_KEY_kana_tsu;
        KANA_TU :: XKB_KEY_kana_tu;
        PROLONGEDSOUND :: XKB_KEY_prolongedsound;
        CAPITAL_KANA_A :: XKB_KEY_kana_A;
        CAPITAL_KANA_I :: XKB_KEY_kana_I;
        CAPITAL_KANA_U :: XKB_KEY_kana_U;
        CAPITAL_KANA_E :: XKB_KEY_kana_E;
        CAPITAL_KANA_O :: XKB_KEY_kana_O;
        KANA_KA :: XKB_KEY_kana_KA;
        KANA_KI :: XKB_KEY_kana_KI;
        KANA_KU :: XKB_KEY_kana_KU;
        KANA_KE :: XKB_KEY_kana_KE;
        KANA_KO :: XKB_KEY_kana_KO;
        KANA_SA :: XKB_KEY_kana_SA;
        KANA_SHI :: XKB_KEY_kana_SHI;
        KANA_SU :: XKB_KEY_kana_SU;
        KANA_SE :: XKB_KEY_kana_SE;
        KANA_SO :: XKB_KEY_kana_SO;
        KANA_TA :: XKB_KEY_kana_TA;
        KANA_CHI :: XKB_KEY_kana_CHI;
        KANA_TI :: XKB_KEY_kana_TI;
        CAPITAL_KANA_TSU :: XKB_KEY_kana_TSU;
        CAPITAL_KANA_TU :: XKB_KEY_kana_TU;
        KANA_TE :: XKB_KEY_kana_TE;
        KANA_TO :: XKB_KEY_kana_TO;
        KANA_NA :: XKB_KEY_kana_NA;
        KANA_NI :: XKB_KEY_kana_NI;
        KANA_NU :: XKB_KEY_kana_NU;
        KANA_NE :: XKB_KEY_kana_NE;
        KANA_NO :: XKB_KEY_kana_NO;
        KANA_HA :: XKB_KEY_kana_HA;
        KANA_HI :: XKB_KEY_kana_HI;
        KANA_FU :: XKB_KEY_kana_FU;
        KANA_HU :: XKB_KEY_kana_HU;
        KANA_HE :: XKB_KEY_kana_HE;
        KANA_HO :: XKB_KEY_kana_HO;
        KANA_MA :: XKB_KEY_kana_MA;
        KANA_MI :: XKB_KEY_kana_MI;
        KANA_MU :: XKB_KEY_kana_MU;
        KANA_ME :: XKB_KEY_kana_ME;
        KANA_MO :: XKB_KEY_kana_MO;
        CAPITAL_KANA_YA :: XKB_KEY_kana_YA;
        CAPITAL_KANA_YU :: XKB_KEY_kana_YU;
        CAPITAL_KANA_YO :: XKB_KEY_kana_YO;
        KANA_RA :: XKB_KEY_kana_RA;
        KANA_RI :: XKB_KEY_kana_RI;
        KANA_RU :: XKB_KEY_kana_RU;
        KANA_RE :: XKB_KEY_kana_RE;
        KANA_RO :: XKB_KEY_kana_RO;
        KANA_WA :: XKB_KEY_kana_WA;
        KANA_N :: XKB_KEY_kana_N;
        VOICEDSOUND :: XKB_KEY_voicedsound;
        SEMIVOICEDSOUND :: XKB_KEY_semivoicedsound;
        KANA_SWITCH :: XKB_KEY_kana_switch;
        FARSI_0 :: XKB_KEY_Farsi_0;
        FARSI_1 :: XKB_KEY_Farsi_1;
        FARSI_2 :: XKB_KEY_Farsi_2;
        FARSI_3 :: XKB_KEY_Farsi_3;
        FARSI_4 :: XKB_KEY_Farsi_4;
        FARSI_5 :: XKB_KEY_Farsi_5;
        FARSI_6 :: XKB_KEY_Farsi_6;
        FARSI_7 :: XKB_KEY_Farsi_7;
        FARSI_8 :: XKB_KEY_Farsi_8;
        FARSI_9 :: XKB_KEY_Farsi_9;
        ARABIC_PERCENT :: XKB_KEY_Arabic_percent;
        ARABIC_SUPERSCRIPT_ALEF :: XKB_KEY_Arabic_superscript_alef;
        ARABIC_TTEH :: XKB_KEY_Arabic_tteh;
        ARABIC_PEH :: XKB_KEY_Arabic_peh;
        ARABIC_TCHEH :: XKB_KEY_Arabic_tcheh;
        ARABIC_DDAL :: XKB_KEY_Arabic_ddal;
        ARABIC_RREH :: XKB_KEY_Arabic_rreh;
        ARABIC_COMMA :: XKB_KEY_Arabic_comma;
        ARABIC_FULLSTOP :: XKB_KEY_Arabic_fullstop;
        ARABIC_0 :: XKB_KEY_Arabic_0;
        ARABIC_1 :: XKB_KEY_Arabic_1;
        ARABIC_2 :: XKB_KEY_Arabic_2;
        ARABIC_3 :: XKB_KEY_Arabic_3;
        ARABIC_4 :: XKB_KEY_Arabic_4;
        ARABIC_5 :: XKB_KEY_Arabic_5;
        ARABIC_6 :: XKB_KEY_Arabic_6;
        ARABIC_7 :: XKB_KEY_Arabic_7;
        ARABIC_8 :: XKB_KEY_Arabic_8;
        ARABIC_9 :: XKB_KEY_Arabic_9;
        ARABIC_SEMICOLON :: XKB_KEY_Arabic_semicolon;
        ARABIC_QUESTION_MARK :: XKB_KEY_Arabic_question_mark;
        ARABIC_HAMZA :: XKB_KEY_Arabic_hamza;
        ARABIC_MADDAONALEF :: XKB_KEY_Arabic_maddaonalef;
        ARABIC_HAMZAONALEF :: XKB_KEY_Arabic_hamzaonalef;
        ARABIC_HAMZAONWAW :: XKB_KEY_Arabic_hamzaonwaw;
        ARABIC_HAMZAUNDERALEF :: XKB_KEY_Arabic_hamzaunderalef;
        ARABIC_HAMZAONYEH :: XKB_KEY_Arabic_hamzaonyeh;
        ARABIC_ALEF :: XKB_KEY_Arabic_alef;
        ARABIC_BEH :: XKB_KEY_Arabic_beh;
        ARABIC_TEHMARBUTA :: XKB_KEY_Arabic_tehmarbuta;
        ARABIC_TEH :: XKB_KEY_Arabic_teh;
        ARABIC_THEH :: XKB_KEY_Arabic_theh;
        ARABIC_JEEM :: XKB_KEY_Arabic_jeem;
        ARABIC_HAH :: XKB_KEY_Arabic_hah;
        ARABIC_KHAH :: XKB_KEY_Arabic_khah;
        ARABIC_DAL :: XKB_KEY_Arabic_dal;
        ARABIC_THAL :: XKB_KEY_Arabic_thal;
        ARABIC_RA :: XKB_KEY_Arabic_ra;
        ARABIC_ZAIN :: XKB_KEY_Arabic_zain;
        ARABIC_SEEN :: XKB_KEY_Arabic_seen;
        ARABIC_SHEEN :: XKB_KEY_Arabic_sheen;
        ARABIC_SAD :: XKB_KEY_Arabic_sad;
        ARABIC_DAD :: XKB_KEY_Arabic_dad;
        ARABIC_TAH :: XKB_KEY_Arabic_tah;
        ARABIC_ZAH :: XKB_KEY_Arabic_zah;
        ARABIC_AIN :: XKB_KEY_Arabic_ain;
        ARABIC_GHAIN :: XKB_KEY_Arabic_ghain;
        ARABIC_TATWEEL :: XKB_KEY_Arabic_tatweel;
        ARABIC_FEH :: XKB_KEY_Arabic_feh;
        ARABIC_QAF :: XKB_KEY_Arabic_qaf;
        ARABIC_KAF :: XKB_KEY_Arabic_kaf;
        ARABIC_LAM :: XKB_KEY_Arabic_lam;
        ARABIC_MEEM :: XKB_KEY_Arabic_meem;
        ARABIC_NOON :: XKB_KEY_Arabic_noon;
        ARABIC_HA :: XKB_KEY_Arabic_ha;
        ARABIC_HEH :: XKB_KEY_Arabic_heh;
        ARABIC_WAW :: XKB_KEY_Arabic_waw;
        ARABIC_ALEFMAKSURA :: XKB_KEY_Arabic_alefmaksura;
        ARABIC_YEH :: XKB_KEY_Arabic_yeh;
        ARABIC_FATHATAN :: XKB_KEY_Arabic_fathatan;
        ARABIC_DAMMATAN :: XKB_KEY_Arabic_dammatan;
        ARABIC_KASRATAN :: XKB_KEY_Arabic_kasratan;
        ARABIC_FATHA :: XKB_KEY_Arabic_fatha;
        ARABIC_DAMMA :: XKB_KEY_Arabic_damma;
        ARABIC_KASRA :: XKB_KEY_Arabic_kasra;
        ARABIC_SHADDA :: XKB_KEY_Arabic_shadda;
        ARABIC_SUKUN :: XKB_KEY_Arabic_sukun;
        ARABIC_MADDA_ABOVE :: XKB_KEY_Arabic_madda_above;
        ARABIC_HAMZA_ABOVE :: XKB_KEY_Arabic_hamza_above;
        ARABIC_HAMZA_BELOW :: XKB_KEY_Arabic_hamza_below;
        ARABIC_JEH :: XKB_KEY_Arabic_jeh;
        ARABIC_VEH :: XKB_KEY_Arabic_veh;
        ARABIC_KEHEH :: XKB_KEY_Arabic_keheh;
        ARABIC_GAF :: XKB_KEY_Arabic_gaf;
        ARABIC_NOON_GHUNNA :: XKB_KEY_Arabic_noon_ghunna;
        ARABIC_HEH_DOACHASHMEE :: XKB_KEY_Arabic_heh_doachashmee;
        FARSI_YEH :: XKB_KEY_Farsi_yeh;
        ARABIC_FARSI_YEH :: XKB_KEY_Arabic_farsi_yeh;
        ARABIC_YEH_BAREE :: XKB_KEY_Arabic_yeh_baree;
        ARABIC_HEH_GOAL :: XKB_KEY_Arabic_heh_goal;
        ARABIC_SWITCH :: XKB_KEY_Arabic_switch;
        CAPITAL_CYRILLIC_GHE_BAR :: XKB_KEY_Cyrillic_GHE_bar;
        CYRILLIC_GHE_BAR :: XKB_KEY_Cyrillic_ghe_bar;
        CAPITAL_CYRILLIC_ZHE_DESCENDER :: XKB_KEY_Cyrillic_ZHE_descender;
        CYRILLIC_ZHE_DESCENDER :: XKB_KEY_Cyrillic_zhe_descender;
        CAPITAL_CYRILLIC_KA_DESCENDER :: XKB_KEY_Cyrillic_KA_descender;
        CYRILLIC_KA_DESCENDER :: XKB_KEY_Cyrillic_ka_descender;
        CAPITAL_CYRILLIC_KA_VERTSTROKE :: XKB_KEY_Cyrillic_KA_vertstroke;
        CYRILLIC_KA_VERTSTROKE :: XKB_KEY_Cyrillic_ka_vertstroke;
        CAPITAL_CYRILLIC_EN_DESCENDER :: XKB_KEY_Cyrillic_EN_descender;
        CYRILLIC_EN_DESCENDER :: XKB_KEY_Cyrillic_en_descender;
        CAPITAL_CYRILLIC_U_STRAIGHT :: XKB_KEY_Cyrillic_U_straight;
        CYRILLIC_U_STRAIGHT :: XKB_KEY_Cyrillic_u_straight;
        CAPITAL_CYRILLIC_U_STRAIGHT_BAR :: XKB_KEY_Cyrillic_U_straight_bar;
        CYRILLIC_U_STRAIGHT_BAR :: XKB_KEY_Cyrillic_u_straight_bar;
        CAPITAL_CYRILLIC_HA_DESCENDER :: XKB_KEY_Cyrillic_HA_descender;
        CYRILLIC_HA_DESCENDER :: XKB_KEY_Cyrillic_ha_descender;
        CAPITAL_CYRILLIC_CHE_DESCENDER :: XKB_KEY_Cyrillic_CHE_descender;
        CYRILLIC_CHE_DESCENDER :: XKB_KEY_Cyrillic_che_descender;
        CAPITAL_CYRILLIC_CHE_VERTSTROKE :: XKB_KEY_Cyrillic_CHE_vertstroke;
        CYRILLIC_CHE_VERTSTROKE :: XKB_KEY_Cyrillic_che_vertstroke;
        CAPITAL_CYRILLIC_SHHA :: XKB_KEY_Cyrillic_SHHA;
        CYRILLIC_SHHA :: XKB_KEY_Cyrillic_shha;
        CAPITAL_CYRILLIC_SCHWA :: XKB_KEY_Cyrillic_SCHWA;
        CYRILLIC_SCHWA :: XKB_KEY_Cyrillic_schwa;
        CAPITAL_CYRILLIC_I_MACRON :: XKB_KEY_Cyrillic_I_macron;
        CYRILLIC_I_MACRON :: XKB_KEY_Cyrillic_i_macron;
        CAPITAL_CYRILLIC_O_BAR :: XKB_KEY_Cyrillic_O_bar;
        CYRILLIC_O_BAR :: XKB_KEY_Cyrillic_o_bar;
        CAPITAL_CYRILLIC_U_MACRON :: XKB_KEY_Cyrillic_U_macron;
        CYRILLIC_U_MACRON :: XKB_KEY_Cyrillic_u_macron;
        SERBIAN_DJE :: XKB_KEY_Serbian_dje;
        MACEDONIA_GJE :: XKB_KEY_Macedonia_gje;
        CYRILLIC_IO :: XKB_KEY_Cyrillic_io;
        UKRAINIAN_IE :: XKB_KEY_Ukrainian_ie;
        UKRANIAN_JE :: XKB_KEY_Ukranian_je;
        MACEDONIA_DSE :: XKB_KEY_Macedonia_dse;
        UKRAINIAN_I :: XKB_KEY_Ukrainian_i;
        UKRANIAN_I :: XKB_KEY_Ukranian_i;
        UKRAINIAN_YI :: XKB_KEY_Ukrainian_yi;
        UKRANIAN_YI :: XKB_KEY_Ukranian_yi;
        CYRILLIC_JE :: XKB_KEY_Cyrillic_je;
        SERBIAN_JE :: XKB_KEY_Serbian_je;
        CYRILLIC_LJE :: XKB_KEY_Cyrillic_lje;
        SERBIAN_LJE :: XKB_KEY_Serbian_lje;
        CYRILLIC_NJE :: XKB_KEY_Cyrillic_nje;
        SERBIAN_NJE :: XKB_KEY_Serbian_nje;
        SERBIAN_TSHE :: XKB_KEY_Serbian_tshe;
        MACEDONIA_KJE :: XKB_KEY_Macedonia_kje;
        UKRAINIAN_GHE_WITH_UPTURN :: XKB_KEY_Ukrainian_ghe_with_upturn;
        BYELORUSSIAN_SHORTU :: XKB_KEY_Byelorussian_shortu;
        CYRILLIC_DZHE :: XKB_KEY_Cyrillic_dzhe;
        SERBIAN_DZE :: XKB_KEY_Serbian_dze;
        NUMEROSIGN :: XKB_KEY_numerosign;
        CAPITAL_SERBIAN_DJE :: XKB_KEY_Serbian_DJE;
        CAPITAL_MACEDONIA_GJE :: XKB_KEY_Macedonia_GJE;
        CAPITAL_CYRILLIC_IO :: XKB_KEY_Cyrillic_IO;
        CAPITAL_UKRAINIAN_IE :: XKB_KEY_Ukrainian_IE;
        CAPITAL_UKRANIAN_JE :: XKB_KEY_Ukranian_JE;
        CAPITAL_MACEDONIA_DSE :: XKB_KEY_Macedonia_DSE;
        CAPITAL_UKRAINIAN_I :: XKB_KEY_Ukrainian_I;
        CAPITAL_UKRANIAN_I :: XKB_KEY_Ukranian_I;
        CAPITAL_UKRAINIAN_YI :: XKB_KEY_Ukrainian_YI;
        CAPITAL_UKRANIAN_YI :: XKB_KEY_Ukranian_YI;
        CAPITAL_CYRILLIC_JE :: XKB_KEY_Cyrillic_JE;
        CAPITAL_SERBIAN_JE :: XKB_KEY_Serbian_JE;
        CAPITAL_CYRILLIC_LJE :: XKB_KEY_Cyrillic_LJE;
        CAPITAL_SERBIAN_LJE :: XKB_KEY_Serbian_LJE;
        CAPITAL_CYRILLIC_NJE :: XKB_KEY_Cyrillic_NJE;
        CAPITAL_SERBIAN_NJE :: XKB_KEY_Serbian_NJE;
        CAPITAL_SERBIAN_TSHE :: XKB_KEY_Serbian_TSHE;
        CAPITAL_MACEDONIA_KJE :: XKB_KEY_Macedonia_KJE;
        CAPITAL_UKRAINIAN_GHE_WITH_UPTURN :: XKB_KEY_Ukrainian_GHE_WITH_UPTURN;
        CAPITAL_BYELORUSSIAN_SHORTU :: XKB_KEY_Byelorussian_SHORTU;
        CAPITAL_CYRILLIC_DZHE :: XKB_KEY_Cyrillic_DZHE;
        CAPITAL_SERBIAN_DZE :: XKB_KEY_Serbian_DZE;
        CYRILLIC_YU :: XKB_KEY_Cyrillic_yu;
        CYRILLIC_A :: XKB_KEY_Cyrillic_a;
        CYRILLIC_BE :: XKB_KEY_Cyrillic_be;
        CYRILLIC_TSE :: XKB_KEY_Cyrillic_tse;
        CYRILLIC_DE :: XKB_KEY_Cyrillic_de;
        CYRILLIC_IE :: XKB_KEY_Cyrillic_ie;
        CYRILLIC_EF :: XKB_KEY_Cyrillic_ef;
        CYRILLIC_GHE :: XKB_KEY_Cyrillic_ghe;
        CYRILLIC_HA :: XKB_KEY_Cyrillic_ha;
        CYRILLIC_I :: XKB_KEY_Cyrillic_i;
        CYRILLIC_SHORTI :: XKB_KEY_Cyrillic_shorti;
        CYRILLIC_KA :: XKB_KEY_Cyrillic_ka;
        CYRILLIC_EL :: XKB_KEY_Cyrillic_el;
        CYRILLIC_EM :: XKB_KEY_Cyrillic_em;
        CYRILLIC_EN :: XKB_KEY_Cyrillic_en;
        CYRILLIC_O :: XKB_KEY_Cyrillic_o;
        CYRILLIC_PE :: XKB_KEY_Cyrillic_pe;
        CYRILLIC_YA :: XKB_KEY_Cyrillic_ya;
        CYRILLIC_ER :: XKB_KEY_Cyrillic_er;
        CYRILLIC_ES :: XKB_KEY_Cyrillic_es;
        CYRILLIC_TE :: XKB_KEY_Cyrillic_te;
        CYRILLIC_U :: XKB_KEY_Cyrillic_u;
        CYRILLIC_ZHE :: XKB_KEY_Cyrillic_zhe;
        CYRILLIC_VE :: XKB_KEY_Cyrillic_ve;
        CYRILLIC_SOFTSIGN :: XKB_KEY_Cyrillic_softsign;
        CYRILLIC_YERU :: XKB_KEY_Cyrillic_yeru;
        CYRILLIC_ZE :: XKB_KEY_Cyrillic_ze;
        CYRILLIC_SHA :: XKB_KEY_Cyrillic_sha;
        CYRILLIC_E :: XKB_KEY_Cyrillic_e;
        CYRILLIC_SHCHA :: XKB_KEY_Cyrillic_shcha;
        CYRILLIC_CHE :: XKB_KEY_Cyrillic_che;
        CYRILLIC_HARDSIGN :: XKB_KEY_Cyrillic_hardsign;
        CAPITAL_CYRILLIC_YU :: XKB_KEY_Cyrillic_YU;
        CAPITAL_CYRILLIC_A :: XKB_KEY_Cyrillic_A;
        CAPITAL_CYRILLIC_BE :: XKB_KEY_Cyrillic_BE;
        CAPITAL_CYRILLIC_TSE :: XKB_KEY_Cyrillic_TSE;
        CAPITAL_CYRILLIC_DE :: XKB_KEY_Cyrillic_DE;
        CAPITAL_CYRILLIC_IE :: XKB_KEY_Cyrillic_IE;
        CAPITAL_CYRILLIC_EF :: XKB_KEY_Cyrillic_EF;
        CAPITAL_CYRILLIC_GHE :: XKB_KEY_Cyrillic_GHE;
        CAPITAL_CYRILLIC_HA :: XKB_KEY_Cyrillic_HA;
        CAPITAL_CYRILLIC_I :: XKB_KEY_Cyrillic_I;
        CAPITAL_CYRILLIC_SHORTI :: XKB_KEY_Cyrillic_SHORTI;
        CAPITAL_CYRILLIC_KA :: XKB_KEY_Cyrillic_KA;
        CAPITAL_CYRILLIC_EL :: XKB_KEY_Cyrillic_EL;
        CAPITAL_CYRILLIC_EM :: XKB_KEY_Cyrillic_EM;
        CAPITAL_CYRILLIC_EN :: XKB_KEY_Cyrillic_EN;
        CAPITAL_CYRILLIC_O :: XKB_KEY_Cyrillic_O;
        CAPITAL_CYRILLIC_PE :: XKB_KEY_Cyrillic_PE;
        CAPITAL_CYRILLIC_YA :: XKB_KEY_Cyrillic_YA;
        CAPITAL_CYRILLIC_ER :: XKB_KEY_Cyrillic_ER;
        CAPITAL_CYRILLIC_ES :: XKB_KEY_Cyrillic_ES;
        CAPITAL_CYRILLIC_TE :: XKB_KEY_Cyrillic_TE;
        CAPITAL_CYRILLIC_U :: XKB_KEY_Cyrillic_U;
        CAPITAL_CYRILLIC_ZHE :: XKB_KEY_Cyrillic_ZHE;
        CAPITAL_CYRILLIC_VE :: XKB_KEY_Cyrillic_VE;
        CAPITAL_CYRILLIC_SOFTSIGN :: XKB_KEY_Cyrillic_SOFTSIGN;
        CAPITAL_CYRILLIC_YERU :: XKB_KEY_Cyrillic_YERU;
        CAPITAL_CYRILLIC_ZE :: XKB_KEY_Cyrillic_ZE;
        CAPITAL_CYRILLIC_SHA :: XKB_KEY_Cyrillic_SHA;
        CAPITAL_CYRILLIC_E :: XKB_KEY_Cyrillic_E;
        CAPITAL_CYRILLIC_SHCHA :: XKB_KEY_Cyrillic_SHCHA;
        CAPITAL_CYRILLIC_CHE :: XKB_KEY_Cyrillic_CHE;
        CAPITAL_CYRILLIC_HARDSIGN :: XKB_KEY_Cyrillic_HARDSIGN;
        CAPITAL_GREEK_ALPHAACCENT :: XKB_KEY_Greek_ALPHAaccent;
        CAPITAL_GREEK_EPSILONACCENT :: XKB_KEY_Greek_EPSILONaccent;
        CAPITAL_GREEK_ETAACCENT :: XKB_KEY_Greek_ETAaccent;
        CAPITAL_GREEK_IOTAACCENT :: XKB_KEY_Greek_IOTAaccent;
        CAPITAL_GREEK_IOTADIERESIS :: XKB_KEY_Greek_IOTAdieresis;
        GREEK_IOTADIAERESIS :: XKB_KEY_Greek_IOTAdiaeresis;
        CAPITAL_GREEK_OMICRONACCENT :: XKB_KEY_Greek_OMICRONaccent;
        CAPITAL_GREEK_UPSILONACCENT :: XKB_KEY_Greek_UPSILONaccent;
        CAPITAL_GREEK_UPSILONDIERESIS :: XKB_KEY_Greek_UPSILONdieresis;
        CAPITAL_GREEK_OMEGAACCENT :: XKB_KEY_Greek_OMEGAaccent;
        GREEK_ACCENTDIERESIS :: XKB_KEY_Greek_accentdieresis;
        GREEK_HORIZBAR :: XKB_KEY_Greek_horizbar;
        GREEK_ALPHAACCENT :: XKB_KEY_Greek_alphaaccent;
        GREEK_EPSILONACCENT :: XKB_KEY_Greek_epsilonaccent;
        GREEK_ETAACCENT :: XKB_KEY_Greek_etaaccent;
        GREEK_IOTAACCENT :: XKB_KEY_Greek_iotaaccent;
        GREEK_IOTADIERESIS :: XKB_KEY_Greek_iotadieresis;
        GREEK_IOTAACCENTDIERESIS :: XKB_KEY_Greek_iotaaccentdieresis;
        GREEK_OMICRONACCENT :: XKB_KEY_Greek_omicronaccent;
        GREEK_UPSILONACCENT :: XKB_KEY_Greek_upsilonaccent;
        GREEK_UPSILONDIERESIS :: XKB_KEY_Greek_upsilondieresis;
        GREEK_UPSILONACCENTDIERESIS :: XKB_KEY_Greek_upsilonaccentdieresis;
        GREEK_OMEGAACCENT :: XKB_KEY_Greek_omegaaccent;
        CAPITAL_GREEK_ALPHA :: XKB_KEY_Greek_ALPHA;
        CAPITAL_GREEK_BETA :: XKB_KEY_Greek_BETA;
        CAPITAL_GREEK_GAMMA :: XKB_KEY_Greek_GAMMA;
        CAPITAL_GREEK_DELTA :: XKB_KEY_Greek_DELTA;
        CAPITAL_GREEK_EPSILON :: XKB_KEY_Greek_EPSILON;
        CAPITAL_GREEK_ZETA :: XKB_KEY_Greek_ZETA;
        CAPITAL_GREEK_ETA :: XKB_KEY_Greek_ETA;
        CAPITAL_GREEK_THETA :: XKB_KEY_Greek_THETA;
        CAPITAL_GREEK_IOTA :: XKB_KEY_Greek_IOTA;
        CAPITAL_GREEK_KAPPA :: XKB_KEY_Greek_KAPPA;
        CAPITAL_GREEK_LAMDA :: XKB_KEY_Greek_LAMDA;
        CAPITAL_GREEK_LAMBDA :: XKB_KEY_Greek_LAMBDA;
        CAPITAL_GREEK_MU :: XKB_KEY_Greek_MU;
        CAPITAL_GREEK_NU :: XKB_KEY_Greek_NU;
        CAPITAL_GREEK_XI :: XKB_KEY_Greek_XI;
        CAPITAL_GREEK_OMICRON :: XKB_KEY_Greek_OMICRON;
        CAPITAL_GREEK_PI :: XKB_KEY_Greek_PI;
        CAPITAL_GREEK_RHO :: XKB_KEY_Greek_RHO;
        CAPITAL_GREEK_SIGMA :: XKB_KEY_Greek_SIGMA;
        CAPITAL_GREEK_TAU :: XKB_KEY_Greek_TAU;
        CAPITAL_GREEK_UPSILON :: XKB_KEY_Greek_UPSILON;
        CAPITAL_GREEK_PHI :: XKB_KEY_Greek_PHI;
        CAPITAL_GREEK_CHI :: XKB_KEY_Greek_CHI;
        CAPITAL_GREEK_PSI :: XKB_KEY_Greek_PSI;
        CAPITAL_GREEK_OMEGA :: XKB_KEY_Greek_OMEGA;
        GREEK_ALPHA :: XKB_KEY_Greek_alpha;
        GREEK_BETA :: XKB_KEY_Greek_beta;
        GREEK_GAMMA :: XKB_KEY_Greek_gamma;
        GREEK_DELTA :: XKB_KEY_Greek_delta;
        GREEK_EPSILON :: XKB_KEY_Greek_epsilon;
        GREEK_ZETA :: XKB_KEY_Greek_zeta;
        GREEK_ETA :: XKB_KEY_Greek_eta;
        GREEK_THETA :: XKB_KEY_Greek_theta;
        GREEK_IOTA :: XKB_KEY_Greek_iota;
        GREEK_KAPPA :: XKB_KEY_Greek_kappa;
        GREEK_LAMDA :: XKB_KEY_Greek_lamda;
        GREEK_LAMBDA :: XKB_KEY_Greek_lambda;
        GREEK_MU :: XKB_KEY_Greek_mu;
        GREEK_NU :: XKB_KEY_Greek_nu;
        GREEK_XI :: XKB_KEY_Greek_xi;
        GREEK_OMICRON :: XKB_KEY_Greek_omicron;
        GREEK_PI :: XKB_KEY_Greek_pi;
        GREEK_RHO :: XKB_KEY_Greek_rho;
        GREEK_SIGMA :: XKB_KEY_Greek_sigma;
        GREEK_FINALSMALLSIGMA :: XKB_KEY_Greek_finalsmallsigma;
        GREEK_TAU :: XKB_KEY_Greek_tau;
        GREEK_UPSILON :: XKB_KEY_Greek_upsilon;
        GREEK_PHI :: XKB_KEY_Greek_phi;
        GREEK_CHI :: XKB_KEY_Greek_chi;
        GREEK_PSI :: XKB_KEY_Greek_psi;
        GREEK_OMEGA :: XKB_KEY_Greek_omega;
        GREEK_SWITCH :: XKB_KEY_Greek_switch;
        LEFTRADICAL :: XKB_KEY_leftradical;
        TOPLEFTRADICAL :: XKB_KEY_topleftradical;
        HORIZCONNECTOR :: XKB_KEY_horizconnector;
        TOPINTEGRAL :: XKB_KEY_topintegral;
        BOTINTEGRAL :: XKB_KEY_botintegral;
        VERTCONNECTOR :: XKB_KEY_vertconnector;
        TOPLEFTSQBRACKET :: XKB_KEY_topleftsqbracket;
        BOTLEFTSQBRACKET :: XKB_KEY_botleftsqbracket;
        TOPRIGHTSQBRACKET :: XKB_KEY_toprightsqbracket;
        BOTRIGHTSQBRACKET :: XKB_KEY_botrightsqbracket;
        TOPLEFTPARENS :: XKB_KEY_topleftparens;
        BOTLEFTPARENS :: XKB_KEY_botleftparens;
        TOPRIGHTPARENS :: XKB_KEY_toprightparens;
        BOTRIGHTPARENS :: XKB_KEY_botrightparens;
        LEFTMIDDLECURLYBRACE :: XKB_KEY_leftmiddlecurlybrace;
        RIGHTMIDDLECURLYBRACE :: XKB_KEY_rightmiddlecurlybrace;
        TOPLEFTSUMMATION :: XKB_KEY_topleftsummation;
        BOTLEFTSUMMATION :: XKB_KEY_botleftsummation;
        TOPVERTSUMMATIONCONNECTOR :: XKB_KEY_topvertsummationconnector;
        BOTVERTSUMMATIONCONNECTOR :: XKB_KEY_botvertsummationconnector;
        TOPRIGHTSUMMATION :: XKB_KEY_toprightsummation;
        BOTRIGHTSUMMATION :: XKB_KEY_botrightsummation;
        RIGHTMIDDLESUMMATION :: XKB_KEY_rightmiddlesummation;
        LESSTHANEQUAL :: XKB_KEY_lessthanequal;
        NOTEQUAL :: XKB_KEY_notequal;
        GREATERTHANEQUAL :: XKB_KEY_greaterthanequal;
        INTEGRAL :: XKB_KEY_integral;
        THEREFORE :: XKB_KEY_therefore;
        VARIATION :: XKB_KEY_variation;
        INFINITY :: XKB_KEY_infinity;
        NABLA :: XKB_KEY_nabla;
        APPROXIMATE :: XKB_KEY_approximate;
        SIMILAREQUAL :: XKB_KEY_similarequal;
        IFONLYIF :: XKB_KEY_ifonlyif;
        IMPLIES :: XKB_KEY_implies;
        IDENTICAL :: XKB_KEY_identical;
        RADICAL :: XKB_KEY_radical;
        INCLUDEDIN :: XKB_KEY_includedin;
        INCLUDES :: XKB_KEY_includes;
        INTERSECTION :: XKB_KEY_intersection;
        UNION :: XKB_KEY_union;
        LOGICALAND :: XKB_KEY_logicaland;
        LOGICALOR :: XKB_KEY_logicalor;
        PARTIALDERIVATIVE :: XKB_KEY_partialderivative;
        FUNCTION :: XKB_KEY_function;
        LEFTARROW :: XKB_KEY_leftarrow;
        UPARROW :: XKB_KEY_uparrow;
        RIGHTARROW :: XKB_KEY_rightarrow;
        DOWNARROW :: XKB_KEY_downarrow;
        BLANK :: XKB_KEY_blank;
        SOLIDDIAMOND :: XKB_KEY_soliddiamond;
        CHECKERBOARD :: XKB_KEY_checkerboard;
        HT :: XKB_KEY_ht;
        FF :: XKB_KEY_ff;
        CR :: XKB_KEY_cr;
        LF :: XKB_KEY_lf;
        NL :: XKB_KEY_nl;
        VT :: XKB_KEY_vt;
        LOWRIGHTCORNER :: XKB_KEY_lowrightcorner;
        UPRIGHTCORNER :: XKB_KEY_uprightcorner;
        UPLEFTCORNER :: XKB_KEY_upleftcorner;
        LOWLEFTCORNER :: XKB_KEY_lowleftcorner;
        CROSSINGLINES :: XKB_KEY_crossinglines;
        HORIZLINESCAN1 :: XKB_KEY_horizlinescan1;
        HORIZLINESCAN3 :: XKB_KEY_horizlinescan3;
        HORIZLINESCAN5 :: XKB_KEY_horizlinescan5;
        HORIZLINESCAN7 :: XKB_KEY_horizlinescan7;
        HORIZLINESCAN9 :: XKB_KEY_horizlinescan9;
        LEFTT :: XKB_KEY_leftt;
        RIGHTT :: XKB_KEY_rightt;
        BOTT :: XKB_KEY_bott;
        TOPT :: XKB_KEY_topt;
        VERTBAR :: XKB_KEY_vertbar;
        EMSPACE :: XKB_KEY_emspace;
        ENSPACE :: XKB_KEY_enspace;
        EM3SPACE :: XKB_KEY_em3space;
        EM4SPACE :: XKB_KEY_em4space;
        DIGITSPACE :: XKB_KEY_digitspace;
        PUNCTSPACE :: XKB_KEY_punctspace;
        THINSPACE :: XKB_KEY_thinspace;
        HAIRSPACE :: XKB_KEY_hairspace;
        EMDASH :: XKB_KEY_emdash;
        ENDASH :: XKB_KEY_endash;
        SIGNIFBLANK :: XKB_KEY_signifblank;
        ELLIPSIS :: XKB_KEY_ellipsis;
        DOUBBASELINEDOT :: XKB_KEY_doubbaselinedot;
        ONETHIRD :: XKB_KEY_onethird;
        TWOTHIRDS :: XKB_KEY_twothirds;
        ONEFIFTH :: XKB_KEY_onefifth;
        TWOFIFTHS :: XKB_KEY_twofifths;
        THREEFIFTHS :: XKB_KEY_threefifths;
        FOURFIFTHS :: XKB_KEY_fourfifths;
        ONESIXTH :: XKB_KEY_onesixth;
        FIVESIXTHS :: XKB_KEY_fivesixths;
        CAREOF :: XKB_KEY_careof;
        FIGDASH :: XKB_KEY_figdash;
        LEFTANGLEBRACKET :: XKB_KEY_leftanglebracket;
        DECIMALPOINT :: XKB_KEY_decimalpoint;
        RIGHTANGLEBRACKET :: XKB_KEY_rightanglebracket;
        MARKER :: XKB_KEY_marker;
        ONEEIGHTH :: XKB_KEY_oneeighth;
        THREEEIGHTHS :: XKB_KEY_threeeighths;
        FIVEEIGHTHS :: XKB_KEY_fiveeighths;
        SEVENEIGHTHS :: XKB_KEY_seveneighths;
        TRADEMARK :: XKB_KEY_trademark;
        SIGNATUREMARK :: XKB_KEY_signaturemark;
        TRADEMARKINCIRCLE :: XKB_KEY_trademarkincircle;
        LEFTOPENTRIANGLE :: XKB_KEY_leftopentriangle;
        RIGHTOPENTRIANGLE :: XKB_KEY_rightopentriangle;
        EMOPENCIRCLE :: XKB_KEY_emopencircle;
        EMOPENRECTANGLE :: XKB_KEY_emopenrectangle;
        LEFTSINGLEQUOTEMARK :: XKB_KEY_leftsinglequotemark;
        RIGHTSINGLEQUOTEMARK :: XKB_KEY_rightsinglequotemark;
        LEFTDOUBLEQUOTEMARK :: XKB_KEY_leftdoublequotemark;
        RIGHTDOUBLEQUOTEMARK :: XKB_KEY_rightdoublequotemark;
        PRESCRIPTION :: XKB_KEY_prescription;
        PERMILLE :: XKB_KEY_permille;
        MINUTES :: XKB_KEY_minutes;
        SECONDS :: XKB_KEY_seconds;
        LATINCROSS :: XKB_KEY_latincross;
        HEXAGRAM :: XKB_KEY_hexagram;
        FILLEDRECTBULLET :: XKB_KEY_filledrectbullet;
        FILLEDLEFTTRIBULLET :: XKB_KEY_filledlefttribullet;
        FILLEDRIGHTTRIBULLET :: XKB_KEY_filledrighttribullet;
        EMFILLEDCIRCLE :: XKB_KEY_emfilledcircle;
        EMFILLEDRECT :: XKB_KEY_emfilledrect;
        ENOPENCIRCBULLET :: XKB_KEY_enopencircbullet;
        ENOPENSQUAREBULLET :: XKB_KEY_enopensquarebullet;
        OPENRECTBULLET :: XKB_KEY_openrectbullet;
        OPENTRIBULLETUP :: XKB_KEY_opentribulletup;
        OPENTRIBULLETDOWN :: XKB_KEY_opentribulletdown;
        OPENSTAR :: XKB_KEY_openstar;
        ENFILLEDCIRCBULLET :: XKB_KEY_enfilledcircbullet;
        ENFILLEDSQBULLET :: XKB_KEY_enfilledsqbullet;
        FILLEDTRIBULLETUP :: XKB_KEY_filledtribulletup;
        FILLEDTRIBULLETDOWN :: XKB_KEY_filledtribulletdown;
        LEFTPOINTER :: XKB_KEY_leftpointer;
        RIGHTPOINTER :: XKB_KEY_rightpointer;
        CLUB :: XKB_KEY_club;
        DIAMOND :: XKB_KEY_diamond;
        HEART :: XKB_KEY_heart;
        MALTESECROSS :: XKB_KEY_maltesecross;
        DAGGER :: XKB_KEY_dagger;
        DOUBLEDAGGER :: XKB_KEY_doubledagger;
        CHECKMARK :: XKB_KEY_checkmark;
        BALLOTCROSS :: XKB_KEY_ballotcross;
        MUSICALSHARP :: XKB_KEY_musicalsharp;
        MUSICALFLAT :: XKB_KEY_musicalflat;
        MALESYMBOL :: XKB_KEY_malesymbol;
        FEMALESYMBOL :: XKB_KEY_femalesymbol;
        TELEPHONE :: XKB_KEY_telephone;
        TELEPHONERECORDER :: XKB_KEY_telephonerecorder;
        PHONOGRAPHCOPYRIGHT :: XKB_KEY_phonographcopyright;
        CARET :: XKB_KEY_caret;
        SINGLELOWQUOTEMARK :: XKB_KEY_singlelowquotemark;
        DOUBLELOWQUOTEMARK :: XKB_KEY_doublelowquotemark;
        CURSOR :: XKB_KEY_cursor;
        LEFTCARET :: XKB_KEY_leftcaret;
        RIGHTCARET :: XKB_KEY_rightcaret;
        DOWNCARET :: XKB_KEY_downcaret;
        UPCARET :: XKB_KEY_upcaret;
        OVERBAR :: XKB_KEY_overbar;
        DOWNTACK :: XKB_KEY_downtack;
        UPSHOE :: XKB_KEY_upshoe;
        DOWNSTILE :: XKB_KEY_downstile;
        UNDERBAR :: XKB_KEY_underbar;
        JOT :: XKB_KEY_jot;
        QUAD :: XKB_KEY_quad;
        UPTACK :: XKB_KEY_uptack;
        CIRCLE :: XKB_KEY_circle;
        UPSTILE :: XKB_KEY_upstile;
        DOWNSHOE :: XKB_KEY_downshoe;
        RIGHTSHOE :: XKB_KEY_rightshoe;
        LEFTSHOE :: XKB_KEY_leftshoe;
        LEFTTACK :: XKB_KEY_lefttack;
        RIGHTTACK :: XKB_KEY_righttack;
        HEBREW_DOUBLELOWLINE :: XKB_KEY_hebrew_doublelowline;
        HEBREW_ALEPH :: XKB_KEY_hebrew_aleph;
        HEBREW_BET :: XKB_KEY_hebrew_bet;
        HEBREW_BETH :: XKB_KEY_hebrew_beth;
        HEBREW_GIMEL :: XKB_KEY_hebrew_gimel;
        HEBREW_GIMMEL :: XKB_KEY_hebrew_gimmel;
        HEBREW_DALET :: XKB_KEY_hebrew_dalet;
        HEBREW_DALETH :: XKB_KEY_hebrew_daleth;
        HEBREW_HE :: XKB_KEY_hebrew_he;
        HEBREW_WAW :: XKB_KEY_hebrew_waw;
        HEBREW_ZAIN :: XKB_KEY_hebrew_zain;
        HEBREW_ZAYIN :: XKB_KEY_hebrew_zayin;
        HEBREW_CHET :: XKB_KEY_hebrew_chet;
        HEBREW_HET :: XKB_KEY_hebrew_het;
        HEBREW_TET :: XKB_KEY_hebrew_tet;
        HEBREW_TETH :: XKB_KEY_hebrew_teth;
        HEBREW_YOD :: XKB_KEY_hebrew_yod;
        HEBREW_FINALKAPH :: XKB_KEY_hebrew_finalkaph;
        HEBREW_KAPH :: XKB_KEY_hebrew_kaph;
        HEBREW_LAMED :: XKB_KEY_hebrew_lamed;
        HEBREW_FINALMEM :: XKB_KEY_hebrew_finalmem;
        HEBREW_MEM :: XKB_KEY_hebrew_mem;
        HEBREW_FINALNUN :: XKB_KEY_hebrew_finalnun;
        HEBREW_NUN :: XKB_KEY_hebrew_nun;
        HEBREW_SAMECH :: XKB_KEY_hebrew_samech;
        HEBREW_SAMEKH :: XKB_KEY_hebrew_samekh;
        HEBREW_AYIN :: XKB_KEY_hebrew_ayin;
        HEBREW_FINALPE :: XKB_KEY_hebrew_finalpe;
        HEBREW_PE :: XKB_KEY_hebrew_pe;
        HEBREW_FINALZADE :: XKB_KEY_hebrew_finalzade;
        HEBREW_FINALZADI :: XKB_KEY_hebrew_finalzadi;
        HEBREW_ZADE :: XKB_KEY_hebrew_zade;
        HEBREW_ZADI :: XKB_KEY_hebrew_zadi;
        HEBREW_QOPH :: XKB_KEY_hebrew_qoph;
        HEBREW_KUF :: XKB_KEY_hebrew_kuf;
        HEBREW_RESH :: XKB_KEY_hebrew_resh;
        HEBREW_SHIN :: XKB_KEY_hebrew_shin;
        HEBREW_TAW :: XKB_KEY_hebrew_taw;
        HEBREW_TAF :: XKB_KEY_hebrew_taf;
        HEBREW_SWITCH :: XKB_KEY_Hebrew_switch;
        THAI_KOKAI :: XKB_KEY_Thai_kokai;
        THAI_KHOKHAI :: XKB_KEY_Thai_khokhai;
        THAI_KHOKHUAT :: XKB_KEY_Thai_khokhuat;
        THAI_KHOKHWAI :: XKB_KEY_Thai_khokhwai;
        THAI_KHOKHON :: XKB_KEY_Thai_khokhon;
        THAI_KHORAKHANG :: XKB_KEY_Thai_khorakhang;
        THAI_NGONGU :: XKB_KEY_Thai_ngongu;
        THAI_CHOCHAN :: XKB_KEY_Thai_chochan;
        THAI_CHOCHING :: XKB_KEY_Thai_choching;
        THAI_CHOCHANG :: XKB_KEY_Thai_chochang;
        THAI_SOSO :: XKB_KEY_Thai_soso;
        THAI_CHOCHOE :: XKB_KEY_Thai_chochoe;
        THAI_YOYING :: XKB_KEY_Thai_yoying;
        THAI_DOCHADA :: XKB_KEY_Thai_dochada;
        THAI_TOPATAK :: XKB_KEY_Thai_topatak;
        THAI_THOTHAN :: XKB_KEY_Thai_thothan;
        THAI_THONANGMONTHO :: XKB_KEY_Thai_thonangmontho;
        THAI_THOPHUTHAO :: XKB_KEY_Thai_thophuthao;
        THAI_NONEN :: XKB_KEY_Thai_nonen;
        THAI_DODEK :: XKB_KEY_Thai_dodek;
        THAI_TOTAO :: XKB_KEY_Thai_totao;
        THAI_THOTHUNG :: XKB_KEY_Thai_thothung;
        THAI_THOTHAHAN :: XKB_KEY_Thai_thothahan;
        THAI_THOTHONG :: XKB_KEY_Thai_thothong;
        THAI_NONU :: XKB_KEY_Thai_nonu;
        THAI_BOBAIMAI :: XKB_KEY_Thai_bobaimai;
        THAI_POPLA :: XKB_KEY_Thai_popla;
        THAI_PHOPHUNG :: XKB_KEY_Thai_phophung;
        THAI_FOFA :: XKB_KEY_Thai_fofa;
        THAI_PHOPHAN :: XKB_KEY_Thai_phophan;
        THAI_FOFAN :: XKB_KEY_Thai_fofan;
        THAI_PHOSAMPHAO :: XKB_KEY_Thai_phosamphao;
        THAI_MOMA :: XKB_KEY_Thai_moma;
        THAI_YOYAK :: XKB_KEY_Thai_yoyak;
        THAI_RORUA :: XKB_KEY_Thai_rorua;
        THAI_RU :: XKB_KEY_Thai_ru;
        THAI_LOLING :: XKB_KEY_Thai_loling;
        THAI_LU :: XKB_KEY_Thai_lu;
        THAI_WOWAEN :: XKB_KEY_Thai_wowaen;
        THAI_SOSALA :: XKB_KEY_Thai_sosala;
        THAI_SORUSI :: XKB_KEY_Thai_sorusi;
        THAI_SOSUA :: XKB_KEY_Thai_sosua;
        THAI_HOHIP :: XKB_KEY_Thai_hohip;
        THAI_LOCHULA :: XKB_KEY_Thai_lochula;
        THAI_OANG :: XKB_KEY_Thai_oang;
        THAI_HONOKHUK :: XKB_KEY_Thai_honokhuk;
        THAI_PAIYANNOI :: XKB_KEY_Thai_paiyannoi;
        THAI_SARAA :: XKB_KEY_Thai_saraa;
        THAI_MAIHANAKAT :: XKB_KEY_Thai_maihanakat;
        THAI_SARAAA :: XKB_KEY_Thai_saraaa;
        THAI_SARAAM :: XKB_KEY_Thai_saraam;
        THAI_SARAI :: XKB_KEY_Thai_sarai;
        THAI_SARAII :: XKB_KEY_Thai_saraii;
        THAI_SARAUE :: XKB_KEY_Thai_saraue;
        THAI_SARAUEE :: XKB_KEY_Thai_sarauee;
        THAI_SARAU :: XKB_KEY_Thai_sarau;
        THAI_SARAUU :: XKB_KEY_Thai_sarauu;
        THAI_PHINTHU :: XKB_KEY_Thai_phinthu;
        THAI_MAIHANAKAT_MAITHO :: XKB_KEY_Thai_maihanakat_maitho;
        THAI_BAHT :: XKB_KEY_Thai_baht;
        THAI_SARAE :: XKB_KEY_Thai_sarae;
        THAI_SARAAE :: XKB_KEY_Thai_saraae;
        THAI_SARAO :: XKB_KEY_Thai_sarao;
        THAI_SARAAIMAIMUAN :: XKB_KEY_Thai_saraaimaimuan;
        THAI_SARAAIMAIMALAI :: XKB_KEY_Thai_saraaimaimalai;
        THAI_LAKKHANGYAO :: XKB_KEY_Thai_lakkhangyao;
        THAI_MAIYAMOK :: XKB_KEY_Thai_maiyamok;
        THAI_MAITAIKHU :: XKB_KEY_Thai_maitaikhu;
        THAI_MAIEK :: XKB_KEY_Thai_maiek;
        THAI_MAITHO :: XKB_KEY_Thai_maitho;
        THAI_MAITRI :: XKB_KEY_Thai_maitri;
        THAI_MAICHATTAWA :: XKB_KEY_Thai_maichattawa;
        THAI_THANTHAKHAT :: XKB_KEY_Thai_thanthakhat;
        THAI_NIKHAHIT :: XKB_KEY_Thai_nikhahit;
        THAI_LEKSUN :: XKB_KEY_Thai_leksun;
        THAI_LEKNUNG :: XKB_KEY_Thai_leknung;
        THAI_LEKSONG :: XKB_KEY_Thai_leksong;
        THAI_LEKSAM :: XKB_KEY_Thai_leksam;
        THAI_LEKSI :: XKB_KEY_Thai_leksi;
        THAI_LEKHA :: XKB_KEY_Thai_lekha;
        THAI_LEKHOK :: XKB_KEY_Thai_lekhok;
        THAI_LEKCHET :: XKB_KEY_Thai_lekchet;
        THAI_LEKPAET :: XKB_KEY_Thai_lekpaet;
        THAI_LEKKAO :: XKB_KEY_Thai_lekkao;
        HANGUL :: XKB_KEY_Hangul;
        HANGUL_START :: XKB_KEY_Hangul_Start;
        HANGUL_END :: XKB_KEY_Hangul_End;
        HANGUL_HANJA :: XKB_KEY_Hangul_Hanja;
        HANGUL_JAMO :: XKB_KEY_Hangul_Jamo;
        HANGUL_ROMAJA :: XKB_KEY_Hangul_Romaja;
        HANGUL_CODEINPUT :: XKB_KEY_Hangul_Codeinput;
        HANGUL_JEONJA :: XKB_KEY_Hangul_Jeonja;
        HANGUL_BANJA :: XKB_KEY_Hangul_Banja;
        HANGUL_PREHANJA :: XKB_KEY_Hangul_PreHanja;
        HANGUL_POSTHANJA :: XKB_KEY_Hangul_PostHanja;
        HANGUL_SINGLECANDIDATE :: XKB_KEY_Hangul_SingleCandidate;
        HANGUL_MULTIPLECANDIDATE :: XKB_KEY_Hangul_MultipleCandidate;
        HANGUL_PREVIOUSCANDIDATE :: XKB_KEY_Hangul_PreviousCandidate;
        HANGUL_SPECIAL :: XKB_KEY_Hangul_Special;
        HANGUL_SWITCH :: XKB_KEY_Hangul_switch;
        HANGUL_KIYEOG :: XKB_KEY_Hangul_Kiyeog;
        HANGUL_SSANGKIYEOG :: XKB_KEY_Hangul_SsangKiyeog;
        HANGUL_KIYEOGSIOS :: XKB_KEY_Hangul_KiyeogSios;
        HANGUL_NIEUN :: XKB_KEY_Hangul_Nieun;
        HANGUL_NIEUNJIEUJ :: XKB_KEY_Hangul_NieunJieuj;
        HANGUL_NIEUNHIEUH :: XKB_KEY_Hangul_NieunHieuh;
        HANGUL_DIKEUD :: XKB_KEY_Hangul_Dikeud;
        HANGUL_SSANGDIKEUD :: XKB_KEY_Hangul_SsangDikeud;
        HANGUL_RIEUL :: XKB_KEY_Hangul_Rieul;
        HANGUL_RIEULKIYEOG :: XKB_KEY_Hangul_RieulKiyeog;
        HANGUL_RIEULMIEUM :: XKB_KEY_Hangul_RieulMieum;
        HANGUL_RIEULPIEUB :: XKB_KEY_Hangul_RieulPieub;
        HANGUL_RIEULSIOS :: XKB_KEY_Hangul_RieulSios;
        HANGUL_RIEULTIEUT :: XKB_KEY_Hangul_RieulTieut;
        HANGUL_RIEULPHIEUF :: XKB_KEY_Hangul_RieulPhieuf;
        HANGUL_RIEULHIEUH :: XKB_KEY_Hangul_RieulHieuh;
        HANGUL_MIEUM :: XKB_KEY_Hangul_Mieum;
        HANGUL_PIEUB :: XKB_KEY_Hangul_Pieub;
        HANGUL_SSANGPIEUB :: XKB_KEY_Hangul_SsangPieub;
        HANGUL_PIEUBSIOS :: XKB_KEY_Hangul_PieubSios;
        HANGUL_SIOS :: XKB_KEY_Hangul_Sios;
        HANGUL_SSANGSIOS :: XKB_KEY_Hangul_SsangSios;
        HANGUL_IEUNG :: XKB_KEY_Hangul_Ieung;
        HANGUL_JIEUJ :: XKB_KEY_Hangul_Jieuj;
        HANGUL_SSANGJIEUJ :: XKB_KEY_Hangul_SsangJieuj;
        HANGUL_CIEUC :: XKB_KEY_Hangul_Cieuc;
        HANGUL_KHIEUQ :: XKB_KEY_Hangul_Khieuq;
        HANGUL_TIEUT :: XKB_KEY_Hangul_Tieut;
        HANGUL_PHIEUF :: XKB_KEY_Hangul_Phieuf;
        HANGUL_HIEUH :: XKB_KEY_Hangul_Hieuh;
        HANGUL_A :: XKB_KEY_Hangul_A;
        HANGUL_AE :: XKB_KEY_Hangul_AE;
        HANGUL_YA :: XKB_KEY_Hangul_YA;
        HANGUL_YAE :: XKB_KEY_Hangul_YAE;
        HANGUL_EO :: XKB_KEY_Hangul_EO;
        HANGUL_E :: XKB_KEY_Hangul_E;
        HANGUL_YEO :: XKB_KEY_Hangul_YEO;
        HANGUL_YE :: XKB_KEY_Hangul_YE;
        HANGUL_O :: XKB_KEY_Hangul_O;
        HANGUL_WA :: XKB_KEY_Hangul_WA;
        HANGUL_WAE :: XKB_KEY_Hangul_WAE;
        HANGUL_OE :: XKB_KEY_Hangul_OE;
        HANGUL_YO :: XKB_KEY_Hangul_YO;
        HANGUL_U :: XKB_KEY_Hangul_U;
        HANGUL_WEO :: XKB_KEY_Hangul_WEO;
        HANGUL_WE :: XKB_KEY_Hangul_WE;
        HANGUL_WI :: XKB_KEY_Hangul_WI;
        HANGUL_YU :: XKB_KEY_Hangul_YU;
        HANGUL_EU :: XKB_KEY_Hangul_EU;
        HANGUL_YI :: XKB_KEY_Hangul_YI;
        HANGUL_I :: XKB_KEY_Hangul_I;
        HANGUL_J_KIYEOG :: XKB_KEY_Hangul_J_Kiyeog;
        HANGUL_J_SSANGKIYEOG :: XKB_KEY_Hangul_J_SsangKiyeog;
        HANGUL_J_KIYEOGSIOS :: XKB_KEY_Hangul_J_KiyeogSios;
        HANGUL_J_NIEUN :: XKB_KEY_Hangul_J_Nieun;
        HANGUL_J_NIEUNJIEUJ :: XKB_KEY_Hangul_J_NieunJieuj;
        HANGUL_J_NIEUNHIEUH :: XKB_KEY_Hangul_J_NieunHieuh;
        HANGUL_J_DIKEUD :: XKB_KEY_Hangul_J_Dikeud;
        HANGUL_J_RIEUL :: XKB_KEY_Hangul_J_Rieul;
        HANGUL_J_RIEULKIYEOG :: XKB_KEY_Hangul_J_RieulKiyeog;
        HANGUL_J_RIEULMIEUM :: XKB_KEY_Hangul_J_RieulMieum;
        HANGUL_J_RIEULPIEUB :: XKB_KEY_Hangul_J_RieulPieub;
        HANGUL_J_RIEULSIOS :: XKB_KEY_Hangul_J_RieulSios;
        HANGUL_J_RIEULTIEUT :: XKB_KEY_Hangul_J_RieulTieut;
        HANGUL_J_RIEULPHIEUF :: XKB_KEY_Hangul_J_RieulPhieuf;
        HANGUL_J_RIEULHIEUH :: XKB_KEY_Hangul_J_RieulHieuh;
        HANGUL_J_MIEUM :: XKB_KEY_Hangul_J_Mieum;
        HANGUL_J_PIEUB :: XKB_KEY_Hangul_J_Pieub;
        HANGUL_J_PIEUBSIOS :: XKB_KEY_Hangul_J_PieubSios;
        HANGUL_J_SIOS :: XKB_KEY_Hangul_J_Sios;
        HANGUL_J_SSANGSIOS :: XKB_KEY_Hangul_J_SsangSios;
        HANGUL_J_IEUNG :: XKB_KEY_Hangul_J_Ieung;
        HANGUL_J_JIEUJ :: XKB_KEY_Hangul_J_Jieuj;
        HANGUL_J_CIEUC :: XKB_KEY_Hangul_J_Cieuc;
        HANGUL_J_KHIEUQ :: XKB_KEY_Hangul_J_Khieuq;
        HANGUL_J_TIEUT :: XKB_KEY_Hangul_J_Tieut;
        HANGUL_J_PHIEUF :: XKB_KEY_Hangul_J_Phieuf;
        HANGUL_J_HIEUH :: XKB_KEY_Hangul_J_Hieuh;
        HANGUL_RIEULYEORINHIEUH :: XKB_KEY_Hangul_RieulYeorinHieuh;
        HANGUL_SUNKYEONGEUMMIEUM :: XKB_KEY_Hangul_SunkyeongeumMieum;
        HANGUL_SUNKYEONGEUMPIEUB :: XKB_KEY_Hangul_SunkyeongeumPieub;
        HANGUL_PANSIOS :: XKB_KEY_Hangul_PanSios;
        HANGUL_KKOGJIDALRINIEUNG :: XKB_KEY_Hangul_KkogjiDalrinIeung;
        HANGUL_SUNKYEONGEUMPHIEUF :: XKB_KEY_Hangul_SunkyeongeumPhieuf;
        HANGUL_YEORINHIEUH :: XKB_KEY_Hangul_YeorinHieuh;
        HANGUL_ARAEA :: XKB_KEY_Hangul_AraeA;
        HANGUL_ARAEAE :: XKB_KEY_Hangul_AraeAE;
        HANGUL_J_PANSIOS :: XKB_KEY_Hangul_J_PanSios;
        HANGUL_J_KKOGJIDALRINIEUNG :: XKB_KEY_Hangul_J_KkogjiDalrinIeung;
        HANGUL_J_YEORINHIEUH :: XKB_KEY_Hangul_J_YeorinHieuh;
        KOREAN_WON :: XKB_KEY_Korean_Won;
        ARMENIAN_LIGATURE_EW :: XKB_KEY_Armenian_ligature_ew;
        ARMENIAN_FULL_STOP :: XKB_KEY_Armenian_full_stop;
        ARMENIAN_VERJAKET :: XKB_KEY_Armenian_verjaket;
        ARMENIAN_SEPARATION_MARK :: XKB_KEY_Armenian_separation_mark;
        ARMENIAN_BUT :: XKB_KEY_Armenian_but;
        ARMENIAN_HYPHEN :: XKB_KEY_Armenian_hyphen;
        ARMENIAN_YENTAMNA :: XKB_KEY_Armenian_yentamna;
        ARMENIAN_EXCLAM :: XKB_KEY_Armenian_exclam;
        ARMENIAN_AMANAK :: XKB_KEY_Armenian_amanak;
        ARMENIAN_ACCENT :: XKB_KEY_Armenian_accent;
        ARMENIAN_SHESHT :: XKB_KEY_Armenian_shesht;
        ARMENIAN_QUESTION :: XKB_KEY_Armenian_question;
        ARMENIAN_PARUYK :: XKB_KEY_Armenian_paruyk;
        CAPITAL_ARMENIAN_AYB :: XKB_KEY_Armenian_AYB;
        ARMENIAN_AYB :: XKB_KEY_Armenian_ayb;
        CAPITAL_ARMENIAN_BEN :: XKB_KEY_Armenian_BEN;
        ARMENIAN_BEN :: XKB_KEY_Armenian_ben;
        CAPITAL_ARMENIAN_GIM :: XKB_KEY_Armenian_GIM;
        ARMENIAN_GIM :: XKB_KEY_Armenian_gim;
        CAPITAL_ARMENIAN_DA :: XKB_KEY_Armenian_DA;
        ARMENIAN_DA :: XKB_KEY_Armenian_da;
        CAPITAL_ARMENIAN_YECH :: XKB_KEY_Armenian_YECH;
        ARMENIAN_YECH :: XKB_KEY_Armenian_yech;
        CAPITAL_ARMENIAN_ZA :: XKB_KEY_Armenian_ZA;
        ARMENIAN_ZA :: XKB_KEY_Armenian_za;
        CAPITAL_ARMENIAN_E :: XKB_KEY_Armenian_E;
        ARMENIAN_E :: XKB_KEY_Armenian_e;
        CAPITAL_ARMENIAN_AT :: XKB_KEY_Armenian_AT;
        ARMENIAN_AT :: XKB_KEY_Armenian_at;
        CAPITAL_ARMENIAN_TO :: XKB_KEY_Armenian_TO;
        ARMENIAN_TO :: XKB_KEY_Armenian_to;
        CAPITAL_ARMENIAN_ZHE :: XKB_KEY_Armenian_ZHE;
        ARMENIAN_ZHE :: XKB_KEY_Armenian_zhe;
        CAPITAL_ARMENIAN_INI :: XKB_KEY_Armenian_INI;
        ARMENIAN_INI :: XKB_KEY_Armenian_ini;
        CAPITAL_ARMENIAN_LYUN :: XKB_KEY_Armenian_LYUN;
        ARMENIAN_LYUN :: XKB_KEY_Armenian_lyun;
        CAPITAL_ARMENIAN_KHE :: XKB_KEY_Armenian_KHE;
        ARMENIAN_KHE :: XKB_KEY_Armenian_khe;
        CAPITAL_ARMENIAN_TSA :: XKB_KEY_Armenian_TSA;
        ARMENIAN_TSA :: XKB_KEY_Armenian_tsa;
        CAPITAL_ARMENIAN_KEN :: XKB_KEY_Armenian_KEN;
        ARMENIAN_KEN :: XKB_KEY_Armenian_ken;
        CAPITAL_ARMENIAN_HO :: XKB_KEY_Armenian_HO;
        ARMENIAN_HO :: XKB_KEY_Armenian_ho;
        CAPITAL_ARMENIAN_DZA :: XKB_KEY_Armenian_DZA;
        ARMENIAN_DZA :: XKB_KEY_Armenian_dza;
        CAPITAL_ARMENIAN_GHAT :: XKB_KEY_Armenian_GHAT;
        ARMENIAN_GHAT :: XKB_KEY_Armenian_ghat;
        CAPITAL_ARMENIAN_TCHE :: XKB_KEY_Armenian_TCHE;
        ARMENIAN_TCHE :: XKB_KEY_Armenian_tche;
        CAPITAL_ARMENIAN_MEN :: XKB_KEY_Armenian_MEN;
        ARMENIAN_MEN :: XKB_KEY_Armenian_men;
        CAPITAL_ARMENIAN_HI :: XKB_KEY_Armenian_HI;
        ARMENIAN_HI :: XKB_KEY_Armenian_hi;
        CAPITAL_ARMENIAN_NU :: XKB_KEY_Armenian_NU;
        ARMENIAN_NU :: XKB_KEY_Armenian_nu;
        CAPITAL_ARMENIAN_SHA :: XKB_KEY_Armenian_SHA;
        ARMENIAN_SHA :: XKB_KEY_Armenian_sha;
        CAPITAL_ARMENIAN_VO :: XKB_KEY_Armenian_VO;
        ARMENIAN_VO :: XKB_KEY_Armenian_vo;
        CAPITAL_ARMENIAN_CHA :: XKB_KEY_Armenian_CHA;
        ARMENIAN_CHA :: XKB_KEY_Armenian_cha;
        CAPITAL_ARMENIAN_PE :: XKB_KEY_Armenian_PE;
        ARMENIAN_PE :: XKB_KEY_Armenian_pe;
        CAPITAL_ARMENIAN_JE :: XKB_KEY_Armenian_JE;
        ARMENIAN_JE :: XKB_KEY_Armenian_je;
        CAPITAL_ARMENIAN_RA :: XKB_KEY_Armenian_RA;
        ARMENIAN_RA :: XKB_KEY_Armenian_ra;
        CAPITAL_ARMENIAN_SE :: XKB_KEY_Armenian_SE;
        ARMENIAN_SE :: XKB_KEY_Armenian_se;
        CAPITAL_ARMENIAN_VEV :: XKB_KEY_Armenian_VEV;
        ARMENIAN_VEV :: XKB_KEY_Armenian_vev;
        CAPITAL_ARMENIAN_TYUN :: XKB_KEY_Armenian_TYUN;
        ARMENIAN_TYUN :: XKB_KEY_Armenian_tyun;
        CAPITAL_ARMENIAN_RE :: XKB_KEY_Armenian_RE;
        ARMENIAN_RE :: XKB_KEY_Armenian_re;
        CAPITAL_ARMENIAN_TSO :: XKB_KEY_Armenian_TSO;
        ARMENIAN_TSO :: XKB_KEY_Armenian_tso;
        CAPITAL_ARMENIAN_VYUN :: XKB_KEY_Armenian_VYUN;
        ARMENIAN_VYUN :: XKB_KEY_Armenian_vyun;
        CAPITAL_ARMENIAN_PYUR :: XKB_KEY_Armenian_PYUR;
        ARMENIAN_PYUR :: XKB_KEY_Armenian_pyur;
        CAPITAL_ARMENIAN_KE :: XKB_KEY_Armenian_KE;
        ARMENIAN_KE :: XKB_KEY_Armenian_ke;
        CAPITAL_ARMENIAN_O :: XKB_KEY_Armenian_O;
        ARMENIAN_O :: XKB_KEY_Armenian_o;
        CAPITAL_ARMENIAN_FE :: XKB_KEY_Armenian_FE;
        ARMENIAN_FE :: XKB_KEY_Armenian_fe;
        ARMENIAN_APOSTROPHE :: XKB_KEY_Armenian_apostrophe;
        GEORGIAN_AN :: XKB_KEY_Georgian_an;
        GEORGIAN_BAN :: XKB_KEY_Georgian_ban;
        GEORGIAN_GAN :: XKB_KEY_Georgian_gan;
        GEORGIAN_DON :: XKB_KEY_Georgian_don;
        GEORGIAN_EN :: XKB_KEY_Georgian_en;
        GEORGIAN_VIN :: XKB_KEY_Georgian_vin;
        GEORGIAN_ZEN :: XKB_KEY_Georgian_zen;
        GEORGIAN_TAN :: XKB_KEY_Georgian_tan;
        GEORGIAN_IN :: XKB_KEY_Georgian_in;
        GEORGIAN_KAN :: XKB_KEY_Georgian_kan;
        GEORGIAN_LAS :: XKB_KEY_Georgian_las;
        GEORGIAN_MAN :: XKB_KEY_Georgian_man;
        GEORGIAN_NAR :: XKB_KEY_Georgian_nar;
        GEORGIAN_ON :: XKB_KEY_Georgian_on;
        GEORGIAN_PAR :: XKB_KEY_Georgian_par;
        GEORGIAN_ZHAR :: XKB_KEY_Georgian_zhar;
        GEORGIAN_RAE :: XKB_KEY_Georgian_rae;
        GEORGIAN_SAN :: XKB_KEY_Georgian_san;
        GEORGIAN_TAR :: XKB_KEY_Georgian_tar;
        GEORGIAN_UN :: XKB_KEY_Georgian_un;
        GEORGIAN_PHAR :: XKB_KEY_Georgian_phar;
        GEORGIAN_KHAR :: XKB_KEY_Georgian_khar;
        GEORGIAN_GHAN :: XKB_KEY_Georgian_ghan;
        GEORGIAN_QAR :: XKB_KEY_Georgian_qar;
        GEORGIAN_SHIN :: XKB_KEY_Georgian_shin;
        GEORGIAN_CHIN :: XKB_KEY_Georgian_chin;
        GEORGIAN_CAN :: XKB_KEY_Georgian_can;
        GEORGIAN_JIL :: XKB_KEY_Georgian_jil;
        GEORGIAN_CIL :: XKB_KEY_Georgian_cil;
        GEORGIAN_CHAR :: XKB_KEY_Georgian_char;
        GEORGIAN_XAN :: XKB_KEY_Georgian_xan;
        GEORGIAN_JHAN :: XKB_KEY_Georgian_jhan;
        GEORGIAN_HAE :: XKB_KEY_Georgian_hae;
        GEORGIAN_HE :: XKB_KEY_Georgian_he;
        GEORGIAN_HIE :: XKB_KEY_Georgian_hie;
        GEORGIAN_WE :: XKB_KEY_Georgian_we;
        GEORGIAN_HAR :: XKB_KEY_Georgian_har;
        GEORGIAN_HOE :: XKB_KEY_Georgian_hoe;
        GEORGIAN_FI :: XKB_KEY_Georgian_fi;
        CAPITAL_XABOVEDOT :: XKB_KEY_Xabovedot;
        CAPITAL_IBREVE :: XKB_KEY_Ibreve;
        CAPITAL_ZSTROKE :: XKB_KEY_Zstroke;
        CAPITAL_GCARON :: XKB_KEY_Gcaron;
        CAPITAL_OCARON :: XKB_KEY_Ocaron;
        CAPITAL_OBARRED :: XKB_KEY_Obarred;
        XABOVEDOT :: XKB_KEY_xabovedot;
        IBREVE :: XKB_KEY_ibreve;
        ZSTROKE :: XKB_KEY_zstroke;
        GCARON :: XKB_KEY_gcaron;
        OCARON :: XKB_KEY_ocaron;
        OBARRED :: XKB_KEY_obarred;
        CAPITAL_SCHWA :: XKB_KEY_SCHWA;
        SCHWA :: XKB_KEY_schwa;
        CAPITAL_EZH :: XKB_KEY_EZH;
        EZH :: XKB_KEY_ezh;
        CAPITAL_LBELOWDOT :: XKB_KEY_Lbelowdot;
        LBELOWDOT :: XKB_KEY_lbelowdot;
        CAPITAL_ABELOWDOT :: XKB_KEY_Abelowdot;
        ABELOWDOT :: XKB_KEY_abelowdot;
        CAPITAL_AHOOK :: XKB_KEY_Ahook;
        AHOOK :: XKB_KEY_ahook;
        CAPITAL_ACIRCUMFLEXACUTE :: XKB_KEY_Acircumflexacute;
        ACIRCUMFLEXACUTE :: XKB_KEY_acircumflexacute;
        CAPITAL_ACIRCUMFLEXGRAVE :: XKB_KEY_Acircumflexgrave;
        ACIRCUMFLEXGRAVE :: XKB_KEY_acircumflexgrave;
        CAPITAL_ACIRCUMFLEXHOOK :: XKB_KEY_Acircumflexhook;
        ACIRCUMFLEXHOOK :: XKB_KEY_acircumflexhook;
        CAPITAL_ACIRCUMFLEXTILDE :: XKB_KEY_Acircumflextilde;
        ACIRCUMFLEXTILDE :: XKB_KEY_acircumflextilde;
        CAPITAL_ACIRCUMFLEXBELOWDOT :: XKB_KEY_Acircumflexbelowdot;
        ACIRCUMFLEXBELOWDOT :: XKB_KEY_acircumflexbelowdot;
        CAPITAL_ABREVEACUTE :: XKB_KEY_Abreveacute;
        ABREVEACUTE :: XKB_KEY_abreveacute;
        CAPITAL_ABREVEGRAVE :: XKB_KEY_Abrevegrave;
        ABREVEGRAVE :: XKB_KEY_abrevegrave;
        CAPITAL_ABREVEHOOK :: XKB_KEY_Abrevehook;
        ABREVEHOOK :: XKB_KEY_abrevehook;
        CAPITAL_ABREVETILDE :: XKB_KEY_Abrevetilde;
        ABREVETILDE :: XKB_KEY_abrevetilde;
        CAPITAL_ABREVEBELOWDOT :: XKB_KEY_Abrevebelowdot;
        ABREVEBELOWDOT :: XKB_KEY_abrevebelowdot;
        CAPITAL_EBELOWDOT :: XKB_KEY_Ebelowdot;
        EBELOWDOT :: XKB_KEY_ebelowdot;
        CAPITAL_EHOOK :: XKB_KEY_Ehook;
        EHOOK :: XKB_KEY_ehook;
        CAPITAL_ETILDE :: XKB_KEY_Etilde;
        ETILDE :: XKB_KEY_etilde;
        CAPITAL_ECIRCUMFLEXACUTE :: XKB_KEY_Ecircumflexacute;
        ECIRCUMFLEXACUTE :: XKB_KEY_ecircumflexacute;
        CAPITAL_ECIRCUMFLEXGRAVE :: XKB_KEY_Ecircumflexgrave;
        ECIRCUMFLEXGRAVE :: XKB_KEY_ecircumflexgrave;
        CAPITAL_ECIRCUMFLEXHOOK :: XKB_KEY_Ecircumflexhook;
        ECIRCUMFLEXHOOK :: XKB_KEY_ecircumflexhook;
        CAPITAL_ECIRCUMFLEXTILDE :: XKB_KEY_Ecircumflextilde;
        ECIRCUMFLEXTILDE :: XKB_KEY_ecircumflextilde;
        CAPITAL_ECIRCUMFLEXBELOWDOT :: XKB_KEY_Ecircumflexbelowdot;
        ECIRCUMFLEXBELOWDOT :: XKB_KEY_ecircumflexbelowdot;
        CAPITAL_IHOOK :: XKB_KEY_Ihook;
        IHOOK :: XKB_KEY_ihook;
        CAPITAL_IBELOWDOT :: XKB_KEY_Ibelowdot;
        IBELOWDOT :: XKB_KEY_ibelowdot;
        CAPITAL_OBELOWDOT :: XKB_KEY_Obelowdot;
        OBELOWDOT :: XKB_KEY_obelowdot;
        CAPITAL_OHOOK :: XKB_KEY_Ohook;
        OHOOK :: XKB_KEY_ohook;
        CAPITAL_OCIRCUMFLEXACUTE :: XKB_KEY_Ocircumflexacute;
        OCIRCUMFLEXACUTE :: XKB_KEY_ocircumflexacute;
        CAPITAL_OCIRCUMFLEXGRAVE :: XKB_KEY_Ocircumflexgrave;
        OCIRCUMFLEXGRAVE :: XKB_KEY_ocircumflexgrave;
        CAPITAL_OCIRCUMFLEXHOOK :: XKB_KEY_Ocircumflexhook;
        OCIRCUMFLEXHOOK :: XKB_KEY_ocircumflexhook;
        CAPITAL_OCIRCUMFLEXTILDE :: XKB_KEY_Ocircumflextilde;
        OCIRCUMFLEXTILDE :: XKB_KEY_ocircumflextilde;
        CAPITAL_OCIRCUMFLEXBELOWDOT :: XKB_KEY_Ocircumflexbelowdot;
        OCIRCUMFLEXBELOWDOT :: XKB_KEY_ocircumflexbelowdot;
        CAPITAL_OHORNACUTE :: XKB_KEY_Ohornacute;
        OHORNACUTE :: XKB_KEY_ohornacute;
        CAPITAL_OHORNGRAVE :: XKB_KEY_Ohorngrave;
        OHORNGRAVE :: XKB_KEY_ohorngrave;
        CAPITAL_OHORNHOOK :: XKB_KEY_Ohornhook;
        OHORNHOOK :: XKB_KEY_ohornhook;
        CAPITAL_OHORNTILDE :: XKB_KEY_Ohorntilde;
        OHORNTILDE :: XKB_KEY_ohorntilde;
        CAPITAL_OHORNBELOWDOT :: XKB_KEY_Ohornbelowdot;
        OHORNBELOWDOT :: XKB_KEY_ohornbelowdot;
        CAPITAL_UBELOWDOT :: XKB_KEY_Ubelowdot;
        UBELOWDOT :: XKB_KEY_ubelowdot;
        CAPITAL_UHOOK :: XKB_KEY_Uhook;
        UHOOK :: XKB_KEY_uhook;
        CAPITAL_UHORNACUTE :: XKB_KEY_Uhornacute;
        UHORNACUTE :: XKB_KEY_uhornacute;
        CAPITAL_UHORNGRAVE :: XKB_KEY_Uhorngrave;
        UHORNGRAVE :: XKB_KEY_uhorngrave;
        CAPITAL_UHORNHOOK :: XKB_KEY_Uhornhook;
        UHORNHOOK :: XKB_KEY_uhornhook;
        CAPITAL_UHORNTILDE :: XKB_KEY_Uhorntilde;
        UHORNTILDE :: XKB_KEY_uhorntilde;
        CAPITAL_UHORNBELOWDOT :: XKB_KEY_Uhornbelowdot;
        UHORNBELOWDOT :: XKB_KEY_uhornbelowdot;
        CAPITAL_YBELOWDOT :: XKB_KEY_Ybelowdot;
        YBELOWDOT :: XKB_KEY_ybelowdot;
        CAPITAL_YHOOK :: XKB_KEY_Yhook;
        YHOOK :: XKB_KEY_yhook;
        CAPITAL_YTILDE :: XKB_KEY_Ytilde;
        YTILDE :: XKB_KEY_ytilde;
        CAPITAL_OHORN :: XKB_KEY_Ohorn;
        OHORN :: XKB_KEY_ohorn;
        CAPITAL_UHORN :: XKB_KEY_Uhorn;
        UHORN :: XKB_KEY_uhorn;
        COMBINING_TILDE :: XKB_KEY_combining_tilde;
        COMBINING_GRAVE :: XKB_KEY_combining_grave;
        COMBINING_ACUTE :: XKB_KEY_combining_acute;
        COMBINING_HOOK :: XKB_KEY_combining_hook;
        COMBINING_BELOWDOT :: XKB_KEY_combining_belowdot;
        ECUSIGN :: XKB_KEY_EcuSign;
        COLONSIGN :: XKB_KEY_ColonSign;
        CRUZEIROSIGN :: XKB_KEY_CruzeiroSign;
        FFRANCSIGN :: XKB_KEY_FFrancSign;
        LIRASIGN :: XKB_KEY_LiraSign;
        MILLSIGN :: XKB_KEY_MillSign;
        NAIRASIGN :: XKB_KEY_NairaSign;
        PESETASIGN :: XKB_KEY_PesetaSign;
        RUPEESIGN :: XKB_KEY_RupeeSign;
        WONSIGN :: XKB_KEY_WonSign;
        NEWSHEQELSIGN :: XKB_KEY_NewSheqelSign;
        DONGSIGN :: XKB_KEY_DongSign;
        EUROSIGN :: XKB_KEY_EuroSign;
        ZEROSUPERIOR :: XKB_KEY_zerosuperior;
        FOURSUPERIOR :: XKB_KEY_foursuperior;
        FIVESUPERIOR :: XKB_KEY_fivesuperior;
        SIXSUPERIOR :: XKB_KEY_sixsuperior;
        SEVENSUPERIOR :: XKB_KEY_sevensuperior;
        EIGHTSUPERIOR :: XKB_KEY_eightsuperior;
        NINESUPERIOR :: XKB_KEY_ninesuperior;
        ZEROSUBSCRIPT :: XKB_KEY_zerosubscript;
        ONESUBSCRIPT :: XKB_KEY_onesubscript;
        TWOSUBSCRIPT :: XKB_KEY_twosubscript;
        THREESUBSCRIPT :: XKB_KEY_threesubscript;
        FOURSUBSCRIPT :: XKB_KEY_foursubscript;
        FIVESUBSCRIPT :: XKB_KEY_fivesubscript;
        SIXSUBSCRIPT :: XKB_KEY_sixsubscript;
        SEVENSUBSCRIPT :: XKB_KEY_sevensubscript;
        EIGHTSUBSCRIPT :: XKB_KEY_eightsubscript;
        NINESUBSCRIPT :: XKB_KEY_ninesubscript;
        PARTDIFFERENTIAL :: XKB_KEY_partdifferential;
        EMPTYSET :: XKB_KEY_emptyset;
        ELEMENTOF :: XKB_KEY_elementof;
        NOTELEMENTOF :: XKB_KEY_notelementof;
        CONTAINSAS :: XKB_KEY_containsas;
        SQUAREROOT :: XKB_KEY_squareroot;
        CUBEROOT :: XKB_KEY_cuberoot;
        FOURTHROOT :: XKB_KEY_fourthroot;
        DINTEGRAL :: XKB_KEY_dintegral;
        TINTEGRAL :: XKB_KEY_tintegral;
        BECAUSE :: XKB_KEY_because;
        APPROXEQ :: XKB_KEY_approxeq;
        NOTAPPROXEQ :: XKB_KEY_notapproxeq;
        NOTIDENTICAL :: XKB_KEY_notidentical;
        STRICTEQ :: XKB_KEY_stricteq;
        BRAILLE_DOT_1 :: XKB_KEY_braille_dot_1;
        BRAILLE_DOT_2 :: XKB_KEY_braille_dot_2;
        BRAILLE_DOT_3 :: XKB_KEY_braille_dot_3;
        BRAILLE_DOT_4 :: XKB_KEY_braille_dot_4;
        BRAILLE_DOT_5 :: XKB_KEY_braille_dot_5;
        BRAILLE_DOT_6 :: XKB_KEY_braille_dot_6;
        BRAILLE_DOT_7 :: XKB_KEY_braille_dot_7;
        BRAILLE_DOT_8 :: XKB_KEY_braille_dot_8;
        BRAILLE_DOT_9 :: XKB_KEY_braille_dot_9;
        BRAILLE_DOT_10 :: XKB_KEY_braille_dot_10;
        BRAILLE_BLANK :: XKB_KEY_braille_blank;
        BRAILLE_DOTS_1 :: XKB_KEY_braille_dots_1;
        BRAILLE_DOTS_2 :: XKB_KEY_braille_dots_2;
        BRAILLE_DOTS_12 :: XKB_KEY_braille_dots_12;
        BRAILLE_DOTS_3 :: XKB_KEY_braille_dots_3;
        BRAILLE_DOTS_13 :: XKB_KEY_braille_dots_13;
        BRAILLE_DOTS_23 :: XKB_KEY_braille_dots_23;
        BRAILLE_DOTS_123 :: XKB_KEY_braille_dots_123;
        BRAILLE_DOTS_4 :: XKB_KEY_braille_dots_4;
        BRAILLE_DOTS_14 :: XKB_KEY_braille_dots_14;
        BRAILLE_DOTS_24 :: XKB_KEY_braille_dots_24;
        BRAILLE_DOTS_124 :: XKB_KEY_braille_dots_124;
        BRAILLE_DOTS_34 :: XKB_KEY_braille_dots_34;
        BRAILLE_DOTS_134 :: XKB_KEY_braille_dots_134;
        BRAILLE_DOTS_234 :: XKB_KEY_braille_dots_234;
        BRAILLE_DOTS_1234 :: XKB_KEY_braille_dots_1234;
        BRAILLE_DOTS_5 :: XKB_KEY_braille_dots_5;
        BRAILLE_DOTS_15 :: XKB_KEY_braille_dots_15;
        BRAILLE_DOTS_25 :: XKB_KEY_braille_dots_25;
        BRAILLE_DOTS_125 :: XKB_KEY_braille_dots_125;
        BRAILLE_DOTS_35 :: XKB_KEY_braille_dots_35;
        BRAILLE_DOTS_135 :: XKB_KEY_braille_dots_135;
        BRAILLE_DOTS_235 :: XKB_KEY_braille_dots_235;
        BRAILLE_DOTS_1235 :: XKB_KEY_braille_dots_1235;
        BRAILLE_DOTS_45 :: XKB_KEY_braille_dots_45;
        BRAILLE_DOTS_145 :: XKB_KEY_braille_dots_145;
        BRAILLE_DOTS_245 :: XKB_KEY_braille_dots_245;
        BRAILLE_DOTS_1245 :: XKB_KEY_braille_dots_1245;
        BRAILLE_DOTS_345 :: XKB_KEY_braille_dots_345;
        BRAILLE_DOTS_1345 :: XKB_KEY_braille_dots_1345;
        BRAILLE_DOTS_2345 :: XKB_KEY_braille_dots_2345;
        BRAILLE_DOTS_12345 :: XKB_KEY_braille_dots_12345;
        BRAILLE_DOTS_6 :: XKB_KEY_braille_dots_6;
        BRAILLE_DOTS_16 :: XKB_KEY_braille_dots_16;
        BRAILLE_DOTS_26 :: XKB_KEY_braille_dots_26;
        BRAILLE_DOTS_126 :: XKB_KEY_braille_dots_126;
        BRAILLE_DOTS_36 :: XKB_KEY_braille_dots_36;
        BRAILLE_DOTS_136 :: XKB_KEY_braille_dots_136;
        BRAILLE_DOTS_236 :: XKB_KEY_braille_dots_236;
        BRAILLE_DOTS_1236 :: XKB_KEY_braille_dots_1236;
        BRAILLE_DOTS_46 :: XKB_KEY_braille_dots_46;
        BRAILLE_DOTS_146 :: XKB_KEY_braille_dots_146;
        BRAILLE_DOTS_246 :: XKB_KEY_braille_dots_246;
        BRAILLE_DOTS_1246 :: XKB_KEY_braille_dots_1246;
        BRAILLE_DOTS_346 :: XKB_KEY_braille_dots_346;
        BRAILLE_DOTS_1346 :: XKB_KEY_braille_dots_1346;
        BRAILLE_DOTS_2346 :: XKB_KEY_braille_dots_2346;
        BRAILLE_DOTS_12346 :: XKB_KEY_braille_dots_12346;
        BRAILLE_DOTS_56 :: XKB_KEY_braille_dots_56;
        BRAILLE_DOTS_156 :: XKB_KEY_braille_dots_156;
        BRAILLE_DOTS_256 :: XKB_KEY_braille_dots_256;
        BRAILLE_DOTS_1256 :: XKB_KEY_braille_dots_1256;
        BRAILLE_DOTS_356 :: XKB_KEY_braille_dots_356;
        BRAILLE_DOTS_1356 :: XKB_KEY_braille_dots_1356;
        BRAILLE_DOTS_2356 :: XKB_KEY_braille_dots_2356;
        BRAILLE_DOTS_12356 :: XKB_KEY_braille_dots_12356;
        BRAILLE_DOTS_456 :: XKB_KEY_braille_dots_456;
        BRAILLE_DOTS_1456 :: XKB_KEY_braille_dots_1456;
        BRAILLE_DOTS_2456 :: XKB_KEY_braille_dots_2456;
        BRAILLE_DOTS_12456 :: XKB_KEY_braille_dots_12456;
        BRAILLE_DOTS_3456 :: XKB_KEY_braille_dots_3456;
        BRAILLE_DOTS_13456 :: XKB_KEY_braille_dots_13456;
        BRAILLE_DOTS_23456 :: XKB_KEY_braille_dots_23456;
        BRAILLE_DOTS_123456 :: XKB_KEY_braille_dots_123456;
        BRAILLE_DOTS_7 :: XKB_KEY_braille_dots_7;
        BRAILLE_DOTS_17 :: XKB_KEY_braille_dots_17;
        BRAILLE_DOTS_27 :: XKB_KEY_braille_dots_27;
        BRAILLE_DOTS_127 :: XKB_KEY_braille_dots_127;
        BRAILLE_DOTS_37 :: XKB_KEY_braille_dots_37;
        BRAILLE_DOTS_137 :: XKB_KEY_braille_dots_137;
        BRAILLE_DOTS_237 :: XKB_KEY_braille_dots_237;
        BRAILLE_DOTS_1237 :: XKB_KEY_braille_dots_1237;
        BRAILLE_DOTS_47 :: XKB_KEY_braille_dots_47;
        BRAILLE_DOTS_147 :: XKB_KEY_braille_dots_147;
        BRAILLE_DOTS_247 :: XKB_KEY_braille_dots_247;
        BRAILLE_DOTS_1247 :: XKB_KEY_braille_dots_1247;
        BRAILLE_DOTS_347 :: XKB_KEY_braille_dots_347;
        BRAILLE_DOTS_1347 :: XKB_KEY_braille_dots_1347;
        BRAILLE_DOTS_2347 :: XKB_KEY_braille_dots_2347;
        BRAILLE_DOTS_12347 :: XKB_KEY_braille_dots_12347;
        BRAILLE_DOTS_57 :: XKB_KEY_braille_dots_57;
        BRAILLE_DOTS_157 :: XKB_KEY_braille_dots_157;
        BRAILLE_DOTS_257 :: XKB_KEY_braille_dots_257;
        BRAILLE_DOTS_1257 :: XKB_KEY_braille_dots_1257;
        BRAILLE_DOTS_357 :: XKB_KEY_braille_dots_357;
        BRAILLE_DOTS_1357 :: XKB_KEY_braille_dots_1357;
        BRAILLE_DOTS_2357 :: XKB_KEY_braille_dots_2357;
        BRAILLE_DOTS_12357 :: XKB_KEY_braille_dots_12357;
        BRAILLE_DOTS_457 :: XKB_KEY_braille_dots_457;
        BRAILLE_DOTS_1457 :: XKB_KEY_braille_dots_1457;
        BRAILLE_DOTS_2457 :: XKB_KEY_braille_dots_2457;
        BRAILLE_DOTS_12457 :: XKB_KEY_braille_dots_12457;
        BRAILLE_DOTS_3457 :: XKB_KEY_braille_dots_3457;
        BRAILLE_DOTS_13457 :: XKB_KEY_braille_dots_13457;
        BRAILLE_DOTS_23457 :: XKB_KEY_braille_dots_23457;
        BRAILLE_DOTS_123457 :: XKB_KEY_braille_dots_123457;
        BRAILLE_DOTS_67 :: XKB_KEY_braille_dots_67;
        BRAILLE_DOTS_167 :: XKB_KEY_braille_dots_167;
        BRAILLE_DOTS_267 :: XKB_KEY_braille_dots_267;
        BRAILLE_DOTS_1267 :: XKB_KEY_braille_dots_1267;
        BRAILLE_DOTS_367 :: XKB_KEY_braille_dots_367;
        BRAILLE_DOTS_1367 :: XKB_KEY_braille_dots_1367;
        BRAILLE_DOTS_2367 :: XKB_KEY_braille_dots_2367;
        BRAILLE_DOTS_12367 :: XKB_KEY_braille_dots_12367;
        BRAILLE_DOTS_467 :: XKB_KEY_braille_dots_467;
        BRAILLE_DOTS_1467 :: XKB_KEY_braille_dots_1467;
        BRAILLE_DOTS_2467 :: XKB_KEY_braille_dots_2467;
        BRAILLE_DOTS_12467 :: XKB_KEY_braille_dots_12467;
        BRAILLE_DOTS_3467 :: XKB_KEY_braille_dots_3467;
        BRAILLE_DOTS_13467 :: XKB_KEY_braille_dots_13467;
        BRAILLE_DOTS_23467 :: XKB_KEY_braille_dots_23467;
        BRAILLE_DOTS_123467 :: XKB_KEY_braille_dots_123467;
        BRAILLE_DOTS_567 :: XKB_KEY_braille_dots_567;
        BRAILLE_DOTS_1567 :: XKB_KEY_braille_dots_1567;
        BRAILLE_DOTS_2567 :: XKB_KEY_braille_dots_2567;
        BRAILLE_DOTS_12567 :: XKB_KEY_braille_dots_12567;
        BRAILLE_DOTS_3567 :: XKB_KEY_braille_dots_3567;
        BRAILLE_DOTS_13567 :: XKB_KEY_braille_dots_13567;
        BRAILLE_DOTS_23567 :: XKB_KEY_braille_dots_23567;
        BRAILLE_DOTS_123567 :: XKB_KEY_braille_dots_123567;
        BRAILLE_DOTS_4567 :: XKB_KEY_braille_dots_4567;
        BRAILLE_DOTS_14567 :: XKB_KEY_braille_dots_14567;
        BRAILLE_DOTS_24567 :: XKB_KEY_braille_dots_24567;
        BRAILLE_DOTS_124567 :: XKB_KEY_braille_dots_124567;
        BRAILLE_DOTS_34567 :: XKB_KEY_braille_dots_34567;
        BRAILLE_DOTS_134567 :: XKB_KEY_braille_dots_134567;
        BRAILLE_DOTS_234567 :: XKB_KEY_braille_dots_234567;
        BRAILLE_DOTS_1234567 :: XKB_KEY_braille_dots_1234567;
        BRAILLE_DOTS_8 :: XKB_KEY_braille_dots_8;
        BRAILLE_DOTS_18 :: XKB_KEY_braille_dots_18;
        BRAILLE_DOTS_28 :: XKB_KEY_braille_dots_28;
        BRAILLE_DOTS_128 :: XKB_KEY_braille_dots_128;
        BRAILLE_DOTS_38 :: XKB_KEY_braille_dots_38;
        BRAILLE_DOTS_138 :: XKB_KEY_braille_dots_138;
        BRAILLE_DOTS_238 :: XKB_KEY_braille_dots_238;
        BRAILLE_DOTS_1238 :: XKB_KEY_braille_dots_1238;
        BRAILLE_DOTS_48 :: XKB_KEY_braille_dots_48;
        BRAILLE_DOTS_148 :: XKB_KEY_braille_dots_148;
        BRAILLE_DOTS_248 :: XKB_KEY_braille_dots_248;
        BRAILLE_DOTS_1248 :: XKB_KEY_braille_dots_1248;
        BRAILLE_DOTS_348 :: XKB_KEY_braille_dots_348;
        BRAILLE_DOTS_1348 :: XKB_KEY_braille_dots_1348;
        BRAILLE_DOTS_2348 :: XKB_KEY_braille_dots_2348;
        BRAILLE_DOTS_12348 :: XKB_KEY_braille_dots_12348;
        BRAILLE_DOTS_58 :: XKB_KEY_braille_dots_58;
        BRAILLE_DOTS_158 :: XKB_KEY_braille_dots_158;
        BRAILLE_DOTS_258 :: XKB_KEY_braille_dots_258;
        BRAILLE_DOTS_1258 :: XKB_KEY_braille_dots_1258;
        BRAILLE_DOTS_358 :: XKB_KEY_braille_dots_358;
        BRAILLE_DOTS_1358 :: XKB_KEY_braille_dots_1358;
        BRAILLE_DOTS_2358 :: XKB_KEY_braille_dots_2358;
        BRAILLE_DOTS_12358 :: XKB_KEY_braille_dots_12358;
        BRAILLE_DOTS_458 :: XKB_KEY_braille_dots_458;
        BRAILLE_DOTS_1458 :: XKB_KEY_braille_dots_1458;
        BRAILLE_DOTS_2458 :: XKB_KEY_braille_dots_2458;
        BRAILLE_DOTS_12458 :: XKB_KEY_braille_dots_12458;
        BRAILLE_DOTS_3458 :: XKB_KEY_braille_dots_3458;
        BRAILLE_DOTS_13458 :: XKB_KEY_braille_dots_13458;
        BRAILLE_DOTS_23458 :: XKB_KEY_braille_dots_23458;
        BRAILLE_DOTS_123458 :: XKB_KEY_braille_dots_123458;
        BRAILLE_DOTS_68 :: XKB_KEY_braille_dots_68;
        BRAILLE_DOTS_168 :: XKB_KEY_braille_dots_168;
        BRAILLE_DOTS_268 :: XKB_KEY_braille_dots_268;
        BRAILLE_DOTS_1268 :: XKB_KEY_braille_dots_1268;
        BRAILLE_DOTS_368 :: XKB_KEY_braille_dots_368;
        BRAILLE_DOTS_1368 :: XKB_KEY_braille_dots_1368;
        BRAILLE_DOTS_2368 :: XKB_KEY_braille_dots_2368;
        BRAILLE_DOTS_12368 :: XKB_KEY_braille_dots_12368;
        BRAILLE_DOTS_468 :: XKB_KEY_braille_dots_468;
        BRAILLE_DOTS_1468 :: XKB_KEY_braille_dots_1468;
        BRAILLE_DOTS_2468 :: XKB_KEY_braille_dots_2468;
        BRAILLE_DOTS_12468 :: XKB_KEY_braille_dots_12468;
        BRAILLE_DOTS_3468 :: XKB_KEY_braille_dots_3468;
        BRAILLE_DOTS_13468 :: XKB_KEY_braille_dots_13468;
        BRAILLE_DOTS_23468 :: XKB_KEY_braille_dots_23468;
        BRAILLE_DOTS_123468 :: XKB_KEY_braille_dots_123468;
        BRAILLE_DOTS_568 :: XKB_KEY_braille_dots_568;
        BRAILLE_DOTS_1568 :: XKB_KEY_braille_dots_1568;
        BRAILLE_DOTS_2568 :: XKB_KEY_braille_dots_2568;
        BRAILLE_DOTS_12568 :: XKB_KEY_braille_dots_12568;
        BRAILLE_DOTS_3568 :: XKB_KEY_braille_dots_3568;
        BRAILLE_DOTS_13568 :: XKB_KEY_braille_dots_13568;
        BRAILLE_DOTS_23568 :: XKB_KEY_braille_dots_23568;
        BRAILLE_DOTS_123568 :: XKB_KEY_braille_dots_123568;
        BRAILLE_DOTS_4568 :: XKB_KEY_braille_dots_4568;
        BRAILLE_DOTS_14568 :: XKB_KEY_braille_dots_14568;
        BRAILLE_DOTS_24568 :: XKB_KEY_braille_dots_24568;
        BRAILLE_DOTS_124568 :: XKB_KEY_braille_dots_124568;
        BRAILLE_DOTS_34568 :: XKB_KEY_braille_dots_34568;
        BRAILLE_DOTS_134568 :: XKB_KEY_braille_dots_134568;
        BRAILLE_DOTS_234568 :: XKB_KEY_braille_dots_234568;
        BRAILLE_DOTS_1234568 :: XKB_KEY_braille_dots_1234568;
        BRAILLE_DOTS_78 :: XKB_KEY_braille_dots_78;
        BRAILLE_DOTS_178 :: XKB_KEY_braille_dots_178;
        BRAILLE_DOTS_278 :: XKB_KEY_braille_dots_278;
        BRAILLE_DOTS_1278 :: XKB_KEY_braille_dots_1278;
        BRAILLE_DOTS_378 :: XKB_KEY_braille_dots_378;
        BRAILLE_DOTS_1378 :: XKB_KEY_braille_dots_1378;
        BRAILLE_DOTS_2378 :: XKB_KEY_braille_dots_2378;
        BRAILLE_DOTS_12378 :: XKB_KEY_braille_dots_12378;
        BRAILLE_DOTS_478 :: XKB_KEY_braille_dots_478;
        BRAILLE_DOTS_1478 :: XKB_KEY_braille_dots_1478;
        BRAILLE_DOTS_2478 :: XKB_KEY_braille_dots_2478;
        BRAILLE_DOTS_12478 :: XKB_KEY_braille_dots_12478;
        BRAILLE_DOTS_3478 :: XKB_KEY_braille_dots_3478;
        BRAILLE_DOTS_13478 :: XKB_KEY_braille_dots_13478;
        BRAILLE_DOTS_23478 :: XKB_KEY_braille_dots_23478;
        BRAILLE_DOTS_123478 :: XKB_KEY_braille_dots_123478;
        BRAILLE_DOTS_578 :: XKB_KEY_braille_dots_578;
        BRAILLE_DOTS_1578 :: XKB_KEY_braille_dots_1578;
        BRAILLE_DOTS_2578 :: XKB_KEY_braille_dots_2578;
        BRAILLE_DOTS_12578 :: XKB_KEY_braille_dots_12578;
        BRAILLE_DOTS_3578 :: XKB_KEY_braille_dots_3578;
        BRAILLE_DOTS_13578 :: XKB_KEY_braille_dots_13578;
        BRAILLE_DOTS_23578 :: XKB_KEY_braille_dots_23578;
        BRAILLE_DOTS_123578 :: XKB_KEY_braille_dots_123578;
        BRAILLE_DOTS_4578 :: XKB_KEY_braille_dots_4578;
        BRAILLE_DOTS_14578 :: XKB_KEY_braille_dots_14578;
        BRAILLE_DOTS_24578 :: XKB_KEY_braille_dots_24578;
        BRAILLE_DOTS_124578 :: XKB_KEY_braille_dots_124578;
        BRAILLE_DOTS_34578 :: XKB_KEY_braille_dots_34578;
        BRAILLE_DOTS_134578 :: XKB_KEY_braille_dots_134578;
        BRAILLE_DOTS_234578 :: XKB_KEY_braille_dots_234578;
        BRAILLE_DOTS_1234578 :: XKB_KEY_braille_dots_1234578;
        BRAILLE_DOTS_678 :: XKB_KEY_braille_dots_678;
        BRAILLE_DOTS_1678 :: XKB_KEY_braille_dots_1678;
        BRAILLE_DOTS_2678 :: XKB_KEY_braille_dots_2678;
        BRAILLE_DOTS_12678 :: XKB_KEY_braille_dots_12678;
        BRAILLE_DOTS_3678 :: XKB_KEY_braille_dots_3678;
        BRAILLE_DOTS_13678 :: XKB_KEY_braille_dots_13678;
        BRAILLE_DOTS_23678 :: XKB_KEY_braille_dots_23678;
        BRAILLE_DOTS_123678 :: XKB_KEY_braille_dots_123678;
        BRAILLE_DOTS_4678 :: XKB_KEY_braille_dots_4678;
        BRAILLE_DOTS_14678 :: XKB_KEY_braille_dots_14678;
        BRAILLE_DOTS_24678 :: XKB_KEY_braille_dots_24678;
        BRAILLE_DOTS_124678 :: XKB_KEY_braille_dots_124678;
        BRAILLE_DOTS_34678 :: XKB_KEY_braille_dots_34678;
        BRAILLE_DOTS_134678 :: XKB_KEY_braille_dots_134678;
        BRAILLE_DOTS_234678 :: XKB_KEY_braille_dots_234678;
        BRAILLE_DOTS_1234678 :: XKB_KEY_braille_dots_1234678;
        BRAILLE_DOTS_5678 :: XKB_KEY_braille_dots_5678;
        BRAILLE_DOTS_15678 :: XKB_KEY_braille_dots_15678;
        BRAILLE_DOTS_25678 :: XKB_KEY_braille_dots_25678;
        BRAILLE_DOTS_125678 :: XKB_KEY_braille_dots_125678;
        BRAILLE_DOTS_35678 :: XKB_KEY_braille_dots_35678;
        BRAILLE_DOTS_135678 :: XKB_KEY_braille_dots_135678;
        BRAILLE_DOTS_235678 :: XKB_KEY_braille_dots_235678;
        BRAILLE_DOTS_1235678 :: XKB_KEY_braille_dots_1235678;
        BRAILLE_DOTS_45678 :: XKB_KEY_braille_dots_45678;
        BRAILLE_DOTS_145678 :: XKB_KEY_braille_dots_145678;
        BRAILLE_DOTS_245678 :: XKB_KEY_braille_dots_245678;
        BRAILLE_DOTS_1245678 :: XKB_KEY_braille_dots_1245678;
        BRAILLE_DOTS_345678 :: XKB_KEY_braille_dots_345678;
        BRAILLE_DOTS_1345678 :: XKB_KEY_braille_dots_1345678;
        BRAILLE_DOTS_2345678 :: XKB_KEY_braille_dots_2345678;
        BRAILLE_DOTS_12345678 :: XKB_KEY_braille_dots_12345678;
        SINH_NG :: XKB_KEY_Sinh_ng;
        SINH_H2 :: XKB_KEY_Sinh_h2;
        SINH_A :: XKB_KEY_Sinh_a;
        SINH_AA :: XKB_KEY_Sinh_aa;
        SINH_AE :: XKB_KEY_Sinh_ae;
        SINH_AEE :: XKB_KEY_Sinh_aee;
        SINH_I :: XKB_KEY_Sinh_i;
        SINH_II :: XKB_KEY_Sinh_ii;
        SINH_U :: XKB_KEY_Sinh_u;
        SINH_UU :: XKB_KEY_Sinh_uu;
        SINH_RI :: XKB_KEY_Sinh_ri;
        SINH_RII :: XKB_KEY_Sinh_rii;
        SINH_LU :: XKB_KEY_Sinh_lu;
        SINH_LUU :: XKB_KEY_Sinh_luu;
        SINH_E :: XKB_KEY_Sinh_e;
        SINH_EE :: XKB_KEY_Sinh_ee;
        SINH_AI :: XKB_KEY_Sinh_ai;
        SINH_O :: XKB_KEY_Sinh_o;
        SINH_OO :: XKB_KEY_Sinh_oo;
        SINH_AU :: XKB_KEY_Sinh_au;
        SINH_KA :: XKB_KEY_Sinh_ka;
        SINH_KHA :: XKB_KEY_Sinh_kha;
        SINH_GA :: XKB_KEY_Sinh_ga;
        SINH_GHA :: XKB_KEY_Sinh_gha;
        SINH_NG2 :: XKB_KEY_Sinh_ng2;
        SINH_NGA :: XKB_KEY_Sinh_nga;
        SINH_CA :: XKB_KEY_Sinh_ca;
        SINH_CHA :: XKB_KEY_Sinh_cha;
        SINH_JA :: XKB_KEY_Sinh_ja;
        SINH_JHA :: XKB_KEY_Sinh_jha;
        SINH_NYA :: XKB_KEY_Sinh_nya;
        SINH_JNYA :: XKB_KEY_Sinh_jnya;
        SINH_NJA :: XKB_KEY_Sinh_nja;
        SINH_TTA :: XKB_KEY_Sinh_tta;
        SINH_TTHA :: XKB_KEY_Sinh_ttha;
        SINH_DDA :: XKB_KEY_Sinh_dda;
        SINH_DDHA :: XKB_KEY_Sinh_ddha;
        SINH_NNA :: XKB_KEY_Sinh_nna;
        SINH_NDDA :: XKB_KEY_Sinh_ndda;
        SINH_THA :: XKB_KEY_Sinh_tha;
        SINH_THHA :: XKB_KEY_Sinh_thha;
        SINH_DHA :: XKB_KEY_Sinh_dha;
        SINH_DHHA :: XKB_KEY_Sinh_dhha;
        SINH_NA :: XKB_KEY_Sinh_na;
        SINH_NDHA :: XKB_KEY_Sinh_ndha;
        SINH_PA :: XKB_KEY_Sinh_pa;
        SINH_PHA :: XKB_KEY_Sinh_pha;
        SINH_BA :: XKB_KEY_Sinh_ba;
        SINH_BHA :: XKB_KEY_Sinh_bha;
        SINH_MA :: XKB_KEY_Sinh_ma;
        SINH_MBA :: XKB_KEY_Sinh_mba;
        SINH_YA :: XKB_KEY_Sinh_ya;
        SINH_RA :: XKB_KEY_Sinh_ra;
        SINH_LA :: XKB_KEY_Sinh_la;
        SINH_VA :: XKB_KEY_Sinh_va;
        SINH_SHA :: XKB_KEY_Sinh_sha;
        SINH_SSHA :: XKB_KEY_Sinh_ssha;
        SINH_SA :: XKB_KEY_Sinh_sa;
        SINH_HA :: XKB_KEY_Sinh_ha;
        SINH_LLA :: XKB_KEY_Sinh_lla;
        SINH_FA :: XKB_KEY_Sinh_fa;
        SINH_AL :: XKB_KEY_Sinh_al;
        SINH_AA2 :: XKB_KEY_Sinh_aa2;
        SINH_AE2 :: XKB_KEY_Sinh_ae2;
        SINH_AEE2 :: XKB_KEY_Sinh_aee2;
        SINH_I2 :: XKB_KEY_Sinh_i2;
        SINH_II2 :: XKB_KEY_Sinh_ii2;
        SINH_U2 :: XKB_KEY_Sinh_u2;
        SINH_UU2 :: XKB_KEY_Sinh_uu2;
        SINH_RU2 :: XKB_KEY_Sinh_ru2;
        SINH_E2 :: XKB_KEY_Sinh_e2;
        SINH_EE2 :: XKB_KEY_Sinh_ee2;
        SINH_AI2 :: XKB_KEY_Sinh_ai2;
        SINH_O2 :: XKB_KEY_Sinh_o2;
        SINH_OO2 :: XKB_KEY_Sinh_oo2;
        SINH_AU2 :: XKB_KEY_Sinh_au2;
        SINH_LU2 :: XKB_KEY_Sinh_lu2;
        SINH_RUU2 :: XKB_KEY_Sinh_ruu2;
        SINH_LUU2 :: XKB_KEY_Sinh_luu2;
        SINH_KUNDDALIYA :: XKB_KEY_Sinh_kunddaliya;
        CAPITAL_SSHARP :: XKB_KEY_SSHARP;
        LEFTSINGLEANGLEQUOTEMARK :: XKB_KEY_leftsingleanglequotemark;
        RIGHTSINGLEANGLEQUOTEMARK :: XKB_KEY_rightsingleanglequotemark;
        XF86MODELOCK :: XKB_KEY_XF86ModeLock;
        XF86MONBRIGHTNESSUP :: XKB_KEY_XF86MonBrightnessUp;
        XF86MONBRIGHTNESSDOWN :: XKB_KEY_XF86MonBrightnessDown;
        XF86KBDLIGHTONOFF :: XKB_KEY_XF86KbdLightOnOff;
        XF86KBDBRIGHTNESSUP :: XKB_KEY_XF86KbdBrightnessUp;
        XF86KBDBRIGHTNESSDOWN :: XKB_KEY_XF86KbdBrightnessDown;
        XF86MONBRIGHTNESSCYCLE :: XKB_KEY_XF86MonBrightnessCycle;
        XF86STANDBY :: XKB_KEY_XF86Standby;
        XF86AUDIOLOWERVOLUME :: XKB_KEY_XF86AudioLowerVolume;
        XF86AUDIOMUTE :: XKB_KEY_XF86AudioMute;
        XF86AUDIORAISEVOLUME :: XKB_KEY_XF86AudioRaiseVolume;
        XF86AUDIOPLAY :: XKB_KEY_XF86AudioPlay;
        XF86AUDIOSTOP :: XKB_KEY_XF86AudioStop;
        XF86AUDIOPREV :: XKB_KEY_XF86AudioPrev;
        XF86AUDIONEXT :: XKB_KEY_XF86AudioNext;
        XF86HOMEPAGE :: XKB_KEY_XF86HomePage;
        XF86MAIL :: XKB_KEY_XF86Mail;
        XF86START :: XKB_KEY_XF86Start;
        XF86SEARCH :: XKB_KEY_XF86Search;
        XF86AUDIORECORD :: XKB_KEY_XF86AudioRecord;
        XF86CALCULATOR :: XKB_KEY_XF86Calculator;
        XF86MEMO :: XKB_KEY_XF86Memo;
        XF86TODOLIST :: XKB_KEY_XF86ToDoList;
        XF86CALENDAR :: XKB_KEY_XF86Calendar;
        XF86POWERDOWN :: XKB_KEY_XF86PowerDown;
        XF86CONTRASTADJUST :: XKB_KEY_XF86ContrastAdjust;
        XF86ROCKERUP :: XKB_KEY_XF86RockerUp;
        XF86ROCKERDOWN :: XKB_KEY_XF86RockerDown;
        XF86ROCKERENTER :: XKB_KEY_XF86RockerEnter;
        XF86BACK :: XKB_KEY_XF86Back;
        XF86FORWARD :: XKB_KEY_XF86Forward;
        XF86STOP :: XKB_KEY_XF86Stop;
        XF86REFRESH :: XKB_KEY_XF86Refresh;
        XF86POWEROFF :: XKB_KEY_XF86PowerOff;
        XF86WAKEUP :: XKB_KEY_XF86WakeUp;
        XF86EJECT :: XKB_KEY_XF86Eject;
        XF86SCREEN_SAVER :: XKB_KEY_XF86ScreenSaver;
        XF86WWW :: XKB_KEY_XF86WWW;
        XF86SLEEP :: XKB_KEY_XF86Sleep;
        XF86FAVORITES :: XKB_KEY_XF86Favorites;
        XF86AUDIOPAUSE :: XKB_KEY_XF86AudioPause;
        XF86AUDIOMEDIA :: XKB_KEY_XF86AudioMedia;
        XF86MYCOMPUTER :: XKB_KEY_XF86MyComputer;
        XF86VENDORHOME :: XKB_KEY_XF86VendorHome;
        XF86LIGHTBULB :: XKB_KEY_XF86LightBulb;
        XF86SHOP :: XKB_KEY_XF86Shop;
        XF86HISTORY :: XKB_KEY_XF86History;
        XF86OPENURL :: XKB_KEY_XF86OpenURL;
        XF86ADDFAVORITE :: XKB_KEY_XF86AddFavorite;
        XF86HOTLINKS :: XKB_KEY_XF86HotLinks;
        XF86BRIGHTNESSADJUST :: XKB_KEY_XF86BrightnessAdjust;
        XF86FINANCE :: XKB_KEY_XF86Finance;
        XF86COMMUNITY :: XKB_KEY_XF86Community;
        XF86AUDIOREWIND :: XKB_KEY_XF86AudioRewind;
        XF86BACKFORWARD :: XKB_KEY_XF86BackForward;
        XF86LAUNCH0 :: XKB_KEY_XF86Launch0;
        XF86LAUNCH1 :: XKB_KEY_XF86Launch1;
        XF86LAUNCH2 :: XKB_KEY_XF86Launch2;
        XF86LAUNCH3 :: XKB_KEY_XF86Launch3;
        XF86LAUNCH4 :: XKB_KEY_XF86Launch4;
        XF86LAUNCH5 :: XKB_KEY_XF86Launch5;
        XF86LAUNCH6 :: XKB_KEY_XF86Launch6;
        XF86LAUNCH7 :: XKB_KEY_XF86Launch7;
        XF86LAUNCH8 :: XKB_KEY_XF86Launch8;
        XF86LAUNCH9 :: XKB_KEY_XF86Launch9;
        XF86LAUNCHA :: XKB_KEY_XF86LaunchA;
        XF86LAUNCHB :: XKB_KEY_XF86LaunchB;
        XF86LAUNCHC :: XKB_KEY_XF86LaunchC;
        XF86LAUNCHD :: XKB_KEY_XF86LaunchD;
        XF86LAUNCHE :: XKB_KEY_XF86LaunchE;
        XF86LAUNCHF :: XKB_KEY_XF86LaunchF;
        XF86APPLICATIONLEFT :: XKB_KEY_XF86ApplicationLeft;
        XF86APPLICATIONRIGHT :: XKB_KEY_XF86ApplicationRight;
        XF86BOOK :: XKB_KEY_XF86Book;
        XF86CD :: XKB_KEY_XF86CD;
        XF86MEDIASELECTCD :: XKB_KEY_XF86MediaSelectCD;
        XF86CALCULATER :: XKB_KEY_XF86Calculater;
        XF86CLEAR :: XKB_KEY_XF86Clear;
        XF86CLOSE :: XKB_KEY_XF86Close;
        XF86COPY :: XKB_KEY_XF86Copy;
        XF86CUT :: XKB_KEY_XF86Cut;
        XF86DISPLAY :: XKB_KEY_XF86Display;
        XF86DOS :: XKB_KEY_XF86DOS;
        XF86DOCUMENTS :: XKB_KEY_XF86Documents;
        XF86EXCEL :: XKB_KEY_XF86Excel;
        XF86EXPLORER :: XKB_KEY_XF86Explorer;
        XF86GAME :: XKB_KEY_XF86Game;
        XF86GO :: XKB_KEY_XF86Go;
        XF86ITOUCH :: XKB_KEY_XF86iTouch;
        XF86LOGOFF :: XKB_KEY_XF86LogOff;
        XF86MARKET :: XKB_KEY_XF86Market;
        XF86MEETING :: XKB_KEY_XF86Meeting;
        XF86MENUKB :: XKB_KEY_XF86MenuKB;
        XF86MENUPB :: XKB_KEY_XF86MenuPB;
        XF86MYSITES :: XKB_KEY_XF86MySites;
        XF86NEW :: XKB_KEY_XF86New;
        XF86NEWS :: XKB_KEY_XF86News;
        XF86OFFICEHOME :: XKB_KEY_XF86OfficeHome;
        XF86OPEN :: XKB_KEY_XF86Open;
        XF86OPTION :: XKB_KEY_XF86Option;
        XF86PASTE :: XKB_KEY_XF86Paste;
        XF86PHONE :: XKB_KEY_XF86Phone;
        XF86Q :: XKB_KEY_XF86Q;
        XF86REPLY :: XKB_KEY_XF86Reply;
        XF86RELOAD :: XKB_KEY_XF86Reload;
        XF86ROTATEWINDOWS :: XKB_KEY_XF86RotateWindows;
        XF86ROTATIONPB :: XKB_KEY_XF86RotationPB;
        XF86ROTATIONKB :: XKB_KEY_XF86RotationKB;
        XF86SAVE :: XKB_KEY_XF86Save;
        XF86SCROLLUP :: XKB_KEY_XF86ScrollUp;
        XF86SCROLLDOWN :: XKB_KEY_XF86ScrollDown;
        XF86SCROLLCLICK :: XKB_KEY_XF86ScrollClick;
        XF86SEND :: XKB_KEY_XF86Send;
        XF86SPELL :: XKB_KEY_XF86Spell;
        XF86SPLITSCREEN :: XKB_KEY_XF86SplitScreen;
        XF86SUPPORT :: XKB_KEY_XF86Support;
        XF86TASKPANE :: XKB_KEY_XF86TaskPane;
        XF86TERMINAL :: XKB_KEY_XF86Terminal;
        XF86TOOLS :: XKB_KEY_XF86Tools;
        XF86TRAVEL :: XKB_KEY_XF86Travel;
        XF86USERPB :: XKB_KEY_XF86UserPB;
        XF86USER1KB :: XKB_KEY_XF86User1KB;
        XF86USER2KB :: XKB_KEY_XF86User2KB;
        XF86VIDEO :: XKB_KEY_XF86Video;
        XF86WHEELBUTTON :: XKB_KEY_XF86WheelButton;
        XF86WORD :: XKB_KEY_XF86Word;
        XF86XFER :: XKB_KEY_XF86Xfer;
        XF86ZOOMIN :: XKB_KEY_XF86ZoomIn;
        XF86ZOOMOUT :: XKB_KEY_XF86ZoomOut;
        XF86AWAY :: XKB_KEY_XF86Away;
        XF86MESSENGER :: XKB_KEY_XF86Messenger;
        XF86WEBCAM :: XKB_KEY_XF86WebCam;
        XF86MAILFORWARD :: XKB_KEY_XF86MailForward;
        XF86PICTURES :: XKB_KEY_XF86Pictures;
        XF86MUSIC :: XKB_KEY_XF86Music;
        XF86BATTERY :: XKB_KEY_XF86Battery;
        XF86BLUETOOTH :: XKB_KEY_XF86Bluetooth;
        XF86WLAN :: XKB_KEY_XF86WLAN;
        XF86UWB :: XKB_KEY_XF86UWB;
        XF86AUDIOFORWARD :: XKB_KEY_XF86AudioForward;
        XF86AUDIOREPEAT :: XKB_KEY_XF86AudioRepeat;
        XF86AUDIORANDOMPLAY :: XKB_KEY_XF86AudioRandomPlay;
        XF86SUBTITLE :: XKB_KEY_XF86Subtitle;
        XF86AUDIOCYCLETRACK :: XKB_KEY_XF86AudioCycleTrack;
        XF86CYCLEANGLE :: XKB_KEY_XF86CycleAngle;
        XF86FRAMEBACK :: XKB_KEY_XF86FrameBack;
        XF86FRAMEFORWARD :: XKB_KEY_XF86FrameForward;
        XF86TIME :: XKB_KEY_XF86Time;
        XF86SELECT :: XKB_KEY_XF86Select;
        XF86VIEW :: XKB_KEY_XF86View;
        XF86TOPMENU :: XKB_KEY_XF86TopMenu;
        XF86RED :: XKB_KEY_XF86Red;
        XF86GREEN :: XKB_KEY_XF86Green;
        XF86YELLOW :: XKB_KEY_XF86Yellow;
        XF86BLUE :: XKB_KEY_XF86Blue;
        XF86SUSPEND :: XKB_KEY_XF86Suspend;
        XF86HIBERNATE :: XKB_KEY_XF86Hibernate;
        XF86TOUCHPADTOGGLE :: XKB_KEY_XF86TouchpadToggle;
        XF86TOUCHPADON :: XKB_KEY_XF86TouchpadOn;
        XF86TOUCHPADOFF :: XKB_KEY_XF86TouchpadOff;
        XF86AUDIOMICMUTE :: XKB_KEY_XF86AudioMicMute;
        XF86KEYBOARD :: XKB_KEY_XF86Keyboard;
        XF86WWAN :: XKB_KEY_XF86WWAN;
        XF86RFKILL :: XKB_KEY_XF86RFKill;
        XF86AUDIOPRESET :: XKB_KEY_XF86AudioPreset;
        XF86ROTATIONLOCKTOGGLE :: XKB_KEY_XF86RotationLockToggle;
        XF86FULLSCREEN :: XKB_KEY_XF86FullScreen;
        XF86SWITCH_VT_1 :: XKB_KEY_XF86Switch_VT_1;
        XF86SWITCH_VT_2 :: XKB_KEY_XF86Switch_VT_2;
        XF86SWITCH_VT_3 :: XKB_KEY_XF86Switch_VT_3;
        XF86SWITCH_VT_4 :: XKB_KEY_XF86Switch_VT_4;
        XF86SWITCH_VT_5 :: XKB_KEY_XF86Switch_VT_5;
        XF86SWITCH_VT_6 :: XKB_KEY_XF86Switch_VT_6;
        XF86SWITCH_VT_7 :: XKB_KEY_XF86Switch_VT_7;
        XF86SWITCH_VT_8 :: XKB_KEY_XF86Switch_VT_8;
        XF86SWITCH_VT_9 :: XKB_KEY_XF86Switch_VT_9;
        XF86SWITCH_VT_10 :: XKB_KEY_XF86Switch_VT_10;
        XF86SWITCH_VT_11 :: XKB_KEY_XF86Switch_VT_11;
        XF86SWITCH_VT_12 :: XKB_KEY_XF86Switch_VT_12;
        XF86UNGRAB :: XKB_KEY_XF86Ungrab;
        XF86CLEARGRAB :: XKB_KEY_XF86ClearGrab;
        XF86NEXT_VMODE :: XKB_KEY_XF86Next_VMode;
        XF86PREV_VMODE :: XKB_KEY_XF86Prev_VMode;
        XF86LOGWINDOWTREE :: XKB_KEY_XF86LogWindowTree;
        XF86LOGGRABINFO :: XKB_KEY_XF86LogGrabInfo;
        XF86MEDIAPLAYPAUSE :: XKB_KEY_XF86MediaPlayPause;
        XF86EXIT :: XKB_KEY_XF86Exit;
        XF86AUDIOBASSBOOST :: XKB_KEY_XF86AudioBassBoost;
        XF86SPORT :: XKB_KEY_XF86Sport;
        XF86BRIGHTNESSAUTO :: XKB_KEY_XF86BrightnessAuto;
        XF86MONBRIGHTNESSAUTO :: XKB_KEY_XF86MonBrightnessAuto;
        XF86DISPLAYOFF :: XKB_KEY_XF86DisplayOff;
        XF86OK :: XKB_KEY_XF86OK;
        XF86GOTO :: XKB_KEY_XF86GoTo;
        XF86INFO :: XKB_KEY_XF86Info;
        XF86VENDORLOGO :: XKB_KEY_XF86VendorLogo;
        XF86MEDIASELECTPROGRAMGUIDE :: XKB_KEY_XF86MediaSelectProgramGuide;
        XF86MEDIASELECTHOME :: XKB_KEY_XF86MediaSelectHome;
        XF86MEDIALANGUAGEMENU :: XKB_KEY_XF86MediaLanguageMenu;
        XF86MEDIATITLEMENU :: XKB_KEY_XF86MediaTitleMenu;
        XF86AUDIOCHANNELMODE :: XKB_KEY_XF86AudioChannelMode;
        XF86ASPECTRATIO :: XKB_KEY_XF86AspectRatio;
        XF86MEDIASELECTPC :: XKB_KEY_XF86MediaSelectPC;
        XF86MEDIASELECTTV :: XKB_KEY_XF86MediaSelectTV;
        XF86MEDIASELECTCABLE :: XKB_KEY_XF86MediaSelectCable;
        XF86MEDIASELECTVCR :: XKB_KEY_XF86MediaSelectVCR;
        XF86MEDIASELECTVCRPLUS :: XKB_KEY_XF86MediaSelectVCRPlus;
        XF86MEDIASELECTSATELLITE :: XKB_KEY_XF86MediaSelectSatellite;
        XF86MEDIASELECTTAPE :: XKB_KEY_XF86MediaSelectTape;
        XF86MEDIASELECTRADIO :: XKB_KEY_XF86MediaSelectRadio;
        XF86MEDIASELECTTUNER :: XKB_KEY_XF86MediaSelectTuner;
        XF86MEDIAPLAYER :: XKB_KEY_XF86MediaPlayer;
        XF86MEDIASELECTTELETEXT :: XKB_KEY_XF86MediaSelectTeletext;
        XF86DVD :: XKB_KEY_XF86DVD;
        XF86MEDIASELECTDVD :: XKB_KEY_XF86MediaSelectDVD;
        XF86MEDIASELECTAUXILIARY :: XKB_KEY_XF86MediaSelectAuxiliary;
        XF86AUDIO :: XKB_KEY_XF86Audio;
        XF86CHANNELUP :: XKB_KEY_XF86ChannelUp;
        XF86CHANNELDOWN :: XKB_KEY_XF86ChannelDown;
        XF86MEDIAPLAYSLOW :: XKB_KEY_XF86MediaPlaySlow;
        XF86BREAK :: XKB_KEY_XF86Break;
        XF86NUMBERENTRYMODE :: XKB_KEY_XF86NumberEntryMode;
        XF86VIDEOPHONE :: XKB_KEY_XF86VideoPhone;
        XF86ZOOMRESET :: XKB_KEY_XF86ZoomReset;
        XF86EDITOR :: XKB_KEY_XF86Editor;
        XF86GRAPHICSEDITOR :: XKB_KEY_XF86GraphicsEditor;
        XF86PRESENTATION :: XKB_KEY_XF86Presentation;
        XF86DATABASE :: XKB_KEY_XF86Database;
        XF86VOICEMAIL :: XKB_KEY_XF86Voicemail;
        XF86ADDRESSBOOK :: XKB_KEY_XF86Addressbook;
        XF86DISPLAYTOGGLE :: XKB_KEY_XF86DisplayToggle;
        XF86SPELLCHECK :: XKB_KEY_XF86SpellCheck;
        XF86CONTEXTMENU :: XKB_KEY_XF86ContextMenu;
        XF86MEDIAREPEAT :: XKB_KEY_XF86MediaRepeat;
        XF8610CHANNELSUP :: XKB_KEY_XF8610ChannelsUp;
        XF8610CHANNELSDOWN :: XKB_KEY_XF8610ChannelsDown;
        XF86IMAGES :: XKB_KEY_XF86Images;
        XF86NOTIFICATIONCENTER :: XKB_KEY_XF86NotificationCenter;
        XF86PICKUPPHONE :: XKB_KEY_XF86PickupPhone;
        XF86HANGUPPHONE :: XKB_KEY_XF86HangupPhone;
        XF86LINKPHONE :: XKB_KEY_XF86LinkPhone;
        XF86FN :: XKB_KEY_XF86Fn;
        XF86FN_ESC :: XKB_KEY_XF86Fn_Esc;
        XF86FN_F1 :: XKB_KEY_XF86Fn_F1;
        XF86FN_F2 :: XKB_KEY_XF86Fn_F2;
        XF86FN_F3 :: XKB_KEY_XF86Fn_F3;
        XF86FN_F4 :: XKB_KEY_XF86Fn_F4;
        XF86FN_F5 :: XKB_KEY_XF86Fn_F5;
        XF86FN_F6 :: XKB_KEY_XF86Fn_F6;
        XF86FN_F7 :: XKB_KEY_XF86Fn_F7;
        XF86FN_F8 :: XKB_KEY_XF86Fn_F8;
        XF86FN_F9 :: XKB_KEY_XF86Fn_F9;
        XF86FN_F10 :: XKB_KEY_XF86Fn_F10;
        XF86FN_F11 :: XKB_KEY_XF86Fn_F11;
        XF86FN_F12 :: XKB_KEY_XF86Fn_F12;
        XF86FN_1 :: XKB_KEY_XF86Fn_1;
        XF86FN_2 :: XKB_KEY_XF86Fn_2;
        XF86FN_D :: XKB_KEY_XF86Fn_D;
        XF86FN_E :: XKB_KEY_XF86Fn_E;
        XF86FN_F :: XKB_KEY_XF86Fn_F;
        XF86FN_S :: XKB_KEY_XF86Fn_S;
        XF86FN_B :: XKB_KEY_XF86Fn_B;
        XF86FNRIGHTSHIFT :: XKB_KEY_XF86FnRightShift;
        XF86NUMERIC0 :: XKB_KEY_XF86Numeric0;
        XF86NUMERIC1 :: XKB_KEY_XF86Numeric1;
        XF86NUMERIC2 :: XKB_KEY_XF86Numeric2;
        XF86NUMERIC3 :: XKB_KEY_XF86Numeric3;
        XF86NUMERIC4 :: XKB_KEY_XF86Numeric4;
        XF86NUMERIC5 :: XKB_KEY_XF86Numeric5;
        XF86NUMERIC6 :: XKB_KEY_XF86Numeric6;
        XF86NUMERIC7 :: XKB_KEY_XF86Numeric7;
        XF86NUMERIC8 :: XKB_KEY_XF86Numeric8;
        XF86NUMERIC9 :: XKB_KEY_XF86Numeric9;
        XF86NUMERICSTAR :: XKB_KEY_XF86NumericStar;
        XF86NUMERICPOUND :: XKB_KEY_XF86NumericPound;
        XF86NUMERICA :: XKB_KEY_XF86NumericA;
        XF86NUMERICB :: XKB_KEY_XF86NumericB;
        XF86NUMERICC :: XKB_KEY_XF86NumericC;
        XF86NUMERICD :: XKB_KEY_XF86NumericD;
        XF86CAMERAFOCUS :: XKB_KEY_XF86CameraFocus;
        XF86WPSBUTTON :: XKB_KEY_XF86WPSButton;
        XF86CAMERAZOOMIN :: XKB_KEY_XF86CameraZoomIn;
        XF86CAMERAZOOMOUT :: XKB_KEY_XF86CameraZoomOut;
        XF86CAMERAUP :: XKB_KEY_XF86CameraUp;
        XF86CAMERADOWN :: XKB_KEY_XF86CameraDown;
        XF86CAMERALEFT :: XKB_KEY_XF86CameraLeft;
        XF86CAMERARIGHT :: XKB_KEY_XF86CameraRight;
        XF86ATTENDANTON :: XKB_KEY_XF86AttendantOn;
        XF86ATTENDANTOFF :: XKB_KEY_XF86AttendantOff;
        XF86ATTENDANTTOGGLE :: XKB_KEY_XF86AttendantToggle;
        XF86LIGHTSTOGGLE :: XKB_KEY_XF86LightsToggle;
        XF86ALSTOGGLE :: XKB_KEY_XF86ALSToggle;
        XF86REFRESHRATETOGGLE :: XKB_KEY_XF86RefreshRateToggle;
        XF86BUTTONCONFIG :: XKB_KEY_XF86Buttonconfig;
        XF86TASKMANAGER :: XKB_KEY_XF86Taskmanager;
        XF86JOURNAL :: XKB_KEY_XF86Journal;
        XF86CONTROLPANEL :: XKB_KEY_XF86ControlPanel;
        XF86APPSELECT :: XKB_KEY_XF86AppSelect;
        XF86SCREENSAVER :: XKB_KEY_XF86Screensaver;
        XF86VOICECOMMAND :: XKB_KEY_XF86VoiceCommand;
        XF86ASSISTANT :: XKB_KEY_XF86Assistant;
        XF86EMOJIPICKER :: XKB_KEY_XF86EmojiPicker;
        XF86DICTATE :: XKB_KEY_XF86Dictate;
        XF86CAMERAACCESSENABLE :: XKB_KEY_XF86CameraAccessEnable;
        XF86CAMERAACCESSDISABLE :: XKB_KEY_XF86CameraAccessDisable;
        XF86CAMERAACCESSTOGGLE :: XKB_KEY_XF86CameraAccessToggle;
        XF86ACCESSIBILITY :: XKB_KEY_XF86Accessibility;
        XF86DONOTDISTURB :: XKB_KEY_XF86DoNotDisturb;
        XF86BRIGHTNESSMIN :: XKB_KEY_XF86BrightnessMin;
        XF86BRIGHTNESSMAX :: XKB_KEY_XF86BrightnessMax;
        XF86ELECTRONICPRIVACYSCREENON :: XKB_KEY_XF86ElectronicPrivacyScreenOn;
        XF86ELECTRONICPRIVACYSCREENOFF :: XKB_KEY_XF86ElectronicPrivacyScreenOff;
        XF86ACTIONONSELECTION :: XKB_KEY_XF86ActionOnSelection;
        XF86CONTEXTUALINSERT :: XKB_KEY_XF86ContextualInsert;
        XF86CONTEXTUALQUERY :: XKB_KEY_XF86ContextualQuery;
        XF86KBDINPUTASSISTPREV :: XKB_KEY_XF86KbdInputAssistPrev;
        XF86KBDINPUTASSISTNEXT :: XKB_KEY_XF86KbdInputAssistNext;
        XF86KBDINPUTASSISTPREVGROUP :: XKB_KEY_XF86KbdInputAssistPrevgroup;
        XF86KBDINPUTASSISTNEXTGROUP :: XKB_KEY_XF86KbdInputAssistNextgroup;
        XF86KBDINPUTASSISTACCEPT :: XKB_KEY_XF86KbdInputAssistAccept;
        XF86KBDINPUTASSISTCANCEL :: XKB_KEY_XF86KbdInputAssistCancel;
        XF86RIGHTUP :: XKB_KEY_XF86RightUp;
        XF86RIGHTDOWN :: XKB_KEY_XF86RightDown;
        XF86LEFTUP :: XKB_KEY_XF86LeftUp;
        XF86LEFTDOWN :: XKB_KEY_XF86LeftDown;
        XF86ROOTMENU :: XKB_KEY_XF86RootMenu;
        XF86MEDIATOPMENU :: XKB_KEY_XF86MediaTopMenu;
        XF86NUMERIC11 :: XKB_KEY_XF86Numeric11;
        XF86NUMERIC12 :: XKB_KEY_XF86Numeric12;
        XF86AUDIODESC :: XKB_KEY_XF86AudioDesc;
        XF863DMODE :: XKB_KEY_XF863DMode;
        XF86NEXTFAVORITE :: XKB_KEY_XF86NextFavorite;
        XF86STOPRECORD :: XKB_KEY_XF86StopRecord;
        XF86PAUSERECORD :: XKB_KEY_XF86PauseRecord;
        XF86VOD :: XKB_KEY_XF86VOD;
        XF86UNMUTE :: XKB_KEY_XF86Unmute;
        XF86FASTREVERSE :: XKB_KEY_XF86FastReverse;
        XF86SLOWREVERSE :: XKB_KEY_XF86SlowReverse;
        XF86DATA :: XKB_KEY_XF86Data;
        XF86ONSCREENKEYBOARD :: XKB_KEY_XF86OnScreenKeyboard;
        XF86PRIVACYSCREENTOGGLE :: XKB_KEY_XF86PrivacyScreenToggle;
        XF86SELECTIVESCREENSHOT :: XKB_KEY_XF86SelectiveScreenshot;
        XF86NEXTELEMENT :: XKB_KEY_XF86NextElement;
        XF86PREVIOUSELEMENT :: XKB_KEY_XF86PreviousElement;
        XF86AUTOPILOTENGAGETOGGLE :: XKB_KEY_XF86AutopilotEngageToggle;
        XF86MARKWAYPOINT :: XKB_KEY_XF86MarkWaypoint;
        XF86SOS :: XKB_KEY_XF86Sos;
        XF86NAVCHART :: XKB_KEY_XF86NavChart;
        XF86FISHINGCHART :: XKB_KEY_XF86FishingChart;
        XF86SINGLERANGERADAR :: XKB_KEY_XF86SingleRangeRadar;
        XF86DUALRANGERADAR :: XKB_KEY_XF86DualRangeRadar;
        XF86RADAROVERLAY :: XKB_KEY_XF86RadarOverlay;
        XF86TRADITIONALSONAR :: XKB_KEY_XF86TraditionalSonar;
        XF86CLEARVUSONAR :: XKB_KEY_XF86ClearvuSonar;
        XF86SIDEVUSONAR :: XKB_KEY_XF86SidevuSonar;
        XF86NAVINFO :: XKB_KEY_XF86NavInfo;
        XF86MACRO1 :: XKB_KEY_XF86Macro1;
        XF86MACRO2 :: XKB_KEY_XF86Macro2;
        XF86MACRO3 :: XKB_KEY_XF86Macro3;
        XF86MACRO4 :: XKB_KEY_XF86Macro4;
        XF86MACRO5 :: XKB_KEY_XF86Macro5;
        XF86MACRO6 :: XKB_KEY_XF86Macro6;
        XF86MACRO7 :: XKB_KEY_XF86Macro7;
        XF86MACRO8 :: XKB_KEY_XF86Macro8;
        XF86MACRO9 :: XKB_KEY_XF86Macro9;
        XF86MACRO10 :: XKB_KEY_XF86Macro10;
        XF86MACRO11 :: XKB_KEY_XF86Macro11;
        XF86MACRO12 :: XKB_KEY_XF86Macro12;
        XF86MACRO13 :: XKB_KEY_XF86Macro13;
        XF86MACRO14 :: XKB_KEY_XF86Macro14;
        XF86MACRO15 :: XKB_KEY_XF86Macro15;
        XF86MACRO16 :: XKB_KEY_XF86Macro16;
        XF86MACRO17 :: XKB_KEY_XF86Macro17;
        XF86MACRO18 :: XKB_KEY_XF86Macro18;
        XF86MACRO19 :: XKB_KEY_XF86Macro19;
        XF86MACRO20 :: XKB_KEY_XF86Macro20;
        XF86MACRO21 :: XKB_KEY_XF86Macro21;
        XF86MACRO22 :: XKB_KEY_XF86Macro22;
        XF86MACRO23 :: XKB_KEY_XF86Macro23;
        XF86MACRO24 :: XKB_KEY_XF86Macro24;
        XF86MACRO25 :: XKB_KEY_XF86Macro25;
        XF86MACRO26 :: XKB_KEY_XF86Macro26;
        XF86MACRO27 :: XKB_KEY_XF86Macro27;
        XF86MACRO28 :: XKB_KEY_XF86Macro28;
        XF86MACRO29 :: XKB_KEY_XF86Macro29;
        XF86MACRO30 :: XKB_KEY_XF86Macro30;
        XF86MACRORECORDSTART :: XKB_KEY_XF86MacroRecordStart;
        XF86MACRORECORDSTOP :: XKB_KEY_XF86MacroRecordStop;
        XF86MACROPRESETCYCLE :: XKB_KEY_XF86MacroPresetCycle;
        XF86MACROPRESET1 :: XKB_KEY_XF86MacroPreset1;
        XF86MACROPRESET2 :: XKB_KEY_XF86MacroPreset2;
        XF86MACROPRESET3 :: XKB_KEY_XF86MacroPreset3;
        XF86KBDLCDMENU1 :: XKB_KEY_XF86KbdLcdMenu1;
        XF86KBDLCDMENU2 :: XKB_KEY_XF86KbdLcdMenu2;
        XF86KBDLCDMENU3 :: XKB_KEY_XF86KbdLcdMenu3;
        XF86KBDLCDMENU4 :: XKB_KEY_XF86KbdLcdMenu4;
        XF86KBDLCDMENU5 :: XKB_KEY_XF86KbdLcdMenu5;
        XF86PERFORMANCEMODE :: XKB_KEY_XF86PerformanceMode;
        SUNFA_GRAVE :: XKB_KEY_SunFA_Grave;
        SUNFA_CIRCUM :: XKB_KEY_SunFA_Circum;
        SUNFA_TILDE :: XKB_KEY_SunFA_Tilde;
        SUNFA_ACUTE :: XKB_KEY_SunFA_Acute;
        SUNFA_DIAERESIS :: XKB_KEY_SunFA_Diaeresis;
        SUNFA_CEDILLA :: XKB_KEY_SunFA_Cedilla;
        SUNF36 :: XKB_KEY_SunF36;
        SUNF37 :: XKB_KEY_SunF37;
        SUNSYS_REQ :: XKB_KEY_SunSys_Req;
        SUNPRINT_SCREEN :: XKB_KEY_SunPrint_Screen;
        SUNCOMPOSE :: XKB_KEY_SunCompose;
        SUNALTGRAPH :: XKB_KEY_SunAltGraph;
        SUNPAGEUP :: XKB_KEY_SunPageUp;
        SUNPAGEDOWN :: XKB_KEY_SunPageDown;
        SUNUNDO :: XKB_KEY_SunUndo;
        SUNAGAIN :: XKB_KEY_SunAgain;
        SUNFIND :: XKB_KEY_SunFind;
        SUNSTOP :: XKB_KEY_SunStop;
        SUNPROPS :: XKB_KEY_SunProps;
        SUNFRONT :: XKB_KEY_SunFront;
        SUNCOPY :: XKB_KEY_SunCopy;
        SUNOPEN :: XKB_KEY_SunOpen;
        SUNPASTE :: XKB_KEY_SunPaste;
        SUNCUT :: XKB_KEY_SunCut;
        SUNPOWERSWITCH :: XKB_KEY_SunPowerSwitch;
        SUNAUDIOLOWERVOLUME :: XKB_KEY_SunAudioLowerVolume;
        SUNAUDIOMUTE :: XKB_KEY_SunAudioMute;
        SUNAUDIORAISEVOLUME :: XKB_KEY_SunAudioRaiseVolume;
        SUNVIDEODEGAUSS :: XKB_KEY_SunVideoDegauss;
        SUNVIDEOLOWERBRIGHTNESS :: XKB_KEY_SunVideoLowerBrightness;
        SUNVIDEORAISEBRIGHTNESS :: XKB_KEY_SunVideoRaiseBrightness;
        SUNPOWERSWITCHSHIFT :: XKB_KEY_SunPowerSwitchShift;
        DRING_ACCENT :: XKB_KEY_Dring_accent;
        DCIRCUMFLEX_ACCENT :: XKB_KEY_Dcircumflex_accent;
        DCEDILLA_ACCENT :: XKB_KEY_Dcedilla_accent;
        DACUTE_ACCENT :: XKB_KEY_Dacute_accent;
        DGRAVE_ACCENT :: XKB_KEY_Dgrave_accent;
        DTILDE :: XKB_KEY_Dtilde;
        DDIAERESIS :: XKB_KEY_Ddiaeresis;
        DREMOVE :: XKB_KEY_DRemove;
        HPCLEARLINE :: XKB_KEY_hpClearLine;
        HPINSERTLINE :: XKB_KEY_hpInsertLine;
        HPDELETELINE :: XKB_KEY_hpDeleteLine;
        HPINSERTCHAR :: XKB_KEY_hpInsertChar;
        HPDELETECHAR :: XKB_KEY_hpDeleteChar;
        HPBACKTAB :: XKB_KEY_hpBackTab;
        HPKP_BACKTAB :: XKB_KEY_hpKP_BackTab;
        HPMODELOCK1 :: XKB_KEY_hpModelock1;
        HPMODELOCK2 :: XKB_KEY_hpModelock2;
        HPRESET :: XKB_KEY_hpReset;
        HPSYSTEM :: XKB_KEY_hpSystem;
        HPUSER :: XKB_KEY_hpUser;
        HPMUTE_ACUTE :: XKB_KEY_hpmute_acute;
        HPMUTE_GRAVE :: XKB_KEY_hpmute_grave;
        HPMUTE_ASCIICIRCUM :: XKB_KEY_hpmute_asciicircum;
        HPMUTE_DIAERESIS :: XKB_KEY_hpmute_diaeresis;
        HPMUTE_ASCIITILDE :: XKB_KEY_hpmute_asciitilde;
        HPLIRA :: XKB_KEY_hplira;
        HPGUILDER :: XKB_KEY_hpguilder;
        HPYDIAERESIS :: XKB_KEY_hpYdiaeresis;
        HPIO :: XKB_KEY_hpIO;
        HPLONGMINUS :: XKB_KEY_hplongminus;
        HPBLOCK :: XKB_KEY_hpblock;
        OSFCOPY :: XKB_KEY_osfCopy;
        OSFCUT :: XKB_KEY_osfCut;
        OSFPASTE :: XKB_KEY_osfPaste;
        OSFBACKTAB :: XKB_KEY_osfBackTab;
        OSFBACKSPACE :: XKB_KEY_osfBackSpace;
        OSFCLEAR :: XKB_KEY_osfClear;
        OSFESCAPE :: XKB_KEY_osfEscape;
        OSFADDMODE :: XKB_KEY_osfAddMode;
        OSFPRIMARYPASTE :: XKB_KEY_osfPrimaryPaste;
        OSFQUICKPASTE :: XKB_KEY_osfQuickPaste;
        OSFPAGELEFT :: XKB_KEY_osfPageLeft;
        OSFPAGEUP :: XKB_KEY_osfPageUp;
        OSFPAGEDOWN :: XKB_KEY_osfPageDown;
        OSFPAGERIGHT :: XKB_KEY_osfPageRight;
        OSFACTIVATE :: XKB_KEY_osfActivate;
        OSFMENUBAR :: XKB_KEY_osfMenuBar;
        OSFLEFT :: XKB_KEY_osfLeft;
        OSFUP :: XKB_KEY_osfUp;
        OSFRIGHT :: XKB_KEY_osfRight;
        OSFDOWN :: XKB_KEY_osfDown;
        OSFENDLINE :: XKB_KEY_osfEndLine;
        OSFBEGINLINE :: XKB_KEY_osfBeginLine;
        OSFENDDATA :: XKB_KEY_osfEndData;
        OSFBEGINDATA :: XKB_KEY_osfBeginData;
        OSFPREVMENU :: XKB_KEY_osfPrevMenu;
        OSFNEXTMENU :: XKB_KEY_osfNextMenu;
        OSFPREVFIELD :: XKB_KEY_osfPrevField;
        OSFNEXTFIELD :: XKB_KEY_osfNextField;
        OSFSELECT :: XKB_KEY_osfSelect;
        OSFINSERT :: XKB_KEY_osfInsert;
        OSFUNDO :: XKB_KEY_osfUndo;
        OSFMENU :: XKB_KEY_osfMenu;
        OSFCANCEL :: XKB_KEY_osfCancel;
        OSFHELP :: XKB_KEY_osfHelp;
        OSFSELECTALL :: XKB_KEY_osfSelectAll;
        OSFDESELECTALL :: XKB_KEY_osfDeselectAll;
        OSFRESELECT :: XKB_KEY_osfReselect;
        OSFEXTEND :: XKB_KEY_osfExtend;
        OSFRESTORE :: XKB_KEY_osfRestore;
        OSFDELETE :: XKB_KEY_osfDelete;
        RESET :: XKB_KEY_Reset;
        SYSTEM :: XKB_KEY_System;
        USER :: XKB_KEY_User;
        CLEARLINE :: XKB_KEY_ClearLine;
        INSERTLINE :: XKB_KEY_InsertLine;
        DELETELINE :: XKB_KEY_DeleteLine;
        INSERTCHAR :: XKB_KEY_InsertChar;
        DELETECHAR :: XKB_KEY_DeleteChar;
        BACKTAB :: XKB_KEY_BackTab;
        KP_BACKTAB :: XKB_KEY_KP_BackTab;
        EXT16BIT_L :: XKB_KEY_Ext16bit_L;
        EXT16BIT_R :: XKB_KEY_Ext16bit_R;
        MUTE_ACUTE :: XKB_KEY_mute_acute;
        MUTE_GRAVE :: XKB_KEY_mute_grave;
        MUTE_ASCIICIRCUM :: XKB_KEY_mute_asciicircum;
        MUTE_DIAERESIS :: XKB_KEY_mute_diaeresis;
        MUTE_ASCIITILDE :: XKB_KEY_mute_asciitilde;
        LIRA :: XKB_KEY_lira;
        GUILDER :: XKB_KEY_guilder;
        IO :: XKB_KEY_IO;
        LONGMINUS :: XKB_KEY_longminus;
        BLOCK :: XKB_KEY_block;
    } else #if OS == .MACOS {
        A :: 0x00;
        S :: 0x01;
        D :: 0x02;
        F :: 0x03;
        H :: 0x04;
        G :: 0x05;
        Z :: 0x06;
        X :: 0x07;
        C :: 0x08;
        V :: 0x09;
        B :: 0x0B;
        Q :: 0x0C;
        W :: 0x0D;
        E :: 0x0E;
        R :: 0x0F;
        Y :: 0x10;
        T :: 0x11;
        DIGIT_1 :: 0x12;
        DIGIT_2 :: 0x13;
        DIGIT_3 :: 0x14;
        DIGIT_4 :: 0x15;
        DIGIT_6 :: 0x16;
        DIGIT_5 :: 0x17;
        EQUAL :: 0x18;
        DIGIT_9 :: 0x19;
        DIGIT_7 :: 0x1A;
        MINUS :: 0x1B;
        DIGIT_8 :: 0x1C;
        DIGIT_0 :: 0x1D;
        BRACKET_RIGHT :: 0x1E;
        O :: 0x1F;
        U :: 0x20;
        BRACKET_LEFT :: 0x21;
        I :: 0x22;
        P :: 0x23;
        L :: 0x25;
        J :: 0x26;
        APOSTROPHE :: 0x27;
        K :: 0x28;
        SEMICOLON :: 0x29;
        BACKSLASH :: 0x2A;
        COMMA :: 0x2B;
        SLASH :: 0x2C;
        N :: 0x2D;
        M :: 0x2E;
        PERIOD :: 0x2F;
        GRAVE :: 0x32;
        KP_DECIMAL :: 0x41;
        KP_MULTIPLY :: 0x43;
        KP_ADD :: 0x45;
        CLEAR :: 0x47;
        KP_DIVIDE :: 0x4B;
        KP_ENTER :: 0x4C;
        KP_SUBTRACT :: 0x4E;
        KP_EQUAL :: 0x51;
        KP_0 :: 0x52;
        KP_1 :: 0x53;
        KP_2 :: 0x54;
        KP_3 :: 0x55;
        KP_4 :: 0x56;
        KP_5 :: 0x57;
        KP_6 :: 0x58;
        KP_7 :: 0x59;
        KP_8 :: 0x5B;
        KP_9 :: 0x5C;

        ENTER :: 0x24;
        TAB :: 0x30;
        SPACE :: 0x31;
        BACKSPACE :: 0x33;
        ESCAPE :: 0x35;
        SUPER_LEFT :: 0x37;
        SHIFT_LEFT :: 0x38;
        CAPS_LOCK :: 0x39;
        ALT_LEFT :: 0x3A;
        CONTROL_LEFT :: 0x3B;
        SUPER_RIGHT :: 0x36;
        SHIFT_RIGHT :: 0x3C;
        ALT_RIGHT :: 0x3D;
        CONTROL_RIGHT :: 0x3E;
        FUNCTION :: 0x3F;
        F17 :: 0x40;
        XF86AUDIORAISEVOLUME :: 0x48;
        XF86AUDIOLOWERVOLUME :: 0x49;
        XF86AUDIOMUTE :: 0x4A;
        F18 :: 0x4F;
        F19 :: 0x50;
        F20 :: 0x5A;
        F5 :: 0x60;
        F6 :: 0x61;
        F7 :: 0x62;
        F3 :: 0x63;
        F8 :: 0x64;
        F9 :: 0x65;
        F11 :: 0x67;
        F13 :: 0x69;
        F16 :: 0x6A;
        F14 :: 0x6B;
        F10 :: 0x6D;
        MENU :: 0x6E;
        F12 :: 0x6F;
        F15 :: 0x71;
        HELP :: 0x72;
        HOME :: 0x73;
        PAGE_UP :: 0x74;
        DELETE :: 0x75;
        F4 :: 0x76;
        END :: 0x77;
        F2 :: 0x78;
        PAGE_DOWN :: 0x79;
        F1 :: 0x7A;
        ARROW_LEFT :: 0x7B;
        ARROW_RIGHT :: 0x7C;
        ARROW_DOWN :: 0x7D;
        ARROW_UP :: 0x7E;

        SECTION :: 0x0A;

        YEN :: 0x5D;
        UNDERSCORE :: 0x5E;
        KP_SEPARATOR :: 0x5F;
        EISU_TOGGLE :: 0x66;
        KANA_SWITCH :: 0x68;
    }
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
    } else #if OS == .MACOS {
        LEFT;
        RIGHT;
        MIDDLE;
        BACK;
        FORWARD;
    }
};
is_mouse_held :: (button := Mouse_Button.LEFT) -> bool {
    using context.forbear;
    return window.pointer_held[button] && window.pointer_inside;
}
on_click :: (button := Mouse_Button.LEFT) -> bool {
    using context.forbear;
    if on_mouse_up(button) {
        measurement, defined := get_measurement();
        assert(defined, "the measurement should exist if is_mouse_inside is true");
        press_position := window.pointer_press_position[button];
        return press_position.x >= measurement.position.x &&
               press_position.y >= measurement.position.y &&
               press_position.x <= measurement.position.x + measurement.size.x &&
               press_position.y <= measurement.position.y + measurement.size.y;
    } else {
        return false;
    }
}
// currently only supported on wayland
get_text_input :: () -> string {
    using context.forbear;
    return window.text;
}
on_key_down :: (
    key: Key,
    // an operating-system defined repetition rate was reached for the given key. on_key_down only runs once, this runs
    // every few frames depending on the operating system seettings.
    on_repeat := false
) -> bool {
    using context.forbear;
    return array_find(window.keys_pressed, key) ||
        (on_repeat && array_find(window.keys_repeated, key));
}
on_key_up :: (key: Key) -> bool {
    using context.forbear;
    return array_find(window.keys_released, key);
}
is_key_held :: (key: Key) -> bool {
    using context.forbear;
    return array_find(window.keys_held, key);
}
// TOOD: scrolling events
on_mouse_down :: (button := Mouse_Button.LEFT) -> bool {
    using context.forbear;
    return window.pointer_pressed[button] && is_mouse_inside();
}
on_mouse_up :: (button := Mouse_Button.LEFT) -> bool {
    using context.forbear;
    return window.pointer_released[button] && is_mouse_inside();
}
get_justification :: (element: *Element, direction: Direction) -> Alignment #expand {
    if direction == Direction.HORIZONTAL {
        return element.style.x_justification;
    } else {
        return element.style.y_justification;
    }
}
get_preferred_size :: (element: *Element, direction: Direction) -> Sizing #expand {
    if direction == Direction.HORIZONTAL {
        return element.style.width;
    } else {
        return element.style.height;
    }
}
should_fit_min :: (element: *Element, direction: Direction) -> bool #expand {
    if direction == .HORIZONTAL {
        return isnan(element.style.min_width) && element.style.width.kind != .FIXED;
    } else {
        return isnan(element.style.min_height) && element.style.height.kind != .FIXED;
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
outer_size :: (element: Element, direction: Direction) -> float {
    margin := get(element.style.margin, direction);
    return get(element.size, direction) + margin.x + margin.y;

}
inner_size :: (element: Element, direction: Direction) -> float {
    return get(element.size, direction) - fitting_base(element, direction);
}
fitting_base :: (element: Element, direction: Direction) -> float {
    padding_axis := get(element.style.padding, direction);
    padding := padding_axis.x + padding_axis.y;
    border_axis := get(element.style.border_width, direction);
    border := border_axis.x + border_axis.y;
    return padding + border;
}

Element_Tree :: [..]Element;
append_to_element_tree :: (element_tree: *Element_Tree, parent_index: s64 = -1) -> pointer: *Element, index: s64 {
    push_allocator(context.forbear.persistent_allocator);

    index := element_tree.count;
    if index != 0 && parent_index == -1 {
        log_error("multiple root elements are not allowed");
        exit(-1);
    }

    element := Element.{
        parent = parent_index,
        tree = element_tree,
    };
    if parent_index != -1 {
        parent := *element_tree.*[parent_index];
        if parent.last_child != -1 {
            element_tree.*[parent.last_child].next_sibling = index;
        }
        element.previous_sibling = parent.last_child;
        if parent.first_child == -1 {
            parent.first_child = index;
        }
        parent.last_child = index;
    }
    array_add(element_tree, element);
    return *element_tree.*[index], index;
}
// beware that this pointer might be come invalid if you define one more element
get_element :: (element_index: s64) -> *Element {
    using context.forbear;
    return *element_tree[element_index];
}

Element_Opening_Data :: struct {
    parent_index: s64;
    scope_key: u64;
    base_style: Base_Style;
    element_index: s64;
};
// intermediary API that's used from adapters, such as the javascript one. when in jai, use `element`
open_element :: (style: Style, key: u64) -> previous_stack_state: Element_Opening_Data {
    parent_index := context.forbear.parent_index;
    element, index := append_to_element_tree(*context.forbear.element_tree, parent_index);
    previous_base_style := context.forbear.base_style;
    complete_with(style, context.forbear.base_style, *element.style);
    context.forbear.base_style = from(element.style);
    if style.z_index < U16_MAX {
        element.z = style.z_index;
    } else if parent_index != -1 {
        parent := context.forbear.element_tree[parent_index];
        if parent.z < U16_MAX {
            element.z = parent.z + 1;
        } else {
            element.z = parent.z;
        }
    }
    element.key = key;
    if element.style.width.kind == {
        // we don't handle FIT or GROW since the element already has the right width by default
        case Sizing.Kind.FIXED;
            element.size.x = element.style.width.fixed;
    }
    if element.style.height.kind == {
        // we don't handle FIT or GROW since the element already has the right width by default
        case Sizing.Kind.FIXED;
            element.size.y = element.style.height.fixed;
    }
    if !isnan(element.style.min_width) {
        element.min_size.x = element.style.min_width;
    } else if element.style.width.kind == .FIXED {
        element.min_size.x = element.style.width.fixed;
    }
    if !isnan(element.style.min_height) {
        element.min_size.y = element.style.min_height;
    } else if element.style.height.kind == .FIXED {
        element.min_size.y = element.style.height.fixed;
    }
    if !isnan(element.style.max_width) {
        element.max_size.x = element.style.max_width;
    } else if element.style.width.kind == .FIXED {
        element.max_size.x = element.style.width.fixed;
    }
    if !isnan(element.style.max_height) {
        element.max_size.y = element.style.max_height;
    } else if element.style.height.kind == .FIXED {
        element.max_size.y = element.style.height.fixed;
    }

    element.size.x = clamp(element.size.x, element.min_size.x, element.max_size.x);
    element.size.y = clamp(element.size.y, element.min_size.y, element.max_size.y);

    previous_parent_index := parent_index;
    previous_scope_key := context.forbear.scope_key;
    context.forbear.parent_index = index;
    context.forbear.scope_key = element.key;

    if element.style.width.kind == Sizing.Kind.FIT {
        element.size.x = fitting_base(element, Direction.HORIZONTAL);
    }
    if element.style.width.kind != Sizing.Kind.FIXED && isnan(element.style.min_width) {
        element.min_size.x = fitting_base(element, Direction.HORIZONTAL);
    }
    if element.style.height.kind == Sizing.Kind.FIT {
        element.size.y = fitting_base(element, Direction.VERTICAL);
    }
    if element.style.height.kind != Sizing.Kind.FIXED && isnan(element.style.min_height) {
        element.min_size.y = fitting_base(element, Direction.VERTICAL);
    }
    // if (isElementActive()) {
    //     setCursor(result.ptr.style.cursor);
    // }

    return Element_Opening_Data.{
        base_style = previous_base_style,
        scope_key = previous_scope_key,
        parent_index = previous_parent_index,
        element_index = index,
    };
}
close_element :: (using data: Element_Opening_Data, source_location := "") {
    element := *context.forbear.element_tree[element_index];
    element.size.x = clamp(element.size.x, element.min_size.x, element.max_size.x);
    element.size.y = clamp(element.size.y, element.min_size.y, element.max_size.y);

    measurement, defined := get_measurement();
    if defined && element.state_size != measurement.state_size {
        if source_location.count > 0 {
            log_error(
                "%: this element called state() a different number of times than last frame",
                source_location
            );
        } else {
            log_error("an element called state() a different number of times than last frame");
        }
        exit(-1);
    }

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
        // we use the caller location here
        key = fnv1a_hash(location.fully_pathed_filename.data, location.fully_pathed_filename.count);
        key = fnv1a_hash(cast(u64) location.line_number, key);
        key = fnv1a_hash(cast(u64) location.character_number, key);
    }
    if context.forbear.scope_key != U64_MAX {
        key = fnv1a_hash(context.forbear.scope_key, key);
    }

    opening := open_element(style, key);
    #insert body;
    close_element(opening, tprint("%:%:%", location.fully_pathed_filename, location.line_number, location.character_number));
    return opening.element_index;
}
element :: (body: Code, location := #caller_location) -> s64 #expand {
    return element(body = body, location = location);
}
element :: (style: Style, body: Code, location := #caller_location) -> s64 #expand {
    return element(style = style, manual_key = "", body = body, location = location);
}

freetype_library: FT_Library;
shaping_context: *kbts_shape_context;
// TODO: should this be a global? the idea is mainly that we have a unique id for all fonts created we can keep caching and
// such apart between different fonts that might all be used for rendering
font_counter: u16;
state_buffers: [2][16 * 1024 * 1024]u8 #align 16;
state_current: s64;
state_used: s64;
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
    raster_face: FT_Face;
    shaping_font: *kbts_font;
    key: u16;

    // kept track of so that this can be set during kbts text shaping
    weight: u16 = U16_MAX;

    // prev_cache: Shaping_Cache;
    // next_cache: Shaping_Cache;
};
// TOOD: handle errors for all of the freetype calls
init_font :: (font: *Font, memory: string) {
    if freetype_library == null {
        FT_Init_FreeType(*freetype_library);
        // TODO: implement subpixel font rendering and auto enable in lower DPI
        // environments to match browser behavior.
        //
        // FT_Library_SetLcdFilter(freetype_library, FT_LCD_FILTER_DEFAULT);
    }
    if shaping_context == null {
        shaping_context = kbts_CreateShapeContext(null, null);
    }
    FT_New_Memory_Face(freetype_library, memory.data, memory.count, 0, *font.raster_face);
    // TODO: judege if we should support more than unicode here
    assert(font.raster_face.charmap.encoding == FT_Encoding.UNICODE);

    font.shaping_font = kbts_ShapePushFontFromMemory(shaping_context, memory.data, xx memory.count, 0);
    font.key = font_counter;
    font_counter += 1;
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
    defer FT_Done_MM_Var(freetype_library, mm);

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
            coords[i] = clamp(cast(s64)weight * 65536, xx a.minimum, xx a.maximum);
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
        shaping_context,
        xx kbts_direction_enum.KBTS_DIRECTION_LTR,
        xx kbts_language_enum.KBTS_LANGUAGE_DONT_KNOW
    );
    WGHT : u32 : 0x77676874;
    if font.weight != U16_MAX {
        kbts_ShapePushGlobalVariation(shaping_context, WGHT, cast(float) font.weight);
    }
    kbts_ShapeUtf8(
        shaping_context,
        content.data,
        xx content.count,
        xx kbts_user_id_generation_mode_enum.KBTS_USER_ID_GENERATION_MODE_CODEPOINT_INDEX
    );
    if font.weight != U16_MAX {
        kbts_ShapePopGlobalVariation(shaping_context, WGHT);
    }
    kbts_ShapeEnd(shaping_context);

    run: kbts_run;
    pen: Vector2;
    // the advance local to this word
    word_advance: Vector2;
    while (kbts_ShapeRun(shaping_context, *run) != 0) {
        shaping_glyph: *kbts_glyph;
        while (kbts_GlyphIteratorNext(*run.Glyphs, *shaping_glyph) != 0) {
            shape_codepoint: kbts_shape_codepoint;
            if kbts_ShapeGetShapeCodepoint(shaping_context, shaping_glyph.UserIdOrCodepointIndex, *shape_codepoint) == 0 {
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
        element := *context.forbear.element_tree[context.forbear.element_tree.count - 1];
        rounded_font_size := round_font_size(element.style.font_size * (cast(float) context.forbear.window.scale));
        set_weight(element.style.font, element.style.font_weight);
        set_font_size(element.style.font, rounded_font_size);
        element.glyphs = shape_text(element.style.font, element.style.text_wrapping, content);
        font_units_to_point := get_font_units_to_pixel(element.style.font, rounded_font_size) / (cast(float) context.forbear.window.scale);
        element.size = Vector2.{element.glyphs.max_size.x, element.glyphs.min_size.y} * font_units_to_point;
        element.min_size = element.glyphs.min_size * font_units_to_point;
        element.max_size = element.glyphs.max_size * font_units_to_point;

        if element.parent != -1 {
            parent := context.forbear.element_tree[element.parent];
            if parent.style.cursor == .DEFAULT {
                element.style.cursor = .TEXT;
            }
            element.style.x_justification = parent.style.x_justification;
            element.style.y_justification = parent.style.y_justification;
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

Forbear :: struct {
    element_tree: Element_Tree;
    measurements: [..]Element_Measurement;

    frame: s64;
    persistent_allocator: Allocator;

    parent_index: s64 = -1;
    scope_key: u64 = U64_MAX;
    base_style: Base_Style;

    shader_program: u32;
    vao: u32;
    vbo: u32;
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

    glGenVertexArrays(1, *vao);
    glBindVertexArray(vao);
    glGenBuffers(1, *vbo);
    glBindBuffer(GL_ARRAY_BUFFER, vbo);

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
            v_color = color;
            v_border_width = border_width;
            v_border_color = border_color;
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
                float a = texture(atlas, v_uv).r * v_color.a;
                out_color = vec4(v_color.rgb * a, a);
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

    buffer: [Glyph_Atlas.SIZE * Glyph_Atlas.SIZE]u8;

    glGenTextures(1, *glyph_atlas.texture);
    glBindTexture(GL_TEXTURE_2D, glyph_atlas.texture);
    // TOOD: keep track of whether subpixel rendering is enabled to create the texture atlas here accordingly
    glTexImage2D(GL_TEXTURE_2D, 0, xx GL_R8, Glyph_Atlas.SIZE, Glyph_Atlas.SIZE, 0, GL_RED, GL_UNSIGNED_BYTE, buffer.data);
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
    if element_tree.count > 0 {
        fit_child :: (element: *Element, child: *Element, fit_direction: Direction) {
            preferred_size := get_preferred_size(element, fit_direction);
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

            if element.style.direction == fit_direction {
                if preferred_size.kind == .FIT {
                    add(*element.size, fit_direction, child_size_contribution);
                } else if preferred_size.kind == .GROW {
                    // TODO: ensure the max and min sizes here
                    if fit_direction == .HORIZONTAL {
                        element.size.x = max(element.size.x, child_size_contribution + fitting_base(element, .HORIZONTAL));
                    } else {
                        element.size.y = max(element.size.y, child_size_contribution + fitting_base(element, .VERTICAL));
                    }
                }
                if should_fit_min(element, fit_direction) {
                    add(*element.min_size, fit_direction, child_min_size_contribution);
                }
            } else {
                // cross axis fitting
                if should_accumulate {
                    // TODO: ensure the max and min sizes here
                    set(
                        *element.size,
                        fit_direction,
                        max(
                            child_size_contribution + fitting_base(element, fit_direction),
                            get(element.size, fit_direction)
                        )
                    );
                }
                if should_fit_min(element, fit_direction) {
                    set(*element.min_size, fit_direction, max(
                        child_min_size_contribution + fitting_base(element, fit_direction),
                        get(element.min_size, fit_direction),
                    ));
                }
            }
        }

        {
            //
            // ==== fitting ====
            //
            for <*element: element_tree {
                if element.first_child != -1 && element.glyphs.array.count == 0 {
                    if element.style.width.kind == .FIT {
                        element.size.x = fitting_base(element, .HORIZONTAL);
                    }
                    if isnan(element.style.min_width) && element.style.width.kind != .FIXED {
                        element.min_size.x = fitting_base(element, .HORIZONTAL);
                    }
                    if element.style.height.kind == .FIT {
                        element.size.y = fitting_base(element, .VERTICAL);
                    }
                    if isnan(element.style.min_height) && element.style.height.kind != .FIXED {
                        element.min_size.y = fitting_base(element, .VERTICAL);
                    }
                    child_index := element.first_child;
                    while child_index != -1 {
                        child := *element_tree[child_index];
                        defer child_index = child.next_sibling;
                        if child.style.placement.kind == .FLOW &&
                        (element.style.width.kind == .FIT || element.style.width.kind == .GROW ||
                        should_fit_min(element, .HORIZONTAL) || element.style.height.kind == .FIT ||
                        element.style.height.kind == .GROW || should_fit_min(element, .VERTICAL)) {
                            fit_child(element, child, .HORIZONTAL);
                            fit_child(element, child, .VERTICAL);
                        }
                    }
                    clamp(*element.size, element.min_size, element.max_size);
                }
            }
        }

        EPSILON :: 0.001;
        approximately_equal :: (a: float, b: float) -> bool {
            return abs(a - b) < EPSILON;
        }

        {
            //
            // ==== growing and shrinking ====
            //
            changing: [..]*Element;
            for *element: element_tree {
                if it_index == 0 {
                    if element.style.width.kind == .GROW {
                        element.size.x = (cast(float) window.width) / (cast(float) window.scale);
                    }
                    if element.style.height.kind == .GROW {
                        element.size.y = (cast(float) window.height) / (cast(float) window.scale);
                    }
                }
                if element.first_child != -1 && element.glyphs.array.count == 0 {
                    array_reset_keeping_memory(*changing);
                    layout_direction := element.style.direction;
                    opposite_direction := opposite(layout_direction);
                    // this value is only the initial one, it's modified during the iteration over the children that follows
                    remaining := inner_size(element, layout_direction);

                    // this grows the children of this element. we need to do three visits here:
                    // 1) grow the children on the opposite axis of the layout direction (Style.direction)
                    // 2) iteratively grow the children equally in the layout direciton
                    // 3) iteratively shrink the children equally in the layout direction
                    child_index := element.first_child;
                    {
                        //
                        // === growing the children ===
                        //
                        while child_index != -1 {
                            child := *element_tree[child_index];
                            defer child_index = child.next_sibling;

                            child.min_size = min(child.min_size, child.max_size);

                            {
                                //
                                // == cross-axis growth ==
                                //
                                child_opposite_margin := get(child.style.margin, opposite_direction);
                                available := get(element.size, opposite_direction)
                                    - fitting_base(element, opposite_direction)
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
                                available := inner_size(element, layout_direction) - child_margin.x - child_margin.y;
                                set(*child.size, layout_direction, clamp(
                                    available,
                                    get(child.min_size, layout_direction),
                                    get(child.max_size, layout_direction),
                                ));
                            } else if child.style.placement.kind == .FLOW {
                                if preferred_size.kind == .GROW && preferred_size.grow > 0.0 {
                                    // we reset the size of the element to 0 so that the division is fair later
                                    set(*child.size, layout_direction, 0);
                                    if get(child.max_size, layout_direction) > 0 {
                                        array_add(*changing, child);
                                    }
                                }
                                remaining -= outer_size(child, layout_direction);
                            }
                        }

                        child_index = element.first_child;
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
                        // === shrinking ===
                        //
                        // we shrink children so that elements don't overflow the parent, but fit to the largest size possible that's bigger than
                        // their minimum size
                        array_reset_keeping_memory(*changing);
                        child_index = element.first_child;
                        while child_index != -1 {
                            child := *element_tree[child_index];
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
            for <*element: element_tree {
                rounded_font_size := round_font_size(element.style.font_size * (cast(float) window.scale));
                font_units_to_point := get_font_units_to_pixel(element.style.font, rounded_font_size) / (cast(float) window.scale);
                base := Vector2.{
                    element.style.border_width.x.x + element.style.padding.x.x,
                    element.style.border_width.y.x + element.style.padding.y.x,
                } / font_units_to_point;

                if element.glyphs.array.count > 0 && element.style.text_wrapping != .NONE {
                    using element.glyphs;

                    Line :: struct {
                        start: s64;
                        end: s64;
                    }
                    lines: [..]Line;
                    line_end := (element.size.x - fitting_base(element, .HORIZONTAL)) / font_units_to_point;
                    pen: Vector2;
                    line_start_index: s64 = 0;

                    break_cursor: s64 = 0;

                    if element.style.text_wrapping == {
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
                            if element.style.x_justification == {
                                case .START;
                                case .CENTER;
                                    glyph.position.x += (line_end - width) / 2.0;
                                case .END;
                                    glyph.position.x += line_end - width;
                            }
                        }
                    }
                    element.size.y = (pen.y + line_height) * font_units_to_point;
                }
            }
        }

        {
            //
            // ==== refit heights ====
            //
            for <*element: element_tree {
                if element.first_child != -1 && element.glyphs.array.count == 0 {
                    if element.style.height.kind == .FIT {
                        element.size.y = fitting_base(element, .VERTICAL);
                    }
                    if isnan(element.style.min_height) && element.style.height.kind != .FIXED {
                        element.min_size.y = fitting_base(element, .VERTICAL);
                    }
                    child_index := element.first_child;
                    while child_index != -1 {
                        child := *element_tree[child_index];
                        defer child_index = child.next_sibling;
                        if child.style.placement.kind == .FLOW && (element.style.height.kind == .FIT || element.style.height.kind == .GROW || should_fit_min(element, .VERTICAL)) {
                            fit_child(element, child, .VERTICAL);
                        }
                    }
                }
            }
        }

        {
            //
            // ==== regrowing veritcally ====
            //
            changing: [..]*Element;
            for *element: element_tree {
                if it_index == 0 {
                    if element.style.height.kind == .GROW {
                        element.size.y = (cast(float) window.height) / (cast(float) window.scale);
                    }
                }
                if element.first_child != -1 && element.glyphs.array.count == 0 {
                    array_reset_keeping_memory(*changing);
                    layout_direction := element.style.direction;
                    opposite_direction := opposite(layout_direction);
                    // this value is only the initial one, it's modified during the iteration over the children that follows
                    remaining := inner_size(element, layout_direction);

                    // this grows the children of this element. we need to do three visits here:
                    // 1) grow the children on the opposite axis of the layout direction (Style.direction)
                    // 2) iteratively grow the children equally in the layout direciton
                    // 3) iteratively shrink the children equally in the layout direction
                    child_index := element.first_child;
                    {
                        //
                        // === growing the children ===
                        //
                        while child_index != -1 {
                            child := *element_tree[child_index];
                            defer child_index = child.next_sibling;

                            child.min_size = min(child.min_size, child.max_size);

                            if opposite_direction == .VERTICAL {
                                //
                                // == cross-axis growth ==
                                //
                                child_opposite_margin := get(child.style.margin, opposite_direction);
                                available := get(element.size, opposite_direction)
                                    - fitting_base(element, opposite_direction)
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
                                    available := inner_size(element, layout_direction) - child_margin.x - child_margin.y;
                                    set(*child.size, layout_direction, clamp(
                                        available,
                                        get(child.min_size, layout_direction),
                                        get(child.max_size, layout_direction),
                                    ));
                                } else if child.style.placement.kind == .FLOW {
                                    if preferred_size.kind == .GROW && preferred_size.grow > 0.0 {
                                        // we reset the size of the element to 0 so that the division is fair later
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
                            child_index = element.first_child;
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
                    // TODO: should we shrink elements here again? if we indeed decide to do this, the min sizes for
                    // wrapped text should also change, otherwise this will reduce the wrapped text's height again after
                    // it wrapped and increased.
                }
            }
        }

        {
            //
            // === place elements and justifying them in both directions ===
            //
            for *element: element_tree {
                if it_index == 0 {
                    if element.style.placement.kind == {
                        case .FLOW;
                            element.position = element.style.translate;
                            element.position.x += element.style.margin.x.x;
                            element.position.y += element.style.margin.y.x;
                        case .FIXED;
                            element.position = element.style.placement.fixed + element.style.translate;
                        case .RELATIVE;
                            element.position = element.style.placement.relative + element.style.translate;
                            element.position.x += element.style.margin.x.x;
                            element.position.y += element.style.margin.y.x;
                    }
                }
                if element.first_child != -1 {
                    base := element.position + Vector2.{
                        element.style.border_width.x.x + element.style.padding.x.x,
                        element.style.border_width.y.x + element.style.padding.y.x,
                    };

                    // TODO: when the direction is horizontal, we should also handle element overflow wrapping here.
                    pen := base;
                    direction := element.style.direction;
                    opposite_direction := opposite(element.style.direction);

                    child_index := element.first_child;
                    while child_index != -1 {
                        child := *element_tree[child_index];
                        if child.style.placement.kind == {
                            case .FIXED;
                                child.position = child.style.placement.fixed + child.style.translate;
                            case .RELATIVE;
                                child.position = element.position + child.style.placement.relative + child.style.translate;
                            case .FLOW;
                                margin := get(child.style.margin, direction);
                                add(*pen, direction, margin.x);
                                child.position = pen + child.style.translate + element.children_offset;
                                add(*pen, direction, get(child.size, direction) + margin.y);
                        }
                        child_index = child.next_sibling;
                    }

                    content_size := get(pen, direction) - get(base, direction);
                    available := get(element.size, direction) - fitting_base(element, direction);
                    justification := get_justification(element, direction);
                    offset: float;
                    if justification == {
                        case .CENTER;
                            offset = (available - content_size) / 2.0;
                        case .END;
                            offset = available - content_size;
                    };

                    available_opposite := get(element.size, opposite_direction) - fitting_base(element, opposite_direction);
                    justification_opposite := get_justification(element, opposite_direction);
                    child_index = element.first_child;
                    while child_index != -1 {
                        child := *element_tree[child_index];
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
        ELEMENT :: 1;
        GLYPH :: 2;
    };

    position: Vector2;
    size: Vector2;
    color: Vector4;

    // element
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
    array_reserve(*z_buckets, element_tree.count);
    for element: element_tree {
        if element.z >= z_buckets.count {
            array_resize(*z_buckets, element.z + 1);
        }
        z_buckets[element.z] += xx (1 + element.glyphs.array.count);
        instance_count += 1 + element.glyphs.array.count;
    }

    draw_instances := NewArray(instance_count, Draw_Instance, false);

    offset: u32;
    for *start: z_buckets {
        count := start.*;
        start.* = xx offset;
        offset += count;
    }
    assert(offset == draw_instances.count);
    for element: element_tree {
        instance: Draw_Instance;
        {
            using instance;
            kind = .ELEMENT;
            z = element.z;
            position = element.position;
            size = element.size;
            // TODO: write out the instance gathering for the other types of backgrounds
            if element.style.background.kind == .COLOR {
                color = element.style.background.color;
            }
            border_width = Vector4.{
                element.style.border_width.x.x, // left
                element.style.border_width.x.y, // right
                element.style.border_width.y.x, // top
                element.style.border_width.y.y  // bottom
            };
            border_color = element.style.border_color;
            border_radius = min(element.style.border_radius, min(element.size.x, element.size.y));
        }
        draw_instances[z_buckets[instance.z]] = instance;
        z_buckets[instance.z] += 1;

        if element.glyphs.array.count != 0 {
            rounded_font_size := round_font_size(element.style.font_size * (cast(float) window.scale));
            font_units_to_point := get_font_units_to_pixel(element.style.font, rounded_font_size) / (cast(float) window.scale);

            for glyph: element.glyphs.array {
                atlas_key := glyph_atlas_key(element.style.font, xx glyph.index, rounded_font_size, element.style.font_weight);
                entry := table_find_pointer(*glyph_atlas.table, atlas_key);
                if entry == null {
                    set_weight(element.style.font, element.style.font_weight);
                    set_font_size(element.style.font, rounded_font_size);
                    // there's no entry in the atlas for this glyph configuration
                    raster := font_raster_glyph(element.style.font, xx glyph.index);
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
                    z = element.z;
                    position = element.position + (Vector2.{0.0, element.glyphs.ascent} + glyph.position) * font_units_to_point;
                    size = entry.size / scale;
                    position += entry.bearing / scale;
                    position.x = floor(position.x * scale + 0.5) / scale;
                    position.y = floor(position.y * scale + 0.5) / scale;
                    color = element.style.color;

                    uv_min = entry.uv_min;
                    uv_max = entry.uv_max;
                }
                draw_instances[z_buckets[instance.z]] = instance;
                z_buckets[instance.z] += 1;
            }
        }
    }

    point_width: float = (cast(float) window.width) / (cast(float) window.scale);
    point_height: float = (cast(float) window.height) / (cast(float) window.scale);

    glUseProgram(shader_program);
    glUniform2f(glGetUniformLocation(shader_program, "viewport"), point_width, point_height);
    glBindVertexArray(vao);
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
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
    }
}

prepare_frame :: () {
    using context.forbear;

    {
        push_allocator(persistent_allocator);
        array_resize(*measurements, element_tree.count, false);
        for element: element_tree {
            // we can't just copy the entire Element_Tree with a mempcy here because it points into frame allocated data
            // that was allocated in the frame pool. besides, in what I was able to measure, this copy tends to be more
            // performant than if we were to copy the entire Element_Tree with memcpy.
            measurements[it_index] = Element_Measurement.{
                size = element.size,
                position = element.position,
                clipping_rectangle = element.clipping_rectangle,
                state_offset = element.state_offset,
                state_size = element.state_size,
                pool_slot = element.pool_slot,
                key = element.key,
            };
        }
    }

    for *slot: pool_slots {
        if slot.used && slot.last_frame != frame {
            if slot.pool.current_point != slot.pool.memory_base {
                madvise(slot.pool.memory_base, cast(u64) (slot.pool.current_point - slot.pool.memory_base), MADV_DONTNEED);
            }
            reset(*slot.pool);
            slot.used = false;
        }
    }

    window.keys_pressed.count = 0;
    window.keys_released.count = 0;
    window.keys_repeated.count = 0;
    window.text.count = 0;
    memset(*window.pointer_released, 0, size_of(type_of(window.pointer_released)));
    memset(*window.pointer_pressed, 0, size_of(type_of(window.pointer_pressed)));
    #if OS == .LINUX {
        if window.repeating_key_code != 0 {
            now := seconds_since_init();
            while now >= window.next_repeat {
                add_key(*window.keys_repeated, window.repeating_key);
                utf8: [64]u8;
                append_text(key_text(backend.connection.key_state, window.repeating_key_code, utf8), *window.text, window.text_buffer);
                window.next_repeat += 1.0 / window.keyboard_repeat_rate;
            }
        }
    }
    state_current = 1 - state_current;
    state_used = 0;
    array_reset_keeping_memory(*element_tree);

    frame += 1;
}
