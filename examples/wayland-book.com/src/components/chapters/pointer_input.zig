const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;
const Strong = @import("../strong.zig").Strong;
const List = @import("../list.zig").List;
const ListItem = @import("../list.zig").ListItem;

pub fn PointerInput() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Pointer input");
        });

        Paragraph(.{})({
            forbear.text("Using the ");
            Strong()({
                forbear.text("wl_seat.get_pointer");
            });
            forbear.text(" request, clients may obtain a ");
            Strong()({
                forbear.text("wl_pointer");
            });
            forbear.text(" object. The server will send events to it whenever the user moves their pointer, presses mouse buttons, uses the scroll wheel, etc — whenever the pointer is over one of your surfaces. We can determine if this condition is met with the ");
            Strong()({
                forbear.text("wl_pointer.enter");
            });
            forbear.text(" event:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("The server sends this event when the pointer moves over one of our surfaces, and specifies both the surface that was \"entered\", as well as the surface-local coordinates (from the top-left corner) that the pointer is positioned over. Coordinates here are specified with the \"fixed\" type, which you may remember from chapter 2.1 represents a 24.8-bit fixed-precision number (");
            Strong()({
                forbear.text("wl_fixed_to_double");
            });
            forbear.text(" will convert this to C's ");
            Strong()({
                forbear.text("double");
            });
            forbear.text(" type).");
        });

        Paragraph(.{})({
            forbear.text("When the pointer is moved away from your surface, the corresponding event is more brief:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("Once a pointer has entered your surface, you'll start receiving additional events for it, which we'll discuss shortly. The first thing you will likely want to do, however, is provide a cursor image. The process is as such:");
        });

        List()({
            ListItem()({
                forbear.text("Create a new ");
                Strong()({
                    forbear.text("wl_surface");
                });
                forbear.text(" with the ");
                Strong()({
                    forbear.text("wl_compositor");
                });
                forbear.text(".");
            });
            ListItem()({
                forbear.text("Use ");
                Strong()({
                    forbear.text("wl_pointer.set_cursor");
                });
                forbear.text(" to attach that surface to the pointer.");
            });
            ListItem()({
                forbear.text("Attach a cursor image ");
                Strong()({
                    forbear.text("wl_buffer");
                });
                forbear.text(" to the surface and commit it.");
            });
        });

        Paragraph(.{})({
            forbear.text("The only new API introduced here is ");
            Strong()({
                forbear.text("wl_pointer.set_cursor");
            });
            forbear.text(":");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("The ");
            Strong()({
                forbear.text("serial");
            });
            forbear.text(" here has to come from the ");
            Strong()({
                forbear.text("enter");
            });
            forbear.text(" event. The ");
            Strong()({
                forbear.text("hotspot_x");
            });
            forbear.text(" and ");
            Strong()({
                forbear.text("hotspot_y");
            });
            forbear.text(" arguments specify the cursor-surface-local coordinates of the \"hotspot\", or the effective position of the pointer within the cursor image (e.g. at the tip of an arrow). Note also that the surface can be null — use this to hide the cursor entirely.");
        });

        Paragraph(.{})({
            forbear.text("If you're looking for a good source of cursor images, libwayland ships with a separate ");
            Strong()({
                forbear.text("wayland-cursor");
            });
            forbear.text(" library, which can load X cursor themes from disk and create ");
            Strong()({
                forbear.text("wl_buffers");
            });
            forbear.text(" for them. See ");
            Strong()({
                forbear.text("wayland-cursor.h");
            });
            forbear.text(" for details, or the updates to our example client in chapter 9.5.");
        });

        Paragraph(.{})({
            forbear.text("Note: wayland-cursor includes code for dealing with animated cursors, which weren't even cool in 1998. If I were you, I wouldn't bother with that. No one has ever complained that my Wayland clients don't support animated cursors.");
        });

        Paragraph(.{})({
            forbear.text("After the cursor has entered your surface and you have attached an appropriate cursor, you're ready to start processing input events. There are motion, button, and axis events.");
        });

        Heading(.{ .level = 2 })({
            forbear.text("Pointer frames");
        });

        Paragraph(.{})({
            forbear.text("A single frame of input processing on the server could carry information about lots of changes — for example, polling the mouse once could return, in a single packet, an updated position and the release of a button. The server sends these changes as separate ");
            Strong()({
                forbear.text("Wayland");
            });
            forbear.text(" events, and uses the \"frame\" event to group them together.");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("Clients should accumulate all ");
            Strong()({
                forbear.text("wl_pointer");
            });
            forbear.text(" events as they're received, then process pending inputs as a single pointer event once the \"frame\" event is received.");
        });

        Heading(.{ .level = 2 })({
            forbear.text("Motion events");
        });

        Paragraph(.{})({
            forbear.text("Motion events are specified in the same coordinate space as the ");
            Strong()({
                forbear.text("enter");
            });
            forbear.text(" event uses, and are straightforward enough:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("Like all input events which include a timestamp, the ");
            Strong()({
                forbear.text("time");
            });
            forbear.text(" value is a monotonically increasing millisecond-precision timestamp associated with this input event.");
        });

        Heading(.{ .level = 2 })({
            forbear.text("Button events");
        });

        Paragraph(.{})({
            forbear.text("Button events are mostly self-explanatory:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("However, the ");
            Strong()({
                forbear.text("button");
            });
            forbear.text(" argument merits some additional explanation. This number is a platform-specific input event, though note that FreeBSD reuses the Linux values. You can find these values for Linux in ");
            Strong()({
                forbear.text("linux/input-event-codes.h");
            });
            forbear.text(", and the most useful ones will probably be represented by the constants ");
            Strong()({
                forbear.text("BTN_LEFT");
            });
            forbear.text(", ");
            Strong()({
                forbear.text("BTN_RIGHT");
            });
            forbear.text(", and ");
            Strong()({
                forbear.text("BTN_MIDDLE");
            });
            forbear.text(". There are more, I'll leave you to peruse the header at your leisure.");
        });

        Heading(.{ .level = 2 })({
            forbear.text("Axis events");
        });

        Paragraph(.{})({
            forbear.text("The axis event is used for scrolling actions, such as rotating your scroll wheel or rocking it from left to right. The most basic form looks like this:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("However, axis events are complex, and this is the part of the ");
            Strong()({
                forbear.text("wl_pointer");
            });
            forbear.text(" interface which has received the most attention over the years. Several additional events exist which increase the specificity of the axis event:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("The axis_source event tells you what kind of axis was actuated — a scroll wheel, or a finger on a touchpad, tilting a rocker to the side, or something more novel. This event is simple, but the remainder are less so:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("The precise semantics of these two events are complex, and if you wish to leverage them I recommend a careful reading of the summaries in ");
            Strong()({
                forbear.text("wayland.xml");
            });
            forbear.text(". In short, the ");
            Strong()({
                forbear.text("axis_discrete");
            });
            forbear.text(" event is used to disambiguate axis events on an arbitrary scale from discrete steps of, for example, a scroll wheel where each \"click\" of the wheel represents a single discrete change in the axis value. The ");
            Strong()({
                forbear.text("axis_stop");
            });
            forbear.text(" event signals that a discrete user motion has completed, and is used when accounting for a scrolling event which takes place over several frames. Any future events should be interpreted as a separate motion.");
        });
    });
}
