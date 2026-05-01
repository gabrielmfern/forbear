const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const List = @import("../list.zig").List;
const ListItem = @import("../list.zig").ListItem;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn ApplicationWindows() void {
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
                forbear.text("Application windows");
            });

            Paragraph()({
                forbear.text("We have shaved many yaks to get here, but it's time: XDG toplevel is the interface which we will finally use to display an application window. The XDG toplevel interface has many requests and events for managing application windows, including dealing with minimized and maximized states, setting window titles, and so on. We'll be discussing each part of it in detail in future chapters, so let's just concern ourselves with the basics now.");
            });

            Paragraph()({
                forbear.text("Based on our knowledge from the last chapter, we know that we can obtain an xdg_surface from a wl_surface, but that it only constitutes the first step: bringing a surface into the fold of XDG shell. The next step is to turn that XDG surface into an XDG toplevel \u{2014} a \"top-level\" application window, so named for its top-level position in the hierarchy of windows and popup menus we will eventually create with XDG shell. To create one of these, we can use the appropriate request from the xdg_surface interface:");
            });

            // TODO: insert code block here

            Paragraph()({
                forbear.text("This new xdg_toplevel interface puts many requests and events at our disposal for managing the lifecycle of application windows. Chapter 10 explores these in depth, but I know you're itching to get something on-screen. If you follow these steps, handling the configure and ack_configure riggings for XDG surface discussed in the previous chapter, and attach and commit a wl_buffer to our wl_surface, an application window will appear and present your buffer's contents to the user. Example code which does just this is provided in the next chapter. It also leverages one additional XDG toplevel request which we haven't covered yet:");
            });

            // TODO: insert code block here

            Paragraph()({
                forbear.text("This should be fairly self-explanatory. There's a similar one that we don't use in the example code, but which may be appropriate for your application:");
            });

            // TODO: insert code block here

            Paragraph()({
                forbear.text("The title is often shown in window decorations, taskbars, etc, whereas the app ID is used to identify your application or group your windows together. You might utilize these by setting your window title to \"Application windows \u{2014} The Wayland Protocol \u{2014} Firefox\", and your app ID to \"firefox\".");
            });

            Paragraph()({
                forbear.text("In summary, the following steps will take you from zero to a window on-screen:");
            });

            List()({
                ListItem()({
                    forbear.text("Bind to wl_compositor and use it to create a wl_surface.");
                });
                ListItem()({
                    forbear.text("Bind to xdg_wm_base and use it to create an xdg_surface with your wl_surface.");
                });
                ListItem()({
                    forbear.text("Create an xdg_toplevel from the xdg_surface with xdg_surface.get_toplevel.");
                });
                ListItem()({
                    forbear.text("Configure a listener for the xdg_surface and await the configure event.");
                });
                ListItem()({
                    forbear.text("Bind to the buffer allocation mechanism of your choosing (such as wl_shm) and allocate a shared buffer, then render your content to it.");
                });
                ListItem()({
                    forbear.text("Use wl_surface.attach to attach the wl_buffer to the wl_surface.");
                });
                ListItem()({
                    forbear.text("Use xdg_surface.ack_configure, passing it the serial from configure, acknowledging that you have prepared a suitable frame.");
                });
                ListItem()({
                    forbear.text("Send a wl_surface.commit request.");
                });
            });

            Paragraph()({
                forbear.text("Turn the page to see these steps in action.");
            });
        });
    });
}
