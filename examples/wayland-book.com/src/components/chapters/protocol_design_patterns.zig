const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;
const Strong = @import("../strong.zig").Strong;
const List = @import("../list.zig").List;
const ListItem = @import("../list.zig").ListItem;

pub fn ProtocolDesignPatterns() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Protocol design patterns");
        });

        Paragraph(.{})({
            forbear.text("There are some key concepts which have been applied in the design of most Wayland protocols that we should briefly cover here. These patterns are found throughout the high-level Wayland protocol and protocol extensions (well, in the Wayland protocol, at least). If you find yourself writing your own protocol extensions, you'd be wise to apply these patterns yourself.");
        });

        Heading(.{ .level = 2 })({
            forbear.text("Atomicity");
        });

        Paragraph(.{})({
            forbear.text("The most important of the Wayland protocol design patterns is ");
            Strong()({
                forbear.text("atomicity");
            });
            forbear.text(". A stated goal of Wayland is \"every frame is perfect\". To this end, most interfaces allow you to update them transactionally, using several requests to build up a new representation of its state, then committing them all at once. For example, there are several properties that may be configured on a ");
            Strong()({
                forbear.text("wl_surface");
            });
            forbear.text(":");
        });

        List()({
            ListItem()({
                forbear.text("An attached pixel buffer");
            });
            ListItem()({
                forbear.text("A damaged area that needs to be redrawn");
            });
            ListItem()({
                forbear.text("A region defined as opaque, for optimization purposes");
            });
            ListItem()({
                forbear.text("A region where input events are acceptable");
            });
            ListItem()({
                forbear.text("A transformation, like rotating 90 degrees");
            });
            ListItem()({
                forbear.text("A buffer scale, used for HiDPI");
            });
        });

        Paragraph(.{})({
            forbear.text("The interface includes separate requests for configuring each of these, but these are applied to a ");
            Strong()({
                forbear.text("pending");
            });
            forbear.text(" state. Only when the ");
            Strong()({
                forbear.text("commit");
            });
            forbear.text(" request is sent does the pending state get merged into the ");
            Strong()({
                forbear.text("current");
            });
            forbear.text(" state, allowing you to atomically update all of these properties within a single frame. Combined with a few other key design decisions, this allows Wayland compositors to render everything perfectly in every frame — no tearing or partially updated windows, just every pixel in its place and every place in its pixel.");
        });

        Heading(.{ .level = 2 })({
            forbear.text("Resource lifetimes");
        });

        Paragraph(.{})({
            forbear.text("Another important design pattern is avoiding a situation where the server or client is sending events or requests that pertain to an invalid object. For this reason, interfaces which define resources that have finite lifetimes will often include requests and events through which the client or server can state their intention to no longer send requests or events for that object. Only once both sides have agreed to this — asynchronously — do they destroy the resources they allocated for that object.");
        });

        Paragraph(.{})({
            forbear.text("Wayland is a fully asynchronous protocol. Messages are guaranteed to arrive in the order they were sent, but only with respect to one sender. For example, the server may have several input events queued up when the client decides to destroy its keyboard device. The client must correctly deal with events for an object it no longer needs until the server catches up. Likewise, had the client queued up some requests for an object before destroying it, it would have had to send these requests in the correct order so that the object is no longer used after the client agreed it had been destroyed.");
        });

        Heading(.{ .level = 2 })({
            forbear.text("Versioning");
        });

        Paragraph(.{})({
            forbear.text("There are two versioning models in use in Wayland protocols: unstable and stable. Both models only allow for backwards-compatible changes, but when a protocol transitions from unstable to stable, one last breaking change is permitted. This gives protocols an incubation period during which we can test them in practice, then apply our insights in one last big set of breaking changes to make a protocol that should stand the test of time.");
        });

        Paragraph(.{})({
            forbear.text("To make a backwards-compatible change, you may only add new events or requests to the end of an interface, or new members to the end of an enum. Additionally, each implementation must limit itself to using only the messages supported by the other end of the connection. We'll discuss in chapter 5 how we establish which versions of each interface are in use by each party.");
        });
    });
}
