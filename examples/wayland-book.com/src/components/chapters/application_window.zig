const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;
const List = @import("../list.zig").List;
const ListItem = @import("../list.zig").ListItem;

pub fn ApplicationWindow() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Application windows");
        });

        Paragraph(.{})({
            forbear.text("We have shaved many yaks to get here, but it's time: XDG toplevel is the interface which we will finally use to display an application window. The XDG toplevel interface has many requests and events for managing application windows, including dealing with minimized and maximized states, setting window titles, and so on. We'll be discussing each part of it in detail in future chapters, so let's just concern ourselves with the basics now.");
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("Based on our knowledge from the last chapter, we know that we can obtain an ");
                forbear.Strong()({
                    forbear.write("xdg_surface");
                });
                forbear.write(" from a ");
                forbear.Strong()({
                    forbear.write("wl_surface");
                });
                forbear.write(", but that it only constitutes the first step: bringing a surface into the fold of XDG shell. The next step is to turn that XDG surface into an XDG toplevel — a \"top-level\" application window, so named for its top-level position in the hierarchy of windows and popup menus we will eventually create with XDG shell. To create one of these, we can use the appropriate request from the ");
                forbear.Strong()({
                    forbear.write("xdg_surface");
                });
                forbear.write(" interface:");
            });
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.composeText(.{})({
                forbear.write("This new ");
                forbear.Strong()({
                    forbear.write("xdg_toplevel");
                });
                forbear.write(" interface puts many requests and events at our disposal for managing the lifecycle of application windows. Chapter 10 explores these in depth, but I know you're itching to get something on-screen. If you follow these steps, handling the ");
                forbear.Strong()({
                    forbear.write("configure");
                });
                forbear.write(" and ");
                forbear.Strong()({
                    forbear.write("ack_configure");
                });
                forbear.write(" riggings for XDG surface discussed in the previous chapter, and attach and commit a ");
                forbear.Strong()({
                    forbear.write("wl_buffer");
                });
                forbear.write(" to our ");
                forbear.Strong()({
                    forbear.write("wl_surface");
                });
                forbear.write(", an application window will appear and present your buffer's contents to the user. Example code which does just this is provided in the next chapter. It also leverages one additional XDG toplevel request which we haven't covered yet:");
            });
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("This should be fairly self-explanatory. There's a similar one that we don't use in the example code, but which may be appropriate for your application:");
        });

        Paragraph(.{})({
            forbear.text("[code block omitted]");
        });

        Paragraph(.{})({
            forbear.text("The title is often shown in window decorations, taskbars, etc, whereas the app ID is used to identify your application or group your windows together. You might utilize these by setting your window title to \"Application windows — The Wayland Protocol — Firefox\", and your app ID to \"firefox\".");
        });

        Paragraph(.{})({
            forbear.text("In summary, the following steps will take you from zero to a window on-screen:");
        });

        List()({
            ListItem()({
                forbear.composeText(.{})({
                    forbear.write("Bind to ");
                    forbear.Strong()({
                        forbear.write("wl_compositor");
                    });
                    forbear.write(" and use it to create a ");
                    forbear.Strong()({
                        forbear.write("wl_surface");
                    });
                    forbear.write(".");
                });
            });

            ListItem()({
                forbear.composeText(.{})({
                    forbear.write("Bind to ");
                    forbear.Strong()({
                        forbear.write("xdg_wm_base");
                    });
                    forbear.write(" and use it to create an ");
                    forbear.Strong()({
                        forbear.write("xdg_surface");
                    });
                    forbear.write(" with your ");
                    forbear.Strong()({
                        forbear.write("wl_surface");
                    });
                    forbear.write(".");
                });
            });

            ListItem()({
                forbear.composeText(.{})({
                    forbear.write("Create an ");
                    forbear.Strong()({
                        forbear.write("xdg_toplevel");
                    });
                    forbear.write(" from the ");
                    forbear.Strong()({
                        forbear.write("xdg_surface");
                    });
                    forbear.write(" with ");
                    forbear.Strong()({
                        forbear.write("xdg_surface.get_toplevel");
                    });
                    forbear.write(".");
                });
            });

            ListItem()({
                forbear.composeText(.{})({
                    forbear.write("Configure a listener for the ");
                    forbear.Strong()({
                        forbear.write("xdg_surface");
                    });
                    forbear.write(" and await the ");
                    forbear.Strong()({
                        forbear.write("configure");
                    });
                    forbear.write(" event.");
                });
            });

            ListItem()({
                forbear.composeText(.{})({
                    forbear.write("Bind to the buffer allocation mechanism of your choosing (such as ");
                    forbear.Strong()({
                        forbear.write("wl_shm");
                    });
                    forbear.write(") and allocate a shared buffer, then render your content to it.");
                });
            });

            ListItem()({
                forbear.composeText(.{})({
                    forbear.write("Use ");
                    forbear.Strong()({
                        forbear.write("wl_surface.attach");
                    });
                    forbear.write(" to attach the ");
                    forbear.Strong()({
                        forbear.write("wl_buffer");
                    });
                    forbear.write(" to the ");
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
                        forbear.write("xdg_surface.ack_configure");
                    });
                    forbear.write(", passing it the serial from ");
                    forbear.Strong()({
                        forbear.write("configure");
                    });
                    forbear.write(", acknowledging that you have prepared a suitable frame.");
                });
            });

            ListItem()({
                forbear.composeText(.{})({
                    forbear.write("Send a ");
                    forbear.Strong()({
                        forbear.write("wl_surface.commit");
                    });
                    forbear.write(" request.");
                });
            });
        });

        Paragraph(.{})({
            forbear.text("Turn the page to see these steps in action.");
        });
    });
}
