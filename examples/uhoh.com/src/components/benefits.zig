const forbear = @import("forbear");
const colors = @import("../colors.zig");
const Section = @import("section.zig").Section;

const benefits = [_][]const u8{
    "Faster onboarding for new hires",
    "Slack, Zoom, Email - we're already there",
    "Standardized tools + backups",
    "Clear, human support docs",
    "Less time explaining what 'ISP' means",
};

pub fn Benefits() !void {
    Section(.{
        .yJustification = .start,
        .padding = forbear.Padding.top(22.5).withBottom(30.0),
    })({
        forbear.element(.{
            .direction = .horizontal,
            .xJustification = .start,
            .yJustification = .center,
        })({
            forbear.element(.{
                .width = .{ .fixed = 390.0 },
                .direction = .vertical,
            })({
                forbear.element(.{
                    .fontWeight = 700,
                    .fontSize = 22.5,
                    .margin = forbear.Margin.block(0.0).withBottom(10.5),
                })({
                    forbear.text("Your tech works. People are happy. Time comes back.");
                });
                inline for (benefits) |benefit| {
                    forbear.element(.{
                        .direction = .horizontal,
                        .margin = forbear.Margin.block(0.0).withBottom(6.0),
                        .xJustification = .start,
                        .yJustification = .center,
                    })({
                        forbear.element(.{
                            .width = .{ .fixed = 6.0 },
                            .height = .{ .fixed = 6.0 },
                            .borderRadius = 3.0,
                            .margin = forbear.Margin.inLine(0.0).withRight(7.5),
                        })({});
                        forbear.element(.{ .fontSize = 12.0 })({
                            forbear.text(benefit);
                        });
                    });
                }
            });
            forbear.image(.{
                .width = .{ .grow = 1.0 },
                .maxWidth = 169,
                .blendMode = .multiply,
                .margin = forbear.Margin.left(24.0),
            }, try forbear.useImage("uhoh-group-21"));
        });
        forbear.element(.{
            .direction = .horizontal,
            .xJustification = .start,
            .yJustification = .center,
            .margin = forbear.Margin.block(13.5).withBottom(0.0),
        })({
            forbear.image(.{
                .width = .{ .grow = 1.0 },
                .maxWidth = 169,
                .blendMode = .multiply,
                .margin = forbear.Margin.inLine(0.0).withRight(10.5),
            }, try forbear.useImage("uhoh-failure"));
            forbear.element(.{
                .fontSize = 12.0,
            })({
                forbear.text("Or... keep asking your most tech-savvy employee to fix the WiFi. You could save money, time, and headaches - or keep duct-taping your IT together until it breaks.");
            });
        });
    });
}
