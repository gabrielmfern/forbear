const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn BeyondTheBasics() void {
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
                forbear.text("Beyond the basics");
            });

            Paragraph(.{})({
                forbear.text("This chapter is not yet authored upstream. The Wayland Book at wayland-book.com does not contain a standalone \"Beyond the basics\" chapter. The phrase appears only as a transitional aside in the seat example chapter's \"What's next?\" section, which previews the remaining material covered by the chapters that follow: XDG shell in depth, clipboard and drag-and-drop, and high-DPI support.");
            });
        });
    });
}
