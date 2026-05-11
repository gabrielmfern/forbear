const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn LibwaylandInDepth() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("libwayland in depth");
        });

        Paragraph(.{})({
            forbear.text("We spoke briefly about libwayland in chapter 1.3 — the most popular Wayland implementation. Much of this book is applicable to any implementation, but we're going to spend the next two chapters familiarizing you with this one.");
        });

        Paragraph(.{})({
            forbear.text("The Wayland package includes pkg-config specs for wayland-client and wayland-server — consult your build system's documentation for instructions on linking with them. Naturally, most applications will only link to one or the other. The library includes a few simple primitives (such as a linked list) and a pre-compiled version of wayland.xml — the core Wayland protocol.");
        });

        Paragraph(.{})({
            forbear.text("We'll start by introducing the primitives.");
        });
    });
}
