const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn ProxiesAndResources() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Proxies & resources");
        });
        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("An ");
                forbear.Strong()({
                    forbear.write("object");
                });
                forbear.write(" is an entity known to both the client and server that has some state, changes to which are negotiated over the wire. On the client side, libwayland refers to these objects through the ");
                forbear.Strong()({
                    forbear.write("wl_proxy");
                });
                forbear.write(" interface. These are a concrete C-friendly \"proxy\" for the abstract object, and provides functions which are indirectly used by the client to marshall requests into the wire format. If you review the ");
                forbear.Strong()({
                    forbear.write("wayland-client-core.h");
                });
                forbear.write(" file, you'll find a few low-level functions for this purpose. Generally, you don't use these directly.");
            });
        });
        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("On the server, objects are abstracted through ");
                forbear.Strong()({
                    forbear.write("wl_resource");
                });
                forbear.write(", which is fairly similar, but have an extra degree of complexity — the server has to track which object belongs to which client. Each ");
                forbear.Strong()({
                    forbear.write("wl_resource");
                });
                forbear.write(" is owned by a single client. Aside from this, the interface is much the same, and provides low-level abstraction for marshalling events to send to the associated client. You will use ");
                forbear.Strong()({
                    forbear.write("wl_resource");
                });
                forbear.write(" directly on a server more often than you'll use directly interface with ");
                forbear.Strong()({
                    forbear.write("wl_proxy");
                });
                forbear.write(" on a client. One example of such a use is to obtain a reference to the ");
                forbear.Strong()({
                    forbear.write("wl_client");
                });
                forbear.write(" which owns a resource that you're manipulating out-of-context, or send a protocol error when the client attempts an invalid operation.");
            });
        });
        Paragraph(.{})({
            forbear.text("Another level up is another set of higher-level interfaces, which most Wayland clients & servers interact with to accomplish a majority of their tasks. We will look at them in the next section.");
        });
    });
}
