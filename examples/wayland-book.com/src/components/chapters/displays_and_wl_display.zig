const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn DisplaysAndWlDisplay() void {
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
                forbear.text("Displays and wl_display");
            });

            Paragraph(.{})({
                forbear.text("Up to this point, we've left a crucial detail out of our explanation of how the Wayland protocol manages joint ownership over objects between the client and server: how those objects are created in the first place. The Wayland display, or wl_display, implicitly exists on every Wayland connection. It has the following interface:");
            });

            // TODO: insert code block here

            Paragraph(.{})({
                forbear.text("The most interesting of these for the average Wayland user is get_registry, which we'll talk about in detail in the following chapter. In short, the registry is used to allocate other objects. The rest of the interface is used for housekeeping on the connection, and are generally not important unless you're writing your own libwayland replacement.");
            });

            Paragraph(.{})({
                forbear.text("Instead, this chapter will focus on a number of functions that libwayland associates with the wl_display object, for establishing and maintaining your Wayland connection. These are used to manipulate libwayland's internal state, rather than being directly related to wire protocol requests and events.");
            });

            Paragraph(.{})({
                forbear.text("We'll start with the most important of these functions: establishing the display. For clients, this will cover the actual process of connecting to the server, and for servers, the process of configuring a display for clients to connect to.");
            });
        });
    });
}
