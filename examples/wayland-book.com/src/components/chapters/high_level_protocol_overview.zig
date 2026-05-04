const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn HighLevelProtocolOverview() void {
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
                forbear.text("High-level protocol overview");
            });

            Paragraph(.{})({
                forbear.text("In chapter 1.3, I mentioned that wayland.xml is probably installed with the Wayland package on your system. Find and pull up that file now in your favorite text editor. It's through this file, and others like it, that we define the interfaces supported by a Wayland client or server.");
            });

            Paragraph(.{})({
                forbear.text("Each interface is defined in this file, along with its requests and events, and their respective signatures. We use XML, everyone's favorite file format, for this purpose. Let's look at the examples we discussed in the previous chapter for wl_surface. Here's a sample:");
            });

            // TODO: insert code block here

            Paragraph(.{})({
                forbear.text("Note: I've trimmed this snippet for brevity, but if you have the wayland.xml file in front of you, seek out this interface and examine it yourself \u{2014} included is additional documentation explaining the purpose and precise semantics of each request and event.");
            });

            Paragraph(.{})({
                forbear.text("When processing this XML file, we assign each request and event an opcode in the order that they appear, numbered from zero and incrementing independently. Combined with the list of arguments, you can decode the request or event when it comes in over the wire, and based on the documentation shipped in the XML file you can decide how to program your software to behave accordingly. This usually comes in the form of code generation \u{2014} we'll talk about how libwayland does this in chapter 3.");
            });

            Paragraph(.{})({
                forbear.text("Starting from chapter 4, most of the remainder of this book is devoted to explaining this file, as well as some supplementary protocol extensions.");
            });
        });
    });
}
