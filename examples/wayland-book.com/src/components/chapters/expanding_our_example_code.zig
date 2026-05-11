const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;
const Strong = @import("../strong.zig").Strong;

pub fn ExpandingOurExampleCode() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Expanding our example code");
        });

        Paragraph(.{})({
            forbear.text("In previous chapters, we built a simple client which can present its surfaces on the display. Let's expand this code a bit to build a client which can receive input events. For the sake of simplicity, we're just going to be logging input events to stderr.");
        });

        Paragraph(.{})({
            forbear.text("This is going to require a lot more code than we've worked with so far, so get strapped in. The first thing we need to do is set up the seat.");
        });

        Heading(.{ .level = 2 })({
            forbear.text("Setting up the seat");
        });

        Paragraph(.{})({
            forbear.text("The first thing we'll need is a reference to a seat. We'll add it to our ");
            Strong()({
                forbear.text("client_state");
            });
            forbear.text(" struct, and add keyboard, pointer, and touch objects for later use as well:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("We'll also need to update ");
            Strong()({
                forbear.text("registry_global");
            });
            forbear.text(" to register a listener for that seat.");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("Note that we bind to the latest version of the seat interface, version 7. Let's also rig up that listener:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("If you compile (");
            Strong()({
                forbear.text("cc -o client client.c xdg-shell-protocol.c");
            });
            forbear.text(") and run this now, you should seat the name of the seat printed to stderr.");
        });

        Heading(.{ .level = 2 })({
            forbear.text("Rigging up pointer events");
        });

        Paragraph(.{})({
            forbear.text("Let's get to pointer events. If you recall, pointer events from the Wayland server are to be accumulated into a single logical event. For this reason, we'll need to define a struct to store them in.");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("We'll be using a bitmask here to identify which events we've received for a single pointer frame, and storing the relevant information from each event in their respective fields. Let's add this to our state struct as well:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("Then we'll need to update our ");
            Strong()({
                forbear.text("wl_seat_capabilities");
            });
            forbear.text(" to set up the pointer object for seats which are capable of pointer input.");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("This merits some explanation. Recall that ");
            Strong()({
                forbear.text("capabilities");
            });
            forbear.text(" is a bitmask of the kinds of devices supported by this seat — a bitwise AND (&) with a capability will produce a non-zero value if supported. Then, if we have a pointer and have ");
            Strong()({
                forbear.text("not");
            });
            forbear.text(" already configured it, we take the first branch, using ");
            Strong()({
                forbear.text("wl_seat_get_pointer");
            });
            forbear.text(" to obtain a pointer reference and storing it in our state. If the seat does ");
            Strong()({
                forbear.text("not");
            });
            forbear.text(" support pointers, but we already have one configured, we use ");
            Strong()({
                forbear.text("wl_pointer_release");
            });
            forbear.text(" to get rid of it. Remember that the capabilities of a seat can change at runtime, for example when the user un-plugs and re-plugs their mouse.");
        });

        Paragraph(.{})({
            forbear.text("We also configured a listener for the pointer. Let's add the struct for that, too:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("Pointers have a lot of events. Let's have a look at them.");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("The \"enter\" and \"leave\" events are fairly straightforward, and they set the stage for the rest of the implementation. We update the event mask to include the appropriate event, then populate it with the data we were provided. The \"motion\" and \"button\" events are rather similar:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("Axis events are somewhat more complex, because there are two axes: horizontal and vertical. Thus, our ");
            Strong()({
                forbear.text("pointer_event");
            });
            forbear.text(" struct contains an array with two groups of axis events. Our code to handle these ends up something like this:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("Similarly straightforward, aside from the main change of updating whichever axis was affected. Note the use of the \"valid\" boolean as well: it's possible that we'll receive a pointer frame which updates one axis, but not another, so we use this \"valid\" value to determine which axes were updated in the frame event.");
        });

        Paragraph(.{})({
            forbear.text("Speaking of which, it's time for the main attraction: our \"frame\" handler.");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("It certainly is the longest of the bunch, isn't it? Hopefully it isn't too confusing, though. All we're doing here is pretty-printing the accumulated state for this frame to stderr. If you compile and run this again now, you should be able to wiggle your mouse over the window and see input events printed out!");
        });

        Heading(.{ .level = 2 })({
            forbear.text("Rigging up keyboard events");
        });

        Paragraph(.{})({
            forbear.text("Let's update our ");
            Strong()({
                forbear.text("client_state");
            });
            forbear.text(" struct with some fields to store XKB state.");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("We need the xkbcommon headers to define these. While we're at it, I'm going to pull in ");
            Strong()({
                forbear.text("assert.h");
            });
            forbear.text(" as well:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("We'll also need to initialize the xkb_context in our main function:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("Next, let's update our seat capabilities function to rig up our keyboard listener, too.");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("We'll have to define the ");
            Strong()({
                forbear.text("wl_keyboard_listener");
            });
            forbear.text(" we use here, too.");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("And now, the meat of the changes. Let's start with the keymap:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("Now we can see why we added ");
            Strong()({
                forbear.text("assert.h");
            });
            forbear.text(" — we're using it here to make sure that the keymap format is the one we expect. Then, we use mmap to map the file descriptor the compositor sent us to a ");
            Strong()({
                forbear.text("char *");
            });
            forbear.text(" pointer we can pass into ");
            Strong()({
                forbear.text("xkb_keymap_new_from_string");
            });
            forbear.text(". Don't forget to munmap and close that fd afterwards — then we set up our XKB state. Note as well that we have also unrefed any previous XKB keymap or state that we had set up in a prior call to this function, in case the compositor changes the keymap at runtime.");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("When the keyboard \"enters\" our surface, we have received keyboard focus. The compositor forwards a list of keys which were already pressed at that time, and here we just enumerate them and log their keysym names and UTF-8 equivalent. We'll do something similar when keys are pressed:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("And finally, we add small implementations of the three remaining events:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("For modifiers, we could decode these further, but most applications won't need to. We just update the XKB state here. As for handling key repeat — this has a lot of constraints particular to your application. Do you want to repeat text input? Do you want to repeat keyboard shortcuts? How does the timing of these interact with your event loop? The answers to these questions is left for you to decide.");
        });

        Paragraph(.{})({
            forbear.text("If you compile this again, you should be able to start typing into the window and see your input printed into the log. Huzzah!");
        });

        Heading(.{ .level = 2 })({
            forbear.text("Rigging up touch events");
        });

        Paragraph(.{})({
            forbear.text("Finally, we'll add support for touch-capable devices. Like pointers, a \"frame\" event exists for touch devices. However, they're further complicated by the possibility that multiple touch points may be updated within a single frame. We'll add some more structures and enums to represent the accumulated state:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("Note that I've arbitrarily chosen 10 touchpoints here, with the assumption that most users will only ever use that many fingers. For larger, multi-user touch screens, you may need a higher limit. Additionally, some touch hardware supports fewer than 10 touch points concurrently — 8 is also common, and hardware which supports fewer still is common among older devices.");
        });

        Paragraph(.{})({
            forbear.text("We'll add this struct to ");
            Strong()({
                forbear.text("client_state");
            });
            forbear.text(":");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("And we'll update the seat capabilities handler to rig up a listener when touch support is available.");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("We've repeated again the pattern of handling both the appearance and disappearance of touch capabilities on the seat, so we're robust to devices appearing and disappearing at runtime. It's less common for touch devices to be hotplugged, though.");
        });

        Paragraph(.{})({
            forbear.text("Here's the listener itself:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("To deal with multiple touch points, we'll need to write a small helper function:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("The basic purpose of this function is to pick a ");
            Strong()({
                forbear.text("touch_point");
            });
            forbear.text(" from the array we added to the ");
            Strong()({
                forbear.text("touch_event");
            });
            forbear.text(" struct, based on the touch ID we're receiving events for. If we find an existing ");
            Strong()({
                forbear.text("touch_point");
            });
            forbear.text(" for that ID, we return it. If not, we return the first available touch point. In case we run out, we return NULL.");
        });

        Paragraph(.{})({
            forbear.text("Now we can take advantage of this to implement our first function: touch up.");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("Like the pointer events, we're also simply accumulating this state for later use. We don't yet know if this event represents a complete touch frame. Let's add something similar for touch up:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("And for motion:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("The touch cancel event is somewhat different, as it \"cancels\" all active touch points at once. We'll just store this in the ");
            Strong()({
                forbear.text("touch_event");
            });
            forbear.text("'s top-level event mask.");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("The shape and orientation events are similar to up, down, and move, however, in that they inform us about the dimensions of a specific touch point.");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("And finally, upon receiving a frame event, we can interpret all of this accumulated state as a single input event, much like our pointer code.");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("Compile and run this again, and you'll be able to see touch events printed to stderr as you interact with your touch device (assuming you have such a device to test with). And now our client supports input!");
        });

        Heading(.{ .level = 2 })({
            forbear.text("What's next?");
        });

        Paragraph(.{})({
            forbear.text("There are a lot of different kinds of input devices, so extending our code to support them was a fair bit of work — our code has grown by 2.5x in this chapter alone. The rewards should feel pretty great, though, as you are now familiar with enough Wayland concepts (and code) that you can implement a lot of clients.");
        });

        Paragraph(.{})({
            forbear.text("There's still a little bit more to learn — in the last few chapters, we'll cover popup windows, context menus, interactive window moving and resizing, clipboard and drag & drop support, and, later, a handful of interesting protocol extensions which support more niche use-cases. I definitely recommend reading at least chapter 10.1 before you start building your own client, as it covers things like having the window resized at the compositor's request.");
        });
    });
}
