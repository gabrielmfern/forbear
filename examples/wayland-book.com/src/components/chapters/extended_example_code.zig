const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn ExtendedExampleCode() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Extended example code");
        });

        Paragraph(.{})({
            forbear.text("Using the sum of what we've learned so far, we can now write a Wayland client which displays something on the screen. The following code is a complete Wayland application which opens an XDG toplevel window and shows a 640x480 grid of squares on it. Compile it like so:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("Then run ");
                forbear.Strong()({
                    forbear.write("./client");
                });
                forbear.write(" to see it in action, or ");
                forbear.Strong()({
                    forbear.write("WAYLAND_DEBUG=1 ./client");
                });
                forbear.write(" to include a bunch of useful debugging information. Tada! In future chapters we will be building upon this client, so stow this code away somewhere safe.");
            });
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });
    });
}
