const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;
const Strong = @import("../strong.zig").Strong;

pub fn KeyboardInput() void {
    forbear.component(.{
        .sourceLocation = @src(),
    })({
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
                forbear.text("Keyboard input");
            });

            Paragraph()({
                forbear.text("Equipped with an understanding of how to use XKB, let's extend our Wayland code to provide us with key events to feed into it. Similarly to how we obtained a wl_pointer resource, we can use the wl_seat.get_keyboard request to create a wl_keyboard for a seat whose capabilities include WL_SEAT_CAPABILITY_KEYBOARD. When you're done with it, you should send the \"release\" request:");
            });

            // TODO: insert code block here

            Paragraph()({
                forbear.text("This will allow the server to clean up the resources associated with this keyboard.");
            });

            Paragraph()({
                forbear.text("But how do you actually use it? Let's start with the basics.");
            });

            Heading(.{ .level = 2 })({
                forbear.text("Key maps");
            });

            Paragraph()({
                forbear.text("When you bind to wl_keyboard, the first event that the server is likely to send is keymap.");
            });

            // TODO: insert code block here

            Paragraph()({
                forbear.text("The keymap_format enum is provided in the event that we come up with a new format for keymaps, but at the time of writing, XKB keymaps are the only format which the server is likely to send.");
            });

            Paragraph()({
                forbear.text("Bulk data like this is transferred over file descriptors. We could simply read from the file descriptor, but in general it's recommended to mmap it instead. In C, this could look similar to the following code:");
            });

            // TODO: insert code block here

            Paragraph()({
                forbear.text("Once we have a keymap, we can interpret future keypress events for this wl_keyboard. Note that the server can send a new keymap at any time, and all future key events should be interpreted in that light.");
            });

            Heading(.{ .level = 2 })({
                forbear.text("Keyboard focus");
            });

            // TODO: insert code block here

            Paragraph()({
                forbear.text("Like wl_pointer's \"enter\" and \"leave\" events are issued when a pointer is moved over your surface, the server sends wl_keyboard.enter when a surface receives keyboard focus, and wl_keyboard.leave when it's lost. Many applications will change their appearance under these conditions \u{2014} for example, to start drawing a blinking caret.");
            });

            Paragraph()({
                forbear.text("The \"enter\" event also includes an array of currently pressed keys. This is an array of 32-bit unsigned integers, each representing the scancode of a pressed key.");
            });

            Heading(.{ .level = 2 })({
                forbear.text("Input events");
            });

            Paragraph()({
                forbear.text("Once the keyboard has entered your surface, you can expect to start receiving input events.");
            });

            // TODO: insert code block here

            Paragraph()({
                forbear.text("The \"key\" event is sent when the user presses or releases a key. Like many input events, a serial is included which you can use to associate future requests with this input event. The \"key\" is the scancode of the key which was pressed or released, and the \"state\" is the pressed or released state of that key.");
            });

            Paragraph()({
                Strong()({
                    forbear.text("Important");
                });
                forbear.text(": the scancode from this event is the Linux evdev scancode. To translate this to an XKB scancode, you must add 8 to the evdev scancode.");
            });

            Paragraph()({
                forbear.text("The modifiers event includes a similar serial, as well as masks of the depressed, latched, and locked modifiers, and the index of the input group currently in use. A modifier is depressed, for example, while you hold down Shift. A modifier can latch, such as pressing Shift with sticky keys enabled - it'll stop taking effect after the next non-modifier key is pressed. And a modifier can be locked, such as when caps lock is toggled on or off. Input groups are used to switch between various keyboard layouts, such as toggling between ISO and ANSI layouts, or for more language-specific features.");
            });

            Paragraph()({
                forbear.text("The interpretation of modifiers is keymap-specific. You should forward them both to XKB to deal with. Most implementations of the \"modifiers\" event are straightforward:");
            });

            // TODO: insert code block here

            Heading(.{ .level = 2 })({
                forbear.text("Key repeat");
            });

            Paragraph()({
                forbear.text("The last event to consider is the \"repeat_info\" event:");
            });

            // TODO: insert code block here

            Paragraph()({
                forbear.text("In Wayland, the client is responsible for implementing \"key repeat\" \u{2014} the feature which continues to type characters as long as you've got the key held doooooown. This event is sent to inform the client of the user's preferences for key repeat settings. The \"delay\" is the number of milliseconds a key should be held down for before key repeat kicks in, and the \"rate\" is the number of characters per second to repeat until the key is released.");
            });
        });
    });
}
