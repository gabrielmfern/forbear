const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn UsingWlCompositor() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Using wl_compositor");
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("They say naming things is one of the most difficult problems in computer science, and here we are, with evidence in hand. The ");
                forbear.Strong()({
                    forbear.write("wl_compositor");
                });
                forbear.write(" global is the Wayland compositor's, er, compositor. Through this interface, you may send the server your windows for presentation, to be composited with the other windows being shown alongside it. The compositor has two jobs: the creation of surfaces and regions.");
            });
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("To quote the spec, a Wayland ");
                forbear.Strong()({
                    forbear.write("surface");
                });
                forbear.write(" has a rectangular area which may be displayed on zero or more outputs, present buffers, receive user input, and define a local coordinate system. We'll take all of these apart in detail later, but let's start with the basics: obtaining a surface and attaching a buffer to it. To obtain a surface, we first bind to the ");
                forbear.Strong()({
                    forbear.write("wl_compositor");
                });
                forbear.write(" global. By extending the example from chapter 5.1 we get the following:");
            });
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("Note that we've specified version 4 when calling ");
                forbear.Strong()({
                    forbear.write("wl_registry_bind");
                });
                forbear.write(", which is the latest version at the time of writing. With this reference secured, we can create a ");
                forbear.Strong()({
                    forbear.write("wl_surface");
                });
                forbear.write(":");
            });
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("Before we can present it, we must first attach a source of pixels to it: a ");
                forbear.Strong()({
                    forbear.write("wl_buffer");
                });
                forbear.write(".");
            });
        });
    });
}
