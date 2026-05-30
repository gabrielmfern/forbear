const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn InteractiveMoveAndResize() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Interactive move and resize");
        });

        Paragraph(.{})({
            forbear.text("Many application windows have interactive UI elements the user can use to drag around or resize windows. Many Wayland clients, by default, expect to be responsible for their own window decorations to provide these interactive elements. On X11, application windows could position themselves independently anywhere on the screen, and used this to facilitate these interactions.");
        });

        Paragraph(.{})({
            forbear.text("However, a deliberate design trait of Wayland makes application windows ignorant of their exact placement on screen or relative to other windows. This decision affords Wayland compositors a greater deal of flexibility — windows could be shown in several places at once, arranged in the 3D space of a VR scene, or presented in any other novel way. Wayland is designed to be generic and widely applicable to many devices and form factors.");
        });

        Paragraph(.{})({
            forbear.text("To balance these two design needs, XDG toplevels offer two requests which can be used to ask the compositor to begin an interactive move or resize operation. The relevant parts of the interface are:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("Like the popup creation request explained in the previous chapter, you have to provide an input event serial to start an interactive operation. For example, when you receive a mouse button down event, you can use that event's serial to begin an interactive move operation. The compositor will take over from here, and begin an interactive operation to your window in its internal coordinate space.");
        });

        Paragraph(.{})({
            forbear.text("Resizing is a bit more complex, due to the need to specify which edges or corners of the window are implicated in the operation:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("But otherwise, it functions much the same. If the user clicks and drags along the bottom-left corner of your window, you may want to send an interactive resize request with the corresponding seat & serial, and set the edges argument to bottom_left.");
        });

        Paragraph(.{})({
            forbear.text("There's one additional request necessary for clients to totally implement interactive client-side window decorations:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("A contextual menu offering window operations, such as closing or minimizing the window, is often raised when clicking on window decorations. For clients where window decorations are managed by the client, this serves to link the client-driven interactions with compositor-driven meta operations like minimizing windows. If your client uses client-side decorations, you may use this request for this purpose.");
        });

        Heading(.{ .level = 2 })({
            forbear.text("xdg-decoration");
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("The last detail which bears mentioning when discussing the behavior of client-side decorations is the protocol which governs the negotiation of their use in the first place. Different Wayland clients and servers may have different preferences about the use of server-side or client-side window decorations. To express these intentions, a protocol extension is used: ");
                forbear.Strong()({
                    forbear.write("xdg-decoration");
                });
                forbear.write(". It can be found in wayland-protocols. The protocol provides a global:");
            });
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("You may pass your xdg_toplevel object into the ");
                forbear.Strong()({
                    forbear.write("get_toplevel_decoration");
                });
                forbear.write(" request to obtain an object with the following interface:");
            });
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("The ");
                forbear.Strong()({
                    forbear.write("set_mode");
                });
                forbear.write(" request is used to express a preference from the client, and ");
                forbear.Strong()({
                    forbear.write("unset_mode");
                });
                forbear.write(" is used to express no preference. The compositor will then use the ");
                forbear.Strong()({
                    forbear.write("configure");
                });
                forbear.write(" event to tell the client whether or not to use client-side decorations. For more details, consult the full XML.");
            });
        });
    });
}
