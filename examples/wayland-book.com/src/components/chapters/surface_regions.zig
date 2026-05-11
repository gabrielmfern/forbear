const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;
const Strong = @import("../strong.zig").Strong;
const List = @import("../list.zig").List;
const ListItem = @import("../list.zig").ListItem;

pub fn SurfaceRegions() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Surface regions");
        });

        Paragraph(.{})({
            forbear.text("We've already used the ");
            Strong()({
                forbear.text("wl_compositor");
            });
            forbear.text(" interface to create ");
            Strong()({
                forbear.text("wl_surfaces");
            });
            forbear.text(" via ");
            Strong()({
                forbear.text("wl_compositor.create_surface");
            });
            forbear.text(". Note, however, that it has a second request: ");
            Strong()({
                forbear.text("create_region");
            });
            forbear.text(".");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("The ");
            Strong()({
                forbear.text("wl_region");
            });
            forbear.text(" interface defines a group of rectangles, which collectively make up an arbitrarily shaped region of geometry. Its requests allow you to do bitwise operations against the geometry it defines by adding or subtracting rectangles from it.");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("To make, for example, a rectangle with a hole in it, you could:");
        });

        List()({
            ListItem()({
                forbear.text("Send ");
                Strong()({
                    forbear.text("wl_compositor.create_region");
                });
                forbear.text(" to allocate a ");
                Strong()({
                    forbear.text("wl_region");
                });
                forbear.text(" object.");
            });
            ListItem()({
                forbear.text("Send ");
                Strong()({
                    forbear.text("wl_region.add(0, 0, 512, 512)");
                });
                forbear.text(" to create a 512x512 rectangle.");
            });
            ListItem()({
                forbear.text("Send ");
                Strong()({
                    forbear.text("wl_region.subtract(128, 128, 256, 256)");
                });
                forbear.text(" to remove a 256x256 rectangle from the middle of the region.");
            });
        });

        Paragraph(.{})({
            forbear.text("These areas can be disjoint as well; it needn't be a single continuous polygon. Once you've created one of these regions, you can pass it into the ");
            Strong()({
                forbear.text("wl_surface");
            });
            forbear.text(" interface, namely with the ");
            Strong()({
                forbear.text("set_opaque_region");
            });
            forbear.text(" and ");
            Strong()({
                forbear.text("set_input_region");
            });
            forbear.text(" requests.");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("The opaque region is a hint to the compositor as to which parts of your surface are considered opaque. Based on this information, they can optimize their rendering process. For example, if your surface is completely opaque and occludes another window beneath it, then the compositor won't waste any time on redrawing the window beneath yours. By default, this is empty, which assumes that any part of your surface might be transparent. This makes the default case the least efficient but the most correct.");
        });

        Paragraph(.{})({
            forbear.text("The input region indicates which parts of your surface accept pointer and touch input events. You might, for example, draw a drop-shadow underneath your surface, but input events which happen in this region should be passed to the client beneath you. Or, if your window is an unusual shape, you could create an input region in that shape. For most surface types by default, your entire surface accepts input.");
        });

        Paragraph(.{})({
            forbear.text("Both of these requests can be used to set an empty region by passing in null instead of a ");
            Strong()({
                forbear.text("wl_region");
            });
            forbear.text(" object. They're also both double-buffered so send a ");
            Strong()({
                forbear.text("wl_surface.commit");
            });
            forbear.text(" to make your changes effective. You can destroy the ");
            Strong()({
                forbear.text("wl_region");
            });
            forbear.text(" object to free up its resources as soon as you've sent the ");
            Strong()({
                forbear.text("set_opaque_region");
            });
            forbear.text(" or ");
            Strong()({
                forbear.text("set_input_region");
            });
            forbear.text(" requests with it. Updating the region after you send these requests will not update the state of the surface.");
        });
    });
}
