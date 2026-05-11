const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;
const Strong = @import("../strong.zig").Strong;

pub fn ProxiesAndResources() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Proxies & resources");
        });
        Paragraph(.{})({
            forbear.text("An ");
            Strong()({
                forbear.text("object");
            });
            forbear.text(" is an entity known to both the client and server that has some state, changes to which are negotiated over the wire. On the client side, libwayland refers to these objects through the ");
            Strong()({
                forbear.text("wl_proxy");
            });
            forbear.text(" interface. These are a concrete C-friendly \"proxy\" for the abstract object, and provides functions which are indirectly used by the client to marshall requests into the wire format. If you review the ");
            Strong()({
                forbear.text("wayland-client-core.h");
            });
            forbear.text(" file, you'll find a few low-level functions for this purpose. Generally, you don't use these directly.");
        });
        Paragraph(.{})({
            forbear.text("On the server, objects are abstracted through ");
            Strong()({
                forbear.text("wl_resource");
            });
            forbear.text(", which is fairly similar, but have an extra degree of complexity — the server has to track which object belongs to which client. Each ");
            Strong()({
                forbear.text("wl_resource");
            });
            forbear.text(" is owned by a single client. Aside from this, the interface is much the same, and provides low-level abstraction for marshalling events to send to the associated client. You will use ");
            Strong()({
                forbear.text("wl_resource");
            });
            forbear.text(" directly on a server more often than you'll use directly interface with ");
            Strong()({
                forbear.text("wl_proxy");
            });
            forbear.text(" on a client. One example of such a use is to obtain a reference to the ");
            Strong()({
                forbear.text("wl_client");
            });
            forbear.text(" which owns a resource that you're manipulating out-of-context, or send a protocol error when the client attempts an invalid operation.");
        });
        Paragraph(.{})({
            forbear.text("Another level up is another set of higher-level interfaces, which most Wayland clients & servers interact with to accomplish a majority of their tasks. We will look at them in the next section.");
        });
    });
}
