#import "Basic";
#import "Socket";
#import "Memory";
#import "POSIX";
#import,file "../wayland.jai";

libc :: #library,system "libc";
memfd_create :: (name: *u8, flags: u32) -> s32 #foreign libc;

WAYLAND_DEBUGGING :: false;
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
    wl_shm_id: u32;
    xdg_wm_base_id: u32;

    reading_buffer: [MAX_WAYLAND_MESSAGE_SIZE]u8;
    pending_reads: []u8;
    writing_buffer: [MAX_WAYLAND_MESSAGE_SIZE]u8;

    client_object_interfaces: [..]Interface_Id;
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
 
    while connection.wl_compositor_id == 0 || connection.wl_shm_id == 0 || connection.xdg_wm_base_id == 0 {
        something: bool;
        event: Message_Info;
        data: *void;
        event, data, something = next_wayland_event(connection);
        if !something {
            poll_wayland_connection(connection);
            event, data, something = next_wayland_event(connection);
        }

        if event.type == {
            case Wl_Registry_Event_Global;
                global := cast(*Wl_Registry_Event_Global) data;
                if global.interface_name == "wl_compositor" {
                    connection.wl_compositor_id = new_wayland_client_object(connection, Interface_Id.WL_COMPOSITOR);
                    send_wayland_message(connection, connection.wl_registry_id, Wl_Registry_Request_Bind.{
                        name = global.name,
                        interface_name = global.interface_name,
                        version = min(INTERFACES[Interface_Id.WL_COMPOSITOR].version, global.version),
                        id = connection.wl_compositor_id,
                    });
                } else if global.interface_name == "wl_shm" {
                    connection.wl_shm_id = new_wayland_client_object(connection, Interface_Id.WL_SHM);
                    send_wayland_message(connection, connection.wl_registry_id, Wl_Registry_Request_Bind.{
                        name = global.name,
                        interface_name = global.interface_name,
                        version = min(INTERFACES[Interface_Id.WL_SHM].version, global.version),
                        id = connection.wl_shm_id,
                    });
                } else if global.interface_name == "xdg_wm_base" {
                    connection.xdg_wm_base_id = new_wayland_client_object(connection, Interface_Id.XDG_WM_BASE);
                    send_wayland_message(connection, connection.wl_registry_id, Wl_Registry_Request_Bind.{
                        name = global.name,
                        interface_name = global.interface_name,
                        version = min(INTERFACES[Interface_Id.XDG_WM_BASE].version, global.version),
                        id = connection.xdg_wm_base_id,
                    });
                }
        }

        reset_temporary_storage();
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
    array_add(*connection.client_object_interfaces, interface_id);
    return xx connection.client_object_interfaces.count;
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

Wayland_Window :: struct {
    wl_surface_id: u32;
    wl_buffer_id: u32;
    wl_shm_pool_id: u32;
    
    xdg_surface_id: u32;
    // only top level windows are supported. there are also popups
    xdg_toplevel_id: u32;
    
    running: bool = true;
};

init_wayland_window :: (connection: *Wayland_Connection, window: *Wayland_Window, width: s32, height: s32) {
    window.wl_surface_id = new_wayland_client_object(connection, Interface_Id.WL_SURFACE);
    send_wayland_message(connection, connection.wl_compositor_id, Wl_Compositor_Request_Create_Surface.{ id = window.wl_surface_id });
    window.xdg_surface_id = new_wayland_client_object(connection, Interface_Id.XDG_SURFACE);
    send_wayland_message(connection, connection.xdg_wm_base_id, Xdg_Wm_Base_Request_Get_Xdg_Surface.{ id = window.xdg_surface_id, surface = window.wl_surface_id });
    window.xdg_toplevel_id = new_wayland_client_object(connection, Interface_Id.XDG_TOPLEVEL);
    send_wayland_message(connection, window.xdg_surface_id, Xdg_Surface_Request_Get_Toplevel.{ id = window.xdg_toplevel_id });
    send_wayland_message(connection, window.wl_surface_id, Wl_Surface_Request_Commit.{});

    while true {
        something: bool;
        event: Message_Info;
        data: *void;
        event, data, something = next_wayland_event(connection);
        if !something {
            poll_wayland_connection(connection);
            event, data, something = next_wayland_event(connection);
        }

        if event.type == {
            case Xdg_Surface_Event_Configure;
                configure := cast(*Xdg_Surface_Event_Configure) data;
                send_wayland_message(connection, window.xdg_surface_id, Xdg_Surface_Request_Ack_Configure.{ serial = configure.serial });
                break;
        }

        reset_temporary_storage();
    }

    buffer_size := width * height * 4;
    buffer_fd := memfd_create("buffer", 0);
    if buffer_fd == -1 {
        log_error("failed to create pixel buffer fd: %\n", errno());
        exit(-1);
    }
    if ftruncate(buffer_fd, xx buffer_size) == -1 {
        log_error("failed to create pixel buffer fd: %\n", errno());
        exit(-1);
    }
    buffer := mmap(null, xx buffer_size, PROT_READ | PROT_WRITE, MAP_SHARED, buffer_fd, 0);
    if buffer == MAP_FAILED {
        log_error("failed to create pixel buffer fd: %\n", errno());
        exit(-1);
    }

    window.wl_shm_pool_id = new_wayland_client_object(connection, Interface_Id.WL_SHM_POOL);
    send_wayland_message(connection, connection.wl_shm_id, Wl_Shm_Request_Create_Pool.{ 
        id = window.wl_shm_pool_id, 
        fd = xx buffer_fd, 
        size = buffer_size 
    });

    window.wl_buffer_id = new_wayland_client_object(connection, Interface_Id.WL_BUFFER);
    send_wayland_message(connection, window.wl_shm_pool_id, Wl_Shm_Pool_Request_Create_Buffer.{ 
        id = window.wl_buffer_id,
        offset = 0,
        width = width,
        height = height,
        stride = width * 4,
        format = Wl_Shm_Format.XRGB8888,
    });

    send_wayland_message(connection, window.wl_surface_id, Wl_Surface_Request_Attach.{ buffer = window.wl_buffer_id, x = 0, y = 0 });
    send_wayland_message(connection, window.wl_surface_id, Wl_Surface_Request_Damage.{ x = 0, y = 0, width = width, height = height });
    send_wayland_message(connection, window.wl_surface_id, Wl_Surface_Request_Frame.{ callback = new_wayland_client_object(connection, Interface_Id.WL_CALLBACK) });
    send_wayland_message(connection, window.wl_surface_id, Wl_Surface_Request_Commit.{});
}

update_wayland_window :: (window: *Wayland_Window, event: Message_Info, data: *void) {
    if event.type == {
        case Xdg_Toplevel_Event_Close;
            window.running = false;
        case Wl_Callback_Event_Done;
            if EXIT_ON_FIRST_FRAME  window.running = false;
    }
    // handle:
    // - configure events
    // - close event
    // for this window
}

main :: () {
    wayland_connection: Wayland_Connection;
    init_wayland_connection(*wayland_connection);

    window: Wayland_Window;
    init_wayland_window(*wayland_connection, *window, 800, 600);

    while window.running {
        event, data, something := next_wayland_event(*wayland_connection);

        if something {
            update_wayland_window(*window, event, data);
        }

        reset_temporary_storage();
    }
}
