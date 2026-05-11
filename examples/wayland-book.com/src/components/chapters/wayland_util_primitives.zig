const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;
const List = @import("../list.zig").List;
const ListItem = @import("../list.zig").ListItem;

pub fn WaylandUtilPrimitives() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("wayland-util primitives");
        });

        Paragraph(.{})({
            forbear.text("Common to both the client and server libraries is wayland-util.h, which defines a number of structs, utility functions, and macros that establish a handful of primitives for use in Wayland applications. Among these are:");
        });

        List()({
            ListItem()({
                forbear.text("Structures for marshalling & unmarshalling Wayland protocol messages in generated code");
            });
            ListItem()({
                forbear.text("A linked list (wl_list) implementation");
            });
            ListItem()({
                forbear.text("An array (wl_array) implementation (rigged up to the corresponding Wayland primitive)");
            });
            ListItem()({
                forbear.text("Utilities for conversion between Wayland scalars (such as fixed-point numbers) and C types");
            });
            ListItem()({
                forbear.text("Debug logging facilities to bubble up information from libwayland internals");
            });
        });

        Paragraph(.{})({
            forbear.text("The header itself contains many comments with quite good documentation — you should read through them yourself. We'll go into detail on how to apply these primitives in the next several pages.");
        });
    });
}
