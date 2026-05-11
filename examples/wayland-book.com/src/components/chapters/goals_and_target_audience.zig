const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn GoalsAndTargetAudience() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Goals & target audience");
        });

        Paragraph(.{})({
            forbear.text("Our goal is for you to come away from this book with an understanding of the Wayland protocol and its high-level usage. You should have a solid understanding of everything in the core Wayland protocol, as well as the knowledge necessary to evaluate and implement the various protocol extensions necessary for its productive use. Primarily, this book uses the concerns of a Wayland client to frame its presentation of Wayland. However, it should provide some utility for those working on Wayland compositors as well.");
        });
        Paragraph(.{})({
            forbear.text("The free desktop ecosystem is complex and built from many discrete parts. We are going to discuss these pieces very little — you won't find information here about leveraging libdrm in your Wayland compositor, or using libinput to process evdev events. Thus, this book is not a comprehensive guide for building Wayland compositors. We're also not going to talk about drawing technologies which are useful for Wayland clients, such as Cairo, Pango, GTK+, and so on, and thus nor is this a robust guide for the practical Wayland client implementation. Instead, we focus only on the particulars of Wayland.");
        });
        Paragraph(.{})({
            forbear.text("This book only covers the protocol and libwayland. If you are writing a client and are already familiar with your favorite user interface rendering library, bring your own pixels and we'll help you display them on Wayland. If you already have an understanding of the technologies required to operate displays and input devices for your compositor, this book will help you learn how to talk to clients.");
        });
    });
}
