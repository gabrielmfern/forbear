const std = @import("std");

const forbear = @import("forbear");

const Introduction = @import("./chapters/introduction.zig").Introduction;
const ProtocolDesign = @import("./chapters/protocol_design.zig").ProtocolDesign;
const WireProtocolBasics = @import("./chapters/wire_protocol_basics.zig").WireProtocolBasics;
const InterfacesRequestsAndEvents = @import("./chapters/interfaces_requests_and_events.zig").InterfacesRequestsAndEvents;
const HighLevelProtocolOverview = @import("./chapters/high_level_protocol_overview.zig").HighLevelProtocolOverview;
const WaylandObjectLifetime = @import("./chapters/wayland_object_lifetime.zig").WaylandObjectLifetime;
const LibwaylandBasics = @import("./chapters/libwayland_basics.zig").LibwaylandBasics;
const WaylandProtocolAndLibwayland = @import("./chapters/wayland_protocol_and_libwayland.zig").WaylandProtocolAndLibwayland;
const DisplaysAndWlDisplay = @import("./chapters/displays_and_wl_display.zig").DisplaysAndWlDisplay;
const GlobalsAndTheRegistry = @import("./chapters/globals_and_the_registry.zig").GlobalsAndTheRegistry;
const SurfacesInDepth = @import("./chapters/surfaces_in_depth.zig").SurfacesInDepth;
const SurfaceBasics = @import("./chapters/surface_basics.zig").SurfaceBasics;
const SurfaceRegions = @import("./chapters/surface_regions.zig").SurfaceRegions;
const CompositingAndSubsurfaces = @import("./chapters/compositing_and_subsurfaces.zig").CompositingAndSubsurfaces;
const BuffersAndSurfaces = @import("./chapters/buffers_and_surfaces.zig").BuffersAndSurfaces;
const SharedMemoryBuffers = @import("./chapters/shared_memory_buffers.zig").SharedMemoryBuffers;
const DmaBuf = @import("./chapters/dma_buf.zig").DmaBuf;
const XdgShellBasics = @import("./chapters/xdg_shell_basics.zig").XdgShellBasics;
const XdgSurfaces = @import("./chapters/xdg_surfaces.zig").XdgSurfaces;
const ApplicationWindows = @import("./chapters/application_windows.zig").ApplicationWindows;
const XdgShellExampleCode = @import("./chapters/xdg_shell_example_code.zig").XdgShellExampleCode;
const SeatHandlingInput = @import("./chapters/seat_handling_input.zig").SeatHandlingInput;
const PointerInput = @import("./chapters/pointer_input.zig").PointerInput;
const KeyboardInput = @import("./chapters/keyboard_input.zig").KeyboardInput;
const TouchInput = @import("./chapters/touch_input.zig").TouchInput;
const SeatExampleCode = @import("./chapters/seat_example_code.zig").SeatExampleCode;
const BeyondTheBasics = @import("./chapters/beyond_the_basics.zig").BeyondTheBasics;
const XdgShellInDepth = @import("./chapters/xdg_shell_in_depth.zig").XdgShellInDepth;
const ClipboardAndDnd = @import("./chapters/clipboard_and_dnd.zig").ClipboardAndDnd;
const HighDpiSupport = @import("./chapters/high_dpi_support.zig").HighDpiSupport;
const Heading = @import("heading.zig").Heading;

fn Topbar() void {
    forbear.element(.{
        .style = .{
            .width = .{ .grow = 1.0 },
            .direction = .horizontal,
            .yJustification = .center,
            .padding = forbear.Padding.all(15.0),
            .fontSize = 20.0,
            .fontWeight = 200,
        },
    })({
        Heading(.{
            .level = 1,
            .style = .{
                .xJustification = .center,
            },
        })({
            forbear.text("The Wayland Protocol");
        });
        // TODO: add a printer icon SVG
    });
}

pub fn Content(activeChatper: *usize) void {
    forbear.component(.{
        .sourceLocation = @src(),
    })({
        const viewport = forbear.useViewportSize();
        forbear.element(.{
            .style = .{
                .width = .{ .grow = 1.0 },
                .height = .{ .fixed = viewport[1] },
                .direction = .vertical,
                .xJustification = .center,
                .yJustification = .start,
            },
        })({
            _ = forbear.useScrolling();

            Topbar();

            switch (activeChatper.*) {
                0 => Introduction(),
                1 => ProtocolDesign(),
                2 => WireProtocolBasics(),
                3 => InterfacesRequestsAndEvents(),
                4 => HighLevelProtocolOverview(),
                5 => WaylandObjectLifetime(),
                6 => LibwaylandBasics(),
                7 => WaylandProtocolAndLibwayland(),
                8 => DisplaysAndWlDisplay(),
                9 => GlobalsAndTheRegistry(),
                10 => SurfacesInDepth(),
                11 => SurfaceBasics(),
                12 => SurfaceRegions(),
                13 => CompositingAndSubsurfaces(),
                14 => BuffersAndSurfaces(),
                15 => SharedMemoryBuffers(),
                16 => DmaBuf(),
                17 => XdgShellBasics(),
                18 => XdgSurfaces(),
                19 => ApplicationWindows(),
                20 => XdgShellExampleCode(),
                21 => SeatHandlingInput(),
                22 => PointerInput(),
                23 => KeyboardInput(),
                24 => TouchInput(),
                25 => SeatExampleCode(),
                26 => BeyondTheBasics(),
                27 => XdgShellInDepth(),
                28 => ClipboardAndDnd(),
                29 => HighDpiSupport(),
                else => {
                    forbear.element(.{
                        .style = .{
                            .width = .{ .grow = 1.0 },
                            .height = .{ .grow = 1.0 },
                            .fontSize = 64.0,
                            .fontWeight = 500,
                            .xJustification = .center,
                            .yJustification = .center,
                        },
                    })({
                        forbear.text("Chapter not implemented yet!");
                    });
                },
            }
        });
    });
}
