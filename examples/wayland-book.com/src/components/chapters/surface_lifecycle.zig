const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;
const List = @import("../list.zig").List;
const ListItem = @import("../list.zig").ListItem;

pub fn SurfaceLifecycle() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Surface lifecycle");
        });
        Paragraph(.{})({
            forbear.text("We mentioned earlier that Wayland is designed to update everything atomically, such that no frame is ever presented in an invalid or intermediate state. Of the many attributes that can be configured for an application window and other surfaces, the driving mechanism behind that atomicity is the wl_surface itself.");
        });
        Paragraph(.{})({
            forbear.text("Every surface has a pending state and an applied state, and no state at all when it's first created. The pending state is negotiated over the course of any number of requests from clients and events from the server, and when both sides agree that it represents a consistent surface state, the surface is committed — and the pending state is applied to the current state of the surface. Until this time, the compositor will continue to render the last consistent state; once committed, will use the new state from the next frame forward.");
        });
        Paragraph(.{})({
            forbear.text("Among the state which is updated atomically are:");
        });
        List()({
            ListItem()({
                forbear.text("The attached wl_buffer, or the pixels making up the content of the surface");
            });
            ListItem()({
                forbear.text("The region which was \"damaged\" since the last frame, and needs to be redrawn");
            });
            ListItem()({
                forbear.text("The region which accepts input events");
            });
            ListItem()({
                forbear.text("The region considered opaque");
            });
            ListItem()({
                forbear.text("Transformations on the attached wl_buffer, to rotate or present a subset of the buffer");
            });
            ListItem()({
                forbear.text("The scale factor of the buffer, used for HiDPI displays");
            });
        });
        Paragraph(.{})({
            forbear.text("In addition to these features of the surface, the surface's role may have additional double-buffered state like this. All of this state, along with any state associated with the role, is applied when wl_surface.commit is sent. You can send these requests several times if you change your mind, and only the most recent value for any of these properties will be considered when the surface is eventually committed.");
        });
        Paragraph(.{})({
            forbear.text("When you first create your surface, the initial state is invalid. To make it valid (or to map the surface), you need to provide the necessary information to build the first consistent state for that surface. This includes giving it a role (like xdg_toplevel), allocating and attaching a buffer, and configuring any role-specific state for that surface. When you send a wl_surface.commit with this state correctly configured, the surface becomes valid (or mapped) and will be presented by the compositor.");
        });
        Paragraph(.{})({
            forbear.text("The next question is: when should I prepare a new frame?");
        });
    });
}
