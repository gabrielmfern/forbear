const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;
const Strong = @import("../strong.zig").Strong;

pub fn UsingWlCompositor() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Using wl_compositor");
        });

        Paragraph(.{})({
            forbear.text("They say naming things is one of the most difficult problems in computer science, and here we are, with evidence in hand. The ");
            Strong()({
                forbear.text("wl_compositor");
            });
            forbear.text(" global is the Wayland compositor's, er, compositor. Through this interface, you may send the server your windows for presentation, to be composited with the other windows being shown alongside it. The compositor has two jobs: the creation of surfaces and regions.");
        });

        Paragraph(.{})({
            forbear.text("To quote the spec, a Wayland ");
            Strong()({
                forbear.text("surface");
            });
            forbear.text(" has a rectangular area which may be displayed on zero or more outputs, present buffers, receive user input, and define a local coordinate system. We'll take all of these apart in detail later, but let's start with the basics: obtaining a surface and attaching a buffer to it. To obtain a surface, we first bind to the ");
            Strong()({
                forbear.text("wl_compositor");
            });
            forbear.text(" global. By extending the example from chapter 5.1 we get the following:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("Note that we've specified version 4 when calling ");
            Strong()({
                forbear.text("wl_registry_bind");
            });
            forbear.text(", which is the latest version at the time of writing. With this reference secured, we can create a ");
            Strong()({
                forbear.text("wl_surface");
            });
            forbear.text(":");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("Before we can present it, we must first attach a source of pixels to it: a ");
            Strong()({
                forbear.text("wl_buffer");
            });
            forbear.text(".");
        });
    });
}
