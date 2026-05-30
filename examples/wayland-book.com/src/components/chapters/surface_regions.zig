const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;
const List = @import("../list.zig").List;
const ListItem = @import("../list.zig").ListItem;

pub fn SurfaceRegions() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Surface regions");
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("We've already used the ");
                forbear.Strong()({
                    forbear.write("wl_compositor");
                });
                forbear.write(" interface to create ");
                forbear.Strong()({
                    forbear.write("wl_surfaces");
                });
                forbear.write(" via ");
                forbear.Strong()({
                    forbear.write("wl_compositor.create_surface");
                });
                forbear.write(". Note, however, that it has a second request: ");
                forbear.Strong()({
                    forbear.write("create_region");
                });
                forbear.write(".");
            });
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("The ");
                forbear.Strong()({
                    forbear.write("wl_region");
                });
                forbear.write(" interface defines a group of rectangles, which collectively make up an arbitrarily shaped region of geometry. Its requests allow you to do bitwise operations against the geometry it defines by adding or subtracting rectangles from it.");
            });
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("To make, for example, a rectangle with a hole in it, you could:");
        });

        List()({
            ListItem()({
                forbear.composeText(.{})({
                    forbear.write("Send ");
                    forbear.Strong()({
                        forbear.write("wl_compositor.create_region");
                    });
                    forbear.write(" to allocate a ");
                    forbear.Strong()({
                        forbear.write("wl_region");
                    });
                    forbear.write(" object.");
                });
            });
            ListItem()({
                forbear.composeText(.{})({
                    forbear.write("Send ");
                    forbear.Strong()({
                        forbear.write("wl_region.add(0, 0, 512, 512)");
                    });
                    forbear.write(" to create a 512x512 rectangle.");
                });
            });
            ListItem()({
                forbear.composeText(.{})({
                    forbear.write("Send ");
                    forbear.Strong()({
                        forbear.write("wl_region.subtract(128, 128, 256, 256)");
                    });
                    forbear.write(" to remove a 256x256 rectangle from the middle of the region.");
                });
            });
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("These areas can be disjoint as well; it needn't be a single continuous polygon. Once you've created one of these regions, you can pass it into the ");
                forbear.Strong()({
                    forbear.write("wl_surface");
                });
                forbear.write(" interface, namely with the ");
                forbear.Strong()({
                    forbear.write("set_opaque_region");
                });
                forbear.write(" and ");
                forbear.Strong()({
                    forbear.write("set_input_region");
                });
                forbear.write(" requests.");
            });
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
            forbear.composeText(.{})({
                forbear.write("Both of these requests can be used to set an empty region by passing in null instead of a ");
                forbear.Strong()({
                    forbear.write("wl_region");
                });
                forbear.write(" object. They're also both double-buffered so send a ");
                forbear.Strong()({
                    forbear.write("wl_surface.commit");
                });
                forbear.write(" to make your changes effective. You can destroy the ");
                forbear.Strong()({
                    forbear.write("wl_region");
                });
                forbear.write(" object to free up its resources as soon as you've sent the ");
                forbear.Strong()({
                    forbear.write("set_opaque_region");
                });
                forbear.write(" or ");
                forbear.Strong()({
                    forbear.write("set_input_region");
                });
                forbear.write(" requests with it. Updating the region after you send these requests will not update the state of the surface.");
            });
        });
    });
}
