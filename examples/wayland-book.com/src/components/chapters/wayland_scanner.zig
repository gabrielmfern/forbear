const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;
const List = @import("../list.zig").List;
const ListItem = @import("../list.zig").ListItem;

pub fn WaylandScanner() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("wayland-scanner");
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("The Wayland package comes with one binary: ");
                forbear.Strong()({
                    forbear.write("wayland-scanner");
                });
                forbear.write(". This tool is used to generate C headers & glue code from the Wayland protocol XML files discussed in chapter 2.3. This tool is used in the \"wayland\" package's build process to pre-generate headers & glue code for the core protocol, ");
                forbear.Strong()({
                    forbear.write("wayland.xml");
                });
                forbear.write(". The headers become ");
                forbear.Strong()({
                    forbear.write("wayland-client-protocol.h");
                });
                forbear.write(" and ");
                forbear.Strong()({
                    forbear.write("wayland-server-protocol.h");
                });
                forbear.write(" — though you normally include ");
                forbear.Strong()({
                    forbear.write("wayland-client.h");
                });
                forbear.write(" and ");
                forbear.Strong()({
                    forbear.write("wayland-server.h");
                });
                forbear.write(" instead of using these directly.");
            });
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("The usage of this tool is fairly simple (and summarized by ");
                forbear.Strong()({
                    forbear.write("wayland-scanner -h");
                });
                forbear.write("), but can be summed up as follows. To generate a client header:");
            });
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("To generate a server header:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("And to generate the glue code:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("Different build systems will have different approaches to configuring custom commands — consult your build system's docs. Generally speaking, you'll want to run ");
                forbear.Strong()({
                    forbear.write("wayland-scanner");
                });
                forbear.write(" at build time, then compile and link your application to the glue code.");
            });
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("Go ahead and do this with any Wayland protocol now, if you have one handy (");
                forbear.Strong()({
                    forbear.write("wayland.xml");
                });
                forbear.write(" is probably available in ");
                forbear.Strong()({
                    forbear.write("/usr/share/wayland");
                });
                forbear.write(", for example). Open up the glue code & header and consult it as you read the following chapters, to understand how the primitives offered by libwayland are applied in practice in the generated code.");
            });
        });
    });
}
