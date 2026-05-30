const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;
const List = @import("../list.zig").List;
const ListItem = @import("../list.zig").ListItem;

pub fn XkbBriefly() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("XKB, briefly");
        });

        Paragraph(.{})({
            forbear.text("The next input device on our list is keyboards, but we need to stop and give you some additional context before we discuss them. Keymaps are an essential detail involved in keyboard input, and XKB is the recommended way of handling them on Wayland.");
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("When you press a key on your keyboard, it sends a ");
                forbear.Strong()({
                    forbear.write("scancode");
                });
                forbear.write(" to the computer, which is simply a number assigned to that physical key. On my keyboard, scancode 1 is the Escape key, the '1' key is scancode 2, 'a' is 30, Shift is 42, and so on. I use a US ANSI keyboard layout, but there are many other layouts, and their scancodes differ. On my friend's German keyboard, scancode 12 produces 'ß', while mine produces '-'.");
            });
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("To solve this problem, we use a library called \"xkbcommon\", which is named for its role as the common code from XKB (X KeyBoard) extracted into a standalone library. XKB defines a huge number of key ");
                forbear.Strong()({
                    forbear.write("symbols");
                });
                forbear.write(", such as XKB_KEY_A, and XKB_KEY_ssharp (ß, from German), and XKB_KEY_kana_WO (を, from Japanese).");
            });
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("Identifying these keys and correlating them with key symbols like this is only part of the problem, however. 'a' can produce 'A' if the shift key is held down, 'を' is written as 'ヲ' in Katakana mode, and while there is strictly speaking an uppercase version of 'ß', it's hardly ever used and certainly never typed. Keys like Shift are called ");
                forbear.Strong()({
                    forbear.write("modifiers");
                });
                forbear.write(", and groups like Hiragana and Katakana are called ");
                forbear.Strong()({
                    forbear.write("groups");
                });
                forbear.write(". Some modifiers can ");
                forbear.Strong()({
                    forbear.write("latch");
                });
                forbear.write(", like Caps Lock. XKB has primitives for dealing with all of these cases, and maintains a state machine which tracks what your keyboard is doing and figures out exactly which ");
                forbear.Strong()({
                    forbear.write("Unicode codepoints");
                });
                forbear.write(" the user is trying to type.");
            });
        });

        Heading(.{ .level = 2 })({
            forbear.text("Using XKB");
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("So how is xkbcommon actually used? Well, the first step is to link to it and grab the header, ");
                forbear.Strong()({
                    forbear.write("xkbcommon/xkbcommon.h");
                });
                forbear.write(". Most programs which utilize xkbcommon will have to manage three objects:");
            });
        });

        List()({
            ListItem()({
                forbear.text("xkb_context: a handle used for configuring other XKB resources");
            });
            ListItem()({
                forbear.text("xkb_keymap: a mapping from scancodes to key symbols");
            });
            ListItem()({
                forbear.text("xkb_state: a state machine that turns key symbols into UTF-8 strings");
            });
        });

        Paragraph(.{})({
            forbear.text("The process for setting this up usually goes as follows:");
        });

        List()({
            ListItem()({
                forbear.text("Use xkb_context_new to create a new xkb_context, passing it XKB_CONTEXT_NO_FLAGS unless you're doing something weird.");
            });
            ListItem()({
                forbear.text("Obtain a key map as a string.");
            });
            ListItem()({
                forbear.text("Use xkb_keymap_new_from_string to create an xkb_keymap for this key map. There's only one key map format, XKB_KEYMAP_FORMAT_TEXT_V1, which you'll pass for the format parameter. Again, unless you're doing something weird, you'll use XKB_KEYMAP_COMPILE_NO_FLAGS for the flags.");
            });
            ListItem()({
                forbear.text("Use xkb_state_new to create an xkb_state with your keymap. The state will increment the refcount for the keymap, so use xkb_keymap_unref if you're done with it yourself.");
            });
            ListItem()({
                forbear.text("Obtain scancodes from a keyboard.");
            });
            ListItem()({
                forbear.text("Feed the scancodes into xkb_state_key_get_one_sym to get keysyms, and into xkb_state_key_get_utf8 to get UTF-8 strings. Tada!");
            });
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("Equipped with these details, we're ready to tackle processing keyboard input.");
        });
    });
}
