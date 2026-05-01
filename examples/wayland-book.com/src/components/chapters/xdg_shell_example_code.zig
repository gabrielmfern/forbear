const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn XdgShellExampleCode() void {
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
                forbear.text("Example code");
            });

            Paragraph(.{})({
                forbear.text("Using the sum of what we've learned so far, we can now write a Wayland client which displays something on the screen. The following code is a complete Wayland application which opens an XDG toplevel window and shows a 640x480 grid of squares on it. Compile it like so:");
            });

            // TODO: insert code block here

            Paragraph(.{})({
                forbear.text("Then run ./client to see it in action, or WAYLAND_DEBUG=1 ./client to include a bunch of useful debugging information. Tada! In future chapters we will be building upon this client, so stow this code away somewhere safe.");
            });

            // TODO: insert code block here
        });
    });
}
