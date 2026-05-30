const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn InterfacesAndListeners() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Interfaces & listeners");
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("Finally, we reach the summit of libwayland's abstractions: interfaces and listeners. The ideas discussed in previous chapters — ");
                forbear.Strong()({
                    forbear.write("wl_proxy");
                });
                forbear.write(" and ");
                forbear.Strong()({
                    forbear.write("wl_resource");
                });
                forbear.write(", and the primitives — are singular implementations which live in libwayland, and they exist to provide support to this layer. When you run an XML file through wayland-scanner, it generates ");
                forbear.Strong()({
                    forbear.write("interfaces");
                });
                forbear.write(" and ");
                forbear.Strong()({
                    forbear.write("listeners");
                });
                forbear.write(", as well as glue code between them and the low-level wire protocol interfaces, all specific to each interface in the high-level protocols.");
            });
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("Recall that each actor on a Wayland connection can both receive and send messages. A client is listening for events and sending requests, and a server listens for requests and sends events. Each side listens for the messages of the other using an aptly-named ");
                forbear.Strong()({
                    forbear.write("wl_listener");
                });
                forbear.write(". Here's an example of this interface:");
            });
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("This is a client-side listener for a ");
                forbear.Strong()({
                    forbear.write("wl_surface");
                });
                forbear.write(". The XML that wayland-scanner uses to generate this is:");
            });
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("It should be fairly clear how these events become a listener interface. Each function pointer takes some arbitrary user data, a reference to the resource which the event pertains to, and the arguments to that event. We can bind a listener to a ");
                forbear.Strong()({
                    forbear.write("wl_surface");
                });
                forbear.write(" like so:");
            });
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("The ");
                forbear.Strong()({
                    forbear.write("wl_surface");
                });
                forbear.write(" interface also defines some requests that the client can make for that surface:");
            });
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("wayland-scanner generates the following prototype, as well as glue code which marshalls this message.");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("The server-side code for interfaces and listeners is identical, but reversed — it generates listeners for requests and glue code for events. When libwayland receives a message, it looks up the object ID, and its interface, then uses that to decode the rest of the message. Then it looks for listeners on this object and invokes your functions with the arguments to the message.");
        });

        Paragraph(.{})({
            forbear.text("That's all there is to it! It took us a couple of layers of abstraction to get here, but you should now understand how an event starts in your server code, becomes a message on the wire, is understood by the client, and dispatched to your client code. There remains one unanswered question, however. All of this presupposes that you already have references to Wayland objects. How do you get those?");
        });
    });
}
