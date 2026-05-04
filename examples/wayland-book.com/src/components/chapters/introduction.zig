const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const list = @import("../list.zig");
const Strong = @import("../strong.zig").Strong;
const List = @import("../list.zig").List;
const ListItem = @import("../list.zig").ListItem;
const Paragraph = @import("../paragraph.zig").Paragraph;

fn LicenseBadge() !void {
    forbear.component(.{})({
        forbear.element(.{
            .style = .{
                .width = .{ .grow = 1.0 },
                .margin = forbear.Margin.top(6.0).withBottom(0.0),
            },
        })({
            forbear.element(.{
                .style = .{
                    .background = .{ .color = .{ 0.93, 0.93, 0.94, 1.0 } },
                },
            })({
                forbear.Image(.{
                    .borderRadius = 3.0,
                }, try forbear.useImage("license-badge"));
            });
        });
    });
}

pub fn Introduction() !void {
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
                forbear.text("Introduction");
            });

            Paragraph(.{})({
                forbear.text("Wayland is the next-generation display server for Unix-like systems, designed and built by the alumni of the venerable Xorg server, and is the best way to get your application windows onto your user's screens. Readers who have worked with X11 in the past will be pleasantly surprised by Wayland's improvements, and those who are new to graphics on Unix will find it a flexible and powerful system for building graphical applications and desktops.");
            });

            Paragraph(.{})({
                forbear.text("This book will help you establish a firm understanding of the concepts, design, and implementation of Wayland, and equip you with the tools to build your own Wayland client and server applications. Over the course of your reading, we'll build a mental model of Wayland and establish the rationale that went into its design. Within these pages you should find many \"aha!\" moments as the intuitive design choices of Wayland become clear, which should help to keep the pages turning. Welcome to the future of open source graphics!");
            });

            Paragraph(.{})({
                // TODO: the text for the actual notice should wrap around this
                Strong()({
                    forbear.text("Notice: ");
                });
                forbear.text("this is a draft. Chapters 1-10 are more or less complete, but may be updated later. Chapters 11 forward in large part remain to be written.");
            });

            forbear.element(.{
                .style = .{
                    .width = .{ .grow = 1.0 },
                    .direction = .vertical,
                    .margin = forbear.Margin.block(6.0).withBottom(18.0),
                },
            })({
                forbear.text("TODO");
                List()({
                    ListItem()({
                        forbear.text("Expand on resource lifetimes and avoiding race conditions in chapter 2.4");
                    });
                    ListItem()({
                        forbear.text("Move linux-dmabuf details to the appendix, add note about wl_drm & Mesa");
                    });
                    ListItem()({
                        forbear.text("Rewrite the introduction text");
                    });
                    ListItem()({
                        forbear.text("Add example code for interactive move, to demonstrate the use of serials");
                    });
                    ListItem()({
                        forbear.text("Prepare PDFs and EPUBs");
                    });
                });
            });

            Heading(.{ .level = 2 })({
                forbear.text("About the book");
            });
            Paragraph(.{})({
                forbear.text("This work is licensed under a Creative Commons Attribution-ShareAlike 4.0 International License. The source code is available here.");
            });
            try LicenseBadge();

            Heading(.{ .level = 2 })({
                forbear.text("About the author");
            });
            Paragraph(.{
                .style = .{
                    .fontSize = 13.0 + 1.0 / 3.0,
                },
            })({
                forbear.text("In the words of Preston Carpenter, a close collaborator of Drew's:");
            });

            Paragraph(.{})({
                forbear.text("Drew DeVault got his start in the Wayland world by building sway, a clone of the popular tiling window manager i3. It is now the most popular tiling Wayland compositor by any measure: users, commit count, and influence. Following its success, Drew gave back to the Wayland community by starting wlroots: unopinionated, composable modules for building a Wayland compositor. Today it is the foundation for dozens of independent compositors, and Drew is one of the foremost experts in Wayland.");
            });
        });
    });
}
