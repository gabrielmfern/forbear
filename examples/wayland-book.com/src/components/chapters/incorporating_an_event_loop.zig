const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;
const Strong = @import("../strong.zig").Strong;

pub fn IncorporatingAnEventLoop() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Incorporating an event loop");
        });

        Paragraph(.{})({
            forbear.text("libwayland provides its own event loop implementation for Wayland servers to take advantage of, but the maintainers have acknowledged this as a design overstep. For clients, there is no such equivalent. Regardless, the Wayland server event loop is useful enough, even if it's out-of-scope.");
        });

        Heading(.{ .level = 2 })({
            forbear.text("Wayland server event loop");
        });

        Paragraph(.{})({
            forbear.text("Each ");
            Strong()({ forbear.text("wl_display"); });
            forbear.text(" created by libwayland-server has a corresponding ");
            Strong()({ forbear.text("wl_event_loop"); });
            forbear.text(", which you may obtain a reference to with ");
            Strong()({ forbear.text("wl_display_get_event_loop"); });
            forbear.text(". If you're writing a new Wayland compositor, you will likely want to use this as your only event loop. You can add file descriptors to it with ");
            Strong()({ forbear.text("wl_event_loop_add_fd"); });
            forbear.text(", and timers with ");
            Strong()({ forbear.text("wl_event_loop_add_timer"); });
            forbear.text(". It also handles signals via ");
            Strong()({ forbear.text("wl_event_loop_add_signal"); });
            forbear.text(", which can be pretty convenient.");
        });

        Paragraph(.{})({
            forbear.text("With the event loop configured to your liking to monitor all of the events your compositor has to respond to, you can process events and dispatch Wayland clients all at once by calling ");
            Strong()({ forbear.text("wl_display_run"); });
            forbear.text(", which will process the event loop and block until the display terminates (via ");
            Strong()({ forbear.text("wl_display_terminate"); });
            forbear.text("). Most Wayland compositors which were built from the ground-up with Wayland in mind (as opposed to being ported from X11) use this approach.");
        });

        Paragraph(.{})({
            forbear.text("However, it's also possible to take the wheel and incorporate the Wayland display into your own event loop. ");
            Strong()({ forbear.text("wl_display"); });
            forbear.text(" uses the event loop internally for processing clients, and you can choose to either monitor the Wayland event loop on your own, dispatching it as necessary, or you can disregard it entirely and manually process client updates. If you wish to allow the Wayland event loop to look after itself and treat it as subservient to your own event loop, you can use ");
            Strong()({ forbear.text("wl_event_loop_get_fd"); });
            forbear.text(" to obtain a pollable file descriptor, then call ");
            Strong()({ forbear.text("wl_event_loop_dispatch"); });
            forbear.text(" to process events when activity occurs on that file descriptor. You will also need to call ");
            Strong()({ forbear.text("wl_display_flush_clients"); });
            forbear.text(" when you have data which needs writing to clients.");
        });

        Heading(.{ .level = 2 })({
            forbear.text("Wayland client event loop");
        });

        Paragraph(.{})({
            forbear.text("libwayland-client, on the other hand, does not have its own event loop. However, since there is only generally one file descriptor, it's easier to manage without. If Wayland events are the only sort which your program expects, then this simple loop will suffice:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("However, if you have a more sophisticated application, you can build your own event loop in any manner you please, and obtain the Wayland display's file descriptor with ");
            Strong()({ forbear.text("wl_display_get_fd"); });
            forbear.text(". Upon ");
            Strong()({ forbear.text("POLLIN"); });
            forbear.text(" events, call ");
            Strong()({ forbear.text("wl_display_dispatch"); });
            forbear.text(" to process incoming events. To flush outgoing requests, call ");
            Strong()({ forbear.text("wl_display_flush"); });
            forbear.text(".");
        });

        Heading(.{ .level = 2 })({
            forbear.text("Almost there!");
        });

        Paragraph(.{})({
            forbear.text("At this point you have all of the context you need to set up a Wayland display and process events and requests. The only remaining step is to allocate objects to chat about with the other side of your connection. For this, we use the registry. At the end of the next chapter, we will have our first useful Wayland client!");
        });
    });
}
