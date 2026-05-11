const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;
const Strong = @import("../strong.zig").Strong;

pub fn InterfacesRequestsEvents() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Interfaces, requests, and events");
        });

        Paragraph(.{})({
            forbear.text("The Wayland protocol works by issuing ");
            Strong()({
                forbear.text("requests");
            });
            forbear.text(" and ");
            Strong()({
                forbear.text("events");
            });
            forbear.text(" that act on ");
            Strong()({
                forbear.text("objects");
            });
            forbear.text(". Each object has an ");
            Strong()({
                forbear.text("interface");
            });
            forbear.text(" which defines what requests and events are possible, and the ");
            Strong()({
                forbear.text("signature");
            });
            forbear.text(" of each. Let's consider an example interface: ");
            Strong()({
                forbear.text("wl_surface");
            });
            forbear.text(".");
        });

        Heading(.{ .level = 2 })({
            forbear.text("Requests");
        });

        Paragraph(.{})({
            forbear.text("A surface is a box of pixels that can be displayed on-screen. It's one of the primitives we build things like application windows out of. One of its ");
            Strong()({
                forbear.text("requests");
            });
            forbear.text(", sent from the client to the server, is \"damage\", which the client uses to indicate that some part of the surface has changed and needs to be redrawn. Here's an annotated example of a \"damage\" message on the wire (in hexadecimal):");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("This is a snippet of a session — the surface was allocated earlier and assigned an ID of 10. When the server receives this message, it looks up the object with ID 10 and finds that it's a ");
            Strong()({
                forbear.text("wl_surface");
            });
            forbear.text(" instance. Knowing this, it looks up the signature for the request with opcode 2. It then knows to expect four integers as the arguments, and it can decode the message and dispatch it for processing internally.");
        });

        Heading(.{ .level = 2 })({
            forbear.text("Events");
        });

        Paragraph(.{})({
            forbear.text("The server can also send messages back to the client — events. One event that the server can send regarding a ");
            Strong()({
                forbear.text("wl_surface");
            });
            forbear.text(" is \"enter\", which it sends when that surface is being displayed on a specific output (the client might respond to this, for example, by adjusting its scale factor for a HiDPI display). Here's an example of such a message:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("This message references another object, by its ID: the ");
            Strong()({
                forbear.text("wl_output");
            });
            forbear.text(" object which the surface is being shown on. The client receives this and dances to a similar tune as the server did. It looks up object 10, associates it with the ");
            Strong()({
                forbear.text("wl_surface");
            });
            forbear.text(" interface, and looks up the signature of the event corresponding to opcode 0. It decodes the rest of the message accordingly, looking up the ");
            Strong()({
                forbear.text("wl_output");
            });
            forbear.text(" with ID 5 as well, then dispatches it for processing internally.");
        });

        Heading(.{ .level = 2 })({
            forbear.text("Interfaces");
        });

        Paragraph(.{})({
            forbear.text("The interfaces which define the list of requests and events, the opcodes associated with each, and the signatures with which you can decode the messages, are agreed upon in advance. I'm sure you're dying to know how — simply turn the page to end the suspense.");
        });
    });
}
