const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const List = @import("../list.zig").List;
const ListItem = @import("../list.zig").ListItem;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn WaylandProtocolAndLibwayland() void {
    forbear.component(.{
        .sourceLocation = @src(),
    })({
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
                forbear.text("Wayland protocol & libwayland");
            });

            Heading(.{ .level = 2 })({
                forbear.text("wayland-util primitives");
            });

            Paragraph(.{})({
                forbear.text("Common to both the client and server libraries is wayland-util.h, which defines a number of structs, utility functions, and macros that establish a handful of primitives for use in Wayland applications. Among these are:");
            });

            List()({
                ListItem()({
                    forbear.text("Structures for marshalling & unmarshalling Wayland protocol messages in generated code");
                });
                ListItem()({
                    forbear.text("A linked list (wl_list) implementation");
                });
                ListItem()({
                    forbear.text("An array (wl_array) implementation (rigged up to the corresponding Wayland primitive)");
                });
                ListItem()({
                    forbear.text("Utilities for conversion between Wayland scalars (such as fixed-point numbers) and C types");
                });
                ListItem()({
                    forbear.text("Debug logging facilities to bubble up information from libwayland internals");
                });
            });

            Paragraph(.{})({
                forbear.text("The header itself contains many comments with quite good documentation \u{2014} you should read through them yourself. We'll go into detail on how to apply these primitives in the next several pages.");
            });

            Heading(.{ .level = 2 })({
                forbear.text("Proxies & resources");
            });

            Paragraph(.{})({
                forbear.text("An object is an entity known to both the client and server that has some state, changes to which are negotiated over the wire. On the client side, libwayland refers to these objects through the wl_proxy interface. These are a concrete C-friendly \"proxy\" for the abstract object, and provides functions which are indirectly used by the client to marshall requests into the wire format. If you review the wayland-client-core.h file, you'll find a few low-level functions for this purpose. Generally, you don't use these directly.");
            });

            Paragraph(.{})({
                forbear.text("On the server, objects are abstracted through wl_resource, which is fairly similar, but have an extra degree of complexity \u{2014} the server has to track which object belongs to which client. Each wl_resource is owned by a single client. Aside from this, the interface is much the same, and provides low-level abstraction for marshalling events to send to the associated client. You will use wl_resource directly on a server more often than you'll use directly interface with wl_proxy on a client. One example of such a use is to obtain a reference to the wl_client which owns a resource that you're manipulating out-of-context, or send a protocol error when the client attempts an invalid operation.");
            });

            Paragraph(.{})({
                forbear.text("Another level up is another set of higher-level interfaces, which most Wayland clients & servers interact with to accomplish a majority of their tasks. We will look at them in the next section.");
            });

            Heading(.{ .level = 2 })({
                forbear.text("Interfaces & listeners");
            });

            Paragraph(.{})({
                forbear.text("Finally, we reach the summit of libwayland's abstractions: interfaces and listeners. The ideas discussed in previous chapters \u{2014} wl_proxy and wl_resource, and the primitives \u{2014} are singular implementations which live in libwayland, and they exist to provide support to this layer. When you run an XML file through wayland-scanner, it generates interfaces and listeners, as well as glue code between them and the low-level wire protocol interfaces, all specific to each interface in the high-level protocols.");
            });

            Paragraph(.{})({
                forbear.text("Recall that each actor on a Wayland connection can both receive and send messages. A client is listening for events and sending requests, and a server listens for requests and sends events. Each side listens for the messages of the other using an aptly-named wl_listener. Here's an example of this interface:");
            });

            // TODO: insert code block here

            Paragraph(.{})({
                forbear.text("This is a client-side listener for a wl_surface. The XML that wayland-scanner uses to generate this is:");
            });

            // TODO: insert code block here

            Paragraph(.{})({
                forbear.text("It should be fairly clear how these events become a listener interface. Each function pointer takes some arbitrary user data, a reference to the resource which the event applies to, and the additional arguments specified in the protocol. The server-side code for interfaces and listeners is identical, but reversed \u{2014} it generates listeners for requests and glue code for events. When libwayland receives a message, it looks up the object ID, and its interface, and dispatches the message accordingly.");
            });
        });
    });
}
