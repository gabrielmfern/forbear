const forbear = @import("forbear");
const colors = @import("../colors.zig");
const Section = @import("section.zig").Section;
const List = @import("./list.zig").List;
const ListItem = @import("./list.zig").ListItem;

pub fn Benefits() !void {
    forbear.component(null)({
        Section(.{
            .direction = .vertical,
            .borderWidth = .bottom(2.0),
            .borderColor = colors.black,
            .padding = .bottom(69.0),
        })({
            forbear.element(.{ .style = .{
                .yJustification = .center,
            } })({
                forbear.element(.{ .style = .{
                    .width = .{ .grow = 1.0 },
                    .direction = .vertical,
                } })({
                    forbear.element(.{ .style = .{
                        .fontWeight = 700,
                        .fontSize = 40.0,
                        .margin = forbear.Margin.top(20.0).withBottom(25.0),
                    } })({
                        forbear.text("Your tech works. People are happy. Time comes back.");
                    });
                    List()({
                        ListItem()({
                            forbear.text("Faster onboarding for new hires");
                        });
                        ListItem()({
                            forbear.text("Slack, Zoom, Email - we're already there");
                        });
                        ListItem()({
                            forbear.text("Standardized tools + backups");
                        });
                        ListItem()({
                            forbear.text("Clear, human support docs");
                        });
                        ListItem()({
                            forbear.text("Less time explaining what 'ISP' means");
                        });
                    });
                });
                forbear.Image(.{
                    .width = .{ .grow = 1.0 },
                    .maxWidth = 369,
                    .blendMode = .darken,
                    .margin = forbear.Margin.left(20.0),
                }, try forbear.useImage("uhoh-group-21"));
            });
            forbear.element(.{ .style = .{
                .yJustification = .center,
                .margin = .top(40.0),
            } })({
                forbear.Image(.{
                    .width = .{ .grow = 1.0 },
                    .maxWidth = 169,
                    .blendMode = .multiply,
                    .margin = .right(40.0),
                }, try forbear.useImage("uhoh-failure"));
                forbear.element(.{ .style = .{
                    .fontSize = 20.0,
                    .width = .{ .grow = 1.0 },
                    .margin = .bottom(25.0),
                } })({
                    forbear.text("Or... keep asking your most tech-savvy employee to fix the WiFi. You could save money, time, and headaches - or keep duct-taping your IT together until it breaks.");
                });
            });
        });
    });
}
