const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn GlobalsAndTheRegistry() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Globals & the registry");
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("If you'll recall from chapter 2.1, each request and event is associated with an object ID, but thus far we haven't discussed how objects are created. When we receive a Wayland message, we must know what interface the object ID represents to decode it. We must also somehow negotiate available objects, the creation of new ones, and the assigning of IDs to them, in some manner. In Wayland we solve both of these problems at once — when we ");
                forbear.Strong()({
                    forbear.write("bind");
                });
                forbear.write(" an object ID, we agree on the interface used for it in all future messages, and stash a mapping of object IDs to interfaces in our local state.");
            });
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("In order to bootstrap these, the server offers a list of ");
                forbear.Strong()({
                    forbear.write("global");
                });
                forbear.write(" objects. These globals often provide information and functionality on their own merits, but most often they're used to broker additional objects to fulfill various purposes, such as the creation of application windows. These globals themselves also have their own object IDs and interfaces, which we have to somehow assign and agree upon.");
            });
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("With questions of chickens and eggs no doubt coming to mind by now, I'll reveal the secret trick: object ID 1 is already implicitly assigned to the ");
                forbear.Strong()({
                    forbear.write("wl_display");
                });
                forbear.write(" interface when you make the connection. As you recall the interface, take note of the ");
                forbear.Strong()({
                    forbear.write("wl_display::get_registry");
                });
                forbear.write(" request:");
            });
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("The ");
                forbear.Strong()({
                    forbear.write("wl_display::get_registry");
                });
                forbear.write(" request can be used to bind an object ID to the ");
                forbear.Strong()({
                    forbear.write("wl_registry");
                });
                forbear.write(" interface, which is the next one found in ");
                forbear.Strong()({
                    forbear.write("wayland.xml");
                });
                forbear.write(". Given that the ");
                forbear.Strong()({
                    forbear.write("wl_display");
                });
                forbear.write(" always has object ID 1, the following wire message ought to make sense (in big-endian):");
            });
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("When we break this down, the first number is the object ID. The most significant 16 bits of the second number are the total length of the message in bytes, and the least significant bits are the request opcode. The remaining words (just one) are the arguments. In short, this calls request 1 (0-indexed) on object ID 1 (the ");
                forbear.Strong()({
                    forbear.write("wl_display");
                });
                forbear.write("), which accepts one argument: a generated ID for a new object. Note in the XML documentation that this new ID is defined ahead of time to be governed by the ");
                forbear.Strong()({
                    forbear.write("wl_registry");
                });
                forbear.write(" interface:");
            });
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("It is this interface which we'll discuss in the following chapters.");
        });
    });
}
