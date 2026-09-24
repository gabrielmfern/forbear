#import "Basic";
#import "Socket";
#import "Memory";
#import "POSIX";
#import "GL";
#import,file "../wayland.jai";
#import,file "../egl.jai";

libc :: #library,system "libc";
memfd_create :: (name: *u8, flags: u32) -> s32 #foreign libc;
MREMAP_MAYMOVE :: 1;

eglExportDMABUFImageQueryMESA: PFNEGLEXPORTDMABUFIMAGEQUERYMESAPROC;
eglExportDMABUFImageMESA: PFNEGLEXPORTDMABUFIMAGEMESAPROC;

WAYLAND_DEBUGGING :: false;
EGL_DEBUGGING :: false;
EXIT_ON_FIRST_FRAME :: false;

MessageHeader :: struct {
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
    if connection.pending_reads.count >= size_of(MessageHeader) {
        incoming_message_header := cast(*MessageHeader) connection.pending_reads.data;
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

    if connection.pending_reads.count < size_of(MessageHeader) ||
       connection.pending_reads.count < (cast(*MessageHeader) connection.pending_reads.data).size {
        return Message_Info.{}, null, false;
    }

    incoming_message_header := cast(*MessageHeader) connection.pending_reads.data;

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

    incoming_message := array_view(connection.pending_reads, size_of(MessageHeader), incoming_message_header.size - size_of(MessageHeader));
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
    bytes := array_view(writing_buffer, 0, size_of(MessageHeader));

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

    header := cast(*MessageHeader) bytes.data;
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
