const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;
const Strong = @import("../strong.zig").Strong;
const List = @import("../list.zig").List;
const ListItem = @import("../list.zig").ListItem;

pub fn BindingInGlobals() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Binding to globals");
        });

        Paragraph(.{})({
            forbear.text("Upon creating a registry object, the server will emit the ");
            Strong()({ forbear.text("global"); });
            forbear.text(" event for each global available on the server. You can then bind to the globals you require.");
        });

        Paragraph(.{})({
            Strong()({ forbear.text("Binding"); });
            forbear.text(" is the process of taking a known object and assigning it an ID. Once the client binds to the registry like this, the server emits the ");
            Strong()({ forbear.text("global"); });
            forbear.text(" event several times to advertise which interfaces it supports. Each of these globals is assigned a unique ");
            Strong()({ forbear.text("name"); });
            forbear.text(", as an unsigned integer. The ");
            Strong()({ forbear.text("interface"); });
            forbear.text(" string maps to the name of the interface found in the protocol: ");
            Strong()({ forbear.text("wl_display"); });
            forbear.text(" from the XML above is an example of such a name. The version number is also defined here — for more information about interface versioning, see appendix C.");
        });

        Paragraph(.{})({
            forbear.text("To bind to any of these interfaces, we use the bind request, which works similarly to the magical process by which we bound to the ");
            Strong()({ forbear.text("wl_registry"); });
            forbear.text(". For example, consider this wire protocol exchange:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("The first message is identical to the one we've already dissected. The second one is an event from the server: object 2 (which the client assigned the ");
            Strong()({ forbear.text("wl_registry"); });
            forbear.text(" to in the first message) opcode 0 (\"global\"), with arguments 1, \"wl_shm\", and 1 — respectively the name, interface, and version of this global. The client responds by calling opcode 0 on object ID 2 (");
            Strong()({ forbear.text("wl_registry::bind"); });
            forbear.text(") and assigns object ID 3 to global name 1 — ");
            Strong()({ forbear.text("binding"); });
            forbear.text(" to the ");
            Strong()({ forbear.text("wl_shm"); });
            forbear.text(" global. Future events and requests for this object are defined by the ");
            Strong()({ forbear.text("wl_shm"); });
            forbear.text(" protocol, which you can find in ");
            Strong()({ forbear.text("wayland.xml"); });
            forbear.text(".");
        });

        Paragraph(.{})({
            forbear.text("Once you've created this object, you can utilize its interface to accomplish various tasks — in the case of ");
            Strong()({ forbear.text("wl_shm"); });
            forbear.text(", managing shared memory between the client and server. Most of the remainder of this book is devoted to explaining the usage of each of these globals.");
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
            Strong()({ forbear.text("Note"); });
            forbear.text(": this chapter the last time we're going to show wire protocol dumps in hexadecimal, and probably the last time you'll ever see them in general. A better way to trace your Wayland client or server is to set the ");
            Strong()({ forbear.text("WAYLAND_DEBUG"); });
            forbear.text(" variable in your environment to 1 before running your program. Try it now with the \"globals\" program!");
        });
    });
}
