const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const List = @import("../list.zig").List;
const ListItem = @import("../list.zig").ListItem;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn SurfaceRegions() void {
    forbear.component(.{
        .sourceLocation = @src(),
    })({
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
                forbear.text("Surface regions");
            });

            Paragraph()({
                forbear.text("We've already used the wl_compositor interface to create wl_surfaces via wl_compositor.create_surface. Note, however, that it has a second request: create_region.");
            });

            // TODO: insert code block here

            Paragraph()({
                forbear.text("The wl_region interface defines a group of rectangles, which collectively make up an arbitrarily shaped region of geometry. Its requests allow you to do bitwise operations against the geometry it defines by adding or subtracting rectangles from it.");
            });

            // TODO: insert code block here

            Paragraph()({
                forbear.text("To make, for example, a rectangle with a hole in it, you could:");
            });

            List()({
                ListItem()({
                    forbear.text("Send wl_compositor.create_region to allocate a wl_region object.");
                });
                ListItem()({
                    forbear.text("Send wl_region.add(0, 0, 512, 512) to create a 512x512 rectangle.");
                });
                ListItem()({
                    forbear.text("Send wl_region.subtract(128, 128, 256, 256) to remove a 256x256 rectangle from the middle of the region.");
                });
            });

            Paragraph()({
                forbear.text("These areas can be disjoint as well; it needn't be a single continuous polygon. Once you've created one of these regions, you can pass it into the wl_surface interface, namely with the set_opaque_region and set_input_region requests.");
            });

            // TODO: insert code block here

            Paragraph()({
                forbear.text("The opaque region is a hint to the compositor as to which parts of your surface are considered opaque. Based on this information, they can optimize their rendering process. For example, if your surface is completely opaque and occludes another window beneath it, then the compositor won't waste any time on redrawing the window beneath yours. By default, this is empty, which assumes that any part of your surface might be transparent. This makes the default case the least efficient but the most correct.");
            });

            Paragraph()({
                forbear.text("The input region indicates which parts of your surface accept pointer and touch input events. You might, for example, draw a drop-shadow underneath your surface, but input events which happen in this region should be passed to the client beneath you. Or, if your window is an unusual shape, you could create an input region in that shape. For most surface types by default, your entire surface accepts input.");
            });

            Paragraph()({
                forbear.text("Both of these requests can be used to set an empty region by passing in null instead of a wl_region object. They're also both double-buffered \u{2014} so send a wl_surface.commit to make your changes effective. You can destroy the wl_region object to free up its resources as soon as you've sent the set_opaque_region or set_input_region requests with it. Updating the region after you send these requests will not update the state of the surface.");
            });
        });
    });
}
