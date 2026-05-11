const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;
const Strong = @import("../strong.zig").Strong;
const List = @import("../list.zig").List;
const ListItem = @import("../list.zig").ListItem;

pub fn FrameCallbacks() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Frame callbacks");
        });

        Paragraph(.{})({
            forbear.text("The simplest way to update your surface is to simply render and attach new frames when it needs to change. This approach works well, for example, with event-driven applications. The user presses a key and the textbox needs to be re-rendered, so you can just re-render it immediately, damage the appropriate area, and attach a new buffer to be presented on the next frame.");
        });

        Paragraph(.{})({
            forbear.text("However, some applications may want to render frames continuously. You might be rendering frames of a video game, playing back a video, or rendering an animation. Your display has an inherent ");
            Strong()({ forbear.text("refresh rate"); });
            forbear.text(", or the fastest rate at which it's able to display updates (generally this is a number like 60 Hz, 144 Hz, etc). It doesn't make sense to render frames any faster than this, and doing so would be a waste of resources — CPU, GPU, even the user's battery. If you send several frames between each display refresh, all but the last will be discarded and have been rendered for naught.");
        });

        Paragraph(.{})({
            forbear.text("Additionally, the compositor might not even want to show new frames for you. Your application might be off-screen, minimized, or hidden behind other windows; or only a small thumbnail of your application is being shown, so they might want to render you at a slower framerate to conserve resources. For this reason, the best way to continuously render frames in a Wayland client is to let the compositor tell you when it's ready for a new frame: using ");
            Strong()({ forbear.text("frame callbacks"); });
            forbear.text(".");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("This request will allocate a ");
            Strong()({ forbear.text("wl_callback"); });
            forbear.text(" object, which has a pretty simple interface:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("When you request a frame callback on a surface, the compositor will send a ");
            Strong()({ forbear.text("done"); });
            forbear.text(" event to the callback object once it's ready for a new frame for this surface. In the case of ");
            Strong()({ forbear.text("frame"); });
            forbear.text(" events, the ");
            Strong()({ forbear.text("callback_data"); });
            forbear.text(" is set to the current time in millisecond, from an unspecified epoch. You can compare this with your last frame to calculate the progress of an animation or to scale input events.");
        });

        Paragraph(.{})({
            forbear.text("With frame callbacks in our toolbelt, why don't we update our application from chapter 7.3 so it scrolls a bit each frame? Let's start by adding a little bit of state to our ");
            Strong()({ forbear.text("client_state"); });
            forbear.text(" struct:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("Then we'll update our ");
            Strong()({ forbear.text("draw_frame"); });
            forbear.text(" function to take the offset into account:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("In the ");
            Strong()({ forbear.text("main"); });
            forbear.text(" function, let's register a callback for our first new frame:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("Then implement it like so:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("Now, with each frame, we'll");
        });

        List()({
            ListItem()({ forbear.text("Destroy the now-used frame callback."); });
            ListItem()({ forbear.text("Request a new callback for the next frame."); });
            ListItem()({ forbear.text("Render and submit the new frame."); });
        });

        Paragraph(.{})({
            forbear.text("The third step, broken down, is:");
        });

        List()({
            ListItem()({ forbear.text("Update our state with a new offset, using the time since the last frame to scroll at a consistent rate."); });
            ListItem()({
                forbear.text("Prepare a new ");
                Strong()({ forbear.text("wl_buffer"); });
                forbear.text(" and render a frame for it.");
            });
            ListItem()({
                forbear.text("Attach the new ");
                Strong()({ forbear.text("wl_buffer"); });
                forbear.text(" to our surface.");
            });
            ListItem()({ forbear.text("Damage the entire surface."); });
            ListItem()({ forbear.text("Commit the surface."); });
        });

        Paragraph(.{})({
            forbear.text("Steps 3 and 4 update the ");
            Strong()({ forbear.text("pending"); });
            forbear.text(" state for the surface, giving it a new buffer and indicating the entire surface has changed. Step 5 commits this pending state, applying it to the surface's current state, and using it on the following frame. Applying this new buffer atomically means that we never show half of the last frame, resulting in a nice tear-free experience. Compile and run the updated client to try it out for yourself!");
        });
    });
}
