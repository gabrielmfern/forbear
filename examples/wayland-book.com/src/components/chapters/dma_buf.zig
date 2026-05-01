const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;
const List = @import("../list.zig").List;
const ListItem = @import("../list.zig").ListItem;

pub fn DmaBuf() void {
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
                forbear.text("DMA-BUF");
            });

            Paragraph(.{})({
                forbear.text("Most Wayland compositors render on the GPU, and many clients do too. With the shared memory approach, sending buffers from client to compositor in those cases is wasteful: the client reads pixels back from the GPU to the CPU, only for the compositor to push them from the CPU back to the GPU for display.");
            });

            Paragraph(.{})({
                forbear.text("The Linux DRM (Direct Rendering Manager) interface, which is also available on some BSDs, lets us export handles to GPU resources. Mesa, the dominant userspace implementation of Linux graphics drivers, ships a protocol that lets EGL clients hand a GPU buffer handle directly to the compositor for rendering \u{2014} no CPU round trip required.");
            });

            Paragraph(.{})({
                forbear.text("The internals of that protocol are out of scope for this book; resources focused on Mesa or Linux DRM are a better fit. A short summary of how to use it follows.");
            });

            List()({
                ListItem()({
                    forbear.text("Use eglGetPlatformDisplayEXT together with EGL_PLATFORM_WAYLAND_KHR to create an EGL display.");
                });
                ListItem()({
                    forbear.text("Configure the display normally, picking a config appropriate to your needs with EGL_SURFACE_TYPE set to EGL_WINDOW_BIT.");
                });
                ListItem()({
                    forbear.text("Call wl_egl_window_create to create a wl_egl_window for a given wl_surface.");
                });
                ListItem()({
                    forbear.text("Call eglCreatePlatformWindowSurfaceEXT to create an EGLSurface for that wl_egl_window.");
                });
                ListItem()({
                    forbear.text("From there, use EGL as you normally would: eglMakeCurrent to make the surface's context current, and eglSwapBuffers to send an up-to-date buffer to the compositor and commit the surface.");
                });
            });

            Paragraph(.{})({
                forbear.text("If you need to resize the wl_egl_window later, use wl_egl_window_resize.");
            });

            Heading(.{ .level = 2 })({
                forbear.text("But I really want to know about the internals");
            });

            Paragraph(.{})({
                forbear.text("Some Wayland programmers who don't use libwayland complain that this approach couples Mesa and libwayland tightly, and that's a fair criticism. Untangling them isn't impossible \u{2014} it just means implementing linux-dmabuf yourself. Read the Wayland extension XML for the protocol details, and look at Mesa's implementation in src/egl/drivers/dri2/platform_wayland.c (at time of writing). Good luck.");
            });

            Heading(.{ .level = 2 })({
                forbear.text("For the server");
            });

            Paragraph(.{})({
                forbear.text("The compositor side is, unfortunately, both involved and out of scope here. A pointer in the right direction: wlroots' implementation (in types/wlr_linux_dmabuf_v1.c at time of writing) is approachable and a good starting point.");
            });
        });
    });
}
