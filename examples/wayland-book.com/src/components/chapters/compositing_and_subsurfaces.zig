const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn CompositingAndSubsurfaces() void {
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
                forbear.text("Compositing and subsurfaces");
            });

            Paragraph()({
                forbear.text("There's only one surface role defined in the core Wayland protocol, wayland.xml: subsurfaces. They have an X, Y position relative to the parent surface — which needn't be constrained by the bounds of their parent surface — and a Z-order relative to their siblings and parent surface.");
            });

            Paragraph()({
                forbear.text("Some use-cases for this feature include playing a video surface in its native pixel format with an RGBA user-interface or subtitles shown on top, using an OpenGL surface for your primary application interface and using subsurfaces to render window decorations in software, or moving around parts of the UI without having to redraw on the client. With the assistance of hardware planes, the compositor, too, might not even have to redraw anything for updating your subsurfaces. On embedded systems in particular, this can be especially useful when it fits your use-case. A cleverly designed application can take advantage of subsurfaces to be very efficient.");
            });

            Paragraph()({
                forbear.text("The interface for managing these is the wl_subcompositor interface. The get_subsurface request is the main entry-point to the subcompositor:");
            });

            // TODO: insert code block here

            Paragraph()({
                forbear.text("Once you have a wl_subsurface object associated with a wl_surface, it becomes a child of that surface. Subsurfaces can themselves have subsurfaces, resulting in an ordered tree of surfaces beneath any top-level surface. Manipulating these children is done through the wl_subsurface interface:");
            });

            // TODO: insert code block here

            Paragraph()({
                forbear.text("A subsurface's z-order may be changed by placing it above or below any sibling surface that shares the same parent, or the parent surface itself.");
            });

            Paragraph()({
                forbear.text("The synchronization of the various properties of a wl_subsurface requires some explanation. These position and z-order properties are synchronized with the parent surface's lifecycle. When a wl_surface.commit request is sent for the main surface, all of its subsurfaces have changes to their position and z-order applied with it.");
            });

            Paragraph()({
                forbear.text("However, the wl_surface state associated with this subsurface, such as the attachment of buffers and accumulation of damage, need not be linked to the parent surface's lifecycle. This is the purpose of the set_sync and set_desync requests. Subsurfaces synced with their parent surface will commit all of their state when the parent surface is committed. Desynced surfaces will manage their own commit lifecycle like any other.");
            });

            Paragraph()({
                forbear.text("In short, the sync and desync requests are non-buffered and apply immediately. The position and z-order requests are buffered, and are not affected by the sync/desync property of the surface — they are always committed with the parent surface. The remaining surface state, on the associated wl_surface, is committed in accordance with the sync/desync status of the subsurface.");
            });
        });
    });
}
