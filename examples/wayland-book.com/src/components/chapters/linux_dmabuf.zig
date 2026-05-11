const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;
const Strong = @import("../strong.zig").Strong;
const List = @import("../list.zig").List;
const ListItem = @import("../list.zig").ListItem;

pub fn LinuxDmabuf() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Linux dmabuf");
        });

        Paragraph(.{})({
            forbear.text("Most Wayland compositors do their rendering on the GPU, and many Wayland clients do their rendering on the GPU as well. With the shared memory approach, sending buffers from the client to the compositor in such cases is very inefficient, as the client has to read their data from the GPU to the CPU, then the compositor has to read it from the CPU back to the GPU to be rendered.");
        });

        Paragraph(.{})({
            forbear.text("The Linux DRM (Direct Rendering Manager) interface (which is also implemented on some BSDs) provides a means for us to export handles to GPU resources. Mesa, the predominant implementation of userspace Linux graphics drivers, implements a protocol that allows EGL users to transfer handles to their GPU buffers from the client to the compositor for rendering, without ever copying data to the CPU.");
        });

        Paragraph(.{})({
            forbear.text("The internals of how this protocol works are out of scope for this book and would be more appropriate for resources which focus on Mesa or Linux DRM in particular. However, we can provide a short summary of its use.");
        });

        List()({
            ListItem()({
                forbear.text("Use ");
                Strong()({
                    forbear.text("eglGetPlatformDisplayEXT");
                });
                forbear.text(" in concert with ");
                Strong()({
                    forbear.text("EGL_PLATFORM_WAYLAND_KHR");
                });
                forbear.text(" to create an EGL display.");
            });
            ListItem()({
                forbear.text("Configure the display normally, choosing a config appropriate to your circumstances with ");
                Strong()({
                    forbear.text("EGL_SURFACE_TYPE");
                });
                forbear.text(" set to ");
                Strong()({
                    forbear.text("EGL_WINDOW_BIT");
                });
                forbear.text(".");
            });
            ListItem()({
                forbear.text("Use ");
                Strong()({
                    forbear.text("wl_egl_window_create");
                });
                forbear.text(" to create a ");
                Strong()({
                    forbear.text("wl_egl_window");
                });
                forbear.text(" for a given ");
                Strong()({
                    forbear.text("wl_surface");
                });
                forbear.text(".");
            });
            ListItem()({
                forbear.text("Use ");
                Strong()({
                    forbear.text("eglCreatePlatformWindowSurfaceEXT");
                });
                forbear.text(" to create an ");
                Strong()({
                    forbear.text("EGLSurface");
                });
                forbear.text(" for a ");
                Strong()({
                    forbear.text("wl_egl_window");
                });
                forbear.text(".");
            });
            ListItem()({
                forbear.text("Proceed using EGL normally, e.g. ");
                Strong()({
                    forbear.text("eglMakeCurrent");
                });
                forbear.text(" to make current the EGL context for your surface and ");
                Strong()({
                    forbear.text("eglSwapBuffers");
                });
                forbear.text(" to send an up-to-date buffer to the compositor and commit the surface.");
            });
        });

        Paragraph(.{})({
            forbear.text("Should you need to change the size of the ");
            Strong()({
                forbear.text("wl_egl_window");
            });
            forbear.text(" later, use ");
            Strong()({
                forbear.text("wl_egl_window_resize");
            });
            forbear.text(".");
        });

        Heading(.{ .level = 2 })({
            forbear.text("But I really want to know about the internals");
        });

        Paragraph(.{})({
            forbear.text("Some Wayland programmers who don't use libwayland complain that this approach ties Mesa and libwayland tightly together, which is true. However, untangling them is not impossible — it just requires a lot of work for you in the form of implementing ");
            Strong()({
                forbear.text("linux-dmabuf");
            });
            forbear.text(" yourself. Consult the Wayland extension XML for details on the protocol, and Mesa's implementation at ");
            Strong()({
                forbear.text("src/egl/drivers/dri2/platform_wayland.c");
            });
            forbear.text(" (at the time of writing). Good luck and godspeed.");
        });

        Heading(.{ .level = 2 })({
            forbear.text("For the server");
        });

        Paragraph(.{})({
            forbear.text("Unfortunately, the details for the compositor are both complicated and out-of-scope for this book. I can point you in the right direction, however: the wlroots implementation (found at ");
            Strong()({
                forbear.text("types/wlr_linux_dmabuf_v1.c");
            });
            forbear.text(" at the time of writing) is straightforward and should set you on the right path.");
        });
    });
}
