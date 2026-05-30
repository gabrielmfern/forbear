const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;
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
                forbear.composeText(.{})({
                    forbear.write("Use ");
                    forbear.Strong()({
                        forbear.write("eglGetPlatformDisplayEXT");
                    });
                    forbear.write(" in concert with ");
                    forbear.Strong()({
                        forbear.write("EGL_PLATFORM_WAYLAND_KHR");
                    });
                    forbear.write(" to create an EGL display.");
                });
            });
            ListItem()({
                forbear.composeText(.{})({
                    forbear.write("Configure the display normally, choosing a config appropriate to your circumstances with ");
                    forbear.Strong()({
                        forbear.write("EGL_SURFACE_TYPE");
                    });
                    forbear.write(" set to ");
                    forbear.Strong()({
                        forbear.write("EGL_WINDOW_BIT");
                    });
                    forbear.write(".");
                });
            });
            ListItem()({
                forbear.composeText(.{})({
                    forbear.write("Use ");
                    forbear.Strong()({
                        forbear.write("wl_egl_window_create");
                    });
                    forbear.write(" to create a ");
                    forbear.Strong()({
                        forbear.write("wl_egl_window");
                    });
                    forbear.write(" for a given ");
                    forbear.Strong()({
                        forbear.write("wl_surface");
                    });
                    forbear.write(".");
                });
            });
            ListItem()({
                forbear.composeText(.{})({
                    forbear.write("Use ");
                    forbear.Strong()({
                        forbear.write("eglCreatePlatformWindowSurfaceEXT");
                    });
                    forbear.write(" to create an ");
                    forbear.Strong()({
                        forbear.write("EGLSurface");
                    });
                    forbear.write(" for a ");
                    forbear.Strong()({
                        forbear.write("wl_egl_window");
                    });
                    forbear.write(".");
                });
            });
            ListItem()({
                forbear.composeText(.{})({
                    forbear.write("Proceed using EGL normally, e.g. ");
                    forbear.Strong()({
                        forbear.write("eglMakeCurrent");
                    });
                    forbear.write(" to make current the EGL context for your surface and ");
                    forbear.Strong()({
                        forbear.write("eglSwapBuffers");
                    });
                    forbear.write(" to send an up-to-date buffer to the compositor and commit the surface.");
                });
            });
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("Should you need to change the size of the ");
                forbear.Strong()({
                    forbear.write("wl_egl_window");
                });
                forbear.write(" later, use ");
                forbear.Strong()({
                    forbear.write("wl_egl_window_resize");
                });
                forbear.write(".");
            });
        });

        Heading(.{ .level = 2 })({
            forbear.text("But I really want to know about the internals");
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("Some Wayland programmers who don't use libwayland complain that this approach ties Mesa and libwayland tightly together, which is true. However, untangling them is not impossible — it just requires a lot of work for you in the form of implementing ");
                forbear.Strong()({
                    forbear.write("linux-dmabuf");
                });
                forbear.write(" yourself. Consult the Wayland extension XML for details on the protocol, and Mesa's implementation at ");
                forbear.Strong()({
                    forbear.write("src/egl/drivers/dri2/platform_wayland.c");
                });
                forbear.write(" (at the time of writing). Good luck and godspeed.");
            });
        });

        Heading(.{ .level = 2 })({
            forbear.text("For the server");
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("Unfortunately, the details for the compositor are both complicated and out-of-scope for this book. I can point you in the right direction, however: the wlroots implementation (found at ");
                forbear.Strong()({
                    forbear.write("types/wlr_linux_dmabuf_v1.c");
                });
                forbear.write(" at the time of writing) is straightforward and should set you on the right path.");
            });
        });
    });
}
