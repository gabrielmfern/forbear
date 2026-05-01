const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn ProtocolDesign() void {
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
                forbear.text("Protocol Design");
            });

            Paragraph()({
                forbear.text("The Wayland protocol is built from several layers of abstraction. It starts with a basic wire protocol format, which is a stream of messages decodable with interfaces agreed upon in advance. Then we have higher level procedures for enumerating interfaces, creating resources which conform to these interfaces, and exchanging messages about them \u{2014} the Wayland protocol and its extensions. On top of this we have some broader patterns which are frequently used in Wayland protocol design. We'll cover all of these in this chapter.");
            });

            Paragraph()({
                forbear.text("Let's work our way from the bottom-up.");
            });
        });
    });
}
