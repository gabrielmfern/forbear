const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;
const Strong = @import("../strong.zig").Strong;

pub fn GlobalsAndTheRegistry() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Globals & the registry");
        });

        Paragraph(.{})({
            forbear.text("If you'll recall from chapter 2.1, each request and event is associated with an object ID, but thus far we haven't discussed how objects are created. When we receive a Wayland message, we must know what interface the object ID represents to decode it. We must also somehow negotiate available objects, the creation of new ones, and the assigning of IDs to them, in some manner. In Wayland we solve both of these problems at once — when we ");
            Strong()({ forbear.text("bind"); });
            forbear.text(" an object ID, we agree on the interface used for it in all future messages, and stash a mapping of object IDs to interfaces in our local state.");
        });

        Paragraph(.{})({
            forbear.text("In order to bootstrap these, the server offers a list of ");
            Strong()({ forbear.text("global"); });
            forbear.text(" objects. These globals often provide information and functionality on their own merits, but most often they're used to broker additional objects to fulfill various purposes, such as the creation of application windows. These globals themselves also have their own object IDs and interfaces, which we have to somehow assign and agree upon.");
        });

        Paragraph(.{})({
            forbear.text("With questions of chickens and eggs no doubt coming to mind by now, I'll reveal the secret trick: object ID 1 is already implicitly assigned to the ");
            Strong()({ forbear.text("wl_display"); });
            forbear.text(" interface when you make the connection. As you recall the interface, take note of the ");
            Strong()({ forbear.text("wl_display::get_registry"); });
            forbear.text(" request:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("The ");
            Strong()({ forbear.text("wl_display::get_registry"); });
            forbear.text(" request can be used to bind an object ID to the ");
            Strong()({ forbear.text("wl_registry"); });
            forbear.text(" interface, which is the next one found in ");
            Strong()({ forbear.text("wayland.xml"); });
            forbear.text(". Given that the ");
            Strong()({ forbear.text("wl_display"); });
            forbear.text(" always has object ID 1, the following wire message ought to make sense (in big-endian):");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("When we break this down, the first number is the object ID. The most significant 16 bits of the second number are the total length of the message in bytes, and the least significant bits are the request opcode. The remaining words (just one) are the arguments. In short, this calls request 1 (0-indexed) on object ID 1 (the ");
            Strong()({ forbear.text("wl_display"); });
            forbear.text("), which accepts one argument: a generated ID for a new object. Note in the XML documentation that this new ID is defined ahead of time to be governed by the ");
            Strong()({ forbear.text("wl_registry"); });
            forbear.text(" interface:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("It is this interface which we'll discuss in the following chapters.");
        });
    });
}
