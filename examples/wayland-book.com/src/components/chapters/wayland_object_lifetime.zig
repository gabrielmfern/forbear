const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn WaylandObjectLifetime() void {
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
                forbear.text("Wayland object lifetime");
            });

            Paragraph(.{})({
                forbear.text("Another important design pattern is avoiding a situation where the server or client is sending events or requests that pertain to an invalid object. For this reason, interfaces which define resources that have finite lifetimes will often include requests and events through which the client or server can state their intention to no longer send requests or events for that object. Only once both sides have agreed to this \u{2014} asynchronously \u{2014} do they destroy the resources they allocated for that object.");
            });

            Paragraph(.{})({
                forbear.text("Wayland is a fully asynchronous protocol. Messages are guaranteed to arrive in the order they were sent, but only with respect to one sender. For example, the server may have several input events queued up when the client decides to destroy its keyboard device. The client must correctly deal with events for an object it no longer needs until the server catches up. Likewise, had the client queued up some requests for an object before destroying it, it would have had to send these requests in the correct order so that the object is no longer used after the client agreed it had been destroyed.");
            });
        });
    });
}
