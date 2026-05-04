const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn XdgShellInDepth() void {
    forbear.component(.{})({
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
                forbear.text("XDG shell, in depth");
            });

            Paragraph(.{})({
                forbear.text("So far we've managed to display something on-screen in a top-level application window, but there's more to XDG shell that we haven't fully appreciated yet. Even the simplest application would be well-served to implement the configuration lifecycle correctly, and xdg-shell offers useful features to more complex application as well. The full breadth of xdg-shell's feature set includes client/server negotiation on window size, multi-window hierarchies, client-side decorations, and semantic positioning for windows like context menus.");
            });
        });
    });
}
