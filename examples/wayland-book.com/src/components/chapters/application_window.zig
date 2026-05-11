const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;
const Strong = @import("../strong.zig").Strong;
const List = @import("../list.zig").List;
const ListItem = @import("../list.zig").ListItem;

pub fn ApplicationWindow() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Application windows");
        });

        Paragraph(.{})({
            forbear.text("We have shaved many yaks to get here, but it's time: XDG toplevel is the interface which we will finally use to display an application window. The XDG toplevel interface has many requests and events for managing application windows, including dealing with minimized and maximized states, setting window titles, and so on. We'll be discussing each part of it in detail in future chapters, so let's just concern ourselves with the basics now.");
        });

        Paragraph(.{})({
            forbear.text("Based on our knowledge from the last chapter, we know that we can obtain an ");
            Strong()({ forbear.text("xdg_surface"); });
            forbear.text(" from a ");
            Strong()({ forbear.text("wl_surface"); });
            forbear.text(", but that it only constitutes the first step: bringing a surface into the fold of XDG shell. The next step is to turn that XDG surface into an XDG toplevel — a \"top-level\" application window, so named for its top-level position in the hierarchy of windows and popup menus we will eventually create with XDG shell. To create one of these, we can use the appropriate request from the ");
            Strong()({ forbear.text("xdg_surface"); });
            forbear.text(" interface:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("This new ");
            Strong()({ forbear.text("xdg_toplevel"); });
            forbear.text(" interface puts many requests and events at our disposal for managing the lifecycle of application windows. Chapter 10 explores these in depth, but I know you're itching to get something on-screen. If you follow these steps, handling the ");
            Strong()({ forbear.text("configure"); });
            forbear.text(" and ");
            Strong()({ forbear.text("ack_configure"); });
            forbear.text(" riggings for XDG surface discussed in the previous chapter, and attach and commit a ");
            Strong()({ forbear.text("wl_buffer"); });
            forbear.text(" to our ");
            Strong()({ forbear.text("wl_surface"); });
            forbear.text(", an application window will appear and present your buffer's contents to the user. Example code which does just this is provided in the next chapter. It also leverages one additional XDG toplevel request which we haven't covered yet:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("This should be fairly self-explanatory. There's a similar one that we don't use in the example code, but which may be appropriate for your application:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("The title is often shown in window decorations, taskbars, etc, whereas the app ID is used to identify your application or group your windows together. You might utilize these by setting your window title to \"Application windows — The Wayland Protocol — Firefox\", and your app ID to \"firefox\".");
        });

        Paragraph(.{})({
            forbear.text("In summary, the following steps will take you from zero to a window on-screen:");
        });

        List()({
            ListItem()({ forbear.text("Bind to ");
            Strong()({ forbear.text("wl_compositor"); });
            forbear.text(" and use it to create a ");
            Strong()({ forbear.text("wl_surface"); });
            forbear.text("."); });

            ListItem()({ forbear.text("Bind to ");
            Strong()({ forbear.text("xdg_wm_base"); });
            forbear.text(" and use it to create an ");
            Strong()({ forbear.text("xdg_surface"); });
            forbear.text(" with your ");
            Strong()({ forbear.text("wl_surface"); });
            forbear.text("."); });

            ListItem()({ forbear.text("Create an ");
            Strong()({ forbear.text("xdg_toplevel"); });
            forbear.text(" from the ");
            Strong()({ forbear.text("xdg_surface"); });
            forbear.text(" with ");
            Strong()({ forbear.text("xdg_surface.get_toplevel"); });
            forbear.text("."); });

            ListItem()({ forbear.text("Configure a listener for the ");
            Strong()({ forbear.text("xdg_surface"); });
            forbear.text(" and await the ");
            Strong()({ forbear.text("configure"); });
            forbear.text(" event."); });

            ListItem()({ forbear.text("Bind to the buffer allocation mechanism of your choosing (such as ");
            Strong()({ forbear.text("wl_shm"); });
            forbear.text(") and allocate a shared buffer, then render your content to it."); });

            ListItem()({ forbear.text("Use ");
            Strong()({ forbear.text("wl_surface.attach"); });
            forbear.text(" to attach the ");
            Strong()({ forbear.text("wl_buffer"); });
            forbear.text(" to the ");
            Strong()({ forbear.text("wl_surface"); });
            forbear.text("."); });

            ListItem()({ forbear.text("Use ");
            Strong()({ forbear.text("xdg_surface.ack_configure"); });
            forbear.text(", passing it the serial from ");
            Strong()({ forbear.text("configure"); });
            forbear.text(", acknowledging that you have prepared a suitable frame."); });

            ListItem()({ forbear.text("Send a ");
            Strong()({ forbear.text("wl_surface.commit"); });
            forbear.text(" request."); });
        });

        Paragraph(.{})({
            forbear.text("Turn the page to see these steps in action.");
        });
    });
}
