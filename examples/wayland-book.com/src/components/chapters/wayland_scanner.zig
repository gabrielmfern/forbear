const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;
const Strong = @import("../strong.zig").Strong;
const List = @import("../list.zig").List;
const ListItem = @import("../list.zig").ListItem;

pub fn WaylandScanner() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("wayland-scanner");
        });

        Paragraph(.{})({
            forbear.text("The Wayland package comes with one binary: ");
            Strong()({ forbear.text("wayland-scanner"); });
            forbear.text(". This tool is used to generate C headers & glue code from the Wayland protocol XML files discussed in chapter 2.3. This tool is used in the \"wayland\" package's build process to pre-generate headers & glue code for the core protocol, ");
            Strong()({ forbear.text("wayland.xml"); });
            forbear.text(". The headers become ");
            Strong()({ forbear.text("wayland-client-protocol.h"); });
            forbear.text(" and ");
            Strong()({ forbear.text("wayland-server-protocol.h"); });
            forbear.text(" — though you normally include ");
            Strong()({ forbear.text("wayland-client.h"); });
            forbear.text(" and ");
            Strong()({ forbear.text("wayland-server.h"); });
            forbear.text(" instead of using these directly.");
        });

        Paragraph(.{})({
            forbear.text("The usage of this tool is fairly simple (and summarized by ");
            Strong()({ forbear.text("wayland-scanner -h"); });
            forbear.text("), but can be summed up as follows. To generate a client header:");
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
            forbear.text("Different build systems will have different approaches to configuring custom commands — consult your build system's docs. Generally speaking, you'll want to run ");
            Strong()({ forbear.text("wayland-scanner"); });
            forbear.text(" at build time, then compile and link your application to the glue code.");
        });

        Paragraph(.{})({
            forbear.text("Go ahead and do this with any Wayland protocol now, if you have one handy (");
            Strong()({ forbear.text("wayland.xml"); });
            forbear.text(" is probably available in ");
            Strong()({ forbear.text("/usr/share/wayland"); });
            forbear.text(", for example). Open up the glue code & header and consult it as you read the following chapters, to understand how the primitives offered by libwayland are applied in practice in the generated code.");
        });
    });
}
