const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;
const List = @import("../list.zig").List;
const ListItem = @import("../list.zig").ListItem;

pub fn PopupsAndParentWindows() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Popups & parent windows");
        });

        Paragraph(.{})({
            forbear.text("When designing software which utilizes application windows, there are many cases where smaller secondary surfaces are used for various purposes. Some examples include context menus which appear on right click, dropdown boxes to select a value from several options, contextual hints which are shown when you hover the mouse over a UI element, or menus and toolbars along the top and bottom of a window. Often these will be nested, for example, by following a path like \"File → Recent Documents → Example.odt\".");
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("For Wayland, the XDG shell provides facilities for managing these windows: popups. We looked at ");
                forbear.Strong()({
                    forbear.write("get_toplevel");
                });
                forbear.write(" for creating top-level application windows earlier. In the case of popups, the ");
                forbear.Strong()({
                    forbear.write("get_popup");
                });
                forbear.write(" request is used instead.");
            });
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("The first and second arguments are reasonably self-explanatory, but the third one introduces a new concept: positioners. The purpose of the positioner is, as the name might suggest, to position the new popup. This is used to allow the compositor to participate in the positioning of popups using its privileged information, for example to avoid having the popup extend past the edge of the display. We'll discuss positioners in chapter 10.4, for now you can simply create one and pass it in without further configuration to achieve reasonably sane default behavior, utilizing the appropriate ");
                forbear.Strong()({
                    forbear.write("create_positioner");
                });
                forbear.write(" request:");
            });
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("So, in short, we can:");
        });

        List()({
            ListItem()({
                forbear.composeText(.{})({
                    forbear.write("Create a new ");
                    forbear.Strong()({
                        forbear.write("wl_surface");
                    });
                });
            });
            ListItem()({
                forbear.composeText(.{})({
                    forbear.write("Obtain an ");
                    forbear.Strong()({
                        forbear.write("xdg_surface");
                    });
                    forbear.write(" for it");
                });
            });
            ListItem()({
                forbear.composeText(.{})({
                    forbear.write("Create a new ");
                    forbear.Strong()({
                        forbear.write("xdg_positioner");
                    });
                    forbear.write(", saving its configuration for chapter 10.4");
                });
            });
            ListItem()({
                forbear.composeText(.{})({
                    forbear.write("Create an ");
                    forbear.Strong()({
                        forbear.write("xdg_popup");
                    });
                    forbear.write(" from our XDG surface and XDG positioner, assigning its parent to the ");
                    forbear.Strong()({
                        forbear.write("xdg_toplevel");
                    });
                    forbear.write(" we created earlier.");
                });
            });
        });

        Paragraph(.{})({
            forbear.text("Then we can render and attach buffers to our popup surface with the same lifecycle discussed earlier. We also have access to a few other popup-specific features.");
        });

        Heading(.{ .level = 2 })({
            forbear.text("Configuration");
        });

        Paragraph(.{})({
            forbear.text("Like the XDG toplevel configure event, the compositor has an event which it may use to suggest the size for your popup to assume. Unlike toplevels, however, this also includes a positioning event, which informs the client as to the position of the popup relative to its parent surface.");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("The client can influence these values with the XDG positioner, to be discussed in chapter 10.4.");
        });

        Heading(.{ .level = 2 })({
            forbear.text("Popup grabs");
        });

        Paragraph(.{})({
            forbear.text("Popup surfaces will often want to \"grab\" all input, for example to allow the user to use the arrow keys to select different menu items. This is facilitated through the grab request:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("A prerequisite of this request is having received a qualifying input event, such as a right click. The serial from this input event should be used in this request. These semantics are covered in detail in chapter 9. The compositor can cancel this grab later, for example if the user presses escape or clicks outside of your popup.");
        });

        Heading(.{ .level = 2 })({
            forbear.text("Dismissal");
        });

        Paragraph(.{})({
            forbear.text("In these cases where the compositor dismisses your popup, such as when the escape key is pressed, the following event is sent:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("To avoid race conditions, the compositor keeps the popup structures in memory and services requests for them even after their dismissal. For more detail about object lifetimes and race conditions, see chapter 2.4.");
        });

        Heading(.{ .level = 2 })({
            forbear.text("Destroying popups");
        });

        Paragraph(.{})({
            forbear.text("Client-initiated destruction of a popup is fairly straightforward:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("However, one detail bears mentioning: you must destroy all popups from the top-down. The only popup you can destroy at any given moment is the top-most one. If you don't, you'll be disconnected with a protocol error.");
        });
    });
}
