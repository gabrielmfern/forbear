const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn TouchInput() void {
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
                forbear.text("Touch input");
            });

            Paragraph(.{})({
                forbear.text("On the surface, touchscreen input is fairly simple, and your implementation can be simple as well. However, the protocol offers you a lot of depth, which applications may take advantage of to provide more nuanced touch-driven gestures and feedback.");
            });

            Paragraph(.{})({
                forbear.text("Most touch-screen devices support multitouch: they can track multiple locations where the screen has been touched. Each of these \"touch points\" is assigned an ID which is unique among all currently active points where the screen is being touched, but might be reused if you lift your finger and press again.");
            });

            Paragraph(.{})({
                forbear.text("Similarly to other input devices, you may obtain a wl_touch resource with wl_seat.get_touch, and you should send a \"release\" request when you're finished with it.");
            });

            Heading(.{ .level = 2 })({
                forbear.text("Touch frames");
            });

            Paragraph(.{})({
                forbear.text("Like pointers, a single frame of touch processing on the server might carry information about many changes, but the server sends these as discrete Wayland events. The wl_touch.frame event is used to group these together.");
            });

            // TODO: insert code block here

            Paragraph(.{})({
                forbear.text("Clients should accumulate all wl_touch events as they're received, then process pending inputs as a single touch event when the \"frame\" event is received.");
            });

            Heading(.{ .level = 2 })({
                forbear.text("Touch and release");
            });

            Paragraph(.{})({
                forbear.text("The first events we'll look at are \"down\" and \"up\", which are respectively raised when you press your finger against the device, and remove your finger from the device.");
            });

            // TODO: insert code block here

            Paragraph(.{})({
                forbear.text("The \"x\" and \"y\" coordinates are fixed-point coordinates in the coordinate space of the surface which was touched \u{2014} which is given in the \"surface\" argument. The time is a monotonically increasing timestamp with an arbitrary epoch, in milliseconds. Note also the inclusion of a serial, which can be included in future requests to associate them with this input event.");
            });

            Heading(.{ .level = 2 })({
                forbear.text("Motion");
            });

            Paragraph(.{})({
                forbear.text("After you receive a \"down\" event with a specific touch ID, you will begin to receive motion events which describe the movement of that touch point across the device.");
            });

            // TODO: insert code block here

            Paragraph(.{})({
                forbear.text("The \"x\" and \"y\" coordinates here are in the relative coordinate space of the surface which the \"enter\" event was sent for.");
            });

            Heading(.{ .level = 2 })({
                forbear.text("Gesture cancellation");
            });

            Paragraph(.{})({
                forbear.text("Touch events often have to meet some threshold before they're recognized as a gesture. For example, swiping across the screen from left to right could be used by the Wayland compositor to switch between applications. However, it's not until some threshold has been crossed \u{2014} say, reaching the midpoint of the screen in a certain amount of time \u{2014} that the compositor recognizes this behavior as a gesture.");
            });

            Paragraph(.{})({
                forbear.text("Until this threshold is reached, the compositor will be sending normal touch events for the surface that is being touched. Once the gesture is identified, the compositor will send a \"cancel\" event to let you know that the compositor is taking over.");
            });

            // TODO: insert code block here

            Paragraph(.{})({
                forbear.text("When you receive this event, all active touch points are cancelled.");
            });

            Heading(.{ .level = 2 })({
                forbear.text("Shape and orientation");
            });

            Paragraph(.{})({
                forbear.text("Some high-end touch hardware is capable of determining more information about the way the user is interacting with it. For users of suitable hardware and applications wishing to employ more advanced interactions or touch feedback, the \"shape\" and \"orientation\" events are provided.");
            });

            // TODO: insert code block here

            Paragraph(.{})({
                forbear.text("The \"shape\" event defines an elliptical approximation of the shape of the object which is touching the screen, with a major and minor axis represented in units in the coordinate space of the touched surface. The orientation event rotates this ellipse by specifying the angle between the major axis and the Y-axis of the touched surface, in degrees.");
            });

            Paragraph(.{})({
                forbear.text("Touch is the last of the input devices supported by the Wayland protocol. With this knowledge in hand, let's update our example code.");
            });
        });
    });
}
