const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;
const Strong = @import("../strong.zig").Strong;

pub fn ConfigurationAndLifecycle() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Configuration & lifecycle");
        });

        Paragraph(.{})({
            forbear.text("Previously, we created a window at a fixed size of our choosing: 640x480. However, the compositor will often have an opinion about what size our window should assume, and we may want to communicate our preferences as well. Failure to do so will often lead to undesirable behavior, like parts of your window being cut off by a compositor who's trying to tell you to make your surface smaller.");
        });

        Paragraph(.{})({
            forbear.text("The compositor can offer additional clues to the application about the context in which it's being shown. It can let you know if your application is maximized or fullscreen, tiled on one or more sides against other windows or the edge of the display, focused or idle, and so on. As ");
            Strong()({
                forbear.text("wl_surface");
            });
            forbear.text(" is used to atomically communicate surface changes from client to server, the ");
            Strong()({
                forbear.text("xdg_surface");
            });
            forbear.text(" interface provides the following two messages for the compositor to suggest changes and the client to acknowledge them:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("On their own, these messages carry little meaning. However, each subclass of ");
            Strong()({
                forbear.text("xdg_surface");
            });
            forbear.text(" (");
            Strong()({
                forbear.text("xdg_toplevel");
            });
            forbear.text(" and ");
            Strong()({
                forbear.text("xdg_popup");
            });
            forbear.text(") have additional events that the server can send ahead of \"configure\", to make each of the suggestions we've mentioned so far. The server will send all of this state; maximized, focused, a suggested size; then a ");
            Strong()({
                forbear.text("configure");
            });
            forbear.text(" event with a serial. When the client has assumed a state consistent with these suggestions, it sends an ");
            Strong()({
                forbear.text("ack_configure");
            });
            forbear.text(" request with the same serial to indicate this. Upon the next commit to the associated ");
            Strong()({
                forbear.text("wl_surface");
            });
            forbear.text(", the compositor will consider the state consistent.");
        });

        Heading(.{ .level = 2 })({
            forbear.text("XDG top-level lifecycle");
        });

        Paragraph(.{})({
            forbear.text("Our example code from chapter 7 works, but it's not the best citizen of the desktop right now. It does not assume the compositor's recommended size, and if the user tries to close the window, it won't go away. Responding to these compositor-supplied events implicates two Wayland events: ");
            Strong()({
                forbear.text("configure");
            });
            forbear.text(" and ");
            Strong()({
                forbear.text("close");
            });
            forbear.text(".");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("The width and height are the compositor's preferred size for the window, and states is an array of the following values:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("The close event can be ignored, a typical reason being to show the user a confirmation to save their unsaved work. Our example code from chapter 7 can be updated fairly easily to support these events:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("If you compile and run this client again, you'll notice that it's a lot more well-behaved than before.");
        });

        Heading(.{ .level = 2 })({
            forbear.text("Requesting state changes");
        });

        Paragraph(.{})({
            forbear.text("The client can also request that the compositor put the client into one of these states, or place constraints on the size of the window.");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("The compositor indicates its acknowledgement of these requests by sending a corresponding configure event.");
        });
    });
}
