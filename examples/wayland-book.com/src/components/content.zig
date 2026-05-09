const std = @import("std");

const forbear = @import("forbear");

const AccurateTiming = @import("./chapters/accurate_timing.zig").AccurateTiming;
const Acknowledgements = @import("./chapters/acknowledgements.zig").Acknowledgements;
const ApplicationWindow = @import("./chapters/application_window.zig").ApplicationWindow;
const BindingInGlobals = @import("./chapters/binding_in_globals.zig").BindingInGlobals;
const BuffersAndSurfaces = @import("./chapters/buffers_and_surfaces.zig").BuffersAndSurfaces;
const ClipboardAccess = @import("./chapters/clipboard_access.zig").ClipboardAccess;
const ConfigurationAndLifecycle = @import("./chapters/configuration_and_lifecycle.zig").ConfigurationAndLifecycle;
const CreatingADisplay = @import("./chapters/creating_a_display.zig").CreatingADisplay;
const DamagingSurfaces = @import("./chapters/damaging_surfaces.zig").DamagingSurfaces;
const DataOffers = @import("./chapters/data_offers.zig").DataOffers;
const DesktopShellComponents = @import("./chapters/desktop_shell_components.zig").DesktopShellComponents;
const DragAndDrop = @import("./chapters/drag_and_drop.zig").DragAndDrop;
const ExpandingOurExampleCode = @import("./chapters/expanding_our_example_code.zig").ExpandingOurExampleCode;
const ExtendedClipboardSupport = @import("./chapters/extended_clipboard_support.zig").ExtendedClipboardSupport;
const ExtendedExampleCode = @import("./chapters/extended_example_code.zig").ExtendedExampleCode;
const FrameCallbacks = @import("./chapters/frame_callbacks.zig").FrameCallbacks;
const GlobalsAndTheRegistry = @import("./chapters/globals_and_the_registry.zig").GlobalsAndTheRegistry;
const GoalsAndTargetAudience = @import("./chapters/goals_and_target_audience.zig").GoalsAndTargetAudience;
const HighDensitySurfaces = @import("./chapters/high_density_surfaces.zig").HighDensitySurfaces;
const HighLevelWaylandDesign = @import("./chapters/high_level_wayland_design.zig").HighLevelWaylandDesign;
const IncorporatingAnEventLoop = @import("./chapters/incorporating_an_event_loop.zig").IncorporatingAnEventLoop;
const InteractiveMoveAndResize = @import("./chapters/interactive_move_and_resize.zig").InteractiveMoveAndResize;
const InterfacesAndListeners = @import("./chapters/interfaces_and_listeners.zig").InterfacesAndListeners;
const InterfacesRequestsEvents = @import("./chapters/interfaces_requests_events.zig").InterfacesRequestsEvents;
const Introduction = @import("./chapters/introduction.zig").Introduction;
const KeyboardInput = @import("./chapters/keyboard_input.zig").KeyboardInput;
const LibwaylandInDepth = @import("./chapters/libwayland_in_depth.zig").LibwaylandInDepth;
const LinuxDmabuf = @import("./chapters/linux_dmabuf.zig").LinuxDmabuf;
const MiscellaneousExtensions = @import("./chapters/miscellaneous_extensions.zig").MiscellaneousExtensions;
const PointerConstraints = @import("./chapters/pointer_constraints.zig").PointerConstraints;
const PointerInput = @import("./chapters/pointer_input.zig").PointerInput;
const PopupsAndParentWindows = @import("./chapters/popups_and_parent_windows.zig").PopupsAndParentWindows;
const Positioners = @import("./chapters/positioners.zig").Positioners;
const ProtocolDesign = @import("./chapters/protocol_design.zig").ProtocolDesign;
const ProtocolDesignPatterns = @import("./chapters/protocol_design_patterns.zig").ProtocolDesignPatterns;
const ProtocolExtensions = @import("./chapters/protocol_extensions.zig").ProtocolExtensions;
const ProxiesAndResources = @import("./chapters/proxies_and_resources.zig").ProxiesAndResources;
const RegisteringGlobals = @import("./chapters/registering_globals.zig").RegisteringGlobals;
const SeatsHandlingInput = @import("./chapters/seats_handling_input.zig").SeatsHandlingInput;
const SharedMemoryBuffers = @import("./chapters/shared_memory_buffers.zig").SharedMemoryBuffers;
const Subsurfaces = @import("./chapters/subsurfaces.zig").Subsurfaces;
const SurfaceLifecycle = @import("./chapters/surface_lifecycle.zig").SurfaceLifecycle;
const SurfaceRegions = @import("./chapters/surface_regions.zig").SurfaceRegions;
const SurfaceRoles = @import("./chapters/surface_roles.zig").SurfaceRoles;
const SurfacesInDepth = @import("./chapters/surfaces_in_depth.zig").SurfacesInDepth;
const TheHighLevelProtocol = @import("./chapters/the_high_level_protocol.zig").TheHighLevelProtocol;
const TheWaylandDisplay = @import("./chapters/the_wayland_display.zig").TheWaylandDisplay;
const TouchInput = @import("./chapters/touch_input.zig").TouchInput;
const UsingWlCompositor = @import("./chapters/using_wl_compositor.zig").UsingWlCompositor;
const WaylandScanner = @import("./chapters/wayland_scanner.zig").WaylandScanner;
const WaylandUtilPrimitives = @import("./chapters/wayland_util_primitives.zig").WaylandUtilPrimitives;
const WhatsInThePackage = @import("./chapters/whats_in_the_package.zig").WhatsInThePackage;
const WireProtocolBasics = @import("./chapters/wire_protocol_basics.zig").WireProtocolBasics;
const WritingNewExtensions = @import("./chapters/writing_new_extensions.zig").WritingNewExtensions;
const XdgShellBasics = @import("./chapters/xdg_shell_basics.zig").XdgShellBasics;
const XdgShellInDepth = @import("./chapters/xdg_shell_in_depth.zig").XdgShellInDepth;
const XdgSurfaces = @import("./chapters/xdg_surfaces.zig").XdgSurfaces;
const XkbBriefly = @import("./chapters/xkb_briefly.zig").XkbBriefly;
const Heading = @import("heading.zig").Heading;

const Vec4 = @Vector(4, f32);

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

fn SectionButton() *const fn (void) void {
    forbear.component(.{})({
        const isHovering = forbear.useState(bool, false);
        forbear.element(.{
            .style = .{
                .width = .{ .grow = 1.0 },
                .height = .{ .grow = 1.0 },
                .minWidth = 90.0,
                .maxWidth = 150.0,
                .xJustification = .center,
                .yJustification = .center,
                .color = forbear.useTransition(
                    Vec4,
                    if (isHovering.*) forbear.hex("#333333") else forbear.hex("#cccccc"),
                    0.15,
                    forbear.linear,
                ),
                .background = .{
                    .color = forbear.useTransition(
                        Vec4,
                        if (isHovering.*) forbear.hex("#e6e6e6") else forbear.transparent,
                        0.15,
                        forbear.linear,
                    ),
                },
            },
        })({
            if (forbear.on(.mouseEnter)) {
                isHovering.* = true;
            }
            if (forbear.on(.mouseLeave)) {
                isHovering.* = false;
            }
            forbear.componentChildrenSlot();
        });
    });

    return forbear.componentChildrenSlotEnd();
}

pub fn Content(activeChapter: *usize) !void {
    forbear.component(.{})({
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
            const scrollingOffset = forbear.useScrolling();

            forbear.ScrollBar(scrollingOffset);

            Topbar();

            forbear.element(.{
                .style = .{
                    .width = .{ .grow = 1.0 },
                    .height = .{ .grow = 1.0 },
                    .xJustification = .center,
                },
            })({
                if (activeChapter.* > 0) {
                    SectionButton()({
                        if (forbear.on(.click)) {
                            activeChapter.* = activeChapter.* - 1;
                        }
                        forbear.text("previous");
                    });
                }
                forbear.element(.{
                    .style = .{
                        .width = .{ .grow = 1.0 },
                        .maxWidth = 750.0,
                        .padding = forbear.Padding.all(15.0),
                        .direction = .vertical,
                        .xJustification = .center,
                    },
                })({
                    switch (activeChapter.*) {
                        0 => try Introduction(),
                        1 => HighLevelWaylandDesign(),
                        2 => GoalsAndTargetAudience(),
                        3 => WhatsInThePackage(),
                        4 => ProtocolDesign(),
                        5 => WireProtocolBasics(),
                        6 => InterfacesRequestsEvents(),
                        7 => TheHighLevelProtocol(),
                        8 => ProtocolDesignPatterns(),
                        9 => LibwaylandInDepth(),
                        10 => WaylandUtilPrimitives(),
                        11 => WaylandScanner(),
                        12 => ProxiesAndResources(),
                        13 => InterfacesAndListeners(),
                        14 => TheWaylandDisplay(),
                        15 => CreatingADisplay(),
                        16 => IncorporatingAnEventLoop(),
                        17 => GlobalsAndTheRegistry(),
                        18 => BindingInGlobals(),
                        19 => RegisteringGlobals(),
                        20 => BuffersAndSurfaces(),
                        21 => UsingWlCompositor(),
                        22 => SharedMemoryBuffers(),
                        23 => LinuxDmabuf(),
                        24 => SurfaceRoles(),
                        25 => XdgShellBasics(),
                        26 => XdgSurfaces(),
                        27 => ApplicationWindow(),
                        28 => ExtendedExampleCode(),
                        29 => SurfacesInDepth(),
                        30 => SurfaceLifecycle(),
                        31 => FrameCallbacks(),
                        32 => DamagingSurfaces(),
                        33 => SurfaceRegions(),
                        34 => Subsurfaces(),
                        35 => HighDensitySurfaces(),
                        36 => SeatsHandlingInput(),
                        37 => PointerInput(),
                        38 => XkbBriefly(),
                        39 => KeyboardInput(),
                        40 => TouchInput(),
                        41 => ExpandingOurExampleCode(),
                        42 => XdgShellInDepth(),
                        43 => ConfigurationAndLifecycle(),
                        44 => PopupsAndParentWindows(),
                        45 => InteractiveMoveAndResize(),
                        46 => Positioners(),
                        47 => ClipboardAccess(),
                        48 => DataOffers(),
                        49 => DragAndDrop(),
                        50 => ProtocolExtensions(),
                        51 => AccurateTiming(),
                        52 => PointerConstraints(),
                        53 => ExtendedClipboardSupport(),
                        54 => DesktopShellComponents(),
                        55 => MiscellaneousExtensions(),
                        56 => WritingNewExtensions(),
                        57 => Acknowledgements(),
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
                if (activeChapter.* < 57) {
                    SectionButton()({
                        if (forbear.on(.click)) {
                            activeChapter.* = activeChapter.* + 1;
                        }
                        forbear.text("next");
                    });
                }
            });
        });
    });
}
