const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;
const Strong = @import("../strong.zig").Strong;

pub fn DamagingSurfaces() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Damaging surfaces");
        });

        Paragraph(.{})({
            forbear.text("You may have noticed in the last example that we added this line of code when we committed a new frame for the surface:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("If so, sharp eye! This code ");
            Strong()({
                forbear.text("damages");
            });
            forbear.text(" our surface, indicating to the compositor that it needs to be redrawn. Here we damage the entire surface (and well beyond it), but we could instead only damage part of it.");
        });

        Paragraph(.{})({
            forbear.text("Let's say, for example, that you've written a GUI toolkit and the user is typing into a textbox. That textbox probably only takes up a small part of the window, and each new character takes up a smaller part still. When the user presses a key, you could render just the new character appended to the text they're writing, then damage only that part of the surface. The compositor can then copy just a fraction of your surface, which can speed things up considerably - especially for embedded devices. As you blink the caret between characters, you'll want to submit damage for its updates, and when the user changes views, you'll likely damage the entire surface. This way, everyone does less work, and the user will thank you for their improved battery life.");
        });

        Paragraph(.{})({
            Strong()({
                forbear.text("Note");
            });
            forbear.text(": The Wayland protocol provides two requests for damaging surfaces: ");
            Strong()({
                forbear.text("damage");
            });
            forbear.text(" and ");
            Strong()({
                forbear.text("damage_buffer");
            });
            forbear.text(". The former is effectively deprecated, and you should only use the latter. The difference between them is that ");
            Strong()({
                forbear.text("damage");
            });
            forbear.text(" takes into account all of the transforms affecting the surface, such as rotations, scale factor, and buffer position and clipping. The latter instead applies damage relative to the buffer, which is generally easier to reason about.");
        });
    });
}
