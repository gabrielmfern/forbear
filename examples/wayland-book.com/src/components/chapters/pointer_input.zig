const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;
const List = @import("../list.zig").List;
const ListItem = @import("../list.zig").ListItem;

pub fn PointerInput() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Pointer input");
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("Using the ");
                forbear.Strong()({
                    forbear.write("wl_seat.get_pointer");
                });
                forbear.write(" request, clients may obtain a ");
                forbear.Strong()({
                    forbear.write("wl_pointer");
                });
                forbear.write(" object. The server will send events to it whenever the user moves their pointer, presses mouse buttons, uses the scroll wheel, etc — whenever the pointer is over one of your surfaces. We can determine if this condition is met with the ");
                forbear.Strong()({
                    forbear.write("wl_pointer.enter");
                });
                forbear.write(" event:");
            });
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("The server sends this event when the pointer moves over one of our surfaces, and specifies both the surface that was \"entered\", as well as the surface-local coordinates (from the top-left corner) that the pointer is positioned over. Coordinates here are specified with the \"fixed\" type, which you may remember from chapter 2.1 represents a 24.8-bit fixed-precision number (");
                forbear.Strong()({
                    forbear.write("wl_fixed_to_double");
                });
                forbear.write(" will convert this to C's ");
                forbear.Strong()({
                    forbear.write("double");
                });
                forbear.write(" type).");
            });
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
                forbear.composeText(.{})({
                    forbear.write("Create a new ");
                    forbear.Strong()({
                        forbear.write("wl_surface");
                    });
                    forbear.write(" with the ");
                    forbear.Strong()({
                        forbear.write("wl_compositor");
                    });
                    forbear.write(".");
                });
            });
            ListItem()({
                forbear.composeText(.{})({
                    forbear.write("Use ");
                    forbear.Strong()({
                        forbear.write("wl_pointer.set_cursor");
                    });
                    forbear.write(" to attach that surface to the pointer.");
                });
            });
            ListItem()({
                forbear.composeText(.{})({
                    forbear.write("Attach a cursor image ");
                    forbear.Strong()({
                        forbear.write("wl_buffer");
                    });
                    forbear.write(" to the surface and commit it.");
                });
            });
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("The only new API introduced here is ");
                forbear.Strong()({
                    forbear.write("wl_pointer.set_cursor");
                });
                forbear.write(":");
            });
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("The ");
                forbear.Strong()({
                    forbear.write("serial");
                });
                forbear.write(" here has to come from the ");
                forbear.Strong()({
                    forbear.write("enter");
                });
                forbear.write(" event. The ");
                forbear.Strong()({
                    forbear.write("hotspot_x");
                });
                forbear.write(" and ");
                forbear.Strong()({
                    forbear.write("hotspot_y");
                });
                forbear.write(" arguments specify the cursor-surface-local coordinates of the \"hotspot\", or the effective position of the pointer within the cursor image (e.g. at the tip of an arrow). Note also that the surface can be null — use this to hide the cursor entirely.");
            });
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("If you're looking for a good source of cursor images, libwayland ships with a separate ");
                forbear.Strong()({
                    forbear.write("wayland-cursor");
                });
                forbear.write(" library, which can load X cursor themes from disk and create ");
                forbear.Strong()({
                    forbear.write("wl_buffers");
                });
                forbear.write(" for them. See ");
                forbear.Strong()({
                    forbear.write("wayland-cursor.h");
                });
                forbear.write(" for details, or the updates to our example client in chapter 9.5.");
            });
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
            forbear.composeText(.{})({
                forbear.write("A single frame of input processing on the server could carry information about lots of changes — for example, polling the mouse once could return, in a single packet, an updated position and the release of a button. The server sends these changes as separate ");
                forbear.Strong()({
                    forbear.write("Wayland");
                });
                forbear.write(" events, and uses the \"frame\" event to group them together.");
            });
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("Clients should accumulate all ");
                forbear.Strong()({
                    forbear.write("wl_pointer");
                });
                forbear.write(" events as they're received, then process pending inputs as a single pointer event once the \"frame\" event is received.");
            });
        });

        Heading(.{ .level = 2 })({
            forbear.text("Motion events");
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("Motion events are specified in the same coordinate space as the ");
                forbear.Strong()({
                    forbear.write("enter");
                });
                forbear.write(" event uses, and are straightforward enough:");
            });
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("Like all input events which include a timestamp, the ");
                forbear.Strong()({
                    forbear.write("time");
                });
                forbear.write(" value is a monotonically increasing millisecond-precision timestamp associated with this input event.");
            });
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
            forbear.composeText(.{})({
                forbear.write("However, the ");
                forbear.Strong()({
                    forbear.write("button");
                });
                forbear.write(" argument merits some additional explanation. This number is a platform-specific input event, though note that FreeBSD reuses the Linux values. You can find these values for Linux in ");
                forbear.Strong()({
                    forbear.write("linux/input-event-codes.h");
                });
                forbear.write(", and the most useful ones will probably be represented by the constants ");
                forbear.Strong()({
                    forbear.write("BTN_LEFT");
                });
                forbear.write(", ");
                forbear.Strong()({
                    forbear.write("BTN_RIGHT");
                });
                forbear.write(", and ");
                forbear.Strong()({
                    forbear.write("BTN_MIDDLE");
                });
                forbear.write(". There are more, I'll leave you to peruse the header at your leisure.");
            });
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
            forbear.composeText(.{})({
                forbear.write("However, axis events are complex, and this is the part of the ");
                forbear.Strong()({
                    forbear.write("wl_pointer");
                });
                forbear.write(" interface which has received the most attention over the years. Several additional events exist which increase the specificity of the axis event:");
            });
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
            forbear.composeText(.{})({
                forbear.write("The precise semantics of these two events are complex, and if you wish to leverage them I recommend a careful reading of the summaries in ");
                forbear.Strong()({
                    forbear.write("wayland.xml");
                });
                forbear.write(". In short, the ");
                forbear.Strong()({
                    forbear.write("axis_discrete");
                });
                forbear.write(" event is used to disambiguate axis events on an arbitrary scale from discrete steps of, for example, a scroll wheel where each \"click\" of the wheel represents a single discrete change in the axis value. The ");
                forbear.Strong()({
                    forbear.write("axis_stop");
                });
                forbear.write(" event signals that a discrete user motion has completed, and is used when accounting for a scrolling event which takes place over several frames. Any future events should be interpreted as a separate motion.");
            });
        });
    });
}
