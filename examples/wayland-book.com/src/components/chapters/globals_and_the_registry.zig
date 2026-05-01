const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn GlobalsAndTheRegistry() void {
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
                forbear.text("Globals & the registry");
            });

            Paragraph(.{})({
                forbear.text("This chapter introduces how Wayland clients discover and bind to objects exposed by the server. Each request and event in the protocol is associated with an object ID, and a client must know what interface that ID represents in order to decode the message. Wayland addresses object discovery and ID assignment together: when a client binds an object ID, both peers agree on the interface that governs all future messages on it, and the client records that mapping locally.");
            });

            Paragraph(.{})({
                forbear.text("To bootstrap this process, the server publishes a set of global objects. Globals sometimes provide functionality directly, but more often they act as factories for additional objects that fulfill specific purposes such as creating application windows. The globals themselves still need object IDs and interfaces assigned through some agreed-upon mechanism.");
            });

            Paragraph(.{})({
                forbear.text("The bootstrap trick is that object ID 1 is implicitly assigned to the wl_display interface as soon as the connection is established. The wl_display interface defines a get_registry request that returns a wl_registry, the entry point for discovering globals.");
            });

            // TODO: insert code block here

            Paragraph(.{})({
                forbear.text("Calling wl_display::get_registry binds a new object ID to the wl_registry interface, which is the next interface defined in wayland.xml. Because wl_display always has object ID 1, the wire-level message that performs this call has a recognizable shape when written in big-endian form.");
            });

            // TODO: insert code block here

            Paragraph(.{})({
                forbear.text("Reading that wire message: the first word is the target object ID, the high 16 bits of the second word give the total message length in bytes, and the low 16 bits give the request opcode. Remaining words are arguments. The example invokes opcode 1 on object ID 1 (the wl_display) and supplies a single argument: the new ID that will be governed by the wl_registry interface, as declared in the XML.");
            });

            // TODO: insert code block here

            Paragraph(.{})({
                forbear.text("The wl_registry interface itself is the subject of the following sections.");
            });
        });
    });
}
