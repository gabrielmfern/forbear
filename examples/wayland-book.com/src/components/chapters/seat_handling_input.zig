const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn SeatHandlingInput() void {
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
                forbear.text("Seat: Handling input");
            });

            Paragraph(.{})({
                forbear.text("Displaying your application to the user is only half of the I/O equation — most applications also need to process input. For this purpose, the seat provides an abstraction over input events on Wayland. In philosophical terms, a Wayland seat refers to one \"seat\" at which a user sits and operates the computer, and is associated with up to one keyboard and up to one \"pointer\" device (i.e. a mouse or touchpad). A similar relationship is defined for touchscreens, drawing tablet devices, and so on.");
            });

            Paragraph(.{})({
                forbear.text("It's important to remember that this is an abstraction, and that the seats represented on a Wayland display may not correspond 1:1 with reality. In practice, it's rare for more than a single seat to be available on a Wayland session. If you plug a second keyboard into your computer, it's generally assigned to the same seat as the first, and the keyboard layout and so on are dynamically switched as you start typing on each. These implementation details are left to the Wayland compositor to consider.");
            });

            Paragraph(.{})({
                forbear.text("From the client's perspective, it's reasonably straightforward. If you bind to the wl_seat global, you get access to the following interface:");
            });

            // TODO: insert code block here

            Paragraph(.{})({
                forbear.text("Note: This interface has been updated many times — take note of the version when you bind to the global. This book assumes you're binding to the latest version, which is version 7 at the time of writing.");
            });

            Paragraph(.{})({
                forbear.text("This interface is relatively straightforward. The server will send the client a capabilities event to signal what kinds of input devices are supported by this seat — represented by a bitfield of capability values — and the client can bind to the input devices it wishes to use accordingly. For example, if the server sends capabilities where (caps & WL_SEAT_CAPABILITY_KEYBOARD) > 0 is true, the client may then use the get_keyboard request to obtain a wl_keyboard object for this seat. The semantics for each particular input device are covered in the remaining chapters.");
            });

            Paragraph(.{})({
                forbear.text("Before we get to those, let's cover some common semantics.");
            });

            Heading(.{ .level = 2 })({
                forbear.text("Event serials");
            });

            Paragraph(.{})({
                forbear.text("Some actions that a Wayland client may perform require a trivial form of authentication in the form of input event serials. For example, a client which opens a popup (a context menu summoned with a right click is one kind of popup) may want to \"grab\" all input events server-side from the affected seat until the popup is dismissed. To prevent abuse of this feature, the server can assign serials to each input event it sends, and require the client to include one of these serials in the request.");
            });

            Paragraph(.{})({
                forbear.text("When the server receives such a request, it looks up the input event associated with the given serial and makes a judgement call. If the event was too long ago, or for the wrong surface, or wasn't the right kind of event — for example, it could reject grabs when you wiggle the mouse, but allow them when you click — it can reject the request.");
            });

            Paragraph(.{})({
                forbear.text("From the server's perspective, they can simply send a incrementing integer with each input event, and record the serials which are considered valid for a particular use-case for later validation. The client receives these serials from their input event handlers, and can simply pass them back right away to perform the desired action.");
            });

            Paragraph(.{})({
                forbear.text("We'll discuss these in more detail in later chapters, when we start covering the specific requests which require input event serials to validate them.");
            });

            Heading(.{ .level = 2 })({
                forbear.text("Input frames");
            });

            Paragraph(.{})({
                forbear.text("A single input event from an input device may be broken up into several Wayland events for practical reasons. For example, a wl_pointer will emit an axis event as you use the scroll wheel, but it will separately emit an event telling you what kind of axis it was: scroll wheel, a finger on a touchpad, tilting the scroll wheel to the side, etc. The same input event from the input source may have also included some motion of the mouse, or the click of a button, if the user did all of these things quickly enough.");
            });

            Paragraph(.{})({
                forbear.text("The semantic grouping of these related events differs slightly from input type to input type, but the frame event is generally common between them. In short, if you buffer up all of the input events you receive from a device, then wait for the frame event to signal that you've received all events for a single input \"frame\", you can interpret the buffered up Wayland events as a single input event, then reset the buffer and start collecting events for the next frame.");
            });

            Paragraph(.{})({
                forbear.text("If this sounds too complicated, don't sweat it. Many applications don't have to worry about input frames. It's only when you start doing more complex input event handling that you'll want to concern yourself with this.");
            });
        });
    });
}
