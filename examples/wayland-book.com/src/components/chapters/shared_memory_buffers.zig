const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn SharedMemoryBuffers() void {
    forbear.component(.{})({
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
                forbear.text("Shared memory buffers");
            });

            Paragraph(.{})({
                forbear.text("The simplest means of getting pixels from client to compositor, and the only one enshrined in wayland.xml, is wl_shm \u{2014} shared memory. Simply put, it allows you to transfer a file descriptor for the compositor to mmap with MAP_SHARED, then share pixel buffers out of this pool. Add some simple synchronization primitives to keep everyone from fighting over each buffer, and you have a workable \u{2014} and portable \u{2014} solution.");
            });

            Heading(.{ .level = 2 })({
                forbear.text("Binding to wl_shm");
            });

            Paragraph(.{})({
                forbear.text("The registry global listener explained in chapter 5.1 will advertise the wl_shm global when it's available. Binding to it is fairly straightforward. Extending the example given in chapter 5.1, we get the following:");
            });

            // TODO: insert code block here

            Paragraph(.{})({
                forbear.text("Once bound, we can optionally add a listener via wl_shm_add_listener. The compositor will advertise its supported pixel formats via this listener. The full list of possible pixel formats is given in wayland.xml. Two formats are required to be supported: ARGB8888, and XRGB8888, which are 24-bit color, with and without an alpha channel respectively.");
            });

            Heading(.{ .level = 2 })({
                forbear.text("Allocating a shared memory pool");
            });

            Paragraph(.{})({
                forbear.text("A combination of POSIX shm_open and random file names can be utilized to create a file suitable for this purpose, and ftruncate can be utilized to bring it up to the appropriate size. The following boilerplate may be freely used under public domain or CC0:");
            });

            // TODO: insert code block here

            Paragraph(.{})({
                forbear.text("Hopefully the code is fairly self-explanatory (famous last words). Armed with this, the client can create a shared memory pool fairly easily. Let's say, for example, that we want to show a 1920x1080 window. We'll need two buffers for double-buffering, so that'll be 4,147,200 pixels. Assuming the pixel format is WL_SHM_FORMAT_XRGB8888, that'll be 4 bytes to the pixel, for a total pool size of 16,588,800 bytes. Bind to the wl_shm global from the registry as explained in chapter 5.1, then use it like so to create an shm pool which can hold these buffers:");
            });

            // TODO: insert code block here

            Heading(.{ .level = 2 })({
                forbear.text("Creating buffers from a pool");
            });

            Paragraph(.{})({
                forbear.text("Once word of this gets to the compositor, it will mmap this file descriptor as well. Wayland is asynchronous, though, so we can start allocating buffers from this pool right away. Since we allocated space for two buffers, we can assign each an index and convert that index into a byte offset in the pool. Equipped with this information, we can create a wl_buffer:");
            });

            // TODO: insert code block here

            Paragraph(.{})({
                forbear.text("We can write an image to this buffer now as well. For example, to set it to solid white:");
            });

            // TODO: insert code block here

            Paragraph(.{})({
                forbear.text("Or, for something more interesting, here's a checkerboard pattern:");
            });

            // TODO: insert code block here

            Paragraph(.{})({
                forbear.text("With the stage set, we'll attach our buffer to our surface, mark the whole surface as damaged, and commit it:");
            });

            // TODO: insert code block here

            Paragraph(.{})({
                forbear.text("If you were to apply all of this newfound knowledge to writing a Wayland client yourself, you may arrive at this point confused when your buffer is not shown on-screen. We're missing a critical final step \u{2014} assigning your surface a role.");
            });

            Paragraph(.{})({
                forbear.text("\"Damaged\" meaning \"this area needs to be redrawn\"");
            });

            Heading(.{ .level = 2 })({
                forbear.text("wl_shm on the server");
            });

            Paragraph(.{})({
                forbear.text("Before we get there, however, the server-side part of this deserves note. libwayland provides some helpers to make using wl_shm easier. To configure it for your display, it only requires the following:");
            });

            // TODO: insert code block here

            Paragraph(.{})({
                forbear.text("The former creates the global and rigs up the internal implementation, and the latter adds a supported pixel format (remember to at least add ARGB8888 and XRGB8888). Once a client attaches a buffer to one of its surfaces, you can pass the buffer resource into wl_shm_buffer_get to obtain a wl_shm_buffer reference, and utilize it like so:");
            });

            // TODO: insert code block here

            Paragraph(.{})({
                forbear.text("If you guard your accesses to the buffer data with begin_access and end_access, libwayland will take care of locking for you.");
            });
        });
    });
}
