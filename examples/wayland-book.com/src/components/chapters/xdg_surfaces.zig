const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;
const Strong = @import("../strong.zig").Strong;

pub fn XdgSurfaces() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("XDG surfaces");
        });

        Paragraph(.{})({
            forbear.text("Surfaces in the domain of xdg-shell are referred to as ");
            Strong()({
                forbear.text("xdg_surfaces");
            });
            forbear.text(", and this interface brings with it a small amount of functionality common to both kinds of XDG surfaces — toplevels and popups. The semantics for each kind of XDG surface are different enough still that they must be specified explicitly through an additional role.");
        });

        Paragraph(.{})({
            forbear.text("The ");
            Strong()({
                forbear.text("xdg_surface");
            });
            forbear.text(" interface provides additional requests for assigning the more specific roles of popup and toplevel. Once we've bound an object to the ");
            Strong()({
                forbear.text("xdg_wm_base");
            });
            forbear.text(" global, we can use the ");
            Strong()({
                forbear.text("get_xdg_surface");
            });
            forbear.text(" request to obtain one for a ");
            Strong()({
                forbear.text("wl_surface");
            });
            forbear.text(".");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("The ");
            Strong()({
                forbear.text("xdg_surface");
            });
            forbear.text(" interface, in addition to requests for assigning a more specific role of toplevel or popup to your surface, also includes some important functionality common to both roles. Let's review these before we move on to the toplevel and popup-specific semantics.");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("The most important API of xdg-surface is this pair: ");
            Strong()({
                forbear.text("configure");
            });
            forbear.text(" and ");
            Strong()({
                forbear.text("ack_configure");
            });
            forbear.text(". You may recall that a goal of Wayland is to make every frame perfect. That means no frames are shown with a half-applied state change, and to accomplish this we have to synchronize these changes between the client and server. For XDG surfaces, this pair of messages is the mechanism which supports this.");
        });

        Paragraph(.{})({
            forbear.text("We're only covering the basics for now, so we'll summarize the importance of these two events as such: as events from the server inform your configuration (or reconfiguration) of a surface, apply them to a pending state. When a ");
            Strong()({
                forbear.text("configure");
            });
            forbear.text(" event arrives, apply the pending changes, use ");
            Strong()({
                forbear.text("ack_configure");
            });
            forbear.text(" to acknowledge you've done so, and render and commit a new frame. We'll show this in practice in the next chapter, and explain it in detail in chapter 8.1.");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("The ");
            Strong()({
                forbear.text("set_window_geometry");
            });
            forbear.text(" request is used primarily for applications using client-side decorations, to distinguish the parts of their surface which are considered a part of the window, and the parts which are not. Most commonly, this is used to exclude client-side drop-shadows rendered behind the window from being considered a part of it. The compositor may apply this information to govern its own behaviors for arranging and interacting with the window.");
        });
    });
}
