const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;
const Strong = @import("../strong.zig").Strong;

pub fn HighDensitySurfaces() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("High density surfaces (HiDPI)");
        });

        Paragraph(.{})({
            forbear.text("In the past several years, a huge leap in pixel density in high-end displays has been seen, new displays packing twice as many pixels into the same physical area as we've seen in years past. We call these displays \"HiDPI\", short for \"high dots per inch\". However, these displays are so far ahead of their \"LoDPI\" peers that application-level changes are necessary to utilize them properly. By doubling the screen resolution in the same space, we would halve the size of all of our user interfaces if we lent them no special consideration. For most displays, this would make the text unreadable and the interactive elements uncomfortably small.");
        });

        Paragraph(.{})({
            forbear.text("In exchange, however, we're offered a much greater amount of graphical fidelity with our vector graphics, most notably with respect to text rendering. Wayland addresses this by adding a \"scale factor\" to each output, and clients are expected to apply this scale factor to their interfaces. Additionally, clients which are unaware of HiDPI signal this limitation through inaction, allowing the compositor to make up for it by scaling up their buffers. The compositor signals the scale factor for each output via the appropriate event: [code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("Note that this was added in version 2, so when binding to the ");
            Strong()({ forbear.text("wl_output"); });
            forbear.text(" global you must set the version to at least 2 to receive these events. This is ");
            Strong()({ forbear.text("not"); });
            forbear.text(" enough to decide to use HiDPI in your clients, however. In order to make that call, the compositor must also send ");
            Strong()({ forbear.text("enter"); });
            forbear.text(" events for your ");
            Strong()({ forbear.text("wl_surface"); });
            forbear.text(" to indicate that it has \"entered\" (is being shown on) a particular output or outputs: [code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("Once you know the collection of outputs a client is shown on, it should take the maximum value of the scale factors, multiply the size (in pixels) of its buffers by this value, then render the UI at 2x or 3x (or Nx) scale. Then, indicate the scale the buffer was prepared at like so: [code block omitted]");
        });

        Paragraph(.{})({
            Strong()({ forbear.text("Note"); });
            forbear.text(": this requires version 3 or newer of ");
            Strong()({ forbear.text("wl_surface"); });
            forbear.text(". This is the version number you should pass to the ");
            Strong()({ forbear.text("wl_registry"); });
            forbear.text(" when you bind to ");
            Strong()({ forbear.text("wl_compositor"); });
            forbear.text(".");
        });

        Paragraph(.{})({
            forbear.text("Upon the next ");
            Strong()({ forbear.text("wl_surface.commit"); });
            forbear.text(", your surface will assume this scale factor. If it's greater than the scale factor of an output the surface is shown on, the compositor will scale it down. If it's less than the scale factor of an output, the compositor will scale it up.");
        });
    });
}
