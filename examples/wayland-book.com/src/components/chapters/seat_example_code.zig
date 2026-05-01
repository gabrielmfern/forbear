const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn SeatExampleCode() void {
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
                forbear.text("Example code");
            });

            Paragraph()({
                forbear.text("In previous chapters, we built a simple client which can present its surfaces on the display. Let's expand this code a bit to build a client which can receive input events. For the sake of simplicity, we're just going to be logging input events to stderr.");
            });

            Paragraph()({
                forbear.text("This is going to require a lot more code than we've worked with so far, so get strapped in. The first thing we need to do is set up the seat.");
            });

            Heading(.{ .level = 2 })({
                forbear.text("Setting up the seat");
            });

            Paragraph()({
                forbear.text("The first thing we'll need is a reference to a seat. We'll add it to our client_state struct, and add keyboard, pointer, and touch objects for later use as well:");
            });

            // TODO: insert code block here

            Paragraph()({
                forbear.text("We'll also need to update registry_global to register a listener for that seat.");
            });

            // TODO: insert code block here

            Paragraph()({
                forbear.text("Note that we bind to the latest version of the seat interface, version 7. Let's also rig up that listener:");
            });

            // TODO: insert code block here

            Paragraph()({
                forbear.text("If you compile (cc -o client client.c xdg-shell-protocol.c) and run this now, you should seat the name of the seat printed to stderr.");
            });

            Heading(.{ .level = 2 })({
                forbear.text("Rigging up pointer events");
            });

            Paragraph()({
                forbear.text("Let's get to pointer events. If you recall, pointer events from the Wayland server are to be accumulated into a single logical event. For this reason, we'll need to define a struct to store them in.");
            });

            // TODO: insert code block here

            Paragraph()({
                forbear.text("We'll be using a bitmask here to identify which events we've received for a single pointer frame, and storing the relevant information from each event in their respective fields. Let's add this to our state struct as well:");
            });

            // TODO: insert code block here

            Paragraph()({
                forbear.text("Then we'll need to update our wl_seat_capabilities to set up the pointer object for seats which are capable of pointer input.");
            });

            // TODO: insert code block here

            Paragraph()({
                forbear.text("This merits some explanation. Recall that capabilities is a bitmask of the kinds of devices supported by this seat \u{2014} a bitwise AND (&) with a capability will produce a non-zero value if supported. Then, if we have a pointer and have not already configured it, we take the first branch, using wl_seat_get_pointer to obtain a pointer reference and storing it in our state. If the seat does not support pointers, but we already have one configured, we use wl_pointer_release to get rid of it. Remember that the capabilities of a seat can change at runtime, for example when the user un-plugs and re-plugs their mouse.");
            });

            Paragraph()({
                forbear.text("We also configured a listener for the pointer. Let's add the struct for that, too:");
            });

            // TODO: insert code block here

            Paragraph()({
                forbear.text("Pointers have a lot of events. Let's have a look at them.");
            });

            // TODO: insert code block here

            Paragraph()({
                forbear.text("The \"enter\" and \"leave\" events are fairly straightforward, and they set the stage for the rest of the implementation. We update the event mask to include the appropriate event, then populate it with the data we were provided. The \"motion\" and \"button\" events are rather similar:");
            });

            // TODO: insert code block here

            Paragraph()({
                forbear.text("Axis events are somewhat more complex, because there are two axes: horizontal and vertical. Thus, our pointer_event struct contains an array with two groups of axis events. Our code to handle these ends up something like this:");
            });

            // TODO: insert code block here

            Paragraph()({
                forbear.text("Similarly straightforward, aside from the main change of updating whichever axis was affected. Note the use of the \"valid\" boolean as well: it's possible that we'll receive a pointer frame which updates one axis, but not another, so we use this \"valid\" value to determine which axes were updated in the frame event.");
            });

            Paragraph()({
                forbear.text("Speaking of which, it's time for the main attraction: our \"frame\" handler.");
            });

            // TODO: insert code block here

            Heading(.{ .level = 2 })({
                forbear.text("Rigging up keyboard events");
            });

            Paragraph()({
                forbear.text("Let's update our client_state struct with some fields to store XKB state.");
            });

            // TODO: insert code block here

            Paragraph()({
                forbear.text("We need the xkbcommon headers to define these. While we're at it, I'm going to pull in assert.h as well:");
            });

            // TODO: insert code block here

            Paragraph()({
                forbear.text("We'll also need to initialize the xkb_context in our main function:");
            });

            // TODO: insert code block here

            Paragraph()({
                forbear.text("Next, let's update our seat capabilities function to rig up our keyboard listener, too.");
            });

            // TODO: insert code block here

            Paragraph()({
                forbear.text("We'll have to define the wl_keyboard_listener we use here, too.");
            });

            // TODO: insert code block here

            Paragraph()({
                forbear.text("And now, the meat of the changes. Let's start with the keymap:");
            });

            // TODO: insert code block here

            Paragraph()({
                forbear.text("Now we can see why we added assert.h \u{2014} we're using it here to make sure that the keymap format is the one we expect. Then, we use mmap to map the file descriptor the compositor sent us to a char * pointer we can pass into xkb_keymap_new_from_string. Don't forget to munmap and close that fd afterwards \u{2014} then we set up our XKB state.");
            });

            // TODO: insert code block here

            Paragraph()({
                forbear.text("When the keyboard \"enters\" our surface, we have received keyboard focus. The compositor forwards a list of keys which were already pressed at that time, and here we just enumerate them and log their keysym names and UTF-8 equivalent. We'll do something similar when keys are pressed:");
            });

            // TODO: insert code block here

            Paragraph()({
                forbear.text("And finally, we add small implementations of the three remaining events:");
            });

            // TODO: insert code block here

            Paragraph()({
                forbear.text("For modifiers, we could decode these further, but most applications won't need to. We just update the XKB state here. As for handling key repeat \u{2014} this has a lot of constraints particular to your application. Do you want to repeat text input? Do you want to repeat keyboard shortcuts? How does the timing of these interact with your event loop? The answers to these questions is left for you to decide.");
            });

            Paragraph()({
                forbear.text("If you compile this again, you should be able to start typing into the window and see your input printed into the log. Huzzah!");
            });

            Heading(.{ .level = 2 })({
                forbear.text("Rigging up touch events");
            });

            Paragraph()({
                forbear.text("Finally, we'll add support for touch-capable devices. Like pointers, a \"frame\" event exists for touch devices. However, they're further complicated by the possibility that multiple touch points may be updated within a single frame. We'll add some more structures and enums to represent the accumulated state:");
            });

            // TODO: insert code block here

            Paragraph()({
                forbear.text("Note that I've arbitrarily chosen 10 touchpoints here, with the assumption that most users will only ever use that many fingers. For larger, multi-user touch screens, you may need a higher limit. Additionally, some touch hardware supports fewer than 10 touch points concurrently \u{2014} 8 is also common, and hardware which supports fewer still is common among older devices.");
            });

            Paragraph()({
                forbear.text("We'll add this struct to client_state:");
            });

            // TODO: insert code block here

            Paragraph()({
                forbear.text("And we'll update the seat capabilities handler to rig up a listener when touch support is available.");
            });

            // TODO: insert code block here

            Paragraph()({
                forbear.text("We've repeated again the pattern of handling both the appearance and disappearance of touch capabilities on the seat, so we're robust to devices appearing and disappearing at runtime. It's less common for touch devices to be hotplugged, though.");
            });

            Paragraph()({
                forbear.text("Here's the listener itself:");
            });

            // TODO: insert code block here

            Paragraph()({
                forbear.text("The basic purpose of this function is to pick a touch_point from the array we added to the touch_event struct, based on the touch ID we're receiving events for. If we find an existing touch_point for that ID, we return it. If not, we return the first available touch point. In case we run out, we return NULL.");
            });

            Paragraph()({
                forbear.text("Now we can take advantage of this to implement our first function: touch up.");
            });

            // TODO: insert code block here

            Paragraph()({
                forbear.text("Like the pointer events, we're also simply accumulating this state for later use. We don't yet know if this event represents a complete touch frame. Let's add something similar for touch up:");
            });

            // TODO: insert code block here

            Paragraph()({
                forbear.text("And for motion:");
            });

            // TODO: insert code block here

            Paragraph()({
                forbear.text("The touch cancel event is somewhat different, as it \"cancels\" all active touch points at once. We'll just store this in the touch_event's top-level event mask.");
            });

            // TODO: insert code block here

            Paragraph()({
                forbear.text("The shape and orientation events are similar to up, down, and move, however, in that they inform us about the dimensions of a specific touch point.");
            });

            // TODO: insert code block here

            // TODO: insert code block here

            Paragraph()({
                forbear.text("Compile and run this again, and you'll be able to see touch events printed to stderr as you interact with your touch device (assuming you have such a device to test with). And now our client supports input!");
            });
        });
    });
}
