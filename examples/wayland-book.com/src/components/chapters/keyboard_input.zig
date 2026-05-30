const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;
const List = @import("../list.zig").List;
const ListItem = @import("../list.zig").ListItem;

pub fn KeyboardInput() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Keyboard input");
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("Equipped with an understanding of how to use XKB, let's extend our Wayland code to provide us with key events to feed into it. Similarly to how we obtained a ");
                forbear.Strong()({
                    forbear.write("wl_pointer");
                });
                forbear.write(" resource, we can use the ");
                forbear.Strong()({
                    forbear.write("wl_seat.get_keyboard");
                });
                forbear.write(" request to create a ");
                forbear.Strong()({
                    forbear.write("wl_keyboard");
                });
                forbear.write(" for a seat whose capabilities include ");
                forbear.Strong()({
                    forbear.write("WL_SEAT_CAPABILITY_KEYBOARD");
                });
                forbear.write(". When you're done with it, you should send the \"release\" request:");
            });
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("This will allow the server to clean up the resources associated with this keyboard.");
        });

        Paragraph(.{})({
            forbear.text("But how do you actually use it? Let's start with the basics.");
        });

        Heading(.{ .level = 2 })({
            forbear.text("Key maps");
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("When you bind to ");
                forbear.Strong()({
                    forbear.write("wl_keyboard");
                });
                forbear.write(", the first event that the server is likely to send is ");
                forbear.Strong()({
                    forbear.write("keymap");
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
                    forbear.write("keymap_format");
                });
                forbear.write(" enum is provided in the event that we come up with a new format for keymaps, but at the time of writing, XKB keymaps are the only format which the server is likely to send.");
            });
        });

        Paragraph(.{})({
            forbear.text("Bulk data like this is transferred over file descriptors. We could simply read from the file descriptor, but in general it's recommended to mmap it instead. In C, this could look similar to the following code:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("Once we have a keymap, we can interpret future keypress events for this ");
                forbear.Strong()({
                    forbear.write("wl_keyboard");
                });
                forbear.write(". Note that the server can send a new keymap at any time, and all future key events should be interpreted in that light.");
            });
        });

        Heading(.{ .level = 2 })({
            forbear.text("Keyboard focus");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("Like ");
                forbear.Strong()({
                    forbear.write("wl_pointer");
                });
                forbear.write("'s \"enter\" and \"leave\" events are issued when a pointer is moved over your surface, the server sends ");
                forbear.Strong()({
                    forbear.write("wl_keyboard.enter");
                });
                forbear.write(" when a surface receives keyboard focus, and ");
                forbear.Strong()({
                    forbear.write("wl_keyboard.leave");
                });
                forbear.write(" when it's lost. Many applications will change their appearance under these conditions — for example, to start drawing a blinking caret.");
            });
        });

        Paragraph(.{})({
            forbear.text("The \"enter\" event also includes an array of currently pressed keys. This is an array of 32-bit unsigned integers, each representing the scancode of a pressed key.");
        });

        Heading(.{ .level = 2 })({
            forbear.text("Input events");
        });

        Paragraph(.{})({
            forbear.text("Once the keyboard has entered your surface, you can expect to start receiving input events.");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("The \"key\" event is sent when the user presses or releases a key. Like many input events, a serial is included which you can use to associate future requests with this input event. The \"key\" is the scancode of the key which was pressed or released, and the \"state\" is the pressed or released state of that key.");
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.Strong()({
                    forbear.write("Important");
                });
                forbear.write(": the scancode from this event is the Linux evdev scancode. To translate this to an XKB scancode, you must add 8 to the evdev scancode.");
            });
        });

        Paragraph(.{})({
            forbear.text("The modifiers event includes a similar serial, as well as masks of the depressed, latched, and locked modifiers, and the index of the input group currently in use. A modifier is depressed, for example, while you hold down Shift. A modifier can latch, such as pressing Shift with sticky keys enabled - it'll stop taking effect after the next non-modifier key is pressed. And a modifier can be locked, such as when caps lock is toggled on or off. Input groups are used to switch between various keyboard layouts, such as toggling between ISO and ANSI layouts, or for more language-specific features.");
        });

        Paragraph(.{})({
            forbear.text("The interpretation of modifiers is keymap-specific. You should forward them both to XKB to deal with. Most implementations of the \"modifiers\" event are straightforward:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Heading(.{ .level = 2 })({
            forbear.text("Key repeat");
        });

        Paragraph(.{})({
            forbear.text("The last event to consider is the \"repeat_info\" event:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("In Wayland, the client is responsible for implementing \"key repeat\" — the feature which continues to type characters as long as you've got the key held doooooown. This event is sent to inform the client of the user's preferences for key repeat settings. The \"delay\" is the number of milliseconds a key should be held down for before key repeat kicks in, and the \"rate\" is the number of characters per second to repeat until the key is released.");
        });
    });
}
