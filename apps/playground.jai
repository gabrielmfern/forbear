#import "Basic";
#import "Socket";
#import "Memory";
#import "POSIX";
#import "Math";
#import "GL";
#import "Hash";
#import,file "../bindings.jai";
#import,file "../egl.jai";

libc :: #library,system "libc";
memfd_create :: (name: *u8, flags: u32) -> s32 #foreign libc;
MREMAP_MAYMOVE :: 1;

eglExportDMABUFImageQueryMESA: PFNEGLEXPORTDMABUFIMAGEQUERYMESAPROC;
eglExportDMABUFImageMESA: PFNEGLEXPORTDMABUFIMAGEMESAPROC;

WAYLAND_DEBUGGING :: false;
EGL_DEBUGGING :: false;
EXIT_ON_FIRST_FRAME :: false;

Message_Header :: struct {
    object_id: u32;
    opcode: u16;
    size: u16;
} #no_padding;

MAX_WAYLAND_MESSAGE_SIZE :: 4096;
Wayland_Connection :: struct {
    fd: s32;
    polling_fd: pollfd;
    
    wl_display_id: u32;
    wl_registry_id: u32;
    wl_compositor_id: u32;
    zwp_dmabuf_id: u32;
    xdg_wm_base_id: u32;

    reading_buffer: [MAX_WAYLAND_MESSAGE_SIZE]u8;
    pending_reads: []u8;

    client_object_interfaces: [..]Interface_Id;
    free_client_object_interface_ids: [..]s64;
    server_object_interfaces: [..]Interface_Id;
};

init_wayland_connection :: (connection: *Wayland_Connection) {
    connection.fd = socket(AF_UNIX, SOCK.STREAM | SOCK.NONBLOCK, 0);
    connection.polling_fd = pollfd.{ fd = connection.fd, events = POLLIN };

    runtime_directory := to_string(getenv("XDG_RUNTIME_DIR"));
    wayland_display := to_string(getenv("WAYLAND_DISPLAY"));
    path := tprint("%/%", runtime_directory, wayland_display);

    sockaddr_un :: struct {
        sun_family: sa_family_t;
        sun_path: [100]u8;
    };

    address: sockaddr_un;
    address.sun_family = AF_UNIX;
    memcpy(cast(*void) address.sun_path.data, cast(*void) path.data, path.count);
    address.sun_path[path.count] = 0;

    if connect(connection.fd, cast(*sockaddr) *address, size_of(sockaddr_un)) != 0 {
        log_error("connection failed: %\n", errno());
        exit(-1);
    }
    if WAYLAND_DEBUGGING {
        print("connected to %\n", path);
    }

    connection.wl_display_id = new_wayland_client_object(connection, Interface_Id.WL_DISPLAY);
    connection.wl_registry_id = new_wayland_client_object(connection, Interface_Id.WL_REGISTRY);
    send_wayland_message(connection, 1, Wl_Display_Request_Get_Registry.{ registry = connection.wl_registry_id });

    bind_global :: (connection: *Wayland_Connection, interface_id: Interface_Id, global: Wl_Registry_Event_Global) -> u32 {
        id := new_wayland_client_object(connection, interface_id);
        send_wayland_message(connection, connection.wl_registry_id, Wl_Registry_Request_Bind.{
            name = global.name,
            interface_name = global.interface_name,
            version = min(INTERFACES[interface_id].version, global.version),
            id = id,
        });
        return id;
    }
 
    while connection.wl_compositor_id == 0 || connection.xdg_wm_base_id == 0 || connection.zwp_dmabuf_id == 0 {
        event, data, something := next_wayland_event(connection);
        if !something {
            poll_wayland_connection(connection);
            continue;
        }

        if event.type == {
            case Wl_Registry_Event_Global;
                global := cast(*Wl_Registry_Event_Global) data;
                if global.interface_name == "wl_compositor" {
                    connection.wl_compositor_id = bind_global(connection, Interface_Id.WL_COMPOSITOR, global);
                }else if global.interface_name == "xdg_wm_base" {
                    connection.xdg_wm_base_id = bind_global(connection, Interface_Id.XDG_WM_BASE, global);
                } else if global.interface_name == "zwp_linux_dmabuf_v1" {
                    connection.zwp_dmabuf_id = bind_global(connection, Interface_Id.ZWP_LINUX_DMABUF_V1, global);
                }
        }

        reset_temporary_storage();
    }
}

update_wayland_connection :: (connection: *Wayland_Connection, event: Message_Info, data: *void) {
    if event.type == {
        case Wl_Display_Event_Delete_Id;
            delete := cast(*Wl_Display_Event_Delete_Id) data;
            array_add(*connection.free_client_object_interface_ids, delete.id);
    }
}

poll_wayland_connection :: (connection: *Wayland_Connection, timeout_ms: s32 = 1000) {
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

next_wayland_event :: (connection: *Wayland_Connection) -> event: Message_Info, data: *void, something: bool {
    should_read_more: bool;
    if connection.pending_reads.count >= size_of(Message_Header) {
        incoming_message_header := cast(*Message_Header) connection.pending_reads.data;
        should_read_more = connection.pending_reads.count < incoming_message_header.size;
    } else {
        should_read_more = true;
    }
    if should_read_more {
        leftover := connection.pending_reads.count;
        // move the leftover to the start of the buffer
        copy(connection.reading_buffer.data, connection.pending_reads.data, leftover);
        result := read(
            connection.fd, 
            cast(*void) (connection.reading_buffer.data + leftover), 
            xx (connection.reading_buffer.count - leftover)
        );
        if result == 0 {
            log_error("compositor closed the connection");
            exit(-1);
        }
        if result == -1 {
            error_code := errno();
            if error_code == EAGAIN {
                // this means there are no more messages to wait for, we can just yield
                return Message_Info.{}, null, false;
            } else {
                log_error("failed to read back from socket: %\n", error_code);
                exit(-1);
            }
        }

        connection.pending_reads = array_view(connection.reading_buffer, 0, result + leftover);
    }

    if connection.pending_reads.count < size_of(Message_Header) ||
       connection.pending_reads.count < (cast(*Message_Header) connection.pending_reads.data).size {
        return Message_Info.{}, null, false;
    }

    incoming_message_header := cast(*Message_Header) connection.pending_reads.data;

    object_interface_id: Interface_Id;
    if incoming_message_header.object_id >= 0xff000000 {
        // means it's a server object id
        object_interface_id = connection.server_object_interfaces[incoming_message_header.object_id - 0xff000000];
    } else {
        object_interface_id = connection.client_object_interfaces[incoming_message_header.object_id - 1];
    }
    event: Message_Info = MESSAGES[
        INTERFACES[object_interface_id].first_event + incoming_message_header.opcode
    ];

    incoming_message := array_view(connection.pending_reads, size_of(Message_Header), incoming_message_header.size - size_of(Message_Header));
    connection.pending_reads.data += incoming_message_header.size;
    connection.pending_reads.count -= incoming_message_header.size;

    data := parse_wayland_message(incoming_message, event);

    if event.type == Wl_Display_Event_Error {
        error := cast(*Wl_Display_Event_Error) data;
        log_error(
            "protocol error on object % (%): code %, %", 
            error.object_id, 
            connection.client_object_interfaces[error.object_id - 1], 
            error.code, 
            error.message
        );
        exit(-1);
    }

    if WAYLAND_DEBUGGING {
        print("\n");
        print("message received\n");
        print("event.type %\n", event.type);
        print("object interface %\n", object_interface_id);
        print("\n");
    }

    return event, data, true;
}

// TODO(depessimization): we should be buffering the messages and flushing them instead of sending them all one by one
writing_buffer: [MAX_WAYLAND_MESSAGE_SIZE]u8;
send_wayland_message :: (connection: *Wayland_Connection, object_id: u32, message: $T) -> bool {
    bytes := array_view(writing_buffer, 0, size_of(Message_Header));

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

    header := cast(*Message_Header) bytes.data;
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
            while true  next_wayland_event(connection);
        }
        log_error("could not send wayland message: %\n", error_code);
        exit(-1);
    }
    memset(writing_buffer.data, 0, bytes.count);

    return result == bytes.count;
}

parsing_buffer : [MAX_MESSAGE_STRUCT_SIZE]u8;
parse_wayland_message :: (bytes: []u8, message_info: Message_Info) -> *void {
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
                continue;
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

Color :: struct {
    b: u8;
    g: u8;
    r: u8;
    // this is unused and the compositor ignores it
    x: u8;
} #no_padding;

Wayland_Window :: struct {
    wl_surface_id: u32;
    wl_buffer_id: u32;
    
    xdg_surface_id: u32;
    // only top level windows are supported. there are also popups
    xdg_toplevel_id: u32;

    width: s32;
    texture_width: s32;
    height: s32;
    texture_height: s32;

    egl_image: EGLImage;
    fourcc: s32;
    modifiers: u64;
    fds: [4]s32;
    offsets: [4]s32;
    strides: [4]s32;
    texture: GLuint;
    fbo: GLuint;

    running: bool = true;
};

// TOOD: we need to have this into its own kind of struct and not global
egl_display: EGLDisplay;
egl_context: EGLContext;

init_wayland_window :: (connection: *Wayland_Connection, window: *Wayland_Window, width: s32, height: s32) {
    window.width = width;
    window.height = height;

    window.wl_surface_id = new_wayland_client_object(connection, Interface_Id.WL_SURFACE);
    send_wayland_message(connection, connection.wl_compositor_id, Wl_Compositor_Request_Create_Surface.{ id = window.wl_surface_id });
    window.xdg_surface_id = new_wayland_client_object(connection, Interface_Id.XDG_SURFACE);
    send_wayland_message(connection, connection.xdg_wm_base_id, Xdg_Wm_Base_Request_Get_Xdg_Surface.{ id = window.xdg_surface_id, surface = window.wl_surface_id });
    window.xdg_toplevel_id = new_wayland_client_object(connection, Interface_Id.XDG_TOPLEVEL);
    send_wayland_message(connection, window.xdg_surface_id, Xdg_Surface_Request_Get_Toplevel.{ id = window.xdg_toplevel_id });
    send_wayland_message(connection, window.wl_surface_id, Wl_Surface_Request_Commit.{});

    glGenTextures(1, *window.texture);
    glBindTexture(GL_TEXTURE_2D, window.texture);
    window.texture_width = width;
    window.texture_height = height;
    glTexImage2D(GL_TEXTURE_2D, 0, xx GL_RGBA8, xx window.width, xx window.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, null);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

    glGenFramebuffers(1, *window.fbo);
    glBindFramebuffer(GL_FRAMEBUFFER, window.fbo);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, window.texture, 0);
    assert(glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE);
}

update_wayland_window :: (connection: *Wayland_Connection, window: *Wayland_Window, event: Message_Info, data: *void) {
    if event.type == {
        case Xdg_Toplevel_Event_Close;
            window.running = false;
        case Xdg_Toplevel_Event_Configure;
            configure := cast(*Xdg_Toplevel_Event_Configure) data;
            if configure.width {
                window.width = configure.width;
            }
            if configure.height {
                window.height = configure.height;
            }
        case Xdg_Surface_Event_Configure;
            configure := cast(*Xdg_Surface_Event_Configure) data;
            send_wayland_message(connection, window.xdg_surface_id, Xdg_Surface_Request_Ack_Configure.{ serial = configure.serial });

            if window.width * window.height != window.texture_width * window.texture_height {
                if window.egl_image != null {
                    if eglDestroyImage(egl_display, window.egl_image) != 1 {
                        log_error("failed to destroy previous egl image: %\n", eglGetError());
                        exit(-1);
                    }
                }

                if window.texture != 0 {
                    glDeleteTextures(1, *window.texture);
                }

                if window.fds[0] != 0 {
                    close(window.fds[0]);
                }

                glGenTextures(1, *window.texture);
                glBindTexture(GL_TEXTURE_2D, window.texture);
                window.texture_width = window.width;
                window.texture_height = window.height;
                glTexImage2D(GL_TEXTURE_2D, 0, xx GL_RGBA8, xx window.width, xx window.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, null);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

                glBindFramebuffer(GL_FRAMEBUFFER, window.fbo);
                glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, window.texture, 0);
                assert(glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE);

                window.egl_image = eglCreateImage(egl_display, egl_context, EGL_GL_TEXTURE_2D, cast(EGLClientBuffer) cast(u64) window.texture, null);
                if window.egl_image == null {
                    log_error("failed to create frame buffer: %\n", eglGetError());
                    exit(-1);
                }

                num_planes: s32;
                if eglExportDMABUFImageQueryMESA(egl_display, window.egl_image, *window.fourcc, *num_planes, *window.modifiers) != 1 {
                    log_error("failed in eglExportDMABUFImageQueryMESA: %\n", eglGetError());
                    exit(-1);
                }
                if EGL_DEBUGGING {
                    print("num_planes %, fourcc %, modifiers %\n", num_planes, formatInt(window.fourcc, base = 16), formatInt(window.modifiers, base = 16));
                }
                if eglExportDMABUFImageMESA(egl_display, window.egl_image, window.fds.data, window.strides.data, window.offsets.data) != 1 {
                    log_error("failed in eglExportDMABUFImageMESA: %\n", eglGetError());
                    exit(-1);
                }
                if EGL_DEBUGGING {
                    print("fds %, strides %, offsets %\n", window.fds, window.strides, window.offsets);
                }
            }

            buffer_params_id := new_wayland_client_object(connection, Interface_Id.ZWP_LINUX_BUFFER_PARAMS_V1);
            send_wayland_message(connection, connection.zwp_dmabuf_id, Zwp_Linux_Dmabuf_V1_Request_Create_Params.{
                params_id = buffer_params_id,
            });
            send_wayland_message(connection, buffer_params_id, Zwp_Linux_Buffer_Params_V1_Request_Add.{
                fd = xx window.fds[0],
                plane_idx = 0,
                offset = xx window.offsets[0],
                stride = xx window.strides[0],
                modifier_hi = xx (window.modifiers >> 32),
                modifier_lo = xx (window.modifiers & 0xFFFFFFFF)
            });

            previous_buffer_id := window.wl_buffer_id;
            window.wl_buffer_id = new_wayland_client_object(connection, Interface_Id.WL_BUFFER);
            send_wayland_message(connection, buffer_params_id, Zwp_Linux_Buffer_Params_V1_Request_Create_Immed.{
                buffer_id = window.wl_buffer_id,
                width = window.width,
                height = window.height,
                format = xx window.fourcc,
                flags = 0,
            });

            send_wayland_message(connection, buffer_params_id, Zwp_Linux_Buffer_Params_V1_Request_Destroy.{ });

            send_wayland_message(connection, window.wl_surface_id, Wl_Surface_Request_Attach.{ buffer = window.wl_buffer_id, x = 0, y = 0 });
            send_wayland_message(connection, window.wl_surface_id, Wl_Surface_Request_Damage.{ x = 0, y = 0, width = window.width, height = window.height });
            if EXIT_ON_FIRST_FRAME {
                send_wayland_message(connection, window.wl_surface_id, Wl_Surface_Request_Frame.{ callback = new_wayland_client_object(connection, Interface_Id.WL_CALLBACK) });
            }
            send_wayland_message(connection, window.wl_surface_id, Wl_Surface_Request_Commit.{});

            if previous_buffer_id != 0 {
                send_wayland_message(connection, previous_buffer_id, Wl_Buffer_Request_Destroy.{});
            }
        case Wl_Callback_Event_Done;
            if EXIT_ON_FIRST_FRAME  window.running = false;
    }
}

Direction :: enum u8 { HORIZONTAL; VERTICAL; };
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
        FIT; FIXED; RATIO; GROW;
    };

    kind: Kind;

    union {
        fixed: float;
        // A ratio with respect to the opposite axis.
        ratio: float;
        // Grows to fill available space, taking a proportional share based on
        // the factor. A factor of 2.0 claims twice the space of 1.0.
        grow: float;
    }
};

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
    CHARACTER;
    // Uses a simple greedy algorithm to break on word boundaries
    WORD;
    NONE;
};

Overflow :: enum u8 { VISIBLE; WRAP; };

Sides :: struct {
    x: Vector2;
    y: Vector2;
};
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

    // font: *Font;

    // Will do nothing if the font is not a variable font. If you don't have a
    // variable font, you should use different fonts for different weights.
    font_weight: u32;
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
    // font: *Font,
    color: Vector4;
    font_size: float;
    font_weight: u32;
    line_height: float;
    text_wrapping: Text_Wrapping;
    cursor: Cursor;
};

from :: (style: Complete_Style) -> Base_Style {
    return Base_Style.{
        // font = style.font,
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
    radians := degrees * PI / 180.0;
    return Vector2.{ x = sin(radians), y = -cos(radians)};
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
    return Vector2.{ x = xx -SQRTH, y = xx -SQRTH };
}
to_top_right :: () -> Vector2 {
    return Vector2.{ x = xx SQRTH, y = xx -SQRTH };
}
to_bottom_left :: () -> Vector2 {
    return Vector2.{ x = xx -SQRTH, y = xx SQRTH };
}
to_bottom_right :: () -> Vector2 {
    return Vector2.{ x = xx SQRTH, y = xx SQRTH };
}
Linear_Gradient :: struct {
    // Stops define where each color sits along the gradient; positions are
    // expected to be monotonically increasing within the [0, 1] range.
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
        // A linear gradient across the element. Defaults to flowing left-to-right;
        // set `direction` to change which way it runs. See `Linear_Gradient`.
        gradient: Linear_Gradient;
    }
};

Placement :: struct {
    Kind :: enum u8 { FLOW; FIXED; RELATIVE; };

    kind: Kind;
    union {
        fixed: Vector2;
        relative: Vector2;
    }
};

UNSET :: 0xFF;
Vector2_NAN :: Vector2.{ x = FLOAT32_NAN, y = FLOAT32_NAN };
Vector4_NAN :: Vector4.{ x = FLOAT32_NAN, y = FLOAT32_NAN, z = FLOAT32_NAN, w = FLOAT32_NAN };
Sides_NAN :: Sides.{ x = Vector2_NAN, y = Vector2_NAN };
Style :: struct {
    background: Background = Background.{ kind = UNSET };

    color: Vector4 = Vector4_NAN;
    border_radius: float = FLOAT32_NAN;
    border_color: Vector4 = Vector4_NAN;
    border_width: Border_Width = Sides_NAN;
    border_style: Border_Style = UNSET;

    shadow: Shadow = Shadow.{ 
        offset = Sides_NAN, 
        blur_radius = FLOAT32_NAN, 
        spread = FLOAT32_NAN, 
        color = Vector4_NAN,
    };

    // font: *Font = null;
    font_weight: u32 = 0;
    font_size: float = FLOAT32_NAN;
    line_height: float = FLOAT32_NAN;
    text_wrapping: Text_Wrapping = UNSET;

    cursor: Cursor = UNSET;

    overflow: Overflow = UNSET;
    placement: Placement = Placement.{ kind = UNSET };
    z_index: u16 = U16_MAX;

    min_width: float = FLOAT32_NAN;
    max_width: float = FLOAT32_NAN;
    width: Sizing = Sizing.{ kind = UNSET };
    min_height: float = FLOAT32_NAN;
    max_height: float = FLOAT32_NAN;
    height: Sizing = Sizing.{ kind = UNSET };

    translate: Vector2 = Vector2_NAN;

    padding: Padding = Sides_NAN;
    margin: Margin = Sides_NAN;

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

    out.font_weight = ifx style.font_weight == 0 then base.font_weight else style.font_weight;
    out.font_size = ifx isnan(style.font_size) then base.font_size else style.font_size;
    out.line_height = ifx isnan(style.line_height) then base.line_height else style.line_height;
    out.text_wrapping = ifx style.text_wrapping == xx UNSET then base.text_wrapping else style.text_wrapping;
    out.cursor = ifx style.cursor == xx UNSET then base.cursor else style.cursor;

    out.overflow = ifx style.overflow == xx UNSET then .VISIBLE else style.overflow;
    out.placement = ifx style.placement.kind == xx UNSET then Placement.{ kind = .FLOW } else style.placement;
    out.z_index = style.z_index;

    out.min_width = ifx isnan(style.min_width) then -1 else style.min_width;
    out.max_width = ifx isnan(style.max_width) then -1 else style.max_width;
    out.width = ifx style.width.kind == xx UNSET then Sizing.{ kind = .FIT } else style.width;

    out.min_height = ifx isnan(style.min_height) then -1 else style.min_height;
    out.max_height = ifx isnan(style.max_height) then -1 else style.max_height;
    out.height = ifx style.height.kind == xx UNSET then Sizing.{ kind = .FIT } else style.height;

    out.translate = ifx isnan(style.translate.x) then make_vector2(0.0) else style.translate;

    out.padding = ifx isnan(style.padding.x.x) then all(0.0) else style.padding;
    out.margin = ifx isnan(style.margin.x.x) then all(0.0) else style.margin;

    out.direction = ifx style.direction == xx UNSET then .HORIZONTAL else style.direction;
    out.x_justification = ifx style.x_justification == xx UNSET then .START else style.x_justification;
    out.y_justification = ifx style.y_justification == xx UNSET then .START else style.y_justification;
}

LayoutGlyph :: struct {
    index: s32;
    position: Vector2;

    textBuf: [4]u8;

    // Meant for the recalculation of the glyphs position if that's required
    // at some other layouting step
    advance: Vector2;
    // Meant for the recalculation of the glyphs position if that's required
    // at some other layouting step
    offset: Vector2;
};

Glyphs :: struct {
    lineHeight: float;
    // Distance from line top to the shared baseline, in pixels. The max ascent
    // across runs, so mixed-size runs in a `composeText` block sit on one
    // baseline. Drawing offsets every glyph down by this.
    ascent: float;
    slice: []LayoutGlyph;
    // Indices into `slice` where a manual line break was requested before the
    // glyph at that index. Ascending; may contain duplicates for consecutive
    // breaks. A value equal to `slice.len` marks a trailing blank line.
    preBreakIndices: []s64;
};

Node :: struct {
    size: Vector2;
    position: Vector2;
    min_size: Vector2;
    max_size: Vector2;

    first_child: s64 = -1;
    last_child: s64 = -1;
    next_sibling: s64 = -1;
    previous_Sibling: s64 = -1;
    parent: s64 = -1;

    style: Complete_Style;

    content_size: Vector2;
    // TODO: should we have this? this feels like the wrong solution to the problem, there should be a user-accessible way of changing the offset of the children without a specific property for it
    // Generally used for scrolling. This is added to the position of the children of this node
    children_offset: Vector2;

    // Clip rect inherited from ancestors that have constrained size with overflowing children.
    // Format: [x, y, width, height]. If NAN, no clipping is applied.
    clipping_rectangle: Vector4 = Vector4_NAN;
    // glyphs: ?Glyphs = null;
    key: u64;
    z: u16;

    tree: *Node_Tree;
};

Node_Tree :: [..]Node;

put_node :: (node_tree: *Node_Tree, parent_index: s64 = -1) -> pointer: *Node, index: s64 {
    index := node_tree.buffer.count;
    if index != 0 && parent_index == -1 {
        log_error("multiple root nodes are not allowed");
        exit(-1);
    }

    node := Node.{
        size = ---,
        position = ---,
        min_size = ---,
        max_size = ---,

        style = ---,

        key = ---,
        z = ---,

        parent = parent_index,
        tree = node_tree,
    };
    if parent_index != -1 {
        parent := node_tree[parent_index];
        if parent.last_child != -1 {
            node_tree[parent.last_child].next_sibling = index;
        }
        node.previous_sibling = parent.last_child;
        if parent.first_child == -1 {
            parent.first_child = index;
        }
        parent.last_child = index;
    }
    array_add(node_tree, node);
    return *node_tree[index], index;
}

element :: (
    body: Code, 
    style := Style.{}, 
    key := "", 
    location := #caller_location
) #expand {
    key: u64;
    if key.count > 0 {
        key = fnv1a_hash(key.data, key.count);
    } else {
        // we use the caller location here
        kye = fnv1a_hash(loc.fully_pathed_filename.data, loc.fully_pathed_filename.count);
        key = fnv1a_hash(cast(u64) loc.line_number, key);
        key = fnv1a_hash(cast(u64) loc.character_number, key);
    }
}

main :: () {
    wayland_connection: Wayland_Connection;
    init_wayland_connection(*wayland_connection);

    egl_display = eglGetPlatformDisplay(EGL_PLATFORM_SURFACELESS_MESA, null, null);
    major: s32;
    minor: s32;
    if eglInitialize(egl_display, *major, *minor) != 1 {
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
    egl_context = eglCreateContext(egl_display, null, null, egl_context_attributes.data);
    eglMakeCurrent(egl_display, null, null, egl_context);
    gl_load(*gl, xx eglGetProcAddress);

    if EGL_DEBUGGING {
        print("loaded OpenGL %.%\n", gl_version_major, gl_version_minor);
        print("opengl renderer %\n", to_string(glGetString(GL_RENDERER)));
    }

    eglExportDMABUFImageQueryMESA = xx eglGetProcAddress("eglExportDMABUFImageQueryMESA");
    eglExportDMABUFImageMESA = xx eglGetProcAddress("eglExportDMABUFImageMESA");
    if eglExportDMABUFImageQueryMESA == null || eglExportDMABUFImageMESA == null {
        log_error("EGL_MESA_image_dma_buf_export is not supported\n");
        exit(-1);
    }

    wayland_window: Wayland_Window;
    init_wayland_window(*wayland_connection, *wayland_window, 800, 600);

    node_tree: Node_Tree;

    while wayland_window.running {
        event, data, something := next_wayland_event(*wayland_connection);
        if something {
            update_wayland_window(*wayland_connection, *wayland_window, event, data);
            update_wayland_connection(*wayland_connection, event, data);
        }

        glViewport(0, 0, xx wayland_window.width, xx wayland_window.height);
        glEnable(GL_SCISSOR_TEST);
        glScissor(0, 0, xx (wayland_window.width / 2), xx wayland_window.height);
        glClearColor(1, 0, 1, 1);
        glClear(GL_COLOR_BUFFER_BIT);

        glFinish();

        reset_temporary_storage();
    }
}
