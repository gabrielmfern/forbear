const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;
const List = @import("../list.zig").List;
const ListItem = @import("../list.zig").ListItem;

pub fn BindingInGlobals() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Binding to globals");
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("Upon creating a registry object, the server will emit the ");
                forbear.Strong()({
                    forbear.write("global");
                });
                forbear.write(" event for each global available on the server. You can then bind to the globals you require.");
            });
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.Strong()({
                    forbear.write("Binding");
                });
                forbear.write(" is the process of taking a known object and assigning it an ID. Once the client binds to the registry like this, the server emits the ");
                forbear.Strong()({
                    forbear.write("global");
                });
                forbear.write(" event several times to advertise which interfaces it supports. Each of these globals is assigned a unique ");
                forbear.Strong()({
                    forbear.write("name");
                });
                forbear.write(", as an unsigned integer. The ");
                forbear.Strong()({
                    forbear.write("interface");
                });
                forbear.write(" string maps to the name of the interface found in the protocol: ");
                forbear.Strong()({
                    forbear.write("wl_display");
                });
                forbear.write(" from the XML above is an example of such a name. The version number is also defined here — for more information about interface versioning, see appendix C.");
            });
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("To bind to any of these interfaces, we use the bind request, which works similarly to the magical process by which we bound to the ");
                forbear.Strong()({
                    forbear.write("wl_registry");
                });
                forbear.write(". For example, consider this wire protocol exchange:");
            });
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("The first message is identical to the one we've already dissected. The second one is an event from the server: object 2 (which the client assigned the ");
                forbear.Strong()({
                    forbear.write("wl_registry");
                });
                forbear.write(" to in the first message) opcode 0 (\"global\"), with arguments 1, \"wl_shm\", and 1 — respectively the name, interface, and version of this global. The client responds by calling opcode 0 on object ID 2 (");
                forbear.Strong()({
                    forbear.write("wl_registry::bind");
                });
                forbear.write(") and assigns object ID 3 to global name 1 — ");
                forbear.Strong()({
                    forbear.write("binding");
                });
                forbear.write(" to the ");
                forbear.Strong()({
                    forbear.write("wl_shm");
                });
                forbear.write(" global. Future events and requests for this object are defined by the ");
                forbear.Strong()({
                    forbear.write("wl_shm");
                });
                forbear.write(" protocol, which you can find in ");
                forbear.Strong()({
                    forbear.write("wayland.xml");
                });
                forbear.write(".");
            });
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("Once you've created this object, you can utilize its interface to accomplish various tasks — in the case of ");
                forbear.Strong()({
                    forbear.write("wl_shm");
                });
                forbear.write(", managing shared memory between the client and server. Most of the remainder of this book is devoted to explaining the usage of each of these globals.");
            });
        });

        Paragraph(.{})({
            forbear.text("Armed with this information, we can write our first useful Wayland client: one which simply prints all of the globals available on the server.");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("Feel free to reference previous chapters to interpret this program. We connect to the display (chapter 4.1), obtain the registry (this chapter), add a listener to it (chapter 3.4), then round-trip, handling the global event by printing the globals available on this compositor. Try it for yourself:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.Strong()({
                    forbear.write("Note");
                });
                forbear.write(": this chapter the last time we're going to show wire protocol dumps in hexadecimal, and probably the last time you'll ever see them in general. A better way to trace your Wayland client or server is to set the ");
                forbear.Strong()({
                    forbear.write("WAYLAND_DEBUG");
                });
                forbear.write(" variable in your environment to 1 before running your program. Try it now with the \"globals\" program!");
            });
        });
    });
}
