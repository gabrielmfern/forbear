const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn XdgSurfaces() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("XDG surfaces");
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("Surfaces in the domain of xdg-shell are referred to as ");
                forbear.Strong()({
                    forbear.write("xdg_surfaces");
                });
                forbear.write(", and this interface brings with it a small amount of functionality common to both kinds of XDG surfaces — toplevels and popups. The semantics for each kind of XDG surface are different enough still that they must be specified explicitly through an additional role.");
            });
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("The ");
                forbear.Strong()({
                    forbear.write("xdg_surface");
                });
                forbear.write(" interface provides additional requests for assigning the more specific roles of popup and toplevel. Once we've bound an object to the ");
                forbear.Strong()({
                    forbear.write("xdg_wm_base");
                });
                forbear.write(" global, we can use the ");
                forbear.Strong()({
                    forbear.write("get_xdg_surface");
                });
                forbear.write(" request to obtain one for a ");
                forbear.Strong()({
                    forbear.write("wl_surface");
                });
                forbear.write(".");
            });
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("The ");
                forbear.Strong()({
                    forbear.write("xdg_surface");
                });
                forbear.write(" interface, in addition to requests for assigning a more specific role of toplevel or popup to your surface, also includes some important functionality common to both roles. Let's review these before we move on to the toplevel and popup-specific semantics.");
            });
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("The most important API of xdg-surface is this pair: ");
                forbear.Strong()({
                    forbear.write("configure");
                });
                forbear.write(" and ");
                forbear.Strong()({
                    forbear.write("ack_configure");
                });
                forbear.write(". You may recall that a goal of Wayland is to make every frame perfect. That means no frames are shown with a half-applied state change, and to accomplish this we have to synchronize these changes between the client and server. For XDG surfaces, this pair of messages is the mechanism which supports this.");
            });
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("We're only covering the basics for now, so we'll summarize the importance of these two events as such: as events from the server inform your configuration (or reconfiguration) of a surface, apply them to a pending state. When a ");
                forbear.Strong()({
                    forbear.write("configure");
                });
                forbear.write(" event arrives, apply the pending changes, use ");
                forbear.Strong()({
                    forbear.write("ack_configure");
                });
                forbear.write(" to acknowledge you've done so, and render and commit a new frame. We'll show this in practice in the next chapter, and explain it in detail in chapter 8.1.");
            });
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("The ");
                forbear.Strong()({
                    forbear.write("set_window_geometry");
                });
                forbear.write(" request is used primarily for applications using client-side decorations, to distinguish the parts of their surface which are considered a part of the window, and the parts which are not. Most commonly, this is used to exclude client-side drop-shadows rendered behind the window from being considered a part of it. The compositor may apply this information to govern its own behaviors for arranging and interacting with the window.");
            });
        });
    });
}
