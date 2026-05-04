const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const List = @import("../list.zig").List;
const ListItem = @import("../list.zig").ListItem;
const Paragraph = @import("../paragraph.zig").Paragraph;
const Strong = @import("../strong.zig").Strong;

pub fn WireProtocolBasics() void {
    forbear.component(.{})({
        forbear.element(.{
            .style = .{
                .width = .{ .grow = 1.0 },
                .direction = .vertical,
                .xJustification = .center,
                .yJustification = .start,
                .padding = forbear.Padding.all(15.0),
                .maxWidth = 750.0,
            },
        })({
            Heading(.{ .level = 1 })({
                forbear.text("Wire protocol basics");
            });

            Paragraph(.{})({
                forbear.text("Note: If you're just going to use libwayland, this chapter is optional - feel free to skip to chapter 2.2.");
            });

            Paragraph(.{})({
                forbear.text("The wire protocol is a stream of 32-bit values, encoded with the host's byte order (e.g. little-endian on x86 family CPUs). These values represent the following primitive types:");
            });

            Paragraph(.{})({
                Strong()({
                    forbear.text("int, uint");
                });
                forbear.text(": 32-bit signed or unsigned integer.");
            });

            Paragraph(.{})({
                Strong()({
                    forbear.text("fixed");
                });
                forbear.text(": 24.8 bit signed fixed-point numbers.");
            });

            Paragraph(.{})({
                Strong()({
                    forbear.text("object");
                });
                forbear.text(": 32-bit object ID.");
            });

            Paragraph(.{})({
                Strong()({
                    forbear.text("new_id");
                });
                forbear.text(": 32-bit object ID which allocates that object when received.");
            });

            Paragraph(.{})({
                forbear.text("In addition to these primitives, the following other types are used:");
            });

            Paragraph(.{})({
                Strong()({
                    forbear.text("string");
                });
                forbear.text(": A string, prefixed with a 32-bit integer specifying its length (in bytes), followed by the string contents and a NUL terminator, padded to 32 bits with undefined data. The encoding is not specified, but in practice UTF-8 is used.");
            });

            Paragraph(.{})({
                Strong()({
                    forbear.text("array");
                });
                forbear.text(": A blob of arbitrary data, prefixed with a 32-bit integer specifying its length (in bytes), then the verbatim contents of the array, padded to 32 bits with undefined data.");
            });

            Paragraph(.{})({
                Strong()({
                    forbear.text("fd");
                });
                forbear.text(": 0-bit value on the primary transport, but transfers a file descriptor to the other end using the ancillary data in the Unix domain socket message (msg_control).");
            });

            Paragraph(.{})({
                Strong()({
                    forbear.text("enum");
                });
                forbear.text(": A single value (or bitmap) from an enumeration of known constants, encoded into a 32-bit integer.");
            });

            Heading(.{ .level = 2 })({
                forbear.text("Messages");
            });

            Paragraph(.{})({
                forbear.text("The wire protocol is a stream of messages built with these primitives. Every message is an event (in the case of server to client messages) or request (client to server) which acts upon an object.");
            });

            Paragraph(.{})({
                forbear.text("The message header is two words. The first word is the affected object ID. The second is two 16-bit values; the upper 16 bits are the size of the message (including the header itself) and the lower 16 bits are the event or request opcode. The message arguments follow, based on a message signature agreed upon in advance by both parties. The recipient looks up the object ID's interface and the event or request defined by its opcode to determine the signature and nature of the message.");
            });

            Paragraph(.{})({
                forbear.text("To understand a message, the client and server have to establish the objects in the first place. Object ID 1 is pre-allocated as the Wayland display singleton, and can be used to bootstrap other objects. We'll discuss this in chapter 4. The next chapter goes over what an interface is, and how requests and events work, assuming you've already negotiated an object ID. Speaking of which...");
            });

            Heading(.{ .level = 2 })({
                forbear.text("Object IDs");
            });

            Paragraph(.{})({
                forbear.text("When a message comes in with a new_id argument, the sender allocates an object ID for it \u{2014} the interface used for this object is established through additional arguments, or agreed upon in advance for that request/event. This object ID can be used in future messages, either as the first word of the header, or as an object_id argument. The client allocates IDs in the range of [1, 0xFEFFFFFF], and the server allocates IDs in the range of [0xFF000000, 0xFFFFFFFF]. IDs begin at the lower end of this bound and increment with each new object allocation.");
            });

            Paragraph(.{})({
                forbear.text("An object ID of 0 represents a null object; that is, a non-existent object or the explicit lack of an object.");
            });

            Heading(.{ .level = 2 })({
                forbear.text("Transports");
            });

            Paragraph(.{})({
                forbear.text("To date all known Wayland implementations work over a Unix domain socket. This is used for one reason in particular: file descriptor messages. Unix sockets are the most practical transport capable of transferring file descriptors between processes, and this is necessary for large data transfers (keymaps, pixel buffers, and clipboard contents being the main use-cases). In theory, a different transport (e.g. TCP) is possible, but someone would have to figure out an alternative way of transferring bulk data.");
            });

            Paragraph(.{})({
                forbear.text("To find the Unix socket to connect to, most implementations just do what libwayland does:");
            });

            List()({
                ListItem()({
                    forbear.text("If WAYLAND_SOCKET is set, interpret it as a file descriptor number on which the connection is already established, assuming that the parent process configured the connection for us.");
                });
                ListItem()({
                    forbear.text("If WAYLAND_DISPLAY is set, concat with XDG_RUNTIME_DIR to form the path to the Unix socket.");
                });
                ListItem()({
                    forbear.text("Assume the socket name is wayland-0 and concat with XDG_RUNTIME_DIR to form the path to the Unix socket.");
                });
                ListItem()({
                    forbear.text("Give up.");
                });
            });
        });
    });
}
