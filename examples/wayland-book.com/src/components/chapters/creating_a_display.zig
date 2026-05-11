const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;
const Strong = @import("../strong.zig").Strong;
const List = @import("../list.zig").List;
const ListItem = @import("../list.zig").ListItem;

pub fn CreatingADisplay() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Creating a display");
        });

        Paragraph(.{})({
            forbear.text("Fire up your text editor — it's time to write our first lines of code.");
        });

        Heading(.{ .level = 2 })({
            forbear.text("For Wayland clients");
        });

        Paragraph(.{})({
            forbear.text("Connecting to a Wayland server and creating a ");
            Strong()({ forbear.text("wl_display"); });
            forbear.text(" to manage the connection's state is quite easy:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("Let's compile and run this program. Assuming you're using a Wayland compositor as you read this, the result should look like this:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("wl_display_connect is the most common way for clients to establish a Wayland connection. The signature is:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("The \"name\" argument is the name of the Wayland display, which is typically \"wayland-0\". You can swap the NULL for this in our test client and try for yourself — it's likely to work. This corresponds to the name of a Unix socket in $XDG_RUNTIME_DIR. NULL is preferred, however, in which case libwayland will:");
        });

        List()({
            ListItem()({ forbear.text("If $WAYLAND_DISPLAY is set, attempt to connect to $XDG_RUNTIME_DIR/$WAYLAND_DISPLAY"); });
            ListItem()({ forbear.text("Otherwise, attempt to connect to $XDG_RUNTIME_DIR/wayland-0"); });
            ListItem()({ forbear.text("Otherwise, fail :("); });
        });

        Paragraph(.{})({
            forbear.text("This allows users to specify the Wayland display they want to run their clients on by setting $WAYLAND_DISPLAY to the desired display. If you have more complex requirements, you can also establish the connection yourself and create a Wayland display from a file descriptor:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("You can also obtain the file descriptor that the wl_display is using via wl_display_get_fd, regardless of how you created the display.");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Heading(.{ .level = 2 })({
            forbear.text("For Wayland servers");
        });

        Paragraph(.{})({
            forbear.text("The process is fairly simple for servers as well. The creation of the display and binding to a socket are separate, to give you time to configure the display before any clients are able to connect to it. Here's another minimal example program:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("Let's compile and run this, too:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("Using wl_display_add_socket_auto will allow libwayland to decide the name for the display automatically, which defaults to wayland-0, or wayland-$n, depending on whether any other Wayland compositors have sockets in $XDG_RUNTIME_DIR. However, as with the client, you have some other options for configuring the display:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("After adding the socket, calling wl_display_run will run libwayland's internal event loop and block until wl_display_terminate is called. What's this event loop? Turn the page and find out!");
        });
    });
}
