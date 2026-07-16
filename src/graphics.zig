const std = @import("std");
const builtin = @import("builtin");

const zmath = @import("zmath");

const BlendMode = @import("node.zig").BlendMode;
const GradientStop = @import("node.zig").GradientStop;
const Node = @import("node.zig").Node;
const NodeTree = @import("node.zig").NodeTree;
const CompleteTextStyle = @import("node.zig").CompleteTextStyle;
const c = @import("c");
const Font = @import("font.zig");
const layouting = @import("layouting.zig");
const countTreeSize = layouting.countTreeSize;
const Window = @import("window.zig").Window;
const root = @import("root.zig");

const LayerInterval = struct {
    start: usize,
    end: usize,
};

pub const DrawKind = enum(u8) {
    shadow = 0,
    element = 1,
    text = 2,
};

pub const DrawCommand = struct {
    kind: DrawKind,
    blendMode: BlendMode,
    start: usize,
    end: usize,
    clipRect: ?Vec4,
    z: u16,

    fn interval(self: DrawCommand) LayerInterval {
        return .{ .start = self.start, .end = self.end };
    }

    fn lessThan(_: void, a: DrawCommand, b: DrawCommand) bool {
        if (a.z != b.z) return a.z < b.z;
        return @intFromEnum(a.kind) < @intFromEnum(b.kind);
    }
};
const Vec4 = @Vector(4, f32);
const Vec3 = @Vector(3, f32);
const Vec2 = @Vector(2, f32);

pub const DrawCommandCounts = struct {
    /// Glyphs actually written per glyph-bearing node, in visitation order.
    /// A node can write fewer than `glyphs.slice.len` when a mid-frame
    /// atlas reset skips some of them; null assumes the full count.
    glyphsWritten: ?[]const usize = null,
};

/// Build the sorted list of draw commands for a given node tree and viewport.
/// Culls nodes outside the viewport, emits element/shadow/text commands,
/// and sorts by (z, kind) so shadows draw before elements before text.
pub fn buildDrawCommands(
    arena: std.mem.Allocator,
    nodeTree: *const NodeTree,
    viewport: Vec2,
    counts: DrawCommandCounts,
) ![]DrawCommand {
    var nodesToRender = std.ArrayList(usize).empty;
    for (nodeTree.list.items, 0..) |node, i| {
        const insideView = node.position[0] + node.size[0] > 0.0 and
            node.position[1] + node.size[1] > 0.0 and
            viewport[0] > node.position[0] and
            viewport[1] > node.position[1];
        if (!insideView) continue;
        try nodesToRender.append(arena, i);
    }

    // Max possible: each node can emit element + shadow + text = 3 commands
    var commands = try arena.alloc(DrawCommand, nodesToRender.items.len * 3);
    var count: usize = 0;

    var shadowIndex: usize = 0;
    var glyphIndex: usize = 0;
    var glyphNodeIndex: usize = 0;

    for (nodesToRender.items, 0..) |nodeIndex, elementIndex| {
        const node = nodeTree.at(nodeIndex);

        commands[count] = .{
            .kind = .element,
            .blendMode = node.style.blendMode,
            .start = elementIndex,
            .end = elementIndex,
            .clipRect = node.clipRect,
            .z = node.z,
        };
        count += 1;

        if (node.style.shadow != null) {
            commands[count] = .{
                .kind = .shadow,
                .blendMode = .normal,
                .start = shadowIndex,
                .end = shadowIndex,
                .clipRect = if (node.parent) |parentIndex| 
                    nodeTree.at(parentIndex).clipRect 
                else 
                    null,
                .z = node.z,
            };
            count += 1;
            shadowIndex += 1;
        }

        if (node.glyphs) |glyphs| {
            const glyphCount = if (counts.glyphsWritten) |written| written[glyphNodeIndex] else glyphs.slice.len;
            glyphNodeIndex += 1;
            if (glyphCount > 0) {
                commands[count] = .{
                    .kind = .text,
                    .blendMode = .normal,
                    .start = glyphIndex,
                    .end = glyphIndex + glyphCount - 1,
                    .clipRect = node.clipRect,
                    .z = node.z,
                };
                count += 1;
                glyphIndex += glyphCount;
            }
        }
    }

    const result = commands[0..count];
    std.mem.sort(DrawCommand, result, {}, DrawCommand.lessThan);
    return result;
}

/// Merges contiguous same-kind/blend/clip/z commands into one instanced
/// draw, since `buildDrawCommands` emits one per node.
pub fn mergeAdjacentDrawCommands(commands: []DrawCommand) []DrawCommand {
    if (commands.len == 0) return commands;

    var writeIndex: usize = 0;
    for (commands[1..]) |cmd| {
        const merged = &commands[writeIndex];
        const canMerge = merged.kind == cmd.kind and
            merged.blendMode == cmd.blendMode and
            merged.z == cmd.z and
            clipRectEql(merged.clipRect, cmd.clipRect) and
            merged.end + 1 == cmd.start;
        if (canMerge) {
            merged.end = cmd.end;
        } else {
            writeIndex += 1;
            commands[writeIndex] = cmd;
        }
    }
    return commands[0 .. writeIndex + 1];
}

fn clipRectEql(a: ?Vec4, b: ?Vec4) bool {
    if (a == null or b == null) return a == null and b == null;
    return @reduce(.And, a.? == b.?);
}

const Stopwatch = struct {
    io: std.Io,
    startNs: i128,

    fn start(io: std.Io) Stopwatch {
        return .{ .io = io, .startNs = std.Io.Clock.awake.now(io).toNanoseconds() };
    }

    fn elapsedMs(self: Stopwatch) i128 {
        return @divTrunc(std.Io.Clock.awake.now(self.io).toNanoseconds() - self.startNs, std.time.ns_per_ms);
    }

    fn elapsedUs(self: Stopwatch) i128 {
        return @divTrunc(std.Io.Clock.awake.now(self.io).toNanoseconds() - self.startNs, std.time.ns_per_us);
    }
};

pub const VulkanError = error{
    ExtensioNotPresent,
    IncompatibleDriver,
    InitializationFailed,
    LayerNotPresent,
    OutOfDeviceMemory,
    OutOfHostMemory,
    ValidationFailed,
    FeatureNotPresent,
    DeviceLost,
    TooManyObjects,
    NativeWindowInUse,
    SurfaceLost,
    CompressionExhausted,
    InvalidOpaqueCaptureAddress,
    InvalidShaderNv,
    InvalidVideoStdParameters,
    FullScreenExclusiveModeLost,
    OutOfDate,
    PresentTimingQueueFullExt,
    InvalidExternalHandle,
    MemoryMapFailed,
    FragmentationExt,
    // Not exactly errors, but they aren't the best scenario, so we can consider them errors
    Suboptimal,
    NotReady,
    Timeout,
    Unknown,
};

const validationFailedResult: c.VkResult = if (@hasDecl(c, "VK_ERROR_VALIDATION_FAILED_EXT"))
    c.VK_ERROR_VALIDATION_FAILED_EXT
else if (@hasDecl(c, "VK_ERROR_VALIDATION_FAILED"))
    c.VK_ERROR_VALIDATION_FAILED
else
    @enumFromInt(-1000011001);

pub fn ensureNoError(result: c.VkResult) !void {
    switch (result) {
        c.VK_ERROR_EXTENSION_NOT_PRESENT => return error.ExtensioNotPresent,
        c.VK_ERROR_INCOMPATIBLE_DRIVER => return error.IncompatibleDriver,
        c.VK_ERROR_INITIALIZATION_FAILED => return error.InitializationFailed,
        c.VK_ERROR_LAYER_NOT_PRESENT => return error.LayerNotPresent,
        c.VK_ERROR_OUT_OF_DEVICE_MEMORY => return error.OutOfDeviceMemory,
        c.VK_ERROR_OUT_OF_HOST_MEMORY => return error.OutOfHostMemory,
        validationFailedResult => return error.ValidationFailed,
        c.VK_ERROR_FEATURE_NOT_PRESENT => return error.FeatureNotPresent,
        c.VK_ERROR_DEVICE_LOST => return error.DeviceLost,
        c.VK_ERROR_TOO_MANY_OBJECTS => return error.TooManyObjects,
        c.VK_ERROR_NATIVE_WINDOW_IN_USE_KHR => return error.NativeWindowInUse,
        c.VK_ERROR_SURFACE_LOST_KHR => return error.SurfaceLost,
        c.VK_ERROR_COMPRESSION_EXHAUSTED_EXT => return error.CompressionExhausted,
        c.VK_ERROR_INVALID_OPAQUE_CAPTURE_ADDRESS_KHR => return error.InvalidOpaqueCaptureAddress,
        c.VK_ERROR_INVALID_SHADER_NV => return error.InvalidShaderNv,
        c.VK_ERROR_INVALID_VIDEO_STD_PARAMETERS_KHR => return error.InvalidVideoStdParameters,
        c.VK_ERROR_FULL_SCREEN_EXCLUSIVE_MODE_LOST_EXT => return error.FullScreenExclusiveModeLost,
        c.VK_ERROR_OUT_OF_DATE_KHR => return error.OutOfDate,
        c.VK_ERROR_INVALID_EXTERNAL_HANDLE => return error.InvalidExternalHandle,
        c.VK_ERROR_MEMORY_MAP_FAILED => return error.MemoryMapFailed,
        c.VK_ERROR_FRAGMENTATION_EXT => return error.FragmentationExt,
        c.VK_ERROR_UNKNOWN => return error.Unknown,
        c.VK_SUBOPTIMAL_KHR => return error.Suboptimal,
        c.VK_NOT_READY => return error.NotReady,
        c.VK_TIMEOUT => return error.Timeout,
        else => {
            if (builtin.os.tag == .linux) {
                switch (result) {
                    c.VK_ERROR_INCOMPATIBLE_DISPLAY_KHR => return error.IncompatibleDriver,
                    else => {},
                }
            }
        },
    }

    if (result != c.VK_SUCCESS) {
        std.log.err("failed with an unexpected error {}", .{result});
        unreachable;
    }
}

pub fn CreateDebugUtilsMessengerEXT(
    instance: c.VkInstance,
    pCreateInfo: [*c]const c.VkDebugUtilsMessengerCreateInfoEXT,
    pAllocator: [*c]const c.VkAllocationCallbacks,
    pDebugMessenger: [*c]c.VkDebugUtilsMessengerEXT,
) c.VkResult {
    const func: c.PFN_vkCreateDebugUtilsMessengerEXT = @ptrCast(@alignCast(c.vkGetInstanceProcAddr(
        instance,
        "vkCreateDebugUtilsMessengerEXT",
    )));
    if (func != null) {
        return func.?(instance, pCreateInfo, pAllocator, pDebugMessenger);
    } else {
        return c.VK_ERROR_EXTENSION_NOT_PRESENT;
    }
}

pub fn DestroyDebugUtilsMessengerEXT(
    instance: c.VkInstance,
    debugMessenger: c.VkDebugUtilsMessengerEXT,
    pAllocator: [*c]const c.VkAllocationCallbacks,
) void {
    const func: c.PFN_vkDestroyDebugUtilsMessengerEXT = @ptrCast(@alignCast(c.vkGetInstanceProcAddr(instance, "vkDestroyDebugUtilsMessengerEXT")));
    if (func != null) {
        func.?(instance, debugMessenger, pAllocator);
    }
}

const DeviceInformation = struct {
    physicalDevice: c.VkPhysicalDevice,
    queueFamilies: []c.VkQueueFamilyProperties,
    deviceProperties: c.VkPhysicalDeviceProperties,
    availableDeviceExtensions: []c.VkExtensionProperties,
};

allocator: std.mem.Allocator,
application_name: [:0]const u8,

vulkanInstance: c.VkInstance,
vulkanDebugMessenger: c.VkDebugUtilsMessengerEXT,

devices: []DeviceInformation,

pub fn init(allocator: std.mem.Allocator, application_name: [:0]const u8) !Graphics {
    const instanceCreateFlags: c.VkInstanceCreateFlags = switch (builtin.os.tag) {
        // MoltenVK needs the portability enumeration extension + flag.
        .macos => c.VK_INSTANCE_CREATE_ENUMERATE_PORTABILITY_BIT_KHR,
        else => 0,
    };

    const requestedInstanceExtensions: []const [*c]const u8 = &(.{
        c.VK_KHR_SURFACE_EXTENSION_NAME,
    } ++ (if (builtin.mode == .Debug) .{c.VK_EXT_DEBUG_UTILS_EXTENSION_NAME} else .{}) ++ switch (builtin.os.tag) {
        .linux => .{"VK_KHR_wayland_surface"},
        .macos => .{
            c.VK_KHR_PORTABILITY_ENUMERATION_EXTENSION_NAME,
            "VK_EXT_metal_surface",
        },
        .windows => .{"VK_KHR_win32_surface"},
        else => .{},
    });

    var count: u32 = 0;
    try ensureNoError(c.vkEnumerateInstanceExtensionProperties(null, &count, null));
    const availableExtensions = try allocator.alloc(c.VkExtensionProperties, @intCast(count));
    defer allocator.free(availableExtensions);
    try ensureNoError(c.vkEnumerateInstanceExtensionProperties(null, &count, availableExtensions.ptr));
    if (builtin.mode == .Debug) {
        std.log.debug("Requested Vulkan instance extensions ({d}):", .{requestedInstanceExtensions.len});
        for (requestedInstanceExtensions) |ext| {
            std.log.debug("  {s}", .{ext});
        }
        std.log.debug("Available Vulkan instance extensions ({d}):", .{availableExtensions.len});
        for (availableExtensions) |ext| {
            const name = std.mem.sliceTo(ext.extensionName[0..], 0);
            std.log.debug("  {s}", .{name});
        }
    }
    for (requestedInstanceExtensions) |requiredExtension| {
        const requiredExtensionSlice = std.mem.span(requiredExtension);
        var found = false;
        for (availableExtensions) |availableExtension| {
            const availableExtensionSlice: []const u8 = std.mem.sliceTo(availableExtension.extensionName[0..], 0);
            if (std.mem.eql(u8, availableExtensionSlice, requiredExtensionSlice)) {
                found = true;
                break;
            }
        }
        if (!found) {
            std.log.err("Missing required Vulkan instance extension: {s}", .{requiredExtensionSlice});
            return error.MissingRequiredExtension;
        }
    }

    var instanceLayers: []const [*c]const u8 = if (builtin.mode == .Debug)
        &.{"VK_LAYER_KHRONOS_validation"}
    else
        &.{};

    var availableLayerCount: u32 = 0;
    try ensureNoError(c.vkEnumerateInstanceLayerProperties(&availableLayerCount, null));
    const availableLayers = try allocator.alloc(c.VkLayerProperties, @intCast(availableLayerCount));
    defer allocator.free(availableLayers);
    try ensureNoError(c.vkEnumerateInstanceLayerProperties(&availableLayerCount, availableLayers.ptr));

    const validationLayerName = "VK_LAYER_KHRONOS_validation";
    var hasValidationLayer = false;
    for (availableLayers) |layer| {
        const name = std.mem.sliceTo(layer.layerName[0..], 0);
        if (std.mem.eql(u8, name, validationLayerName)) {
            hasValidationLayer = true;
            break;
        }
    }

    if (!hasValidationLayer) {
        instanceLayers = &.{};
        std.log.warn("Vulkan validation layer not found; continuing without it", .{});
    }

    var vulkanInstance: c.VkInstance = undefined;
    try ensureNoError(c.vkCreateInstance(
        &c.VkInstanceCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
            .flags = instanceCreateFlags,
            .pNext = null,
            .pApplicationInfo = &c.VkApplicationInfo{
                .sType = c.VK_STRUCTURE_TYPE_APPLICATION_INFO,
                .pNext = null,
                .pApplicationName = application_name.ptr,
                .applicationVersion = c.VK_MAKE_VERSION(1, 0, 0),
                .pEngineName = "forbear",
                .engineVersion = c.VK_MAKE_VERSION(1, 0, 0),
                .apiVersion = c.VK_API_VERSION_1_1,
            },
            .enabledLayerCount = @intCast(instanceLayers.len),
            .ppEnabledLayerNames = instanceLayers.ptr,
            .enabledExtensionCount = @intCast(requestedInstanceExtensions.len),
            .ppEnabledExtensionNames = requestedInstanceExtensions.ptr,
        },
        null,
        &vulkanInstance,
    ));
    std.debug.assert(vulkanInstance != null);
    errdefer c.vkDestroyInstance(vulkanInstance, null);

    var vulkanDebugMessenger: c.VkDebugUtilsMessengerEXT = null;
    if (builtin.mode == .Debug) {
        const debugMessengerResult = CreateDebugUtilsMessengerEXT(
            vulkanInstance,
            &c.VkDebugUtilsMessengerCreateInfoEXT{
                .sType = c.VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT,
                .pNext = null,
                .flags = 0,
                .messageSeverity = c.VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT | c.VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT | c.VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT,
                .messageType = c.VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT | c.VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT | c.VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT,
                .pfnUserCallback = &(struct {
                    fn debugCallback(
                        messageSeverity: c.VkDebugUtilsMessageSeverityFlagBitsEXT,
                        messageType: c.VkDebugUtilsMessageTypeFlagsEXT,
                        callbackData: [*c]const c.VkDebugUtilsMessengerCallbackDataEXT,
                        userData: ?*anyopaque,
                    ) callconv(.c) c.VkBool32 {
                        _ = messageType;
                        _ = userData;

                        const message: []const u8 = std.mem.span(callbackData.*.pMessage);
                        if (messageSeverity == c.VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT) {
                            std.log.debug("{s} (vulkan debug messenger)", .{message});
                        } else if (messageSeverity == c.VK_DEBUG_UTILS_MESSAGE_SEVERITY_INFO_BIT_EXT) {
                            std.log.info("{s} (vulkan debug messenger)", .{message});
                        } else if (messageSeverity == c.VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT) {
                            std.log.warn("{s} (vulkan debug messenger)", .{message});
                        } else if (messageSeverity == c.VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT) {
                            std.log.err("{s} (vulkan debug messenger)", .{message});
                        }

                        return c.VK_FALSE;
                    }
                }).debugCallback,
                .pUserData = null,
            },
            null,
            &vulkanDebugMessenger,
        );
        errdefer DestroyDebugUtilsMessengerEXT(vulkanInstance, vulkanDebugMessenger, null);

        if (debugMessengerResult == c.VK_ERROR_EXTENSION_NOT_PRESENT) {
            std.log.warn("VK_EXT_debug_utils not present; continuing without debug messenger", .{});
            vulkanDebugMessenger = null;
        } else {
            try ensureNoError(debugMessengerResult);
            std.debug.assert(vulkanDebugMessenger != null);
        }
    }
    errdefer if (vulkanDebugMessenger) |messenger| {
        DestroyDebugUtilsMessengerEXT(vulkanInstance, messenger, null);
    };

    var physicalDevicesLen: u32 = undefined;
    try ensureNoError(c.vkEnumeratePhysicalDevices(vulkanInstance, &physicalDevicesLen, null));
    const physicalDevices = try allocator.alloc(c.VkPhysicalDevice, @intCast(physicalDevicesLen));
    defer allocator.free(physicalDevices);
    try ensureNoError(c.vkEnumeratePhysicalDevices(
        vulkanInstance,
        &physicalDevicesLen,
        physicalDevices.ptr,
    ));

    const devices = try allocator.alloc(DeviceInformation, physicalDevices.len);
    errdefer allocator.free(devices);
    for (physicalDevices, 0..) |physicalDevice, i| {
        var deviceProperties: c.VkPhysicalDeviceProperties = undefined;
        c.vkGetPhysicalDeviceProperties(physicalDevice, &deviceProperties);

        var availableDeviceExtensionsLen: u32 = 0;
        try ensureNoError(c.vkEnumerateDeviceExtensionProperties(
            physicalDevice,
            null,
            &availableDeviceExtensionsLen,
            null,
        ));
        const availableDeviceExtensions = try allocator.alloc(c.VkExtensionProperties, @intCast(availableDeviceExtensionsLen));
        errdefer allocator.free(availableDeviceExtensions);
        try ensureNoError(c.vkEnumerateDeviceExtensionProperties(physicalDevice, null, &availableDeviceExtensionsLen, availableDeviceExtensions.ptr));

        var queueFamiliesLen: u32 = undefined;
        c.vkGetPhysicalDeviceQueueFamilyProperties(
            physicalDevice,
            &queueFamiliesLen,
            null,
        );
        const queueFamilies = try allocator.alloc(
            c.VkQueueFamilyProperties,
            @intCast(queueFamiliesLen),
        );
        c.vkGetPhysicalDeviceQueueFamilyProperties(
            physicalDevice,
            &queueFamiliesLen,
            queueFamilies.ptr,
        );
        errdefer allocator.free(queueFamilies);

        devices[i] = .{
            .physicalDevice = physicalDevice,
            .queueFamilies = queueFamilies,
            .deviceProperties = deviceProperties,
            .availableDeviceExtensions = availableDeviceExtensions,
        };
    }

    return Graphics{
        .allocator = allocator,
        .application_name = application_name,

        .vulkanInstance = vulkanInstance,
        .vulkanDebugMessenger = vulkanDebugMessenger,

        .devices = devices,
    };
}

pub fn deinit(self: *Graphics) void {
    for (self.devices) |device| {
        self.allocator.free(device.queueFamilies);
        self.allocator.free(device.availableDeviceExtensions);
    }
    self.allocator.free(self.devices);

    if (self.vulkanDebugMessenger) |messenger| {
        DestroyDebugUtilsMessengerEXT(self.vulkanInstance, messenger, null);
    }
    c.vkDestroyInstance(self.vulkanInstance, null);
}

const QueueIndices = struct {
    graphics: u32,
    presentation: u32,
};

const Graphics = @This();

// Win32 code required for graphics
const HANDLE = *anyopaque;
const HWND = ?HANDLE;
const HINSTANCE = ?HANDLE;
const SIZE_T = usize;
const BOOL = c_int;
const VkWin32SurfaceCreateFlagsKHR = c.VkFlags;
const VkWin32SurfaceCreateInfoKHR = extern struct {
    sType: c.VkStructureType,
    pNext: ?*const anyopaque,
    flags: VkWin32SurfaceCreateFlagsKHR,
    hinstance: HINSTANCE,
    hwnd: HWND,
};
// The Windows Vulkan SDK ships the import library as vulkan-1.lib (not vulkan.lib),
// so the extern library name must match what build.zig links (`vulkan-1`).
extern "vulkan-1" fn vkCreateWin32SurfaceKHR(
    instance: c.VkInstance,
    pCreateInfo: ?*const VkWin32SurfaceCreateInfoKHR,
    pAllocator: ?*c.VkAllocationCallbacks,
    pSurface: ?*c.VkSurfaceKHR,
) c.VkResult;
extern "user32" fn SetProcessWorkingSetSize(hProcess: HANDLE, dwMinimumWorkingSetSize: SIZE_T, dwMaximumWorkingSetSize: SIZE_T) callconv(.c) BOOL;
extern "user32" fn GetCurrentProcess() callconv(.c) HANDLE;

// Single-subpass, single-color-attachment render pass that draws straight into the swapchain image.
// This is the render-pass form of what the renderer used to do with dynamic rendering; it exists so
// we don't depend on VK_KHR_dynamic_rendering, which old/legacy drivers may not expose. The attachment
// clears on load, stores on completion, and the render pass transitions UNDEFINED -> PRESENT_SRC for us
// (replacing the manual image barriers the dynamic-rendering path needed).
fn createRenderPass(logicalDevice: c.VkDevice, format: c.VkFormat) !c.VkRenderPass {
    const colorAttachment = c.VkAttachmentDescription{
        .flags = 0,
        .format = format,
        .samples = c.VK_SAMPLE_COUNT_1_BIT,
        .loadOp = c.VK_ATTACHMENT_LOAD_OP_CLEAR,
        .storeOp = c.VK_ATTACHMENT_STORE_OP_STORE,
        .stencilLoadOp = c.VK_ATTACHMENT_LOAD_OP_DONT_CARE,
        .stencilStoreOp = c.VK_ATTACHMENT_STORE_OP_DONT_CARE,
        .initialLayout = c.VK_IMAGE_LAYOUT_UNDEFINED,
        .finalLayout = c.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR,
    };
    const colorAttachmentRef = c.VkAttachmentReference{
        .attachment = 0,
        .layout = c.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
    };
    // Wait for the acquired image (signalled at COLOR_ATTACHMENT_OUTPUT via the imageAvailable
    // semaphore, see drawFrame's waitStages) before the subpass writes color.
    const dependency = c.VkSubpassDependency{
        .srcSubpass = c.VK_SUBPASS_EXTERNAL,
        .dstSubpass = 0,
        .srcStageMask = c.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
        .dstStageMask = c.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
        .srcAccessMask = 0,
        .dstAccessMask = c.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT,
        .dependencyFlags = 0,
    };
    var renderPass: c.VkRenderPass = undefined;
    try ensureNoError(c.vkCreateRenderPass(logicalDevice, &c.VkRenderPassCreateInfo{
        .sType = c.VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO,
        .pNext = null,
        .flags = 0,
        .attachmentCount = 1,
        .pAttachments = &colorAttachment,
        .subpassCount = 1,
        .pSubpasses = &c.VkSubpassDescription{
            .flags = 0,
            .pipelineBindPoint = c.VK_PIPELINE_BIND_POINT_GRAPHICS,
            .inputAttachmentCount = 0,
            .pInputAttachments = null,
            .colorAttachmentCount = 1,
            .pColorAttachments = &colorAttachmentRef,
            .pResolveAttachments = null,
            .pDepthStencilAttachment = null,
            .preserveAttachmentCount = 0,
            .pPreserveAttachments = null,
        },
        .dependencyCount = 1,
        .pDependencies = &dependency,
    }, null, &renderPass));
    return renderPass;
}

pub fn initRenderer(
    self: *Graphics,
    window: *Window,
) !Renderer {
    var vulkanSurface: c.VkSurfaceKHR = undefined;
    switch (builtin.os.tag) {
        .linux => {
            try ensureNoError(c.vkCreateWaylandSurfaceKHR(
                self.vulkanInstance,
                &c.VkWaylandSurfaceCreateInfoKHR{
                    .sType = c.VK_STRUCTURE_TYPE_WAYLAND_SURFACE_CREATE_INFO_KHR,
                    .pNext = null,
                    .flags = 0,
                    .display = window.wlDisplay,
                    .surface = window.wlSurface,
                },
                null,
                &vulkanSurface,
            ));
        },
        .macos => {
            const caMetalLayer = window.nativeMetalLayer();
            if (caMetalLayer == null) return error.NullNativeView;
            try ensureNoError(c.vkCreateMetalSurfaceEXT(
                self.vulkanInstance,
                &c.VkMetalSurfaceCreateInfoEXT{
                    .sType = c.VK_STRUCTURE_TYPE_METAL_SURFACE_CREATE_INFO_EXT,
                    .pNext = null,
                    .flags = 0,
                    .pLayer = caMetalLayer,
                },
                null,
                &vulkanSurface,
            ));
        },
        .windows => {
            try ensureNoError(vkCreateWin32SurfaceKHR(
                self.vulkanInstance,
                &VkWin32SurfaceCreateInfoKHR{
                    .sType = c.VK_STRUCTURE_TYPE_WIN32_SURFACE_CREATE_INFO_KHR,
                    .pNext = null,
                    .flags = 0,
                    .hinstance = window.hInstance,
                    .hwnd = window.handle,
                },
                null,
                &vulkanSurface,
            ));
        },
        else => @compileError("Unsupported platform"),
    }
    std.debug.assert(vulkanSurface != null);
    errdefer c.vkDestroySurfaceKHR(self.vulkanInstance, vulkanSurface, null);

    return try Renderer.init(vulkanSurface, window, self);
}

fn findMemoryType(
    typeFilter: u32,
    properties: c.VkMemoryPropertyFlags,
    physicalDevice: c.VkPhysicalDevice,
) !u32 {
    var memoryProperties: c.VkPhysicalDeviceMemoryProperties = undefined;
    c.vkGetPhysicalDeviceMemoryProperties(physicalDevice, &memoryProperties);

    for (0..memoryProperties.memoryTypeCount) |i| {
        if ((typeFilter & (@as(u32, 1) << @intCast(i))) != 0 and
            (memoryProperties.memoryTypes[i].propertyFlags & properties) == properties)
        {
            return @intCast(i);
        }
    }

    return error.MemoryTypeNotFound;
}

pub const Image = struct {
    pub const Format = enum {
        png,
    };

    image: c.VkImage,
    imageExtent: c.VkExtent3D,
    imageView: c.VkImageView,
    memory: c.VkDeviceMemory,
    mipLevels: u32,

    /// The original received contents in `init`, kept around for when the
    /// image is actually decompressed on use
    contents: []const u8,
    loaded: bool,

    width: c_int,
    height: c_int,

    renderer: *const Renderer,

    const offsets = [_][2]isize{
        .{ -1, -1 }, .{ 0, -1 }, .{ 1, -1 },
        .{ -1, 0 },  .{ 1, 0 },  .{ -1, 1 },
        .{ 0, 1 },   .{ 1, 1 },
    };

    fn dilatePixel(pixels: []u8, x: usize, y: usize, width: usize, height: usize) void {
        const index = (y * width + x) * 4;

        var r: u32 = 0;
        var g: u32 = 0;
        var b: u32 = 0;
        var count: u32 = 0;
        for (offsets) |off| {
            const neighbourX: isize = @as(isize, @intCast(x)) + off[0];
            const neighbourY: isize = @as(isize, @intCast(y)) + off[1];
            if (neighbourX < 0 or neighbourY < 0 or neighbourX >= width or neighbourY >= height) {
                continue;
            }
            const neighbourIndex: usize = (@as(usize, @intCast(neighbourY)) * width + @as(usize, @intCast(neighbourX))) * 4;
            if (pixels[neighbourIndex + 3] == 0 and pixels[neighbourIndex] == 0 and pixels[neighbourIndex + 1] == 0 and pixels[neighbourIndex + 2] == 0) {
                continue;
            }
            r += pixels[neighbourIndex];
            g += pixels[neighbourIndex + 1];
            b += pixels[neighbourIndex + 2];
            count += 1;
        }

        if (count > 0) {
            pixels[index] = @intCast(r / count);
            pixels[index + 1] = @intCast(g / count);
            pixels[index + 2] = @intCast(b / count);
        }
    }

    pub fn load(self: *@This()) !void {
        self.loaded = true;
        const imageSize: usize = @intCast(self.width * self.height * 4);

        const stagingBuffer = try Buffer.init(
            self.renderer.logicalDevice,
            self.renderer.physicalDevice,
            imageSize,
            c.VK_BUFFER_USAGE_TRANSFER_SRC_BIT,
            c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
        );
        defer stagingBuffer.deinit(self.renderer.logicalDevice);

        var width: c_int = undefined;
        var height: c_int = undefined;
        var channels: c_int = undefined;
        // stb_image doesn't allow to not pass in the width, hegith and channel pointers
        const io = root.getForbear().io;
        const timerStart = std.Io.Clock.Timestamp.now(io, .awake);
        const pixelsPtr = c.stbi_load_from_memory(self.contents.ptr, @intCast(self.contents.len), &width, &height, &channels, 4);
        if (pixelsPtr == null) return error.ImageLoadFailed;
        const decodeTime: u64 = @intCast(@max(0, timerStart.untilNow(io).raw.toNanoseconds()));
        std.debug.assert(self.width == width);
        std.debug.assert(self.height == height);

        defer c.stbi_image_free(pixelsPtr);

        // Edge color dilation: extend visible colors into transparent pixels.
        //
        // Problem: Transparent pixels in PNGs typically have RGB = (0,0,0) (black). When the GPU
        // uses linear filtering to sample between a visible pixel and an adjacent transparent pixel,
        // it interpolates the RGB values, causing dark fringes at content edges.
        //
        // Solution: For each transparent pixel, set its RGB to the average of neighboring visible
        // pixels. The pixel stays transparent (alpha = 0), but now linear filtering produces correct
        // colors instead of bleeding in black. Multiple passes propagate colors further into large
        // transparent regions, which is needed for mipmap generation where pixels are averaged.
        const pixels = pixelsPtr[0..imageSize];
        const w: usize = @intCast(width);
        const h: usize = @intCast(height);
        const dilationStart = std.Io.Clock.Timestamp.now(io, .awake);
        // top edge pixels and bottom edge pxiels
        for (0..w) |col| {
            const topX = col;
            const topY = 0;
            const bottomX = col;
            const bottomY = h - 1;

            dilatePixel(pixels, topX, topY, w, h);
            dilatePixel(pixels, bottomX, bottomY, w, h);
        }
        // left edge pixels and right edge pixels
        for (1..h) |row| {
            const leftX: usize = 0;
            const leftY = row;
            const rightX = w - 1;
            const rightY = row;

            dilatePixel(pixels, leftX, leftY, w, h);
            dilatePixel(pixels, rightX, rightY, w, h);
        }
        const dilationTime: u64 = @intCast(@max(0, dilationStart.untilNow(io).raw.toNanoseconds()));

        std.log.info("Image {d}x{d}: decode={d:.2}ms, dilation={d:.2}ms", .{
            width,
            height,
            @as(f64, @floatFromInt(decodeTime)) / std.time.ns_per_ms,
            @as(f64, @floatFromInt(dilationTime)) / std.time.ns_per_ms,
        });

        try stagingBuffer.set(self.renderer.logicalDevice, pixels);

        var commandBuffer: c.VkCommandBuffer = undefined;
        try ensureNoError(c.vkAllocateCommandBuffers(self.renderer.logicalDevice, &c.VkCommandBufferAllocateInfo{
            .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
            .level = c.VK_COMMAND_BUFFER_LEVEL_PRIMARY,
            .commandPool = self.renderer.commandPool,
            .commandBufferCount = 1,
            .pNext = null,
        }, &commandBuffer));

        try ensureNoError(c.vkBeginCommandBuffer(commandBuffer, &c.VkCommandBufferBeginInfo{
            .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
            .flags = c.VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT,
            .pNext = null,
            .pInheritanceInfo = null,
        }));

        // Transition mip level 0 to transfer dst and copy staging buffer
        c.vkCmdPipelineBarrier(commandBuffer, c.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, c.VK_PIPELINE_STAGE_TRANSFER_BIT, 0, 0, null, 0, null, 1, &c.VkImageMemoryBarrier{
            .sType = c.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
            .oldLayout = c.VK_IMAGE_LAYOUT_UNDEFINED,
            .newLayout = c.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
            .srcQueueFamilyIndex = c.VK_QUEUE_FAMILY_IGNORED,
            .dstQueueFamilyIndex = c.VK_QUEUE_FAMILY_IGNORED,
            .image = self.image,
            .subresourceRange = .{
                .aspectMask = c.VK_IMAGE_ASPECT_COLOR_BIT,
                .baseMipLevel = 0,
                .levelCount = self.mipLevels,
                .baseArrayLayer = 0,
                .layerCount = 1,
            },
            .srcAccessMask = 0,
            .dstAccessMask = c.VK_ACCESS_TRANSFER_WRITE_BIT,
            .pNext = null,
        });

        c.vkCmdCopyBufferToImage(commandBuffer, stagingBuffer.handle, self.image, c.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, 1, &c.VkBufferImageCopy{
            .bufferOffset = 0,
            .bufferRowLength = 0,
            .bufferImageHeight = 0,
            .imageSubresource = .{
                .aspectMask = c.VK_IMAGE_ASPECT_COLOR_BIT,
                .mipLevel = 0,
                .baseArrayLayer = 0,
                .layerCount = 1,
            },
            .imageOffset = .{ .x = 0, .y = 0, .z = 0 },
            .imageExtent = self.imageExtent,
        });

        // Generate mipmaps via blit chain
        var mipWidth: i32 = self.width;
        var mipHeight: i32 = self.height;

        for (1..self.mipLevels) |i| {
            // Transition previous level to transfer src
            c.vkCmdPipelineBarrier(commandBuffer, c.VK_PIPELINE_STAGE_TRANSFER_BIT, c.VK_PIPELINE_STAGE_TRANSFER_BIT, 0, 0, null, 0, null, 1, &c.VkImageMemoryBarrier{
                .sType = c.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
                .oldLayout = c.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
                .newLayout = c.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
                .srcQueueFamilyIndex = c.VK_QUEUE_FAMILY_IGNORED,
                .dstQueueFamilyIndex = c.VK_QUEUE_FAMILY_IGNORED,
                .image = self.image,
                .subresourceRange = .{
                    .aspectMask = c.VK_IMAGE_ASPECT_COLOR_BIT,
                    .baseMipLevel = @intCast(i - 1),
                    .levelCount = 1,
                    .baseArrayLayer = 0,
                    .layerCount = 1,
                },
                .srcAccessMask = c.VK_ACCESS_TRANSFER_WRITE_BIT,
                .dstAccessMask = c.VK_ACCESS_TRANSFER_READ_BIT,
                .pNext = null,
            });

            const nextMipWidth = if (mipWidth > 1) @divTrunc(mipWidth, 2) else 1;
            const nextMipHeight = if (mipHeight > 1) @divTrunc(mipHeight, 2) else 1;

            c.vkCmdBlitImage(
                commandBuffer,
                self.image,
                c.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
                self.image,
                c.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
                1,
                &c.VkImageBlit{
                    .srcOffsets = .{
                        .{ .x = 0, .y = 0, .z = 0 },
                        .{ .x = mipWidth, .y = mipHeight, .z = 1 },
                    },
                    .srcSubresource = .{
                        .aspectMask = c.VK_IMAGE_ASPECT_COLOR_BIT,
                        .mipLevel = @intCast(i - 1),
                        .baseArrayLayer = 0,
                        .layerCount = 1,
                    },
                    .dstOffsets = .{
                        .{ .x = 0, .y = 0, .z = 0 },
                        .{ .x = nextMipWidth, .y = nextMipHeight, .z = 1 },
                    },
                    .dstSubresource = .{
                        .aspectMask = c.VK_IMAGE_ASPECT_COLOR_BIT,
                        .mipLevel = @intCast(i),
                        .baseArrayLayer = 0,
                        .layerCount = 1,
                    },
                },
                c.VK_FILTER_LINEAR,
            );

            // Transition this level to shader read
            c.vkCmdPipelineBarrier(commandBuffer, c.VK_PIPELINE_STAGE_TRANSFER_BIT, c.VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT, 0, 0, null, 0, null, 1, &c.VkImageMemoryBarrier{
                .sType = c.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
                .oldLayout = c.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
                .newLayout = c.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
                .srcQueueFamilyIndex = c.VK_QUEUE_FAMILY_IGNORED,
                .dstQueueFamilyIndex = c.VK_QUEUE_FAMILY_IGNORED,
                .image = self.image,
                .subresourceRange = .{
                    .aspectMask = c.VK_IMAGE_ASPECT_COLOR_BIT,
                    .baseMipLevel = @intCast(i - 1),
                    .levelCount = 1,
                    .baseArrayLayer = 0,
                    .layerCount = 1,
                },
                .srcAccessMask = c.VK_ACCESS_TRANSFER_READ_BIT,
                .dstAccessMask = c.VK_ACCESS_SHADER_READ_BIT,
                .pNext = null,
            });

            mipWidth = nextMipWidth;
            mipHeight = nextMipHeight;
        }

        // Transition the last mip level to shader read
        c.vkCmdPipelineBarrier(commandBuffer, c.VK_PIPELINE_STAGE_TRANSFER_BIT, c.VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT, 0, 0, null, 0, null, 1, &c.VkImageMemoryBarrier{
            .sType = c.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
            .oldLayout = c.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
            .newLayout = c.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
            .srcQueueFamilyIndex = c.VK_QUEUE_FAMILY_IGNORED,
            .dstQueueFamilyIndex = c.VK_QUEUE_FAMILY_IGNORED,
            .image = self.image,
            .subresourceRange = .{
                .aspectMask = c.VK_IMAGE_ASPECT_COLOR_BIT,
                .baseMipLevel = self.mipLevels - 1,
                .levelCount = 1,
                .baseArrayLayer = 0,
                .layerCount = 1,
            },
            .srcAccessMask = c.VK_ACCESS_TRANSFER_WRITE_BIT,
            .dstAccessMask = c.VK_ACCESS_SHADER_READ_BIT,
            .pNext = null,
        });

        try ensureNoError(c.vkEndCommandBuffer(commandBuffer));

        try ensureNoError(c.vkQueueSubmit(self.renderer.graphicsQueue, 1, &c.VkSubmitInfo{
            .sType = c.VK_STRUCTURE_TYPE_SUBMIT_INFO,
            .commandBufferCount = 1,
            .pCommandBuffers = &commandBuffer,
            .pNext = null,
        }, null));
        try ensureNoError(c.vkQueueWaitIdle(self.renderer.graphicsQueue));
        c.vkFreeCommandBuffers(self.renderer.logicalDevice, self.renderer.commandPool, 1, &commandBuffer);
    }

    pub fn init(contents: []const u8, format: Format, renderer: *const Renderer) !@This() {
        switch (format) {
            .png => {
                var width: c_int = undefined;
                var height: c_int = undefined;
                var channels: c_int = undefined;
                if (c.stbi_info_from_memory(contents.ptr, @intCast(contents.len), &width, &height, &channels) == 0) {
                    return error.ImageInfoLoadFailed;
                }

                const extent = c.VkExtent3D{
                    .width = @intCast(width),
                    .height = @intCast(height),
                    .depth = 1,
                };

                const mipLevels: u32 = std.math.log2(@as(u32, @intCast(@max(width, height)))) + 1;

                var image: c.VkImage = undefined;
                try ensureNoError(c.vkCreateImage(renderer.logicalDevice, &c.VkImageCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO,
                    .imageType = c.VK_IMAGE_TYPE_2D,
                    .extent = extent,
                    .mipLevels = mipLevels,
                    .arrayLayers = 1,
                    .format = c.VK_FORMAT_R8G8B8A8_UNORM,
                    .tiling = c.VK_IMAGE_TILING_OPTIMAL,
                    .initialLayout = c.VK_IMAGE_LAYOUT_UNDEFINED,
                    .usage = c.VK_IMAGE_USAGE_SAMPLED_BIT | c.VK_IMAGE_USAGE_TRANSFER_DST_BIT | c.VK_IMAGE_USAGE_TRANSFER_SRC_BIT,
                    .sharingMode = c.VK_SHARING_MODE_EXCLUSIVE,
                    .samples = c.VK_SAMPLE_COUNT_1_BIT,
                    .flags = 0,
                    .pNext = null,
                }, null, &image));
                errdefer c.vkDestroyImage(renderer.logicalDevice, image, null);

                var memRequirements: c.VkMemoryRequirements = undefined;
                c.vkGetImageMemoryRequirements(renderer.logicalDevice, image, &memRequirements);

                var memory: c.VkDeviceMemory = undefined;
                try ensureNoError(c.vkAllocateMemory(renderer.logicalDevice, &c.VkMemoryAllocateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
                    .pNext = null,
                    .allocationSize = memRequirements.size,
                    .memoryTypeIndex = try findMemoryType(
                        memRequirements.memoryTypeBits,
                        c.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT,
                        renderer.physicalDevice,
                    ),
                }, null, &memory));
                errdefer c.vkFreeMemory(renderer.logicalDevice, memory, null);

                try ensureNoError(c.vkBindImageMemory(renderer.logicalDevice, image, memory, 0));

                var imageView: c.VkImageView = undefined;
                try ensureNoError(c.vkCreateImageView(renderer.logicalDevice, &c.VkImageViewCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO,
                    .image = image,
                    .pNext = null,
                    .flags = 0,
                    .viewType = c.VK_IMAGE_VIEW_TYPE_2D,
                    .format = c.VK_FORMAT_R8G8B8A8_UNORM,
                    .components = c.VkComponentMapping{
                        .r = c.VK_COMPONENT_SWIZZLE_R,
                        .g = c.VK_COMPONENT_SWIZZLE_G,
                        .b = c.VK_COMPONENT_SWIZZLE_B,
                        .a = c.VK_COMPONENT_SWIZZLE_A,
                    },
                    .subresourceRange = c.VkImageSubresourceRange{
                        .aspectMask = c.VK_IMAGE_ASPECT_COLOR_BIT,
                        .baseMipLevel = 0,
                        .levelCount = mipLevels,
                        .baseArrayLayer = 0,
                        .layerCount = 1,
                    },
                }, null, &imageView));

                return @This(){
                    .image = image,
                    .imageExtent = extent,
                    .imageView = imageView,
                    .memory = memory,
                    .mipLevels = mipLevels,

                    .contents = contents,
                    .loaded = false,

                    .width = width,
                    .height = height,

                    .renderer = renderer,
                };
            },
        }
    }

    pub fn deinit(self: *const @This()) void {
        c.vkDestroyImageView(self.renderer.logicalDevice, self.imageView, null);
        c.vkDestroyImage(self.renderer.logicalDevice, self.image, null);
        c.vkFreeMemory(self.renderer.logicalDevice, self.memory, null);
    }
};

const FontTextureAtlas = struct {
    allocator: std.mem.Allocator,
    image: c.VkImage,
    imageView: c.VkImageView,
    memory: c.VkDeviceMemory,
    mapped: []u8,
    rowPitch: usize,
    capacityExtent: c.VkExtent3D,
    freeRectangles: std.ArrayList(FreeRectangle),

    const FreeRectangle = struct {
        u: usize,
        v: usize,
        width: usize,
        height: usize,
    };

    fn init(
        allocator: std.mem.Allocator,
        logicalDevice: c.VkDevice,
        physicalDevice: c.VkPhysicalDevice,
        commandPool: c.VkCommandPool,
        graphicsQueue: c.VkQueue,
    ) !@This() {
        const extent = c.VkExtent3D{
            .width = 1024,
            .height = 1024,
            .depth = 1,
        };

        var image: c.VkImage = undefined;
        try ensureNoError(c.vkCreateImage(logicalDevice, &c.VkImageCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO,
            .imageType = c.VK_IMAGE_TYPE_2D,
            .extent = extent,
            .mipLevels = 1,
            .arrayLayers = 1,
            // Use RGBA format for subpixel/LCD text rendering (RGB coverage + alpha)
            .format = c.VK_FORMAT_R8G8B8A8_UNORM,
            .tiling = c.VK_IMAGE_TILING_LINEAR,
            .initialLayout = c.VK_IMAGE_LAYOUT_UNDEFINED,
            .usage = c.VK_IMAGE_USAGE_SAMPLED_BIT | c.VK_IMAGE_USAGE_TRANSFER_DST_BIT,
            .sharingMode = c.VK_SHARING_MODE_EXCLUSIVE,
            .samples = c.VK_SAMPLE_COUNT_1_BIT,
            .flags = 0,
            .pNext = null,
        }, null, &image));
        errdefer c.vkDestroyImage(logicalDevice, image, null);

        var memRequirements: c.VkMemoryRequirements = undefined;
        c.vkGetImageMemoryRequirements(logicalDevice, image, &memRequirements);

        var memory: c.VkDeviceMemory = undefined;
        try ensureNoError(c.vkAllocateMemory(logicalDevice, &c.VkMemoryAllocateInfo{
            .sType = c.VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
            .pNext = null,
            .allocationSize = memRequirements.size,
            .memoryTypeIndex = try findMemoryType(
                memRequirements.memoryTypeBits,
                c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
                physicalDevice,
            ),
        }, null, &memory));

        try ensureNoError(c.vkBindImageMemory(logicalDevice, image, memory, 0));

        var subresourceLayout: c.VkSubresourceLayout = undefined;
        c.vkGetImageSubresourceLayout(logicalDevice, image, &c.VkImageSubresource{
            .aspectMask = c.VK_IMAGE_ASPECT_COLOR_BIT,
            .mipLevel = 0,
            .arrayLayer = 0,
        }, &subresourceLayout);

        var imageView: c.VkImageView = undefined;
        try ensureNoError(c.vkCreateImageView(
            logicalDevice,
            &c.VkImageViewCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO,
                .image = image,
                .pNext = null,
                .flags = 0,
                .viewType = c.VK_IMAGE_VIEW_TYPE_2D,
                .format = c.VK_FORMAT_R8G8B8A8_UNORM,
                .components = c.VkComponentMapping{
                    .r = c.VK_COMPONENT_SWIZZLE_R,
                    .g = c.VK_COMPONENT_SWIZZLE_G,
                    .b = c.VK_COMPONENT_SWIZZLE_B,
                    .a = c.VK_COMPONENT_SWIZZLE_A,
                },
                .subresourceRange = c.VkImageSubresourceRange{
                    .aspectMask = c.VK_IMAGE_ASPECT_COLOR_BIT,
                    .baseMipLevel = 0,
                    .levelCount = 1,
                    .baseArrayLayer = 0,
                    .layerCount = 1,
                },
            },
            null,
            &imageView,
        ));
        errdefer c.vkDestroyImageView(logicalDevice, imageView, null);

        {
            var commandBuffer: c.VkCommandBuffer = undefined;
            try ensureNoError(c.vkAllocateCommandBuffers(logicalDevice, &c.VkCommandBufferAllocateInfo{
                .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
                .level = c.VK_COMMAND_BUFFER_LEVEL_PRIMARY,
                .commandPool = commandPool,
                .commandBufferCount = 1,
                .pNext = null,
            }, &commandBuffer));

            try ensureNoError(c.vkBeginCommandBuffer(commandBuffer, &c.VkCommandBufferBeginInfo{
                .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
                .flags = c.VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT,
                .pNext = null,
                .pInheritanceInfo = null,
            }));

            const barrier = c.VkImageMemoryBarrier{
                .sType = c.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
                .oldLayout = c.VK_IMAGE_LAYOUT_UNDEFINED,
                .newLayout = c.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
                .srcQueueFamilyIndex = c.VK_QUEUE_FAMILY_IGNORED,
                .dstQueueFamilyIndex = c.VK_QUEUE_FAMILY_IGNORED,
                .image = image,
                .subresourceRange = .{
                    .aspectMask = c.VK_IMAGE_ASPECT_COLOR_BIT,
                    .baseMipLevel = 0,
                    .levelCount = 1,
                    .baseArrayLayer = 0,
                    .layerCount = 1,
                },
                .srcAccessMask = 0,
                .dstAccessMask = c.VK_ACCESS_SHADER_READ_BIT,
                .pNext = null,
            };

            c.vkCmdPipelineBarrier(
                commandBuffer,
                c.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT,
                c.VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT,
                0,
                0,
                null,
                0,
                null,
                1,
                &barrier,
            );

            try ensureNoError(c.vkEndCommandBuffer(commandBuffer));

            try ensureNoError(c.vkQueueSubmit(graphicsQueue, 1, &c.VkSubmitInfo{
                .sType = c.VK_STRUCTURE_TYPE_SUBMIT_INFO,
                .commandBufferCount = 1,
                .pCommandBuffers = &commandBuffer,
                .pNext = null,
                .waitSemaphoreCount = 0,
                .pWaitSemaphores = null,
                .pWaitDstStageMask = null,
                .signalSemaphoreCount = 0,
                .pSignalSemaphores = null,
            }, null));
            try ensureNoError(c.vkQueueWaitIdle(graphicsQueue));
            c.vkFreeCommandBuffers(logicalDevice, commandPool, 1, &commandBuffer);
        }

        const freeRectangle = FreeRectangle{
            .u = 0,
            .v = 0,
            .width = extent.width,
            .height = extent.height,
        };

        var freeRectangles = try std.ArrayList(FreeRectangle).initCapacity(allocator, 1);
        freeRectangles.appendAssumeCapacity(freeRectangle);

        var imageData: ?*anyopaque = undefined;
        try ensureNoError(c.vkMapMemory(logicalDevice, memory, 0, memRequirements.size, 0, &imageData));
        const imageDataSlice: []u8 = @as([*c]u8, @ptrCast(@alignCast(imageData)))[0..@intCast(memRequirements.size)];
        @memset(imageDataSlice, 0);

        return @This(){
            .allocator = allocator,

            .image = image,
            .imageView = imageView,
            .memory = memory,

            .mapped = imageDataSlice,
            .rowPitch = @intCast(subresourceLayout.rowPitch),

            .capacityExtent = extent,
            .freeRectangles = freeRectangles,
        };
    }

    fn getBestFreeRectangle(
        self: *@This(),
        wantedWidth: usize,
        wantedHeight: usize,
    ) ?usize {
        var bestRectangleIndex: ?usize = null;
        var bestAreaDifference: usize = @intCast(std.math.maxInt(usize));

        const requiredArea = wantedWidth * wantedHeight;
        for (self.freeRectangles.items, 0..) |freeRectangle, index| {
            if (freeRectangle.width >= wantedWidth and freeRectangle.height >= wantedHeight) {
                const freeArea = freeRectangle.width * freeRectangle.height;
                const areaDifference = freeArea - requiredArea;
                if (areaDifference < bestAreaDifference) {
                    bestAreaDifference = areaDifference;
                    bestRectangleIndex = index;
                }
            }
        }

        return bestRectangleIndex;
    }

    fn reclaim(self: *@This(), rect: FreeRectangle) !void {
        try self.freeRectangles.append(self.allocator, rect);
        self.mergeFreeRectangles();
    }

    fn mergeFreeRectangles(self: *@This()) void {
        var merged = true;
        while (merged) {
            merged = false;
            var i: usize = 0;
            outer: while (i < self.freeRectangles.items.len) {
                var j: usize = i + 1;
                while (j < self.freeRectangles.items.len) {
                    const a = self.freeRectangles.items[i];
                    const b = self.freeRectangles.items[j];

                    if (a.width == b.width and a.u == b.u) {
                        // vertically adjacent
                        if (a.v + a.height == b.v) {
                            self.freeRectangles.items[i] = .{ .u = a.u, .v = a.v, .width = a.width, .height = a.height + b.height };
                            _ = self.freeRectangles.swapRemove(j);
                            merged = true;
                            continue :outer;
                        } else if (b.v + b.height == a.v) {
                            self.freeRectangles.items[i] = .{ .u = b.u, .v = b.v, .width = a.width, .height = a.height + b.height };
                            _ = self.freeRectangles.swapRemove(j);
                            merged = true;
                            continue :outer;
                        }
                    }

                    if (a.height == b.height and a.v == b.v) {
                        // horizontally adjacent
                        if (a.u + a.width == b.u) {
                            self.freeRectangles.items[i] = .{ .u = a.u, .v = a.v, .width = a.width + b.width, .height = a.height };
                            _ = self.freeRectangles.swapRemove(j);
                            merged = true;
                            continue :outer;
                        } else if (b.u + b.width == a.u) {
                            self.freeRectangles.items[i] = .{ .u = b.u, .v = b.v, .width = a.width + b.width, .height = a.height };
                            _ = self.freeRectangles.swapRemove(j);
                            merged = true;
                            continue :outer;
                        }
                    }

                    j += 1;
                }
                i += 1;
            }
        }
    }

    fn reset(self: *@This()) void {
        self.freeRectangles.clearRetainingCapacity();
        self.freeRectangles.appendAssumeCapacity(.{
            .u = 0,
            .v = 0,
            .width = @intCast(self.capacityExtent.width),
            .height = @intCast(self.capacityExtent.height),
        });
        @memset(self.mapped, 0);
    }

    const TextureCoordinates = struct {
        u: f32,
        v: f32,
        w: f32,
        h: f32,
    };

    /// Upload LCD/subpixel glyph data to the texture atlas.
    /// The input data is in FreeType LCD format (3 bytes per pixel: R, G, B).
    /// uploadWidth is the width in bytes from FreeType (= pixel_width * 3 for LCD mode).
    /// The texture atlas uses RGBA format (4 bytes per pixel) for dual-source blending.
    fn upload(
        self: *@This(),
        data: ?[]u8,
        uploadWidth: usize,
        uploadHeight: usize,
        pitch: usize,
    ) !TextureCoordinates {
        if (data != null) {
            std.debug.assert(pitch * uploadHeight <= data.?.len);
        }
        // No free rectangles available in the texture atlas
        std.debug.assert(self.freeRectangles.items.len > 0);

        // FreeType LCD mode: uploadWidth is 3x the actual pixel width (RGB bytes)
        // Convert to actual pixel width for texture storage
        const pixelWidth = uploadWidth / 3;

        const freeRectangleIndex = self.getBestFreeRectangle(
            @intCast(pixelWidth),
            @intCast(uploadHeight),
        ) orelse return error.MaximumTextureAtlasSizeReached;
        const freeRectangle = self.freeRectangles.orderedRemove(freeRectangleIndex);
        std.log.debug("Uploading glyph to texture atlas at ({d}, {d}) size ({d}x{d})", .{
            freeRectangle.u,
            freeRectangle.v,
            pixelWidth,
            uploadHeight,
        });
        // we share the remaining space in the free rectangle in a way that this first one has the
        // most area
        if (freeRectangle.width > pixelWidth) {
            try self.freeRectangles.append(
                self.allocator,
                FreeRectangle{
                    .u = freeRectangle.u + pixelWidth,
                    .v = freeRectangle.v,
                    .width = freeRectangle.width - pixelWidth,
                    .height = freeRectangle.height,
                },
            );
        }
        if (freeRectangle.height > uploadHeight) {
            try self.freeRectangles.append(
                self.allocator,
                FreeRectangle{
                    .u = freeRectangle.u,
                    .v = freeRectangle.v + uploadHeight,
                    .width = pixelWidth,
                    .height = freeRectangle.height - uploadHeight,
                },
            );
        }

        // Convert RGB (3 bytes per pixel from FreeType LCD) to RGBA (4 bytes per pixel)
        // rowPitch is in bytes, and we have 4 bytes per pixel (RGBA)
        for (0..uploadHeight) |y| {
            const destRowStart = (freeRectangle.v + y) * self.rowPitch + freeRectangle.u * 4;
            if (data != null) {
                const srcRowStart = y * pitch;
                for (0..pixelWidth) |x| {
                    const srcOffset = srcRowStart + x * 3;
                    const destOffset = destRowStart + x * 4;
                    // Copy RGB from FreeType LCD bitmap
                    self.mapped[destOffset + 0] = data.?[srcOffset + 0]; // R
                    self.mapped[destOffset + 1] = data.?[srcOffset + 1]; // G
                    self.mapped[destOffset + 2] = data.?[srcOffset + 2]; // B
                    // Alpha = max of RGB coverages (for discard test and general alpha)
                    self.mapped[destOffset + 3] = @max(@max(data.?[srcOffset + 0], data.?[srcOffset + 1]), data.?[srcOffset + 2]);
                }
            } else {
                for (0..pixelWidth) |x| {
                    const destOffset = destRowStart + x * 4;
                    self.mapped[destOffset + 0] = 0;
                    self.mapped[destOffset + 1] = 0;
                    self.mapped[destOffset + 2] = 0;
                    self.mapped[destOffset + 3] = 0;
                }
            }
        }

        return .{
            .u = @as(f32, @floatFromInt(freeRectangle.u)),
            .v = @as(f32, @floatFromInt(freeRectangle.v)),
            .w = @as(f32, @floatFromInt(pixelWidth)),
            .h = @as(f32, @floatFromInt(uploadHeight)),
        };
    }

    fn width(self: @This()) usize {
        return @as(usize, @intCast(self.capacityExtent.width));
    }

    fn height(self: @This()) usize {
        return @as(usize, @intCast(self.capacityExtent.height));
    }

    fn deinit(self: *@This(), allocator: std.mem.Allocator, logicalDevice: c.VkDevice) void {
        c.vkUnmapMemory(logicalDevice, self.memory);
        self.freeRectangles.deinit(allocator);
        c.vkFreeMemory(logicalDevice, self.memory, null);
        c.vkDestroyImageView(logicalDevice, self.imageView, null);
        c.vkDestroyImage(logicalDevice, self.image, null);
    }
};

const Buffer = struct {
    handle: c.VkBuffer,
    memory: c.VkDeviceMemory,
    size: c.VkDeviceSize,

    fn init(
        logicalDevice: c.VkDevice,
        physicalDevice: c.VkPhysicalDevice,
        size: c.VkDeviceSize,
        usage: c.VkBufferUsageFlags,
        properties: c.VkMemoryPropertyFlags,
    ) !@This() {
        var buffer: c.VkBuffer = undefined;
        try ensureNoError(c.vkCreateBuffer(
            logicalDevice,
            &c.VkBufferCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
                .pNext = null,
                .flags = 0,
                .size = size,
                .usage = usage,
                .sharingMode = c.VK_SHARING_MODE_EXCLUSIVE,
                .queueFamilyIndexCount = 0,
                .pQueueFamilyIndices = null,
            },
            null,
            &buffer,
        ));
        errdefer c.vkDestroyBuffer(logicalDevice, buffer, null);

        var bufferMemoryRequirements: c.VkMemoryRequirements = undefined;
        c.vkGetBufferMemoryRequirements(logicalDevice, buffer, &bufferMemoryRequirements);
        var bufferMemory: c.VkDeviceMemory = undefined;
        try ensureNoError(c.vkAllocateMemory(
            logicalDevice,
            &c.VkMemoryAllocateInfo{
                .sType = c.VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
                .pNext = null,
                .allocationSize = bufferMemoryRequirements.size,
                .memoryTypeIndex = try findMemoryType(
                    bufferMemoryRequirements.memoryTypeBits,
                    properties,
                    physicalDevice,
                ),
            },
            null,
            &bufferMemory,
        ));
        errdefer c.vkFreeMemory(logicalDevice, bufferMemory, null);

        try ensureNoError(c.vkBindBufferMemory(logicalDevice, buffer, bufferMemory, 0));

        return .{
            .handle = buffer,
            .memory = bufferMemory,
            .size = size,
        };
    }

    fn copyFrom(
        self: *@This(),
        from: *const Buffer,
        logicalDevice: c.VkDevice,
        graphicsQueue: c.VkQueue,
        commandPool: c.VkCommandPool,
    ) !void {
        if (self.size != from.size) {
            return error.BufferSizeMismatch;
        }

        var commandBuffer: c.VkCommandBuffer = undefined;
        try ensureNoError(c.vkAllocateCommandBuffers(
            logicalDevice,
            &c.VkCommandBufferAllocateInfo{
                .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
                .level = c.VK_COMMAND_BUFFER_LEVEL_PRIMARY,
                .pNext = null,
                .commandPool = commandPool,
                .commandBufferCount = 1,
            },
            &commandBuffer,
        ));
        defer c.vkFreeCommandBuffers(logicalDevice, commandPool, 1, &commandBuffer);

        try ensureNoError(c.vkBeginCommandBuffer(commandBuffer, &c.VkCommandBufferBeginInfo{
            .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
            .pNext = null,
            .flags = c.VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT,
            .pInheritanceInfo = null,
        }));
        c.vkCmdCopyBuffer(commandBuffer, from.handle, self.handle, 1, &c.VkBufferCopy{
            .srcOffset = 0,
            .dstOffset = 0,
            .size = self.size,
        });
        try ensureNoError(c.vkEndCommandBuffer(commandBuffer));

        try ensureNoError(c.vkQueueSubmit(
            graphicsQueue,
            1,
            &c.VkSubmitInfo{
                .sType = c.VK_STRUCTURE_TYPE_SUBMIT_INFO,
                .pNext = null,
                .commandBufferCount = 1,
                .pCommandBuffers = &commandBuffer,
            },
            null,
        ));
        try ensureNoError(c.vkQueueWaitIdle(graphicsQueue));
    }

    fn set(self: @This(), logicalDevice: c.VkDevice, data: []const u8) !void {
        if (data.len != @as(usize, @intCast(self.size))) {
            return error.BufferSizeDataMismatch;
        }
        var vertexBufferData: ?*anyopaque = undefined;
        try ensureNoError(c.vkMapMemory(logicalDevice, self.memory, 0, data.len, 0, &vertexBufferData));
        @memcpy(@as([*c]u8, @ptrCast(@alignCast(vertexBufferData)))[0..data.len], data);
        c.vkUnmapMemory(logicalDevice, self.memory);
    }

    fn deinit(self: @This(), logicalDevice: c.VkDevice) void {
        c.vkFreeMemory(logicalDevice, self.memory, null);
        c.vkDestroyBuffer(logicalDevice, self.handle, null);
    }
};

/// Per-frame host-visible storage buffer with power-of-two growth. Owns one
/// `Buffer` per frame-in-flight and the memory-mapped slice that writes into
/// it, and knows how to re-point a descriptor binding at the fresh buffer
/// after a resize.
fn ResizableStorageBuffer(comptime T: type) type {
    return struct {
        buffers: [maxFramesInFlight]Buffer,
        mapped: [maxFramesInFlight][]T,
        binding: u32,

        const Self = @This();

        fn init(
            logicalDevice: c.VkDevice,
            physicalDevice: c.VkPhysicalDevice,
            initialCapacity: usize,
            binding: u32,
        ) !Self {
            var self: Self = .{
                .buffers = undefined,
                .mapped = undefined,
                .binding = binding,
            };
            for (0..maxFramesInFlight) |i| {
                try self.createAndMap(logicalDevice, physicalDevice, initialCapacity, i);
            }
            return self;
        }

        fn deinit(self: *Self, logicalDevice: c.VkDevice) void {
            for (self.buffers) |buffer| {
                c.vkUnmapMemory(logicalDevice, buffer.memory);
                buffer.deinit(logicalDevice);
            }
        }

        fn createAndMap(
            self: *Self,
            logicalDevice: c.VkDevice,
            physicalDevice: c.VkPhysicalDevice,
            capacity: usize,
            frameIndex: usize,
        ) !void {
            const buffer = try Buffer.init(
                logicalDevice,
                physicalDevice,
                @sizeOf(T) * capacity,
                c.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT,
                c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
            );
            self.buffers[frameIndex] = buffer;
            var data: ?*anyopaque = undefined;
            try ensureNoError(c.vkMapMemory(logicalDevice, buffer.memory, 0, buffer.size, 0, &data));
            self.mapped[frameIndex] = @as([*]T, @ptrCast(@alignCast(data)))[0..capacity];
        }

        fn writeDescriptor(
            self: *const Self,
            logicalDevice: c.VkDevice,
            descriptorSet: c.VkDescriptorSet,
            frameIndex: usize,
        ) void {
            const bufferInfo = c.VkDescriptorBufferInfo{
                .buffer = self.buffers[frameIndex].handle,
                .offset = 0,
                .range = c.VK_WHOLE_SIZE,
            };
            const write = c.VkWriteDescriptorSet{
                .sType = c.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
                .pNext = null,
                .dstSet = descriptorSet,
                .dstBinding = self.binding,
                .dstArrayElement = 0,
                .descriptorCount = 1,
                .descriptorType = c.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
                .pImageInfo = null,
                .pBufferInfo = &bufferInfo,
                .pTexelBufferView = null,
            };
            c.vkUpdateDescriptorSets(logicalDevice, 1, &write, 0, null);
        }

        /// Grows the buffer to at least `required` entries (rounded up to the
        /// next power of two) for `frameIndex`, rebinding the descriptor so
        /// the shader sees the fresh buffer. No-op when capacity is already
        /// sufficient.
        fn ensureCapacity(
            self: *Self,
            logicalDevice: c.VkDevice,
            physicalDevice: c.VkPhysicalDevice,
            descriptorSet: c.VkDescriptorSet,
            required: usize,
            frameIndex: usize,
        ) !void {
            if (required <= self.mapped[frameIndex].len) return;

            const newCapacity = try std.math.ceilPowerOfTwo(usize, required);
            std.log.debug("resizing {s} buffer from {d} to {d} for frame {d}", .{
                @typeName(T),
                self.mapped[frameIndex].len,
                newCapacity,
                frameIndex,
            });
            c.vkUnmapMemory(logicalDevice, self.buffers[frameIndex].memory);
            self.buffers[frameIndex].deinit(logicalDevice);
            try self.createAndMap(logicalDevice, physicalDevice, newCapacity, frameIndex);
            self.writeDescriptor(logicalDevice, descriptorSet, frameIndex);
        }
    };
}

pub const Vertex = extern struct {
    position: @Vector(3, f32),

    pub fn getBindingDescription() c.VkVertexInputBindingDescription {
        return c.VkVertexInputBindingDescription{
            .binding = 0,
            .stride = @sizeOf(@This()),
            .inputRate = c.VK_VERTEX_INPUT_RATE_VERTEX,
        };
    }

    pub fn getAttributeDescriptions() [1]c.VkVertexInputAttributeDescription {
        return .{
            c.VkVertexInputAttributeDescription{
                .binding = 0,
                .location = 0,
                .format = c.VK_FORMAT_R32G32B32_SFLOAT,
                .offset = @offsetOf(@This(), "position"),
            },
        };
    }
};

const Model = struct {
    vertexBuffer: Buffer,
    vertexCount: u32,

    fn init(
        vertices: []const Vertex,
        logicalDevice: c.VkDevice,
        physicalDevice: c.VkPhysicalDevice,
        transferQueue: c.VkQueue,
        commandPool: c.VkCommandPool,
    ) !@This() {
        const stagingBuffer = try Buffer.init(
            logicalDevice,
            physicalDevice,
            @sizeOf(Vertex) * vertices.len,
            c.VK_BUFFER_USAGE_TRANSFER_SRC_BIT,
            c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
        );
        defer stagingBuffer.deinit(logicalDevice);
        try stagingBuffer.set(logicalDevice, @ptrCast(@alignCast(vertices)));

        var vertexBuffer = try Buffer.init(
            logicalDevice,
            physicalDevice,
            @sizeOf(Vertex) * vertices.len,
            c.VK_BUFFER_USAGE_TRANSFER_DST_BIT | c.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT,
            c.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT,
        );
        errdefer vertexBuffer.deinit(logicalDevice);
        try vertexBuffer.copyFrom(&stagingBuffer, logicalDevice, transferQueue, commandPool);

        return Model{
            .vertexBuffer = vertexBuffer,
            .vertexCount = @intCast(vertices.len),
        };
    }

    fn deinit(self: @This(), logicalDevice: c.VkDevice) void {
        self.vertexBuffer.deinit(logicalDevice);
    }
};

const ShadowRenderingData = extern struct {
    blur: f32,
    borderRadius: f32,
    color: Vec4,
    modelViewProjectionMatrix: zmath.Mat,
    elementSize: [2]f32,
    elementOffset: [2]f32,
    size: [2]f32,
    spread: f32,
};

const ShadowsPipeline = struct {
    logicalDevice: c.VkDevice,
    physicalDevice: c.VkPhysicalDevice,

    pipelineLayout: c.VkPipelineLayout,
    graphicsPipeline: c.VkPipeline,

    shaderBufferDescriptorSetLayout: c.VkDescriptorSetLayout,
    descriptorPool: c.VkDescriptorPool,
    descriptorSets: [maxFramesInFlight]c.VkDescriptorSet,

    shadows: ResizableStorageBuffer(ShadowRenderingData),

    const shadowVertexShader: []const u32 = @ptrCast(@alignCast(@embedFile("shadow_vertex_shader")));
    const shadowFragmentShader: []const u32 = @ptrCast(@alignCast(@embedFile("shadow_fragment_shader")));

    fn init(
        logicalDevice: c.VkDevice,
        physicalDevice: c.VkPhysicalDevice,
        renderPass: c.VkRenderPass,
    ) !@This() {
        var vertexShaderModule: c.VkShaderModule = undefined;
        try ensureNoError(c.vkCreateShaderModule(
            logicalDevice,
            &c.VkShaderModuleCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO,
                .pNext = null,
                .flags = 0,
                .codeSize = @sizeOf(u32) * shadowVertexShader.len,
                .pCode = shadowVertexShader.ptr,
            },
            null,
            &vertexShaderModule,
        ));
        defer c.vkDestroyShaderModule(logicalDevice, vertexShaderModule, null);

        var fragmentShaderModule: c.VkShaderModule = undefined;
        try ensureNoError(c.vkCreateShaderModule(
            logicalDevice,
            &c.VkShaderModuleCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO,
                .pNext = null,
                .flags = 0,
                .codeSize = @sizeOf(u32) * shadowFragmentShader.len,
                .pCode = shadowFragmentShader.ptr,
            },
            null,
            &fragmentShaderModule,
        ));
        defer c.vkDestroyShaderModule(logicalDevice, fragmentShaderModule, null);

        const shaderStages: []const c.VkPipelineShaderStageCreateInfo = &.{
            c.VkPipelineShaderStageCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
                .pNext = null,
                .flags = 0,
                .stage = c.VK_SHADER_STAGE_VERTEX_BIT,
                .module = vertexShaderModule,
                .pName = "main",
                .pSpecializationInfo = null,
            },
            c.VkPipelineShaderStageCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
                .pNext = null,
                .flags = 0,
                .stage = c.VK_SHADER_STAGE_FRAGMENT_BIT,
                .module = fragmentShaderModule,
                .pName = "main",
                .pSpecializationInfo = null,
            },
        };

        const dynamicStates: []const c.VkDynamicState = &.{
            c.VK_DYNAMIC_STATE_VIEWPORT,
            c.VK_DYNAMIC_STATE_SCISSOR,
        };

        const bindings = [_]c.VkDescriptorSetLayoutBinding{
            .{
                .binding = 0,
                .descriptorType = c.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
                .descriptorCount = 1,
                .stageFlags = c.VK_SHADER_STAGE_VERTEX_BIT,
                .pImmutableSamplers = null,
            },
        };

        var shaderBufferDescriptorSetLayout: c.VkDescriptorSetLayout = undefined;
        try ensureNoError(c.vkCreateDescriptorSetLayout(
            logicalDevice,
            &c.VkDescriptorSetLayoutCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
                .pNext = null,
                .flags = c.VK_DESCRIPTOR_SET_LAYOUT_CREATE_UPDATE_AFTER_BIND_POOL_BIT,
                .bindingCount = bindings.len,
                .pBindings = &bindings,
            },
            null,
            &shaderBufferDescriptorSetLayout,
        ));

        var pipelineLayout: c.VkPipelineLayout = undefined;
        try ensureNoError(c.vkCreatePipelineLayout(
            logicalDevice,
            &c.VkPipelineLayoutCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO,
                .pNext = null,
                .flags = 0,
                .setLayoutCount = 1,
                .pSetLayouts = &shaderBufferDescriptorSetLayout,
                .pushConstantRangeCount = 0,
                .pPushConstantRanges = null,
            },
            null,
            &pipelineLayout,
        ));
        errdefer c.vkDestroyPipelineLayout(logicalDevice, pipelineLayout, null);

        const bindingDescription = Vertex.getBindingDescription();
        const attributeDescriptions = Vertex.getAttributeDescriptions();

        var graphicsPipeline: c.VkPipeline = undefined;
        try ensureNoError(c.vkCreateGraphicsPipelines(
            logicalDevice,
            null,
            1,
            &c.VkGraphicsPipelineCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO,
                .pNext = null,
                .stageCount = @intCast(shaderStages.len),
                .pStages = shaderStages.ptr,
                .pVertexInputState = &c.VkPipelineVertexInputStateCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
                    .pNext = null,
                    .flags = 0,
                    .vertexBindingDescriptionCount = 1,
                    .pVertexBindingDescriptions = &bindingDescription,
                    .vertexAttributeDescriptionCount = attributeDescriptions.len,
                    .pVertexAttributeDescriptions = &attributeDescriptions,
                },
                .pInputAssemblyState = &c.VkPipelineInputAssemblyStateCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO,
                    .pNext = null,
                    .flags = 0,
                    .topology = c.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
                    .primitiveRestartEnable = c.VK_FALSE,
                },
                .pViewportState = &c.VkPipelineViewportStateCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO,
                    .pNext = null,
                    .flags = 0,
                    .viewportCount = 1,
                    .scissorCount = 1,
                },
                .pRasterizationState = &c.VkPipelineRasterizationStateCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO,
                    .pNext = null,
                    .flags = 0,
                    .depthClampEnable = c.VK_FALSE,
                    .rasterizerDiscardEnable = c.VK_FALSE,
                    .polygonMode = c.VK_POLYGON_MODE_FILL,
                    .cullMode = c.VK_CULL_MODE_BACK_BIT,
                    .frontFace = c.VK_FRONT_FACE_CLOCKWISE,
                    .lineWidth = 1.0,
                    .depthBiasEnable = c.VK_FALSE,
                    .depthBiasConstantFactor = 0.0,
                    .depthBiasClamp = 0.0,
                    .depthBiasSlopeFactor = 0.0,
                },
                .pMultisampleState = &c.VkPipelineMultisampleStateCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO,
                    .sampleShadingEnable = c.VK_FALSE,
                    .rasterizationSamples = c.VK_SAMPLE_COUNT_1_BIT,
                    .minSampleShading = 1.0,
                    .pSampleMask = null,
                    .alphaToCoverageEnable = c.VK_FALSE,
                    .alphaToOneEnable = c.VK_FALSE,
                    .pNext = null,
                    .flags = 0,
                },
                .pColorBlendState = &c.VkPipelineColorBlendStateCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO,
                    .pNext = null,
                    .flags = 0,
                    .logicOpEnable = c.VK_FALSE,
                    .logicOp = c.VK_LOGIC_OP_COPY,
                    .attachmentCount = 1,
                    .pAttachments = &c.VkPipelineColorBlendAttachmentState{
                        .colorWriteMask = c.VK_COLOR_COMPONENT_R_BIT | c.VK_COLOR_COMPONENT_G_BIT | c.VK_COLOR_COMPONENT_B_BIT | c.VK_COLOR_COMPONENT_A_BIT,
                        .blendEnable = c.VK_TRUE,
                        .srcColorBlendFactor = c.VK_BLEND_FACTOR_SRC_ALPHA,
                        .dstColorBlendFactor = c.VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA,
                        .colorBlendOp = c.VK_BLEND_OP_ADD,
                        .srcAlphaBlendFactor = c.VK_BLEND_FACTOR_ONE,
                        .dstAlphaBlendFactor = c.VK_BLEND_FACTOR_ZERO,
                        .alphaBlendOp = c.VK_BLEND_OP_ADD,
                    },
                    .blendConstants = .{ 0.0, 0.0, 0.0, 0.0 },
                },
                .pDynamicState = &c.VkPipelineDynamicStateCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_PIPELINE_DYNAMIC_STATE_CREATE_INFO,
                    .pNext = null,
                    .flags = 0,
                    .dynamicStateCount = @intCast(dynamicStates.len),
                    .pDynamicStates = dynamicStates.ptr,
                },
                .layout = pipelineLayout,
                .renderPass = renderPass,
                .subpass = 0,
                .basePipelineHandle = null,
                .basePipelineIndex = -1,
            },
            null,
            &graphicsPipeline,
        ));
        errdefer c.vkDestroyPipeline(logicalDevice, graphicsPipeline, null);

        var shadows = try ResizableStorageBuffer(ShadowRenderingData).init(
            logicalDevice,
            physicalDevice,
            1,
            0,
        );
        errdefer shadows.deinit(logicalDevice);

        const poolSizes = [_]c.VkDescriptorPoolSize{
            .{
                .type = c.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
                .descriptorCount = maxFramesInFlight,
            },
        };

        var descriptorPool: c.VkDescriptorPool = undefined;
        try ensureNoError(c.vkCreateDescriptorPool(logicalDevice, &c.VkDescriptorPoolCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO,
            .poolSizeCount = poolSizes.len,
            .maxSets = maxFramesInFlight,
            .pPoolSizes = &poolSizes,
            .flags = c.VK_DESCRIPTOR_POOL_CREATE_UPDATE_AFTER_BIND_BIT,
            .pNext = null,
        }, null, &descriptorPool));

        var descriptorSets: [maxFramesInFlight]c.VkDescriptorSet = undefined;
        try ensureNoError(c.vkAllocateDescriptorSets(logicalDevice, &c.VkDescriptorSetAllocateInfo{
            .sType = c.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO,
            .descriptorPool = descriptorPool,
            .descriptorSetCount = maxFramesInFlight,
            .pSetLayouts = &([1]c.VkDescriptorSetLayout{shaderBufferDescriptorSetLayout} ** maxFramesInFlight),
        }, &descriptorSets));

        for (0..maxFramesInFlight) |i| {
            shadows.writeDescriptor(logicalDevice, descriptorSets[i], i);
        }

        return ShadowsPipeline{
            .logicalDevice = logicalDevice,
            .physicalDevice = physicalDevice,

            .pipelineLayout = pipelineLayout,
            .graphicsPipeline = graphicsPipeline,

            .shaderBufferDescriptorSetLayout = shaderBufferDescriptorSetLayout,
            .shadows = shadows,
            .descriptorSets = descriptorSets,
            .descriptorPool = descriptorPool,
        };
    }

    fn ensureCapacity(self: *@This(), required: usize, frameIndex: usize) !void {
        try self.shadows.ensureCapacity(
            self.logicalDevice,
            self.physicalDevice,
            self.descriptorSets[frameIndex],
            required,
            frameIndex,
        );
    }

    fn draw(
        self: *@This(),
        layerInterval: LayerInterval,
        frameIndex: usize,
        commandBuffer: c.VkCommandBuffer,
        rectangleModel: *Model,
    ) void {
        c.vkCmdBindPipeline(
            commandBuffer,
            c.VK_PIPELINE_BIND_POINT_GRAPHICS,
            self.graphicsPipeline,
        );

        c.vkCmdBindDescriptorSets(
            commandBuffer,
            c.VK_PIPELINE_BIND_POINT_GRAPHICS,
            self.pipelineLayout,
            0,
            1,
            &self.descriptorSets[frameIndex],
            0,
            null,
        );

        c.vkCmdBindVertexBuffers(
            commandBuffer,
            0,
            1,
            &rectangleModel.vertexBuffer.handle,
            &@intCast(0),
        );
        c.vkCmdDraw(
            commandBuffer,
            rectangleModel.vertexCount,
            @intCast(layerInterval.end - layerInterval.start + 1),
            0,
            @intCast(layerInterval.start),
        );
    }

    fn deinit(self: *@This(), logicalDevice: c.VkDevice) void {
        c.vkDestroyDescriptorPool(logicalDevice, self.descriptorPool, null);
        self.shadows.deinit(logicalDevice);
        c.vkDestroyDescriptorSetLayout(logicalDevice, self.shaderBufferDescriptorSetLayout, null);
        c.vkDestroyPipeline(logicalDevice, self.graphicsPipeline, null);
        c.vkDestroyPipelineLayout(logicalDevice, self.pipelineLayout, null);
    }
};

const ElementRenderingData = extern struct {
    backgroundColor: Vec4,
    borderColor: Vec4,
    borderRadius: f32,
    borderSize: Vec4,
    imageIndex: i32,
    gradientStart: i32,
    gradientEnd: i32,
    blendMode: u32,
    filterType: u32,
    borderStyle: u32,
    modelViewProjectionMatrix: zmath.Mat,
    size: [2]f32,
    gradientDirection: [2]f32,
};

const ElementsPipeline = struct {
    allocator: std.mem.Allocator,
    logicalDevice: c.VkDevice,
    physicalDevice: c.VkPhysicalDevice,

    pipelineLayout: c.VkPipelineLayout,
    blendAddGraphicsPipeline: c.VkPipeline,
    blendMultiplyGraphicsPipeline: c.VkPipeline,
    blendDarkenGraphicsPipeline: c.VkPipeline,

    shaderBufferDescriptorSetLayout: c.VkDescriptorSetLayout,
    descriptorPool: c.VkDescriptorPool,
    descriptorSets: [maxFramesInFlight]c.VkDescriptorSet,

    elements: ResizableStorageBuffer(ElementRenderingData),
    gradientStops: ResizableStorageBuffer(GradientStop),

    registeredImages: std.ArrayList(*const Image),
    sampler: c.VkSampler,

    const maxImages = 1024;

    const elementVertexShader: []const u32 = @ptrCast(@alignCast(@embedFile("element_vertex_shader")));
    const elementFragmentShader: []const u32 = @ptrCast(@alignCast(@embedFile("element_fragment_shader")));

    fn init(
        allocator: std.mem.Allocator,
        logicalDevice: c.VkDevice,
        physicalDevice: c.VkPhysicalDevice,
        renderPass: c.VkRenderPass,
    ) !@This() {
        var vertexShaderModule: c.VkShaderModule = undefined;
        try ensureNoError(c.vkCreateShaderModule(
            logicalDevice,
            &c.VkShaderModuleCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO,
                .pNext = null,
                .flags = 0,
                .codeSize = @sizeOf(u32) * elementVertexShader.len,
                .pCode = elementVertexShader.ptr,
            },
            null,
            &vertexShaderModule,
        ));
        defer c.vkDestroyShaderModule(logicalDevice, vertexShaderModule, null);

        var fragmentShaderModule: c.VkShaderModule = undefined;
        try ensureNoError(c.vkCreateShaderModule(
            logicalDevice,
            &c.VkShaderModuleCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO,
                .pNext = null,
                .flags = 0,
                .codeSize = @sizeOf(u32) * elementFragmentShader.len,
                .pCode = elementFragmentShader.ptr,
            },
            null,
            &fragmentShaderModule,
        ));
        defer c.vkDestroyShaderModule(logicalDevice, fragmentShaderModule, null);

        const shaderStages: []const c.VkPipelineShaderStageCreateInfo = &.{
            c.VkPipelineShaderStageCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
                .pNext = null,
                .flags = 0,
                .stage = c.VK_SHADER_STAGE_VERTEX_BIT,
                .module = vertexShaderModule,
                .pName = "main",
                .pSpecializationInfo = null,
            },
            c.VkPipelineShaderStageCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
                .pNext = null,
                .flags = 0,
                .stage = c.VK_SHADER_STAGE_FRAGMENT_BIT,
                .module = fragmentShaderModule,
                .pName = "main",
                .pSpecializationInfo = null,
            },
        };

        const dynamicStates: []const c.VkDynamicState = &.{
            c.VK_DYNAMIC_STATE_VIEWPORT,
            c.VK_DYNAMIC_STATE_SCISSOR,
        };

        const bindings = [_]c.VkDescriptorSetLayoutBinding{
            .{
                .binding = 0,
                .descriptorType = c.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
                .descriptorCount = 1,
                .stageFlags = c.VK_SHADER_STAGE_VERTEX_BIT,
                .pImmutableSamplers = null,
            },
            .{
                .binding = 1,
                .descriptorType = c.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
                .descriptorCount = maxImages,
                .stageFlags = c.VK_SHADER_STAGE_FRAGMENT_BIT,
                .pImmutableSamplers = null,
            },
            .{
                .binding = 2,
                .descriptorType = c.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
                .descriptorCount = 1,
                .stageFlags = c.VK_SHADER_STAGE_FRAGMENT_BIT,
                .pImmutableSamplers = null,
            },
        };

        const bindingFlags = [_]c.VkDescriptorBindingFlags{
            0,
            c.VK_DESCRIPTOR_BINDING_UPDATE_AFTER_BIND_BIT |
                c.VK_DESCRIPTOR_BINDING_PARTIALLY_BOUND_BIT |
                c.VK_DESCRIPTOR_BINDING_UPDATE_UNUSED_WHILE_PENDING_BIT,
            0,
        };

        const bindingFlagsCreateInfo = c.VkDescriptorSetLayoutBindingFlagsCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_BINDING_FLAGS_CREATE_INFO,
            .pNext = null,
            .bindingCount = bindings.len,
            .pBindingFlags = &bindingFlags,
        };

        var shaderBufferDescriptorSetLayout: c.VkDescriptorSetLayout = undefined;
        try ensureNoError(c.vkCreateDescriptorSetLayout(
            logicalDevice,
            &c.VkDescriptorSetLayoutCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
                .pNext = &bindingFlagsCreateInfo,
                .flags = c.VK_DESCRIPTOR_SET_LAYOUT_CREATE_UPDATE_AFTER_BIND_POOL_BIT,
                .bindingCount = bindings.len,
                .pBindings = &bindings,
            },
            null,
            &shaderBufferDescriptorSetLayout,
        ));

        var pipelineLayout: c.VkPipelineLayout = undefined;
        try ensureNoError(c.vkCreatePipelineLayout(
            logicalDevice,
            &c.VkPipelineLayoutCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO,
                .pNext = null,
                .flags = 0,
                .setLayoutCount = 1,
                .pSetLayouts = &shaderBufferDescriptorSetLayout,
                .pushConstantRangeCount = 0,
                .pPushConstantRanges = null,
            },
            null,
            &pipelineLayout,
        ));
        errdefer c.vkDestroyPipelineLayout(logicalDevice, pipelineLayout, null);

        const bindingDescription = Vertex.getBindingDescription();
        const attributeDescriptions = Vertex.getAttributeDescriptions();

        var blendAddGraphicsPipeline: c.VkPipeline = undefined;
        try ensureNoError(c.vkCreateGraphicsPipelines(
            logicalDevice,
            null,
            1,
            &c.VkGraphicsPipelineCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO,
                .pNext = null,
                .stageCount = @intCast(shaderStages.len),
                .pStages = shaderStages.ptr,
                .pVertexInputState = &c.VkPipelineVertexInputStateCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
                    .pNext = null,
                    .flags = 0,
                    .vertexBindingDescriptionCount = 1,
                    .pVertexBindingDescriptions = &bindingDescription,
                    .vertexAttributeDescriptionCount = attributeDescriptions.len,
                    .pVertexAttributeDescriptions = &attributeDescriptions,
                },
                .pInputAssemblyState = &c.VkPipelineInputAssemblyStateCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO,
                    .pNext = null,
                    .flags = 0,
                    .topology = c.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
                    .primitiveRestartEnable = c.VK_FALSE,
                },
                .pViewportState = &c.VkPipelineViewportStateCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO,
                    .pNext = null,
                    .flags = 0,
                    .viewportCount = 1,
                    .scissorCount = 1,
                },
                .pRasterizationState = &c.VkPipelineRasterizationStateCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO,
                    .pNext = null,
                    .flags = 0,
                    .depthClampEnable = c.VK_FALSE,
                    .rasterizerDiscardEnable = c.VK_FALSE,
                    .polygonMode = c.VK_POLYGON_MODE_FILL,
                    .cullMode = c.VK_CULL_MODE_BACK_BIT,
                    .frontFace = c.VK_FRONT_FACE_CLOCKWISE,
                    .lineWidth = 1.0,
                    .depthBiasEnable = c.VK_FALSE,
                    .depthBiasConstantFactor = 0.0,
                    .depthBiasClamp = 0.0,
                    .depthBiasSlopeFactor = 0.0,
                },
                .pMultisampleState = &c.VkPipelineMultisampleStateCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO,
                    .sampleShadingEnable = c.VK_FALSE,
                    .rasterizationSamples = c.VK_SAMPLE_COUNT_1_BIT,
                    .minSampleShading = 1.0,
                    .pSampleMask = null,
                    .alphaToCoverageEnable = c.VK_FALSE,
                    .alphaToOneEnable = c.VK_FALSE,
                    .pNext = null,
                    .flags = 0,
                },
                .pColorBlendState = &c.VkPipelineColorBlendStateCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO,
                    .pNext = null,
                    .flags = 0,
                    .logicOpEnable = c.VK_FALSE,
                    .logicOp = c.VK_LOGIC_OP_COPY,
                    .attachmentCount = 1,
                    .pAttachments = &c.VkPipelineColorBlendAttachmentState{
                        .colorWriteMask = c.VK_COLOR_COMPONENT_R_BIT | c.VK_COLOR_COMPONENT_G_BIT | c.VK_COLOR_COMPONENT_B_BIT | c.VK_COLOR_COMPONENT_A_BIT,
                        .blendEnable = c.VK_TRUE,
                        .srcColorBlendFactor = c.VK_BLEND_FACTOR_SRC_ALPHA,
                        .dstColorBlendFactor = c.VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA,
                        .colorBlendOp = c.VK_BLEND_OP_ADD,
                        .srcAlphaBlendFactor = c.VK_BLEND_FACTOR_ONE,
                        .dstAlphaBlendFactor = c.VK_BLEND_FACTOR_ZERO,
                        .alphaBlendOp = c.VK_BLEND_OP_ADD,
                    },
                    .blendConstants = .{ 0.0, 0.0, 0.0, 0.0 },
                },
                .pDynamicState = &c.VkPipelineDynamicStateCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_PIPELINE_DYNAMIC_STATE_CREATE_INFO,
                    .pNext = null,
                    .flags = 0,
                    .dynamicStateCount = @intCast(dynamicStates.len),
                    .pDynamicStates = dynamicStates.ptr,
                },
                .layout = pipelineLayout,
                .renderPass = renderPass,
                .subpass = 0,
                .basePipelineHandle = null,
                .basePipelineIndex = -1,
            },
            null,
            &blendAddGraphicsPipeline,
        ));
        errdefer c.vkDestroyPipeline(logicalDevice, blendAddGraphicsPipeline, null);

        var blendMultiplyGraphicsPipeline: c.VkPipeline = undefined;
        try ensureNoError(c.vkCreateGraphicsPipelines(
            logicalDevice,
            null,
            1,
            &c.VkGraphicsPipelineCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO,
                .pNext = null,
                .stageCount = @intCast(shaderStages.len),
                .pStages = shaderStages.ptr,
                .pVertexInputState = &c.VkPipelineVertexInputStateCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
                    .pNext = null,
                    .flags = 0,
                    .vertexBindingDescriptionCount = 1,
                    .pVertexBindingDescriptions = &bindingDescription,
                    .vertexAttributeDescriptionCount = attributeDescriptions.len,
                    .pVertexAttributeDescriptions = &attributeDescriptions,
                },
                .pInputAssemblyState = &c.VkPipelineInputAssemblyStateCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO,
                    .pNext = null,
                    .flags = 0,
                    .topology = c.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
                    .primitiveRestartEnable = c.VK_FALSE,
                },
                .pViewportState = &c.VkPipelineViewportStateCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO,
                    .pNext = null,
                    .flags = 0,
                    .viewportCount = 1,
                    .scissorCount = 1,
                },
                .pRasterizationState = &c.VkPipelineRasterizationStateCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO,
                    .pNext = null,
                    .flags = 0,
                    .depthClampEnable = c.VK_FALSE,
                    .rasterizerDiscardEnable = c.VK_FALSE,
                    .polygonMode = c.VK_POLYGON_MODE_FILL,
                    .cullMode = c.VK_CULL_MODE_BACK_BIT,
                    .frontFace = c.VK_FRONT_FACE_CLOCKWISE,
                    .lineWidth = 1.0,
                    .depthBiasEnable = c.VK_FALSE,
                    .depthBiasConstantFactor = 0.0,
                    .depthBiasClamp = 0.0,
                    .depthBiasSlopeFactor = 0.0,
                },
                .pMultisampleState = &c.VkPipelineMultisampleStateCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO,
                    .sampleShadingEnable = c.VK_FALSE,
                    .rasterizationSamples = c.VK_SAMPLE_COUNT_1_BIT,
                    .minSampleShading = 1.0,
                    .pSampleMask = null,
                    .alphaToCoverageEnable = c.VK_FALSE,
                    .alphaToOneEnable = c.VK_FALSE,
                    .pNext = null,
                    .flags = 0,
                },
                .pColorBlendState = &c.VkPipelineColorBlendStateCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO,
                    .pNext = null,
                    .flags = 0,
                    .logicOpEnable = c.VK_FALSE,
                    .logicOp = c.VK_LOGIC_OP_COPY,
                    .attachmentCount = 1,
                    // Multiply blend with source alpha: the fragment shader
                    // outputs premultiplied alpha (src_rgb = α_s * Cs), so:
                    //   color = src_rgb * Cb + (1 - α_s) * Cb
                    //         = α_s * Cs * Cb + (1 - α_s) * Cb
                    // This matches the CSS multiply compositing formula.
                    // Fully transparent pixels leave the framebuffer unchanged.
                    .pAttachments = &c.VkPipelineColorBlendAttachmentState{
                        .colorWriteMask = c.VK_COLOR_COMPONENT_R_BIT | c.VK_COLOR_COMPONENT_G_BIT | c.VK_COLOR_COMPONENT_B_BIT | c.VK_COLOR_COMPONENT_A_BIT,
                        .blendEnable = c.VK_TRUE,
                        .srcColorBlendFactor = c.VK_BLEND_FACTOR_DST_COLOR,
                        .dstColorBlendFactor = c.VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA,
                        .colorBlendOp = c.VK_BLEND_OP_ADD,
                        .srcAlphaBlendFactor = c.VK_BLEND_FACTOR_ONE,
                        .dstAlphaBlendFactor = c.VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA,
                        .alphaBlendOp = c.VK_BLEND_OP_ADD,
                    },
                    .blendConstants = .{ 0.0, 0.0, 0.0, 0.0 },
                },
                .pDynamicState = &c.VkPipelineDynamicStateCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_PIPELINE_DYNAMIC_STATE_CREATE_INFO,
                    .pNext = null,
                    .flags = 0,
                    .dynamicStateCount = @intCast(dynamicStates.len),
                    .pDynamicStates = dynamicStates.ptr,
                },
                .layout = pipelineLayout,
                .renderPass = renderPass,
                .subpass = 0,
                .basePipelineHandle = null,
                .basePipelineIndex = -1,
            },
            null,
            &blendMultiplyGraphicsPipeline,
        ));
        errdefer c.vkDestroyPipeline(logicalDevice, blendMultiplyGraphicsPipeline, null);

        var blendDarkenGraphicsPipeline: c.VkPipeline = undefined;
        try ensureNoError(c.vkCreateGraphicsPipelines(
            logicalDevice,
            null,
            1,
            &c.VkGraphicsPipelineCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO,
                .pNext = null,
                .stageCount = @intCast(shaderStages.len),
                .pStages = shaderStages.ptr,
                .pVertexInputState = &c.VkPipelineVertexInputStateCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
                    .pNext = null,
                    .flags = 0,
                    .vertexBindingDescriptionCount = 1,
                    .pVertexBindingDescriptions = &bindingDescription,
                    .vertexAttributeDescriptionCount = attributeDescriptions.len,
                    .pVertexAttributeDescriptions = &attributeDescriptions,
                },
                .pInputAssemblyState = &c.VkPipelineInputAssemblyStateCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO,
                    .pNext = null,
                    .flags = 0,
                    .topology = c.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
                    .primitiveRestartEnable = c.VK_FALSE,
                },
                .pViewportState = &c.VkPipelineViewportStateCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO,
                    .pNext = null,
                    .flags = 0,
                    .viewportCount = 1,
                    .scissorCount = 1,
                },
                .pRasterizationState = &c.VkPipelineRasterizationStateCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO,
                    .pNext = null,
                    .flags = 0,
                    .depthClampEnable = c.VK_FALSE,
                    .rasterizerDiscardEnable = c.VK_FALSE,
                    .polygonMode = c.VK_POLYGON_MODE_FILL,
                    .cullMode = c.VK_CULL_MODE_BACK_BIT,
                    .frontFace = c.VK_FRONT_FACE_CLOCKWISE,
                    .lineWidth = 1.0,
                    .depthBiasEnable = c.VK_FALSE,
                    .depthBiasConstantFactor = 0.0,
                    .depthBiasClamp = 0.0,
                    .depthBiasSlopeFactor = 0.0,
                },
                .pMultisampleState = &c.VkPipelineMultisampleStateCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO,
                    .sampleShadingEnable = c.VK_FALSE,
                    .rasterizationSamples = c.VK_SAMPLE_COUNT_1_BIT,
                    .minSampleShading = 1.0,
                    .pSampleMask = null,
                    .alphaToCoverageEnable = c.VK_FALSE,
                    .alphaToOneEnable = c.VK_FALSE,
                    .pNext = null,
                    .flags = 0,
                },
                .pColorBlendState = &c.VkPipelineColorBlendStateCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO,
                    .pNext = null,
                    .flags = 0,
                    .logicOpEnable = c.VK_FALSE,
                    .logicOp = c.VK_LOGIC_OP_COPY,
                    .attachmentCount = 1,
                    // Darken approximation: shader outputs mix(1, Cs, α) so that
                    // min(mix(1, Cs, α), Cd) → Cd when α=0, min(Cs, Cd) when α=1.
                    // Alpha uses standard Porter-Duff source-over.
                    .pAttachments = &c.VkPipelineColorBlendAttachmentState{
                        .colorWriteMask = c.VK_COLOR_COMPONENT_R_BIT | c.VK_COLOR_COMPONENT_G_BIT | c.VK_COLOR_COMPONENT_B_BIT | c.VK_COLOR_COMPONENT_A_BIT,
                        .blendEnable = c.VK_TRUE,
                        .srcColorBlendFactor = c.VK_BLEND_FACTOR_ONE,
                        .dstColorBlendFactor = c.VK_BLEND_FACTOR_ONE,
                        .colorBlendOp = c.VK_BLEND_OP_MIN,
                        .srcAlphaBlendFactor = c.VK_BLEND_FACTOR_ONE,
                        .dstAlphaBlendFactor = c.VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA,
                        .alphaBlendOp = c.VK_BLEND_OP_ADD,
                    },
                    .blendConstants = .{ 0.0, 0.0, 0.0, 0.0 },
                },
                .pDynamicState = &c.VkPipelineDynamicStateCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_PIPELINE_DYNAMIC_STATE_CREATE_INFO,
                    .pNext = null,
                    .flags = 0,
                    .dynamicStateCount = @intCast(dynamicStates.len),
                    .pDynamicStates = dynamicStates.ptr,
                },
                .layout = pipelineLayout,
                .renderPass = renderPass,
                .subpass = 0,
                .basePipelineHandle = null,
                .basePipelineIndex = -1,
                .pTessellationState = null,
                .pDepthStencilState = null,
            },
            null,
            &blendDarkenGraphicsPipeline,
        ));
        errdefer c.vkDestroyPipeline(logicalDevice, blendDarkenGraphicsPipeline, null);

        var elements = try ResizableStorageBuffer(ElementRenderingData).init(
            logicalDevice,
            physicalDevice,
            1,
            0,
        );
        errdefer elements.deinit(logicalDevice);

        var gradientStops = try ResizableStorageBuffer(GradientStop).init(
            logicalDevice,
            physicalDevice,
            1,
            2,
        );
        errdefer gradientStops.deinit(logicalDevice);

        const poolSizes = [_]c.VkDescriptorPoolSize{
            .{
                .type = c.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
                .descriptorCount = maxFramesInFlight * 2,
            },
            .{
                .type = c.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
                .descriptorCount = maxFramesInFlight * maxImages,
            },
        };

        var descriptorPool: c.VkDescriptorPool = undefined;
        try ensureNoError(c.vkCreateDescriptorPool(logicalDevice, &c.VkDescriptorPoolCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO,
            .poolSizeCount = poolSizes.len,
            .maxSets = maxFramesInFlight,
            .pPoolSizes = &poolSizes,
            .flags = c.VK_DESCRIPTOR_POOL_CREATE_UPDATE_AFTER_BIND_BIT,
            .pNext = null,
        }, null, &descriptorPool));

        var descriptorSets: [maxFramesInFlight]c.VkDescriptorSet = undefined;
        try ensureNoError(c.vkAllocateDescriptorSets(logicalDevice, &c.VkDescriptorSetAllocateInfo{
            .sType = c.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO,
            .descriptorPool = descriptorPool,
            .descriptorSetCount = maxFramesInFlight,
            .pSetLayouts = &([1]c.VkDescriptorSetLayout{shaderBufferDescriptorSetLayout} ** maxFramesInFlight),
        }, &descriptorSets));

        for (0..maxFramesInFlight) |i| {
            elements.writeDescriptor(logicalDevice, descriptorSets[i], i);
            gradientStops.writeDescriptor(logicalDevice, descriptorSets[i], i);
        }

        var sampler: c.VkSampler = undefined;
        try ensureNoError(c.vkCreateSampler(logicalDevice, &c.VkSamplerCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_SAMPLER_CREATE_INFO,
            .magFilter = c.VK_FILTER_LINEAR,
            .minFilter = c.VK_FILTER_LINEAR,
            .addressModeU = c.VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE,
            .addressModeV = c.VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE,
            .addressModeW = c.VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE,
            .anisotropyEnable = c.VK_FALSE,
            .maxAnisotropy = 1.0,
            .borderColor = c.VK_BORDER_COLOR_INT_OPAQUE_WHITE,
            .unnormalizedCoordinates = c.VK_FALSE,
            .compareEnable = c.VK_FALSE,
            .compareOp = c.VK_COMPARE_OP_ALWAYS,
            .mipmapMode = c.VK_SAMPLER_MIPMAP_MODE_LINEAR,
            .mipLodBias = 0.0,
            .minLod = 0.0,
            .maxLod = c.VK_LOD_CLAMP_NONE,
            .pNext = null,
            .flags = 0,
        }, null, &sampler));

        return ElementsPipeline{
            .allocator = allocator,
            .logicalDevice = logicalDevice,
            .physicalDevice = physicalDevice,

            .pipelineLayout = pipelineLayout,
            .blendAddGraphicsPipeline = blendAddGraphicsPipeline,
            .blendMultiplyGraphicsPipeline = blendMultiplyGraphicsPipeline,
            .blendDarkenGraphicsPipeline = blendDarkenGraphicsPipeline,

            .shaderBufferDescriptorSetLayout = shaderBufferDescriptorSetLayout,
            .elements = elements,
            .gradientStops = gradientStops,
            .descriptorSets = descriptorSets,
            .descriptorPool = descriptorPool,
            .sampler = sampler,
            .registeredImages = try std.ArrayList(*const Image).initCapacity(allocator, 16),
        };
    }

    fn ensureCapacity(self: *@This(), requiredElements: usize, requiredGradientStops: usize, frameIndex: usize) !void {
        try self.elements.ensureCapacity(
            self.logicalDevice,
            self.physicalDevice,
            self.descriptorSets[frameIndex],
            requiredElements,
            frameIndex,
        );
        try self.gradientStops.ensureCapacity(
            self.logicalDevice,
            self.physicalDevice,
            self.descriptorSets[frameIndex],
            requiredGradientStops,
            frameIndex,
        );
    }

    fn registerImage(self: *@This(), image: *Image, logicalDevice: c.VkDevice) !u32 {
        for (self.registeredImages.items, 0..) |registered, i| {
            if (registered == image) return @intCast(i);
        }

        const index = self.registeredImages.items.len;
        if (index >= ElementsPipeline.maxImages) return error.TooManyImages;

        if (!image.loaded) {
            try image.load();
        }

        try self.registeredImages.append(self.allocator, image);

        for (0..maxFramesInFlight) |frameIndex| {
            const imageInfo = c.VkDescriptorImageInfo{
                .imageLayout = c.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
                .imageView = image.imageView,
                .sampler = self.sampler,
            };

            const descriptorWrite = c.VkWriteDescriptorSet{
                .sType = c.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
                .pNext = null,
                .dstSet = self.descriptorSets[frameIndex],
                .dstBinding = 1,
                .dstArrayElement = @intCast(index),
                .descriptorCount = 1,
                .descriptorType = c.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
                .pImageInfo = &imageInfo,
                .pBufferInfo = null,
                .pTexelBufferView = null,
            };

            c.vkUpdateDescriptorSets(logicalDevice, 1, &descriptorWrite, 0, null);
        }

        return @intCast(index);
    }

    fn draw(
        self: *@This(),
        layerInterval: LayerInterval,
        blendMode: BlendMode,
        frameIndex: usize,
        commandBuffer: c.VkCommandBuffer,
        rectangleModel: *Model,
    ) void {
        const graphicsPipeline = switch (blendMode) {
            .darken => self.blendDarkenGraphicsPipeline,
            .multiply => self.blendMultiplyGraphicsPipeline,
            .normal => self.blendAddGraphicsPipeline,
        };
        c.vkCmdBindPipeline(
            commandBuffer,
            c.VK_PIPELINE_BIND_POINT_GRAPHICS,
            graphicsPipeline,
        );
        c.vkCmdBindDescriptorSets(
            commandBuffer,
            c.VK_PIPELINE_BIND_POINT_GRAPHICS,
            self.pipelineLayout,
            0,
            1,
            &self.descriptorSets[frameIndex],
            0,
            null,
        );
        c.vkCmdBindVertexBuffers(
            commandBuffer,
            0,
            1,
            &rectangleModel.vertexBuffer.handle,
            &@intCast(0),
        );
        c.vkCmdDraw(
            commandBuffer,
            rectangleModel.vertexCount,
            @intCast(layerInterval.end - layerInterval.start + 1),
            0,
            @intCast(layerInterval.start),
        );
    }

    fn deinit(self: *@This(), logicalDevice: c.VkDevice) void {
        self.registeredImages.deinit(self.allocator);

        c.vkDestroySampler(logicalDevice, self.sampler, null);
        c.vkDestroyDescriptorPool(logicalDevice, self.descriptorPool, null);

        self.elements.deinit(logicalDevice);
        self.gradientStops.deinit(logicalDevice);

        c.vkDestroyDescriptorSetLayout(logicalDevice, self.shaderBufferDescriptorSetLayout, null);
        c.vkDestroyPipeline(logicalDevice, self.blendAddGraphicsPipeline, null);
        c.vkDestroyPipeline(logicalDevice, self.blendMultiplyGraphicsPipeline, null);
        c.vkDestroyPipeline(logicalDevice, self.blendDarkenGraphicsPipeline, null);
        c.vkDestroyPipelineLayout(logicalDevice, self.pipelineLayout, null);
    }
};

const TextPipeline = struct {
    const GlyphPageKeyContext = struct {
        pub fn hash(_: @This(), key: GlyphPageKey) u64 {
            var hasher = std.hash.Wyhash.init(0);
            // GlyphPageKey uses f32, which doesn't generally have a unique
            // representation, meaning this hash can be non-unique, but
            // since the values for font size are always >= 0, we know this
            // is then unique.
            hasher.update(std.mem.asBytes(&key));
            return hasher.final();
        }
        pub fn eql(_: @This(), a: GlyphPageKey, b: GlyphPageKey) bool {
            return std.meta.eql(a, b);
        }
    };

    // GlyphPageKey carries the font size as an f32, so an animated size mints a
    // distinct page every frame. Pages were never evicted, so scrolling text
    // whose size animates leaked one ~18KB page per intermediate size without
    // bound. Cap the cache and drop the least-recently-used page (reclaiming its
    // atlas rectangles) once full, so memory stays flat. Pages are boxed: the
    // LRU stores pointers, so growth never reallocates a value array of inline
    // 18KB pages.
    const pageCacheCapacity = 64;
    const GlyphPageCache = Font.LRU(GlyphPageKey, *GlyphPage, pageCacheCapacity, GlyphPageKeyContext);

    logicalDevice: c.VkDevice,
    physicalDevice: c.VkPhysicalDevice,

    pipelineLayout: c.VkPipelineLayout,
    graphicsPipeline: c.VkPipeline,

    descriptorSetLayout: c.VkDescriptorSetLayout,
    descriptorPool: c.VkDescriptorPool,
    descriptorSets: [maxFramesInFlight]c.VkDescriptorSet,

    fontTextureAtlas: FontTextureAtlas,
    allocator: std.mem.Allocator,
    glyphPageCache: GlyphPageCache,
    needsAtlasReset: bool = false,
    sampler: c.VkSampler,

    glyphs: ResizableStorageBuffer(GlypRenderingShaderData),

    const GlyphRenderingData = struct {
        textureCoordinates: FontTextureAtlas.TextureCoordinates,
        bitmapWidth: u32,
        bitmapHeight: u32,
        bitmapLeft: i32,
        bitmapTop: i32,
    };

    const GlyphPageKey = struct {
        fontSize: f32,
        fontWeight: u32,
        fontKey: u64,
    };

    const GlyphPage = Font.LRU(c_uint, GlyphRenderingData, 256, std.hash_map.AutoContext(c_uint));

    const GlypRenderingShaderData = extern struct {
        // std430 layout (must match shaders/text/vertex.vert):
        // position @0, size @8, color @16, uvOffset @32, uvSize @40, stride 48.
        // The orthographic projection is no longer baked per glyph; it is applied
        // in the vertex shader via a push constant. See TextPipeline.draw.
        position: [2]f32,
        size: [2]f32,
        color: Vec4,
        uvOffset: [2]f32,
        uvSize: [2]f32,
    };

    const textVertexShader: []const u32 = @ptrCast(@alignCast(@embedFile("text_vertex_shader")));
    const textFragmentShader: []const u32 = @ptrCast(@alignCast(@embedFile("text_fragment_shader")));

    fn init(
        allocator: std.mem.Allocator,
        logicalDevice: c.VkDevice,
        physicalDevice: c.VkPhysicalDevice,
        graphicsQueue: c.VkQueue,
        commandPool: c.VkCommandPool,
        renderPass: c.VkRenderPass,
    ) !@This() {
        var vertexShaderModule: c.VkShaderModule = undefined;
        try ensureNoError(c.vkCreateShaderModule(
            logicalDevice,
            &c.VkShaderModuleCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO,
                .pNext = null,
                .flags = 0,
                .codeSize = @sizeOf(u32) * textVertexShader.len,
                .pCode = textVertexShader.ptr,
            },
            null,
            &vertexShaderModule,
        ));
        defer c.vkDestroyShaderModule(logicalDevice, vertexShaderModule, null);

        var fragmentShaderModule: c.VkShaderModule = undefined;
        try ensureNoError(c.vkCreateShaderModule(
            logicalDevice,
            &c.VkShaderModuleCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO,
                .pNext = null,
                .flags = 0,
                .codeSize = @sizeOf(u32) * textFragmentShader.len,
                .pCode = textFragmentShader.ptr,
            },
            null,
            &fragmentShaderModule,
        ));
        defer c.vkDestroyShaderModule(logicalDevice, fragmentShaderModule, null);

        const shaderStages: []const c.VkPipelineShaderStageCreateInfo = &.{
            c.VkPipelineShaderStageCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
                .pNext = null,
                .flags = 0,
                .stage = c.VK_SHADER_STAGE_VERTEX_BIT,
                .module = vertexShaderModule,
                .pName = "main",
                .pSpecializationInfo = null,
            },
            c.VkPipelineShaderStageCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
                .pNext = null,
                .flags = 0,
                .stage = c.VK_SHADER_STAGE_FRAGMENT_BIT,
                .module = fragmentShaderModule,
                .pName = "main",
                .pSpecializationInfo = null,
            },
        };

        const dynamicStates: []const c.VkDynamicState = &.{
            c.VK_DYNAMIC_STATE_VIEWPORT,
            c.VK_DYNAMIC_STATE_SCISSOR,
        };

        const bindings = [_]c.VkDescriptorSetLayoutBinding{
            .{
                .binding = 0,
                .descriptorType = c.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
                .descriptorCount = 1,
                .stageFlags = c.VK_SHADER_STAGE_VERTEX_BIT,
                .pImmutableSamplers = null,
            },
            .{
                .binding = 1,
                .descriptorType = c.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
                .descriptorCount = 1,
                .stageFlags = c.VK_SHADER_STAGE_FRAGMENT_BIT,
                .pImmutableSamplers = null,
            },
        };

        var descriptorSetLayout: c.VkDescriptorSetLayout = undefined;
        try ensureNoError(c.vkCreateDescriptorSetLayout(
            logicalDevice,
            &c.VkDescriptorSetLayoutCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
                .pNext = null,
                .flags = 0,
                .bindingCount = bindings.len,
                .pBindings = &bindings,
            },
            null,
            &descriptorSetLayout,
        ));

        // The vertex shader reads the frame-constant projection matrix from a
        // push constant rather than a baked per-glyph mat4.
        const pushConstantRange = c.VkPushConstantRange{
            .stageFlags = c.VK_SHADER_STAGE_VERTEX_BIT,
            .offset = 0,
            .size = @sizeOf(zmath.Mat),
        };
        var pipelineLayout: c.VkPipelineLayout = undefined;
        try ensureNoError(c.vkCreatePipelineLayout(
            logicalDevice,
            &c.VkPipelineLayoutCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO,
                .pNext = null,
                .flags = 0,
                .setLayoutCount = 1,
                .pSetLayouts = &descriptorSetLayout,
                .pushConstantRangeCount = 1,
                .pPushConstantRanges = &pushConstantRange,
            },
            null,
            &pipelineLayout,
        ));
        errdefer c.vkDestroyPipelineLayout(logicalDevice, pipelineLayout, null);

        const bindingDescription = Vertex.getBindingDescription();
        const attributeDescriptions = Vertex.getAttributeDescriptions();

        var graphicsPipeline: c.VkPipeline = undefined;
        try ensureNoError(c.vkCreateGraphicsPipelines(
            logicalDevice,
            null,
            1,
            &c.VkGraphicsPipelineCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO,
                .pNext = null,
                .stageCount = @intCast(shaderStages.len),
                .pStages = shaderStages.ptr,
                .pVertexInputState = &c.VkPipelineVertexInputStateCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
                    .pNext = null,
                    .flags = 0,
                    .vertexBindingDescriptionCount = 1,
                    .pVertexBindingDescriptions = &bindingDescription,
                    .vertexAttributeDescriptionCount = attributeDescriptions.len,
                    .pVertexAttributeDescriptions = &attributeDescriptions,
                },
                .pInputAssemblyState = &c.VkPipelineInputAssemblyStateCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO,
                    .pNext = null,
                    .flags = 0,
                    .topology = c.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
                    .primitiveRestartEnable = c.VK_FALSE,
                },
                .pViewportState = &c.VkPipelineViewportStateCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO,
                    .pNext = null,
                    .flags = 0,
                    .viewportCount = 1,
                    .scissorCount = 1,
                },
                .pRasterizationState = &c.VkPipelineRasterizationStateCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO,
                    .pNext = null,
                    .flags = 0,
                    .depthClampEnable = c.VK_FALSE,
                    .rasterizerDiscardEnable = c.VK_FALSE,
                    .polygonMode = c.VK_POLYGON_MODE_FILL,
                    .cullMode = c.VK_CULL_MODE_BACK_BIT,
                    .frontFace = c.VK_FRONT_FACE_CLOCKWISE,
                    .lineWidth = 1.0,
                    .depthBiasEnable = c.VK_FALSE,
                    .depthBiasConstantFactor = 0.0,
                    .depthBiasClamp = 0.0,
                    .depthBiasSlopeFactor = 0.0,
                },
                .pMultisampleState = &c.VkPipelineMultisampleStateCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO,
                    .sampleShadingEnable = c.VK_FALSE,
                    .rasterizationSamples = c.VK_SAMPLE_COUNT_1_BIT,
                    .minSampleShading = 1.0,
                    .pSampleMask = null,
                    .alphaToCoverageEnable = c.VK_FALSE,
                    .alphaToOneEnable = c.VK_FALSE,
                    .pNext = null,
                    .flags = 0,
                },
                // Dual-source blending for subpixel text rendering:
                // Fragment shader outputs two colors at location 0 (index 0 and index 1)
                // - index 0: pre-multiplied text color (text_color.rgb * coverage.rgb)
                // - index 1: blend weights (text_color.a * coverage.rgb for per-channel blending)
                // Blend equation: result = src * ONE + dst * (1 - src1_color)
                .pColorBlendState = &c.VkPipelineColorBlendStateCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO,
                    .pNext = null,
                    .flags = 0,
                    .logicOpEnable = c.VK_FALSE,
                    .logicOp = c.VK_LOGIC_OP_COPY,
                    .attachmentCount = 1,
                    .pAttachments = &c.VkPipelineColorBlendAttachmentState{
                        .colorWriteMask = c.VK_COLOR_COMPONENT_R_BIT | c.VK_COLOR_COMPONENT_G_BIT | c.VK_COLOR_COMPONENT_B_BIT | c.VK_COLOR_COMPONENT_A_BIT,
                        .blendEnable = c.VK_TRUE,
                        // Dual-source blending: use SRC1_COLOR from fragment shader's second output
                        .srcColorBlendFactor = c.VK_BLEND_FACTOR_ONE,
                        .dstColorBlendFactor = c.VK_BLEND_FACTOR_ONE_MINUS_SRC1_COLOR,
                        .colorBlendOp = c.VK_BLEND_OP_ADD,
                        .srcAlphaBlendFactor = c.VK_BLEND_FACTOR_ONE,
                        .dstAlphaBlendFactor = c.VK_BLEND_FACTOR_ONE_MINUS_SRC1_ALPHA,
                        .alphaBlendOp = c.VK_BLEND_OP_ADD,
                    },
                    .blendConstants = .{ 0.0, 0.0, 0.0, 0.0 },
                },
                .pDynamicState = &c.VkPipelineDynamicStateCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_PIPELINE_DYNAMIC_STATE_CREATE_INFO,
                    .pNext = null,
                    .flags = 0,
                    .dynamicStateCount = @intCast(dynamicStates.len),
                    .pDynamicStates = dynamicStates.ptr,
                },
                .layout = pipelineLayout,
                .renderPass = renderPass,
                .subpass = 0,
                .basePipelineHandle = null,
                .basePipelineIndex = -1,
            },
            null,
            &graphicsPipeline,
        ));
        errdefer c.vkDestroyPipeline(logicalDevice, graphicsPipeline, null);

        var glyphs = try ResizableStorageBuffer(GlypRenderingShaderData).init(
            logicalDevice,
            physicalDevice,
            1,
            0,
        );
        errdefer glyphs.deinit(logicalDevice);

        var fontTextureAtlas = try FontTextureAtlas.init(
            allocator,
            logicalDevice,
            physicalDevice,
            commandPool,
            graphicsQueue,
        );
        errdefer fontTextureAtlas.deinit(allocator, logicalDevice);

        const poolSizes = [_]c.VkDescriptorPoolSize{
            .{
                .type = c.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
                .descriptorCount = maxFramesInFlight,
            },
            .{
                .type = c.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
                .descriptorCount = maxFramesInFlight,
            },
        };

        var descriptorPool: c.VkDescriptorPool = undefined;
        try ensureNoError(c.vkCreateDescriptorPool(logicalDevice, &c.VkDescriptorPoolCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO,
            .poolSizeCount = poolSizes.len,
            .maxSets = maxFramesInFlight,
            .pPoolSizes = &poolSizes,
            .flags = 0,
            .pNext = null,
        }, null, &descriptorPool));

        var descriptorSets: [maxFramesInFlight]c.VkDescriptorSet = undefined;
        try ensureNoError(c.vkAllocateDescriptorSets(logicalDevice, &c.VkDescriptorSetAllocateInfo{
            .sType = c.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO,
            .descriptorPool = descriptorPool,
            .descriptorSetCount = maxFramesInFlight,
            .pSetLayouts = &([1]c.VkDescriptorSetLayout{descriptorSetLayout} ** maxFramesInFlight),
        }, &descriptorSets));

        var sampler: c.VkSampler = undefined;
        try ensureNoError(c.vkCreateSampler(logicalDevice, &c.VkSamplerCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_SAMPLER_CREATE_INFO,
            .magFilter = c.VK_FILTER_NEAREST,
            .minFilter = c.VK_FILTER_NEAREST,
            .addressModeU = c.VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE,
            .addressModeV = c.VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE,
            .addressModeW = c.VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE,
            .anisotropyEnable = c.VK_FALSE,
            .maxAnisotropy = 1.0,
            .borderColor = c.VK_BORDER_COLOR_INT_OPAQUE_BLACK,
            .unnormalizedCoordinates = c.VK_FALSE,
            .compareEnable = c.VK_FALSE,
            .compareOp = c.VK_COMPARE_OP_ALWAYS,
            .mipmapMode = c.VK_SAMPLER_MIPMAP_MODE_NEAREST,
            .mipLodBias = 0.0,
            .minLod = 0.0,
            .maxLod = 0.0,
            .pNext = null,
            .flags = 0,
        }, null, &sampler));

        for (0..maxFramesInFlight) |i| {
            glyphs.writeDescriptor(logicalDevice, descriptorSets[i], i);

            const imageInfo = c.VkDescriptorImageInfo{
                .imageLayout = c.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
                .imageView = fontTextureAtlas.imageView,
                .sampler = sampler,
            };

            const descriptorWrites = [_]c.VkWriteDescriptorSet{
                .{
                    .sType = c.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
                    .pNext = null,
                    .dstSet = descriptorSets[i],
                    .dstBinding = 1,
                    .dstArrayElement = 0,
                    .descriptorCount = 1,
                    .descriptorType = c.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
                    .pImageInfo = &imageInfo,
                    .pBufferInfo = null,
                    .pTexelBufferView = null,
                },
            };

            c.vkUpdateDescriptorSets(logicalDevice, descriptorWrites.len, &descriptorWrites, 0, null);
        }

        return TextPipeline{
            .logicalDevice = logicalDevice,
            .physicalDevice = physicalDevice,

            .pipelineLayout = pipelineLayout,
            .graphicsPipeline = graphicsPipeline,

            .descriptorSetLayout = descriptorSetLayout,
            .glyphs = glyphs,
            .descriptorSets = descriptorSets,
            .descriptorPool = descriptorPool,

            .allocator = allocator,
            .glyphPageCache = try GlyphPageCache.init(allocator),
            .fontTextureAtlas = fontTextureAtlas,
            .sampler = sampler,
        };
    }

    fn ensureCapacity(self: *@This(), required: usize, frameIndex: usize) !void {
        try self.glyphs.ensureCapacity(
            self.logicalDevice,
            self.physicalDevice,
            self.descriptorSets[frameIndex],
            required,
            frameIndex,
        );
    }

    /// Shared by both eviction paths (a whole page evicted from the page
    /// cache, or a single glyph evicted from a page) so atlas space is
    /// always handed back the same way.
    fn reclaimGlyph(self: *@This(), data: GlyphRenderingData) !void {
        try self.fontTextureAtlas.reclaim(.{
            .u = @intFromFloat(data.textureCoordinates.u),
            .v = @intFromFloat(data.textureCoordinates.v),
            .width = data.bitmapWidth,
            .height = data.bitmapHeight,
        });
    }

    fn getOrCreateGlyphPage(self: *@This(), key: GlyphPageKey) !*GlyphPage {
        if (self.glyphPageCache.getMut(key)) |entry| return entry.value;

        const page = try self.allocator.create(GlyphPage);
        page.* = try GlyphPage.init(self.allocator);
        const putResult = self.glyphPageCache.put(key, page);
        if (putResult.evicted) |evicted| {
            for (evicted.value.entries[0..evicted.value.length]) |glyphEntry| {
                try self.reclaimGlyph(glyphEntry.value);
            }
            evicted.value.deinit();
            self.allocator.destroy(evicted.value);
        }
        return page;
    }

    /// Null means the atlas is full (`needsAtlasReset` is set); callers
    /// should skip this glyph for the current frame.
    fn getOrRasterizeGlyph(
        self: *@This(),
        glyphPage: *GlyphPage,
        font: *Font,
        fontSize: f32,
        fontWeight: u32,
        glyphIndex: c_uint,
        arena: std.mem.Allocator,
    ) !?GlyphRenderingData {
        if (glyphPage.get(glyphIndex)) |entry| return entry.value;

        // TODO: render glyphs in the GPU using the font texture atlas as frame buffer
        try font.setWeight(fontWeight, arena);
        const rasterizedGlyph = try font.rasterize(glyphIndex, fontSize);

        const textureCoordinates = self.fontTextureAtlas.upload(
            rasterizedGlyph.bitmap,
            @intCast(rasterizedGlyph.width),
            @intCast(rasterizedGlyph.height),
            @intCast(@abs(rasterizedGlyph.pitch)),
        ) catch |err| switch (err) {
            error.MaximumTextureAtlasSizeReached => {
                self.needsAtlasReset = true;
                return null;
            },
            else => return err,
        };
        const pixelWidth = rasterizedGlyph.width / 3;
        const data = GlyphRenderingData{
            .bitmapTop = @intCast(rasterizedGlyph.top),
            .bitmapLeft = @intCast(rasterizedGlyph.left),
            .bitmapWidth = @intCast(pixelWidth),
            .bitmapHeight = @intCast(rasterizedGlyph.height),
            .textureCoordinates = textureCoordinates,
        };
        const putResult = glyphPage.put(glyphIndex, data);
        if (putResult.evicted) |evicted| {
            try self.reclaimGlyph(evicted.value);
        }
        return data;
    }

    fn draw(
        self: *@This(),
        layerInterval: LayerInterval,
        frameIndex: usize,
        commandBuffer: c.VkCommandBuffer,
        rectangleModel: *Model,
        projection: zmath.Mat,
    ) void {
        c.vkCmdBindPipeline(
            commandBuffer,
            c.VK_PIPELINE_BIND_POINT_GRAPHICS,
            self.graphicsPipeline,
        );

        c.vkCmdPushConstants(
            commandBuffer,
            self.pipelineLayout,
            c.VK_SHADER_STAGE_VERTEX_BIT,
            0,
            @sizeOf(zmath.Mat),
            @ptrCast(&projection),
        );

        c.vkCmdBindDescriptorSets(
            commandBuffer,
            c.VK_PIPELINE_BIND_POINT_GRAPHICS,
            self.pipelineLayout,
            0,
            1,
            &self.descriptorSets[frameIndex],
            0,
            null,
        );

        c.vkCmdBindVertexBuffers(
            commandBuffer,
            0,
            1,
            &rectangleModel.vertexBuffer.handle,
            &@intCast(0),
        );
        c.vkCmdDraw(
            commandBuffer,
            rectangleModel.vertexCount,
            @intCast(layerInterval.end - layerInterval.start + 1),
            0,
            @intCast(layerInterval.start),
        );
    }

    fn deinit(self: *@This(), logicalDevice: c.VkDevice, allocator: std.mem.Allocator) void {
        c.vkDestroyDescriptorPool(logicalDevice, self.descriptorPool, null);
        self.fontTextureAtlas.deinit(allocator, logicalDevice);
        c.vkDestroySampler(logicalDevice, self.sampler, null);
        for (self.glyphPageCache.entries[0..self.glyphPageCache.length]) |*entry| {
            entry.value.deinit();
            allocator.destroy(entry.value);
        }
        self.glyphPageCache.deinit();

        self.glyphs.deinit(logicalDevice);

        c.vkDestroyDescriptorSetLayout(logicalDevice, self.descriptorSetLayout, null);
        c.vkDestroyPipeline(logicalDevice, self.graphicsPipeline, null);
        c.vkDestroyPipelineLayout(logicalDevice, self.pipelineLayout, null);
    }
};

const maxFramesInFlight = 2;

pub const FrameRateCapper = struct {
    lastFrameEnd: ?std.Io.Clock.Timestamp = null,

    pub fn cap(self: *@This(), io: std.Io, targetFrameTimeNs: u64) !void {
        if (self.lastFrameEnd) |lastFrameEnd| {
            const now = std.Io.Clock.Timestamp.now(io, .awake);
            const elapsed = lastFrameEnd.durationTo(now);
            const elapsedNs: u64 = @intCast(@max(0, elapsed.raw.toNanoseconds()));
            if (elapsedNs < targetFrameTimeNs) {
                const sleepNs: i96 = @intCast(targetFrameTimeNs - elapsedNs);
                try io.sleep(.{ .nanoseconds = sleepNs }, .awake);
            }
        }
        self.lastFrameEnd = std.Io.Clock.Timestamp.now(io, .awake);
    }
};

pub const Renderer = struct {
    const Self = @This();

    mutex: std.Io.Mutex,

    allocator: std.mem.Allocator,
    graphics: *const Graphics,

    physicalDevice: c.VkPhysicalDevice,
    logicalDevice: c.VkDevice,
    graphicsQueue: c.VkQueue,
    graphicsQueueFamilyIndex: u32,
    presentationQueue: c.VkQueue,
    presentationQueueFamilyIndex: u32,

    surface: c.VkSurfaceKHR,
    window: *Window,
    swapchain: Swapchain,
    // Mirror of `swapchain.extent`, packed as (width << 32 | height), so the
    // render thread can read the viewport size without contending `mutex` against
    // a swapchain recreate that may hold it for milliseconds.
    viewportExtent: std.atomic.Value(u64),

    elementsPipeline: ElementsPipeline,
    shadowsPipeline: ShadowsPipeline,
    textPipeline: TextPipeline,
    rectangleModel: Model,

    commandPool: c.VkCommandPool,
    commandBuffers: [maxFramesInFlight]c.VkCommandBuffer,

    inFlightFences: [maxFramesInFlight]c.VkFence,
    imageAvailableSemaphores: [maxFramesInFlight]c.VkSemaphore,
    renderFinishedSemaphores: []c.VkSemaphore,

    frameRateCapper: FrameRateCapper,
    executingFrame: bool,
    framesRenderedInSwapchain: usize,

    // Single-subpass render pass the swapchain framebuffers and all three pipelines are built against.
    // Stable across resizes (depends only on the surface format), so it is created once.
    renderPass: c.VkRenderPass,

    fn recreateSwapchain(self: *Self, width: u32, height: u32) !void {
        std.log.debug("swapchain recreation has began", .{});
        const timestamp = @divTrunc(std.Io.Clock.awake.now(root.getForbear().io).toNanoseconds(), std.time.ns_per_ms);

        const previousSwapchain = self.swapchain;
        const recreateStart = @divTrunc(std.Io.Clock.awake.now(root.getForbear().io).toNanoseconds(), std.time.ns_per_ms);
        if (builtin.os.tag == .windows) {
            // On Windows, there is a stupid hell of a bug, probably because
            // we're using a rendering thread, that makes it so
            // vkAcquireNextImageKHR takes 2 seconds after the swapchain
            // recreation, unless we recreate the surface which is wasteful and
            // very annoying but is the only way to get a reasonable experience
            // on Windows.
            previousSwapchain.deinit(self.logicalDevice);
            c.vkDestroySurfaceKHR(self.graphics.vulkanInstance, self.surface, null);
            try ensureNoError(vkCreateWin32SurfaceKHR(
                self.graphics.vulkanInstance,
                &VkWin32SurfaceCreateInfoKHR{
                    .sType = c.VK_STRUCTURE_TYPE_WIN32_SURFACE_CREATE_INFO_KHR,
                    .pNext = null,
                    .flags = 0,
                    .hinstance = self.window.hInstance,
                    .hwnd = self.window.handle,
                },
                null,
                &self.surface,
            ));
            self.swapchain = try Swapchain.init(
                self.allocator,
                self.physicalDevice,
                self.logicalDevice,
                self.surface,
                width,
                height,
                null,
            );
        } else {
            self.swapchain = try Swapchain.init(
                self.allocator,
                self.physicalDevice,
                self.logicalDevice,
                self.surface,
                width,
                height,
                previousSwapchain,
            );
            previousSwapchain.deinit(self.logicalDevice);
        }
        errdefer self.swapchain.deinit(self.logicalDevice);
        try self.swapchain.createFramebuffers(self.logicalDevice, self.renderPass);
        std.log.debug("spent {d}ms just recreating swapchain", .{@divTrunc(std.Io.Clock.awake.now(root.getForbear().io).toNanoseconds(), std.time.ns_per_ms) - recreateStart});

        std.log.debug("swapchain recreation took {d}ms", .{@divTrunc(std.Io.Clock.awake.now(root.getForbear().io).toNanoseconds(), std.time.ns_per_ms) - timestamp});

        for (0..maxFramesInFlight) |i| {
            c.vkDestroyFence(self.logicalDevice, self.inFlightFences[i], null);
            try ensureNoError(c.vkCreateFence(
                self.logicalDevice,
                &c.VkFenceCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO,
                    .flags = c.VK_FENCE_CREATE_SIGNALED_BIT,
                    .pNext = null,
                },
                null,
                &self.inFlightFences[i],
            ));

            c.vkDestroySemaphore(self.logicalDevice, self.imageAvailableSemaphores[i], null);
            try ensureNoError(c.vkCreateSemaphore(
                self.logicalDevice,
                &c.VkSemaphoreCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO,
                    .flags = 0,
                    .pNext = null,
                },
                null,
                &self.imageAvailableSemaphores[i],
            ));
        }

        for (self.renderFinishedSemaphores) |semaphore| {
            c.vkDestroySemaphore(self.logicalDevice, semaphore, null);
        }
        self.renderFinishedSemaphores = try self.allocator.realloc(self.renderFinishedSemaphores, self.swapchain.images.len);
        errdefer self.allocator.free(self.renderFinishedSemaphores);

        for (self.renderFinishedSemaphores) |*semaphore| {
            try ensureNoError(c.vkCreateSemaphore(
                self.logicalDevice,
                &c.VkSemaphoreCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO,
                    .flags = 0,
                    .pNext = null,
                },
                null,
                semaphore,
            ));
        }
        errdefer {
            for (self.renderFinishedSemaphores) |semaphore| {
                c.vkDestroySemaphore(self.logicalDevice, semaphore, null);
            }
        }
        self.framesRenderedInSwapchain = 0;
        self.viewportExtent.store((@as(u64, self.swapchain.extent.width) << 32) | self.swapchain.extent.height, .release);
    }

    pub fn viewportSize(self: *Self) Vec2 {
        const packed_extent = self.viewportExtent.load(.acquire);
        return .{ @floatFromInt(packed_extent >> 32), @floatFromInt(@as(u32, @truncate(packed_extent))) };
    }

    fn init(
        surface: c.VkSurfaceKHR,
        window: *Window,
        graphics: *const Graphics,
    ) !Renderer {
        const requiredDeviceExtensions: []const [*c]const u8 = &(.{
            c.VK_KHR_SWAPCHAIN_EXTENSION_NAME,
            // We target Vulkan 1.1. Drawing goes through a classic VkRenderPass (core 1.0), so the only
            // thing we pull in as an extension is descriptor indexing (core 1.2) for the bindless
            // sampled-image array. The shaders are all 32-bit, so no shaderInt8/16/64 dependency.
            c.VK_EXT_DESCRIPTOR_INDEXING_EXTENSION_NAME,
        } ++ switch (builtin.os.tag) {
            .macos => .{
                "VK_KHR_portability_subset",
            },
            else => .{},
        });

        var preferred: ?struct {
            device: DeviceInformation,
            graphicsQueueFamilyIndex: u32,
            presentationQueueFamilyIndex: u32,
            score: usize,
        } = null;
        blk: for (graphics.devices) |device| {
            if (device.deviceProperties.apiVersion < c.VK_API_VERSION_1_1) {
                std.log.info("Skipping device '{s}': Vulkan 1.1 is required", .{
                    std.mem.sliceTo(device.deviceProperties.deviceName[0..], 0),
                });
                continue :blk;
            }

            for (requiredDeviceExtensions) |extension| {
                const extensionSlice = std.mem.span(extension);
                var supported = false;
                for (device.availableDeviceExtensions) |availableExtension| {
                    const availableExtensionSlice = availableExtension.extensionName[0..extensionSlice.len];
                    if (std.mem.eql(u8, availableExtensionSlice, extensionSlice)) {
                        supported = true;
                        break;
                    }
                }
                if (supported == false) {
                    std.log.info("Skipping device '{s}': missing required extension '{s}'", .{
                        std.mem.sliceTo(device.deviceProperties.deviceName[0..], 0),
                        extensionSlice,
                    });
                    continue :blk;
                }
            }

            var descriptorIndexingFeatures = c.VkPhysicalDeviceDescriptorIndexingFeaturesEXT{
                .sType = c.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DESCRIPTOR_INDEXING_FEATURES_EXT,
            };
            var deviceFeatures2 = c.VkPhysicalDeviceFeatures2{
                .sType = c.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2,
                .pNext = &descriptorIndexingFeatures,
            };
            c.vkGetPhysicalDeviceFeatures2(device.physicalDevice, &deviceFeatures2);

            // There is no aggregate `descriptorIndexing` bit in the EXT struct; the extension being
            // present (checked above) is what stands in for it, then we verify the specific bits we use.
            if (descriptorIndexingFeatures.shaderSampledImageArrayNonUniformIndexing != c.VK_TRUE or
                descriptorIndexingFeatures.descriptorBindingPartiallyBound != c.VK_TRUE or
                descriptorIndexingFeatures.descriptorBindingSampledImageUpdateAfterBind != c.VK_TRUE or
                descriptorIndexingFeatures.descriptorBindingUpdateUnusedWhilePending != c.VK_TRUE or
                descriptorIndexingFeatures.runtimeDescriptorArray != c.VK_TRUE)
            {
                std.log.info("Skipping device '{s}': missing required descriptor indexing features", .{
                    std.mem.sliceTo(device.deviceProperties.deviceName[0..], 0),
                });
                continue :blk;
            }

            if (deviceFeatures2.features.dualSrcBlend != c.VK_TRUE) {
                std.log.info("Skipping device '{s}': missing required base feature (dualSrcBlend)", .{
                    std.mem.sliceTo(device.deviceProperties.deviceName[0..], 0),
                });
                continue :blk;
            }

            var score: u32 = device.deviceProperties.limits.maxImageDimension2D;
            if (device.deviceProperties.deviceType == c.VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU) {
                score += 1000;
            }

            var graphicsQueueFamilyIndex: ?u32 = null;
            var presentationQueueFamilyIndex: ?u32 = null;
            for (device.queueFamilies, 0..) |queueFamily, index| {
                if ((queueFamily.queueFlags & c.VK_QUEUE_GRAPHICS_BIT) != 0) {
                    graphicsQueueFamilyIndex = @intCast(index);
                }

                var supportsPresentation: u32 = c.VK_FALSE;
                try ensureNoError(c.vkGetPhysicalDeviceSurfaceSupportKHR(
                    device.physicalDevice,
                    @intCast(index),
                    surface,
                    &supportsPresentation,
                ));

                if (supportsPresentation == c.VK_TRUE) {
                    presentationQueueFamilyIndex = @intCast(index);
                }

                if (graphicsQueueFamilyIndex != null and presentationQueueFamilyIndex != null) {
                    break;
                }
            }

            if (graphicsQueueFamilyIndex == null or presentationQueueFamilyIndex == null) {
                std.log.info("Skipping device '{s}': missing required queue family (graphics={}, presentation={})", .{
                    std.mem.sliceTo(device.deviceProperties.deviceName[0..], 0),
                    graphicsQueueFamilyIndex != null,
                    presentationQueueFamilyIndex != null,
                });
                continue;
            }

            if (graphicsQueueFamilyIndex.? == presentationQueueFamilyIndex.?) {
                score += 100;
            }

            if (preferred) |currentPreferred| {
                if (score > currentPreferred.score) {
                    preferred = .{
                        .device = device,
                        .graphicsQueueFamilyIndex = graphicsQueueFamilyIndex.?,
                        .presentationQueueFamilyIndex = presentationQueueFamilyIndex.?,
                        .score = score,
                    };
                }
            } else {
                preferred = .{
                    .device = device,
                    .graphicsQueueFamilyIndex = graphicsQueueFamilyIndex.?,
                    .presentationQueueFamilyIndex = presentationQueueFamilyIndex.?,
                    .score = score,
                };
            }
        }
        if (preferred == null) {
            return error.NoSuitablePhysicalDevice;
        }
        const physicalDevice = preferred.?.device.physicalDevice;
        const graphicsQueueFamilyIndex = preferred.?.graphicsQueueFamilyIndex;
        const presentationQueueFamilyIndex = preferred.?.presentationQueueFamilyIndex;

        const queueCreateInfos: []const c.VkDeviceQueueCreateInfo = if (graphicsQueueFamilyIndex == presentationQueueFamilyIndex) &.{.{
            .sType = c.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
            .pNext = null,
            .flags = 0,
            .queueFamilyIndex = graphicsQueueFamilyIndex,
            .queueCount = 1,
            .pQueuePriorities = &@as(f32, 1.0),
        }} else &.{
            .{
                .sType = c.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
                .pNext = null,
                .flags = 0,
                .queueFamilyIndex = graphicsQueueFamilyIndex,
                .queueCount = 1,
                .pQueuePriorities = &@as(f32, 1.0),
            },
            .{
                .sType = c.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
                .pNext = null,
                .flags = 0,
                .queueFamilyIndex = preferred.?.presentationQueueFamilyIndex,
                .queueCount = 1,
                .pQueuePriorities = &@as(f32, 1.0),
            },
        };

        var logicalDevice: c.VkDevice = undefined;
        var descriptorIndexingFeatures = c.VkPhysicalDeviceDescriptorIndexingFeaturesEXT{
            .sType = c.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DESCRIPTOR_INDEXING_FEATURES_EXT,
            .shaderSampledImageArrayNonUniformIndexing = c.VK_TRUE,
            .descriptorBindingPartiallyBound = c.VK_TRUE,
            .descriptorBindingSampledImageUpdateAfterBind = c.VK_TRUE,
            .descriptorBindingUpdateUnusedWhilePending = c.VK_TRUE,
            .runtimeDescriptorArray = c.VK_TRUE,
        };
        try ensureNoError(c.vkCreateDevice(
            physicalDevice,
            &c.VkDeviceCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
                .pNext = &descriptorIndexingFeatures,
                .flags = 0,
                .queueCreateInfoCount = @intCast(queueCreateInfos.len),
                .pQueueCreateInfos = queueCreateInfos.ptr,
                .pEnabledFeatures = &c.VkPhysicalDeviceFeatures{
                    .dualSrcBlend = c.VK_TRUE,
                },
                .ppEnabledExtensionNames = requiredDeviceExtensions.ptr,
                .enabledExtensionCount = @intCast(requiredDeviceExtensions.len),

                .enabledLayerCount = 0,
                .ppEnabledLayerNames = null,
            },
            null,
            &logicalDevice,
        ));
        errdefer c.vkDestroyDevice(logicalDevice, null);

        var graphicsQueue: c.VkQueue = undefined;
        c.vkGetDeviceQueue(logicalDevice, graphicsQueueFamilyIndex, 0, &graphicsQueue);
        var presentationQueue: c.VkQueue = undefined;
        c.vkGetDeviceQueue(logicalDevice, presentationQueueFamilyIndex, 0, &presentationQueue);

        var swapchain = try Swapchain.init(
            graphics.allocator,
            physicalDevice,
            logicalDevice,
            surface,
            window.width,
            window.height,
            null,
        );
        errdefer swapchain.deinit(logicalDevice);

        const renderPass = try createRenderPass(logicalDevice, swapchain.surfaceFormat.format);
        errdefer c.vkDestroyRenderPass(logicalDevice, renderPass, null);
        try swapchain.createFramebuffers(logicalDevice, renderPass);

        var commandPool: c.VkCommandPool = undefined;
        try ensureNoError(c.vkCreateCommandPool(
            logicalDevice,
            &c.VkCommandPoolCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
                .pNext = null,
                .flags = c.VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT,
                .queueFamilyIndex = graphicsQueueFamilyIndex,
            },
            null,
            &commandPool,
        ));
        errdefer c.vkDestroyCommandPool(logicalDevice, commandPool, null);

        const rectangleModel = try Model.init(
            &.{
                .{ .position = .{ 0.0, 0.0, 0.0 } },
                .{ .position = .{ 1.0, 0.0, 0.0 } },
                .{ .position = .{ 0.0, 1.0, 0.0 } },

                .{ .position = .{ 1.0, 0.0, 0.0 } },
                .{ .position = .{ 1.0, 1.0, 0.0 } },
                .{ .position = .{ 0.0, 1.0, 0.0 } },
            },
            logicalDevice,
            physicalDevice,
            graphicsQueue,
            commandPool,
        );

        var elementsPipeline = try ElementsPipeline.init(
            graphics.allocator,
            logicalDevice,
            physicalDevice,
            renderPass,
        );
        errdefer elementsPipeline.deinit(logicalDevice);

        var textPipeline = try TextPipeline.init(
            graphics.allocator,
            logicalDevice,
            physicalDevice,
            graphicsQueue,
            commandPool,
            renderPass,
        );
        errdefer textPipeline.deinit(logicalDevice, graphics.allocator);

        var shadowsPipeline = try ShadowsPipeline.init(
            logicalDevice,
            physicalDevice,
            renderPass,
        );
        errdefer shadowsPipeline.deinit(logicalDevice);

        var commandBuffers: [maxFramesInFlight]c.VkCommandBuffer = undefined;
        try ensureNoError(c.vkAllocateCommandBuffers(
            logicalDevice,
            &c.VkCommandBufferAllocateInfo{
                .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
                .pNext = null,
                .commandPool = commandPool,
                .level = c.VK_COMMAND_BUFFER_LEVEL_PRIMARY,
                .commandBufferCount = maxFramesInFlight,
            },
            &commandBuffers,
        ));
        errdefer c.vkFreeCommandBuffers(logicalDevice, commandPool, maxFramesInFlight, &commandBuffers);

        var inFlightFences: [maxFramesInFlight]c.VkFence = undefined;
        var imageAvailableSemaphores: [maxFramesInFlight]c.VkSemaphore = undefined;
        for (0..maxFramesInFlight) |i| {
            try ensureNoError(c.vkCreateFence(
                logicalDevice,
                &c.VkFenceCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO,
                    .flags = c.VK_FENCE_CREATE_SIGNALED_BIT,
                    .pNext = null,
                },
                null,
                &inFlightFences[i],
            ));

            try ensureNoError(c.vkCreateSemaphore(
                logicalDevice,
                &c.VkSemaphoreCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO,
                    .flags = 0,
                    .pNext = null,
                },
                null,
                &imageAvailableSemaphores[i],
            ));
        }
        errdefer {
            for (0..maxFramesInFlight) |i| {
                c.vkDestroySemaphore(logicalDevice, imageAvailableSemaphores[i], null);
                c.vkDestroyFence(logicalDevice, inFlightFences[i], null);
            }
        }

        const renderFinishedSemaphores = try graphics.allocator.alloc(c.VkSemaphore, swapchain.images.len);
        errdefer graphics.allocator.free(renderFinishedSemaphores);

        for (renderFinishedSemaphores) |*semaphore| {
            try ensureNoError(c.vkCreateSemaphore(
                logicalDevice,
                &c.VkSemaphoreCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO,
                    .flags = 0,
                    .pNext = null,
                },
                null,
                semaphore,
            ));
        }
        errdefer {
            for (renderFinishedSemaphores) |semaphore| {
                c.vkDestroySemaphore(logicalDevice, semaphore, null);
            }
        }

        return Renderer{
            .allocator = graphics.allocator,
            .graphics = graphics,
            .window = window,
            .mutex = std.Io.Mutex.init,

            .physicalDevice = physicalDevice,
            .logicalDevice = logicalDevice,
            .renderPass = renderPass,
            .graphicsQueue = graphicsQueue,
            .graphicsQueueFamilyIndex = graphicsQueueFamilyIndex,
            .presentationQueue = presentationQueue,
            .presentationQueueFamilyIndex = presentationQueueFamilyIndex,

            .surface = surface,
            .swapchain = swapchain,
            .viewportExtent = .init((@as(u64, swapchain.extent.width) << 32) | swapchain.extent.height),

            .elementsPipeline = elementsPipeline,
            .textPipeline = textPipeline,
            .shadowsPipeline = shadowsPipeline,
            .rectangleModel = rectangleModel,

            .commandPool = commandPool,
            .commandBuffers = commandBuffers,

            .inFlightFences = inFlightFences,
            .imageAvailableSemaphores = imageAvailableSemaphores,
            .renderFinishedSemaphores = renderFinishedSemaphores,

            .framesRenderedInSwapchain = 0,
            .executingFrame = false,
            .frameRateCapper = FrameRateCapper{},
        };
    }

    pub fn onResize(window: *Window, newWidth: u32, newHeight: u32, newDpi: [2]u32, data: *anyopaque) void {
        _ = window;
        _ = newDpi;
        const self: *Self = @ptrCast(@alignCast(data));
        self.handleResize(newWidth, newHeight) catch |err| {
            std.log.err("failed to recreate swapchain on resize: {}", .{err});
        };
    }

    pub fn handleResize(self: *Self, width: u32, height: u32) !void {
        const io = root.getForbear().io;
        self.mutex.lockUncancelable(io);
        defer self.mutex.unlock(io);
        try self.stallForFrames();
        try self.flushFrame();
        try self.recreateSwapchain(width, height);
    }

    fn stallForFrames(self: *Self) !void {
        try ensureNoError(c.vkQueueWaitIdle(self.presentationQueue));
        for (self.inFlightFences) |fence| {
            ensureNoError(c.vkGetFenceStatus(self.logicalDevice, fence)) catch |err| {
                if (err != error.NotReady) {
                    return err;
                }
            };

            try ensureNoError(c.vkWaitForFences(self.logicalDevice, 1, &fence, c.VK_TRUE, std.math.maxInt(u64)));
        }
    }

    fn flushFrame(self: *Self) !void {
        if (self.executingFrame) {
            try ensureNoError(c.vkEndCommandBuffer(self.commandBuffers[self.framesRenderedInSwapchain % maxFramesInFlight]));
            try ensureNoError(c.vkQueueSubmit(
                self.graphicsQueue,
                1,
                &c.VkSubmitInfo{
                    .sType = c.VK_STRUCTURE_TYPE_SUBMIT_INFO,
                    .commandBufferCount = 1,
                    .pCommandBuffers = &self.commandBuffers[self.framesRenderedInSwapchain % maxFramesInFlight],
                    .pNext = null,
                    .pSignalSemaphores = null,
                    .pWaitSemaphores = null,
                    .pWaitDstStageMask = null,
                    .signalSemaphoreCount = 0,
                    .waitSemaphoreCount = 0,
                },
                self.inFlightFences[self.framesRenderedInSwapchain % maxFramesInFlight],
            ));

            try ensureNoError(c.vkWaitForFences(
                self.logicalDevice,
                1,
                &self.inFlightFences[self.framesRenderedInSwapchain % maxFramesInFlight],
                c.VK_TRUE,
                std.math.maxInt(u64),
            ));
            try ensureNoError(c.vkResetFences(
                self.logicalDevice,
                1,
                &self.inFlightFences[self.framesRenderedInSwapchain % maxFramesInFlight],
            ));
            self.framesRenderedInSwapchain += 1;
            self.executingFrame = false;
        }
    }

    pub fn waitIdle(self: *Self) !void {
        const io = root.getForbear().io;
        self.mutex.lockUncancelable(io);
        defer self.mutex.unlock(io);
        try ensureNoError(c.vkDeviceWaitIdle(self.logicalDevice));
        try ensureNoError(c.vkQueueWaitIdle(self.graphicsQueue));
        try ensureNoError(c.vkQueueWaitIdle(self.presentationQueue));
    }

    pub fn deinit(self: *Self) void {
        // No mutex needed - rendering thread should have exited before deinit is called
        for (self.renderFinishedSemaphores) |semaphore| {
            c.vkDestroySemaphore(self.logicalDevice, semaphore, null);
        }
        self.allocator.free(self.renderFinishedSemaphores);

        for (0..maxFramesInFlight) |i| {
            c.vkDestroySemaphore(self.logicalDevice, self.imageAvailableSemaphores[i], null);
            c.vkDestroyFence(self.logicalDevice, self.inFlightFences[i], null);
        }
        c.vkFreeCommandBuffers(self.logicalDevice, self.commandPool, maxFramesInFlight, &self.commandBuffers);
        c.vkDestroyCommandPool(self.logicalDevice, self.commandPool, null);
        self.elementsPipeline.deinit(self.logicalDevice);
        self.textPipeline.deinit(self.logicalDevice, self.allocator);
        self.shadowsPipeline.deinit(self.logicalDevice);
        self.rectangleModel.deinit(self.logicalDevice);
        self.swapchain.deinit(self.logicalDevice);
        c.vkDestroyRenderPass(self.logicalDevice, self.renderPass, null);
        c.vkDestroyDevice(self.logicalDevice, null);
        c.vkDestroySurfaceKHR(self.graphics.vulkanInstance, self.surface, null);
    }

    fn setScissor(self: *Self, clipRect: ?Vec4, fullViewport: c.VkRect2D) void {
        const scissor = if (clipRect) |clip| blk: {
            const x1: f32 = @max(0.0, clip[0]);
            const y1: f32 = @max(0.0, clip[1]);
            const x2: f32 = clip[0] + clip[2];
            const y2: f32 = clip[1] + clip[3];
            break :blk c.VkRect2D{
                .offset = c.VkOffset2D{
                    .x = @intFromFloat(x1),
                    .y = @intFromFloat(y1),
                },
                .extent = c.VkExtent2D{
                    .width = @intFromFloat(@max(0.0, x2 - x1)),
                    .height = @intFromFloat(@max(0.0, y2 - y1)),
                },
            };
        } else fullViewport;
        c.vkCmdSetScissor(self.commandBuffers[self.framesRenderedInSwapchain % maxFramesInFlight], 0, 1, &[_]c.VkRect2D{scissor});
    }

    fn handleResizeMidFrame(self: *Self) !void {
        std.log.debug("image acquring errored with out of date, this means we need to recreate the swapchain", .{});
        try self.stallForFrames();
        try self.flushFrame();

        c.vkDestroySemaphore(self.logicalDevice, self.imageAvailableSemaphores[self.framesRenderedInSwapchain % maxFramesInFlight], null);
        try ensureNoError(c.vkCreateSemaphore(
            self.logicalDevice,
            &c.VkSemaphoreCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO,
                .flags = 0,
                .pNext = null,
            },
            null,
            &self.imageAvailableSemaphores[self.framesRenderedInSwapchain % maxFramesInFlight],
        ));

        var capabilities: c.VkSurfaceCapabilitiesKHR = undefined;
        try ensureNoError(c.vkGetPhysicalDeviceSurfaceCapabilitiesKHR(self.physicalDevice, self.surface, &capabilities));
        try self.recreateSwapchain(capabilities.currentExtent.width, capabilities.currentExtent.height);
    }

    pub fn drawFrame(
        self: *Self,
        arena: std.mem.Allocator,
        nodeTree: *const NodeTree,
        clearColor: Vec4,
        targetFrameTimeNs: u64,
    ) !void {
        const io = root.getForbear().io;
        self.mutex.lockUncancelable(io);
        defer self.mutex.unlock(io);
        const frameIndex = self.framesRenderedInSwapchain % maxFramesInFlight;

        try ensureNoError(c.vkWaitForFences(
            self.logicalDevice,
            1,
            &self.inFlightFences[frameIndex],
            c.VK_TRUE,
            std.math.maxInt(u64),
        ));

        try ensureNoError(c.vkResetCommandBuffer(self.commandBuffers[frameIndex], 0));

        if (self.textPipeline.needsAtlasReset) {
            self.textPipeline.fontTextureAtlas.reset();
            for (self.textPipeline.glyphPageCache.entries[0..self.textPipeline.glyphPageCache.length]) |*entry| {
                entry.value.clear();
            }
            self.textPipeline.needsAtlasReset = false;
        }

        const acquireStopwatch = Stopwatch.start(io);
        var imageIndex: u32 = undefined;
        ensureNoError(c.vkAcquireNextImageKHR(
            self.logicalDevice,
            self.swapchain.handle,
            // Bounded so a stalled presentation engine (notably the Win32 modal
            // move/size loop, where DWM only services FIFO presents on size-event
            // ticks) can't park this thread forever. ~6 vsync intervals: well above
            // any honest acquire latency, well below a perceptible hang. On timeout
            // the spec leaves the semaphore unsignaled and writes no index, so we
            // just skip the frame and let the loop retry.
            targetFrameTimeNs *| 6,
            self.imageAvailableSemaphores[frameIndex],
            null,
            &imageIndex,
        )) catch |err| {
            switch (err) {
                error.Suboptimal => {
                    std.log.debug("Suboptimal, but image will still be used", .{});
                },
                error.OutOfDate => {
                    try self.handleResizeMidFrame();
                    return;
                },
                error.Timeout, error.NotReady => return,
                else => return err,
            }
        };
        {
            const acquireMs = acquireStopwatch.elapsedMs();
            if (acquireMs > 100) {
                std.log.err("image ({d}) acquiring took {d}ms!!!!!!!", .{ imageIndex, acquireMs });
            }
        }

        const swapchainImageIndex: usize = @intCast(imageIndex);

        const projectionMatrix = zmath.orthographicOffCenterRh(
            0.0,
            @floatFromInt(self.swapchain.extent.width),
            @floatFromInt(self.swapchain.extent.height),
            0.0,
            -1.0,
            1.0,
        );

        const viewportVec = Vec2{ @floatFromInt(self.swapchain.extent.width), @floatFromInt(self.swapchain.extent.height) };

        const prepStopwatch = Stopwatch.start(io);
        var nodesToRender = std.ArrayList(usize).empty;
        var totalShadowCount: usize = 0;
        var totalGlyphCount: usize = 0;
        var totalGradientStopCount: usize = 0;
        for (nodeTree.list.items, 0..) |node, i| {
            const insideView = node.position[0] + node.size[0] > 0.0 and node.position[1] + node.size[1] > 0.0 and viewportVec[0] > node.position[0] and viewportVec[1] > node.position[1];
            if (!insideView) continue;

            try nodesToRender.append(arena, i);
            if (node.style.shadow != null) {
                totalShadowCount += 1;
            }
            if (node.glyphs) |glyphs| {
                totalGlyphCount += glyphs.slice.len;
            }
            if (node.style.background == .gradient) {
                totalGradientStopCount += node.style.background.gradient.stops.len;
            }
        }
        const totalElementCount: usize = nodesToRender.items.len;

        try self.shadowsPipeline.ensureCapacity(totalShadowCount, frameIndex);
        try self.elementsPipeline.ensureCapacity(totalElementCount, totalGradientStopCount, frameIndex);
        try self.textPipeline.ensureCapacity(totalGlyphCount, frameIndex);

        const atlasWidthInv: f32 = 1.0 / @as(f32, @floatFromInt(self.textPipeline.fontTextureAtlas.capacityExtent.width));
        const atlasHeightInv: f32 = 1.0 / @as(f32, @floatFromInt(self.textPipeline.fontTextureAtlas.capacityExtent.height));

        var shadowIndex: usize = 0;
        var glyphIndex: usize = 0;
        var gradientStopIndex: usize = 0;
        // Fed to buildDrawCommands below so a mid-loop atlas reset can't
        // desync a text command's range from what was actually written.
        var glyphsWritten = std.ArrayList(usize).empty;

        for (nodesToRender.items, 0..) |nodeIndex, elementIndex| {
            const node = nodeTree.at(nodeIndex);

            const textureIndex: i32 = switch (node.style.background) {
                .color, .gradient => -1,
                .image => |imgPtr| @intCast(try self.elementsPipeline.registerImage(imgPtr, self.logicalDevice)),
            };
            var gradientStart: i32 = -1;
            var gradientEnd: i32 = -1;
            var gradientDirection: [2]f32 = .{ 1.0, 0.0 };
            if (node.style.background == .gradient and node.style.background.gradient.stops.len > 0) {
                const stops = node.style.background.gradient.stops;
                gradientDirection = node.style.background.gradient.direction.vector();
                gradientStart = @intCast(gradientStopIndex);
                for (stops) |stop| {
                    self.elementsPipeline.gradientStops.mapped[frameIndex][gradientStopIndex] = GradientStop{
                        .color = stop.color,
                        .position = stop.position,
                    };
                    gradientStopIndex += 1;
                }
                gradientEnd = @intCast(gradientStopIndex - 1);
            }
            self.elementsPipeline.elements.mapped[frameIndex][elementIndex] = ElementRenderingData{
                .modelViewProjectionMatrix = zmath.mul(
                    zmath.mul(
                        zmath.scaling(node.size[0], node.size[1], 1.0),
                        zmath.translation(node.position[0], node.position[1], 0.0),
                    ),
                    projectionMatrix,
                ),
                .backgroundColor = switch (node.style.background) {
                    .color => |color| color,
                    .image => Vec4{ 1.0, 1.0, 1.0, 1.0 },
                    .gradient => Vec4{ 0.0, 0.0, 0.0, 0.0 },
                },
                .size = node.size,
                .borderRadius = node.style.borderRadius,
                .borderColor = node.style.borderColor,
                .borderSize = .{
                    node.style.borderWidth.y[0],
                    node.style.borderWidth.y[1],
                    node.style.borderWidth.x[0],
                    node.style.borderWidth.x[1],
                },
                .imageIndex = textureIndex,
                .gradientStart = gradientStart,
                .gradientEnd = gradientEnd,
                .gradientDirection = gradientDirection,
                .blendMode = @intCast(@intFromEnum(node.style.blendMode)),
                .filterType = @intCast(@intFromEnum(node.style.filter)),
                .borderStyle = @intCast(@intFromEnum(node.style.borderStyle)),
            };

            if (node.style.shadow) |shadow| {
                const padding = Vec2{
                    shadow.blurRadius + @abs(shadow.spread) + shadow.offset.x[0] + shadow.offset.x[1],
                    shadow.blurRadius + @abs(shadow.spread) + shadow.offset.y[0] + shadow.offset.y[1],
                };
                const position = Vec2{
                    node.position[0] - padding[0] - shadow.offset.x[0] + shadow.offset.x[1],
                    node.position[1] - padding[1] - shadow.offset.y[0] + shadow.offset.y[1],
                };
                const size = node.size + padding * Vec2{ 2, 2 };
                const shadowCenter = position + size * Vec2{ 0.5, 0.5 };
                const elementCenter = node.position + node.size * Vec2{ 0.5, 0.5 };
                const elementOffset = elementCenter - shadowCenter;
                self.shadowsPipeline.shadows.mapped[frameIndex][shadowIndex] = ShadowRenderingData{
                    .modelViewProjectionMatrix = zmath.mul(
                        zmath.mul(
                            zmath.scaling(size[0], size[1], 1.0),
                            zmath.translation(position[0], position[1], 0.0),
                        ),
                        projectionMatrix,
                    ),
                    .color = shadow.color,
                    .blur = shadow.blurRadius,
                    .spread = shadow.spread,
                    .elementSize = node.size,
                    .elementOffset = .{ elementOffset[0], elementOffset[1] },
                    .size = size,
                    .borderRadius = node.style.borderRadius,
                };
                shadowIndex += 1;
            }

            if (node.glyphs) |glyphs| {
                const pixelAscent = glyphs.ascent;
                const glyphStartIndex = glyphIndex;

                // Per-run style resolution. Plain `text()` nodes leave
                // `glyph.style` null and fall back to the node's style;
                // `composeText` nodes point each glyph at its run. Glyphs of a
                // run are contiguous, so the page/color lookup only refreshes
                // when the run changes.
                var activeStyle: ?*const CompleteTextStyle = undefined;
                var styleInitialized = false;
                var glyphFont: *Font = undefined;
                var glyphFontSize: f32 = undefined;
                var glyphFontWeight: u32 = undefined;
                var linearColor: Vec4 = undefined;
                var glyphPage: *TextPipeline.GlyphPage = undefined;

                for (glyphs.slice) |glyph| {
                    if (!styleInitialized or glyph.style != activeStyle) {
                        activeStyle = glyph.style;
                        glyphFont = glyph.style.font;
                        glyphFontSize = glyph.style.fontSize;
                        glyphFontWeight = glyph.style.fontWeight;
                        linearColor = glyph.style.color;

                        // Outer lookup: once per run (per font/size/weight/dpi combo)
                        const glyphPageKey = TextPipeline.GlyphPageKey{
                            .fontKey = glyphFont.key,
                            // `rasterize` already rounds to integer pixels, so an
                            // animated size keyed raw mints a fresh ~18KB page per
                            // intermediate frame for an identical bitmap, churning
                            // the heap until lookups go cold.
                            .fontSize = @round(glyphFontSize),
                            .fontWeight = glyphFontWeight,
                        };
                        glyphPage = try self.textPipeline.getOrCreateGlyphPage(glyphPageKey);
                        styleInitialized = true;
                    }

                    const glyphRenderingData = try self.textPipeline.getOrRasterizeGlyph(
                        glyphPage,
                        glyphFont,
                        glyphFontSize,
                        glyphFontWeight,
                        glyph.index,
                        arena,
                    ) orelse continue; // atlas full; needsAtlasReset is set, skip for this frame

                    const left: f32 = @floatFromInt(glyphRenderingData.bitmapLeft);
                    const top: f32 = @floatFromInt(glyphRenderingData.bitmapTop);
                    const width: f32 = @floatFromInt(glyphRenderingData.bitmapWidth);
                    const height: f32 = @floatFromInt(glyphRenderingData.bitmapHeight);

                    self.textPipeline.glyphs.mapped[frameIndex][glyphIndex] = TextPipeline.GlypRenderingShaderData{
                        // Pixel rect only; the vertex shader scales the unit quad
                        // to it and applies the projection (push constant).
                        .position = .{
                            @round(glyph.position[0] + left),
                            @round(glyph.position[1] + pixelAscent - top),
                        },
                        .size = .{ width, height },
                        .color = linearColor,
                        .uvOffset = .{
                            glyphRenderingData.textureCoordinates.u * atlasWidthInv,
                            glyphRenderingData.textureCoordinates.v * atlasHeightInv,
                        },
                        .uvSize = .{
                            glyphRenderingData.textureCoordinates.w * atlasWidthInv,
                            glyphRenderingData.textureCoordinates.h * atlasHeightInv,
                        },
                    };
                    glyphIndex += 1;
                }

                try glyphsWritten.append(arena, glyphIndex - glyphStartIndex);
            }
        }

        const drawCommands = mergeAdjacentDrawCommands(try buildDrawCommands(arena, nodeTree, viewportVec, .{
            .glyphsWritten = glyphsWritten.items,
        }));

        {
            const prepUs = prepStopwatch.elapsedUs();
            if (prepUs > 1000) {
                std.log.warn(
                    "prepared {d} shadows, {d} elements, {d} glyphs to render taking {d}μs",
                    .{ totalShadowCount, totalElementCount, totalGlyphCount, prepUs },
                );
            }
        }

        try ensureNoError(c.vkBeginCommandBuffer(self.commandBuffers[frameIndex], &c.VkCommandBufferBeginInfo{
            .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
            .pNext = null,
            .flags = 0,
            .pInheritanceInfo = null,
        }));
        self.executingFrame = true;

        // The render pass handles the UNDEFINED -> COLOR_ATTACHMENT_OPTIMAL -> PRESENT_SRC layout
        // transitions for us (see createRenderPass), so no manual image barriers are needed here.
        c.vkCmdBeginRenderPass(
            self.commandBuffers[frameIndex],
            &c.VkRenderPassBeginInfo{
                .sType = c.VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO,
                .pNext = null,
                .renderPass = self.renderPass,
                .framebuffer = self.swapchain.framebuffers[swapchainImageIndex],
                .renderArea = c.VkRect2D{
                    .offset = c.VkOffset2D{ .x = 0, .y = 0 },
                    .extent = self.swapchain.extent,
                },
                .clearValueCount = 1,
                .pClearValues = &c.VkClearValue{
                    .color = c.VkClearColorValue{
                        .float32 = clearColor,
                    },
                },
            },
            c.VK_SUBPASS_CONTENTS_INLINE,
        );

        c.vkCmdSetViewport(self.commandBuffers[frameIndex], 0, 1, &[_]c.VkViewport{c.VkViewport{
            .x = 0.0,
            .y = 0.0,
            .width = @floatFromInt(self.swapchain.extent.width),
            .height = @floatFromInt(self.swapchain.extent.height),
            .minDepth = 0.0,
            .maxDepth = 1.0,
        }});

        const fullViewportScissor = c.VkRect2D{
            .offset = c.VkOffset2D{ .x = 0, .y = 0 },
            .extent = self.swapchain.extent,
        };
        c.vkCmdSetScissor(self.commandBuffers[frameIndex], 0, 1, &[_]c.VkRect2D{fullViewportScissor});

        // Simple draw loop (commands already sorted and merged by buildDrawCommands / mergeAdjacentDrawCommands)
        var lastClipRect: ?Vec4 = null;
        for (drawCommands) |cmd| {
            // Set scissor when clip rect changes
            if (lastClipRect == null or cmd.clipRect == null or
                !@reduce(.And, lastClipRect.? == cmd.clipRect.?))
            {
                self.setScissor(cmd.clipRect, fullViewportScissor);
                lastClipRect = cmd.clipRect;
            }

            switch (cmd.kind) {
                .shadow => self.shadowsPipeline.draw(
                    cmd.interval(),
                    frameIndex,
                    self.commandBuffers[frameIndex],
                    &self.rectangleModel,
                ),
                .element => self.elementsPipeline.draw(
                    cmd.interval(),
                    cmd.blendMode,
                    frameIndex,
                    self.commandBuffers[frameIndex],
                    &self.rectangleModel,
                ),
                .text => self.textPipeline.draw(
                    cmd.interval(),
                    frameIndex,
                    self.commandBuffers[frameIndex],
                    &self.rectangleModel,
                    projectionMatrix,
                ),
            }
        }

        c.vkCmdEndRenderPass(self.commandBuffers[frameIndex]);
        try ensureNoError(c.vkEndCommandBuffer(self.commandBuffers[frameIndex]));

        const waitSemaphores: []const c.VkSemaphore = &.{self.imageAvailableSemaphores[frameIndex]};
        const renderFinishedSemaphores = self.renderFinishedSemaphores;
        const signalSemaphores: []const c.VkSemaphore = &.{renderFinishedSemaphores[swapchainImageIndex]};
        const waitStages: []const c.VkPipelineStageFlags = &.{c.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT};

        try ensureNoError(c.vkResetFences(
            self.logicalDevice,
            1,
            &self.inFlightFences[frameIndex],
        ));
        try ensureNoError(c.vkQueueSubmit(
            self.graphicsQueue,
            1,
            &c.VkSubmitInfo{
                .sType = c.VK_STRUCTURE_TYPE_SUBMIT_INFO,
                .pNext = null,
                .waitSemaphoreCount = @intCast(waitSemaphores.len),
                .pWaitSemaphores = waitSemaphores.ptr,
                .pWaitDstStageMask = waitStages.ptr,
                .commandBufferCount = 1,
                .pCommandBuffers = &self.commandBuffers[frameIndex],
                .signalSemaphoreCount = @intCast(signalSemaphores.len),
                .pSignalSemaphores = signalSemaphores.ptr,
            },
            self.inFlightFences[frameIndex],
        ));
        self.executingFrame = false;

        ensureNoError(c.vkQueuePresentKHR(self.presentationQueue, &c.VkPresentInfoKHR{
            .sType = c.VK_STRUCTURE_TYPE_PRESENT_INFO_KHR,
            .waitSemaphoreCount = @intCast(signalSemaphores.len),
            .pWaitSemaphores = signalSemaphores.ptr,
            .swapchainCount = 1,
            .pSwapchains = &self.swapchain.handle,
            .pImageIndices = &imageIndex,
            .pResults = null,
        })) catch |err| {
            switch (err) {
                error.Suboptimal => {
                    std.log.debug("Suboptimal, but image will still be used", .{});
                },
                error.OutOfDate => {
                    try self.handleResizeMidFrame();
                    return;
                },
                else => return err,
            }
        };

        self.framesRenderedInSwapchain += 1;
        // We cap this because the driver's native Vulkan "frame rate capper"
        // can be disabled causing a "slow motion" effect during swapchain
        // recreation. (generally done in window resizing)
        // This is only done for the first 50 frames because after that FIFO
        // should kick in properly.
        if (builtin.os.tag == .linux and self.framesRenderedInSwapchain < 50) {
            try self.frameRateCapper.cap(root.getForbear().io, targetFrameTimeNs);
        }
        if (self.framesRenderedInSwapchain == 50) {
            switch (builtin.os.tag) {
                .linux => {
                    std.log.debug("fifty frames rendered, trimming memory {d}", .{c.malloc_trim(0)});
                },
                .windows => {
                    _ = SetProcessWorkingSetSize(GetCurrentProcess(), std.math.maxInt(isize) - 1, std.math.maxInt(isize) - 1);
                },
                else => {},
            }
        }
    }

    fn findSupportedFormat(
        physicalDevice: c.VkPhysicalDevice,
        candidates: []const c.VkFormat,
        tiling: c.VkImageTiling,
        features: c.VkFormatFeatureFlags,
    ) !c.VkFormat {
        for (candidates) |format| {
            var props: c.VkFormatProperties = undefined;
            c.vkGetPhysicalDeviceFormatProperties(physicalDevice, format, &props);

            if (tiling == c.VK_IMAGE_TILING_LINEAR and (props.linearTilingFeatures & features) == features) {
                return format;
            } else if (tiling == c.VK_IMAGE_TILING_OPTIMAL and (props.optimalTilingFeatures & features) == features) {
                return format;
            }
        }

        return error.NoSupportedFormat;
    }

    const Swapchain = struct {
        handle: c.VkSwapchainKHR,
        surfaceFormat: c.VkSurfaceFormatKHR,
        presentMode: c.VkPresentModeKHR,
        extent: c.VkExtent2D,

        images: []c.VkImage,
        imageViews: []c.VkImageView,
        // One framebuffer per swapchain image view, bound to the renderer's render pass. Created by
        // createFramebuffers() after the render pass exists, and recreated alongside the swapchain on resize.
        framebuffers: []c.VkFramebuffer,

        allocator: std.mem.Allocator,

        const SwapchainSupportDetails = struct {
            capabilities: c.VkSurfaceCapabilitiesKHR,
            formats: []c.VkSurfaceFormatKHR,
            presentModes: []c.VkPresentModeKHR,

            allocator: std.mem.Allocator,

            fn deinit(self: @This()) void {
                self.allocator.free(self.formats);
                self.allocator.free(self.presentModes);
            }
        };

        fn init(
            allocator: std.mem.Allocator,
            physicalDevice: c.VkPhysicalDevice,
            logicalDevice: c.VkDevice,
            surface: c.VkSurfaceKHR,
            width: u32,
            height: u32,
            oldSwapchain: ?@This(),
        ) !Swapchain {
            var swapchainSupportDetails: SwapchainSupportDetails = undefined;
            swapchainSupportDetails.allocator = allocator;
            try ensureNoError(c.vkGetPhysicalDeviceSurfaceCapabilitiesKHR(
                physicalDevice,
                surface,
                &swapchainSupportDetails.capabilities,
            ));

            var formatsLen: u32 = 0;
            try ensureNoError(c.vkGetPhysicalDeviceSurfaceFormatsKHR(
                physicalDevice,
                surface,
                &formatsLen,
                null,
            ));
            swapchainSupportDetails.formats = try allocator.alloc(c.VkSurfaceFormatKHR, @intCast(formatsLen));
            errdefer allocator.free(swapchainSupportDetails.formats);
            try ensureNoError(c.vkGetPhysicalDeviceSurfaceFormatsKHR(
                physicalDevice,
                surface,
                &formatsLen,
                swapchainSupportDetails.formats.ptr,
            ));

            var presentModesLen: u32 = 0;
            try ensureNoError(c.vkGetPhysicalDeviceSurfacePresentModesKHR(
                physicalDevice,
                surface,
                &presentModesLen,
                null,
            ));
            swapchainSupportDetails.presentModes = try allocator.alloc(c.VkPresentModeKHR, @intCast(presentModesLen));
            errdefer allocator.free(swapchainSupportDetails.presentModes);
            try ensureNoError(c.vkGetPhysicalDeviceSurfacePresentModesKHR(
                physicalDevice,
                surface,
                &presentModesLen,
                swapchainSupportDetails.presentModes.ptr,
            ));
            defer swapchainSupportDetails.deinit();

            var surfaceFormat: c.VkSurfaceFormatKHR = swapchainSupportDetails.formats[0];
            for (swapchainSupportDetails.formats) |availableFormat| {
                if (availableFormat.format == c.VK_FORMAT_B8G8R8A8_UNORM and
                    availableFormat.colorSpace == c.VK_COLOR_SPACE_SRGB_NONLINEAR_KHR)
                {
                    surfaceFormat = availableFormat;
                    break;
                }
            }

            const presentMode: c.VkPresentModeKHR = c.VK_PRESENT_MODE_FIFO_KHR;

            var swapchainExtent: c.VkExtent2D = swapchainSupportDetails.capabilities.currentExtent;
            if (swapchainExtent.width == std.math.maxInt(u32)) {
                swapchainExtent = c.VkExtent2D{
                    .width = std.math.clamp(
                        width,
                        swapchainSupportDetails.capabilities.minImageExtent.width,
                        swapchainSupportDetails.capabilities.maxImageExtent.width,
                    ),
                    .height = std.math.clamp(
                        height,
                        swapchainSupportDetails.capabilities.minImageExtent.height,
                        swapchainSupportDetails.capabilities.maxImageExtent.height,
                    ),
                };
            }

            var imageCount: u32 = swapchainSupportDetails.capabilities.minImageCount + 1;
            if (swapchainSupportDetails.capabilities.maxImageCount > 0 and imageCount > swapchainSupportDetails.capabilities.maxImageCount) {
                imageCount = swapchainSupportDetails.capabilities.maxImageCount;
            }

            var swapchain: c.VkSwapchainKHR = undefined;
            try ensureNoError(c.vkCreateSwapchainKHR(
                logicalDevice,
                &c.VkSwapchainCreateInfoKHR{
                    .sType = c.VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR,
                    .surface = surface,
                    .minImageCount = imageCount,
                    .imageFormat = surfaceFormat.format,
                    .imageColorSpace = surfaceFormat.colorSpace,
                    .imageExtent = swapchainExtent,
                    .imageArrayLayers = 1,
                    .imageUsage = c.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT,
                    .imageSharingMode = c.VK_SHARING_MODE_EXCLUSIVE,
                    .queueFamilyIndexCount = 0,
                    .pQueueFamilyIndices = null,
                    .preTransform = swapchainSupportDetails.capabilities.currentTransform,
                    .compositeAlpha = c.VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR,
                    .presentMode = presentMode,
                    .clipped = c.VK_TRUE,
                    .oldSwapchain = if (oldSwapchain) |prev| prev.handle else null,
                },
                null,
                &swapchain,
            ));
            errdefer c.vkDestroySwapchainKHR(logicalDevice, swapchain, null);

            std.debug.assert(swapchain != null);

            var swapChainImagesLen: u32 = 0;
            try ensureNoError(c.vkGetSwapchainImagesKHR(
                logicalDevice,
                swapchain,
                &swapChainImagesLen,
                null,
            ));
            const swapChainImages = try allocator.alloc(c.VkImage, @intCast(swapChainImagesLen));
            errdefer allocator.free(swapChainImages);
            try ensureNoError(c.vkGetSwapchainImagesKHR(
                logicalDevice,
                swapchain,
                &swapChainImagesLen,
                swapChainImages.ptr,
            ));

            const imageViews = try allocator.alloc(c.VkImageView, swapChainImages.len);
            errdefer {
                for (imageViews) |imageView| {
                    if (imageView != null) {
                        c.vkDestroyImageView(logicalDevice, imageView, null);
                    }
                }
                allocator.free(imageViews);
            }
            for (swapChainImages, 0..) |image, i| {
                try ensureNoError(c.vkCreateImageView(
                    logicalDevice,
                    &c.VkImageViewCreateInfo{
                        .sType = c.VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO,
                        .image = image,
                        .pNext = null,
                        .flags = 0,
                        .viewType = c.VK_IMAGE_VIEW_TYPE_2D,
                        .format = surfaceFormat.format,
                        .components = c.VkComponentMapping{
                            .r = c.VK_COMPONENT_SWIZZLE_R,
                            .g = c.VK_COMPONENT_SWIZZLE_G,
                            .b = c.VK_COMPONENT_SWIZZLE_B,
                            .a = c.VK_COMPONENT_SWIZZLE_A,
                        },
                        .subresourceRange = c.VkImageSubresourceRange{
                            .aspectMask = c.VK_IMAGE_ASPECT_COLOR_BIT,
                            .baseMipLevel = 0,
                            .levelCount = 1,
                            .baseArrayLayer = 0,
                            .layerCount = 1,
                        },
                    },
                    null,
                    &imageViews[i],
                ));
            }

            return Swapchain{
                .handle = swapchain,
                .surfaceFormat = surfaceFormat,
                .presentMode = presentMode,
                .extent = swapchainExtent,
                .images = swapChainImages,
                .imageViews = imageViews,
                // Filled in by createFramebuffers() once the render pass is available.
                .framebuffers = &.{},
                .allocator = allocator,
            };
        }

        fn createFramebuffers(self: *Swapchain, logicalDevice: c.VkDevice, renderPass: c.VkRenderPass) !void {
            const framebuffers = try self.allocator.alloc(c.VkFramebuffer, self.imageViews.len);
            errdefer self.allocator.free(framebuffers);
            for (self.imageViews, 0..) |imageView, i| {
                errdefer for (framebuffers[0..i]) |fb| c.vkDestroyFramebuffer(logicalDevice, fb, null);
                try ensureNoError(c.vkCreateFramebuffer(logicalDevice, &c.VkFramebufferCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO,
                    .pNext = null,
                    .flags = 0,
                    .renderPass = renderPass,
                    .attachmentCount = 1,
                    .pAttachments = &imageView,
                    .width = self.extent.width,
                    .height = self.extent.height,
                    .layers = 1,
                }, null, &framebuffers[i]));
            }
            self.framebuffers = framebuffers;
        }

        fn deinit(self: Swapchain, logicalDevice: c.VkDevice) void {
            for (self.framebuffers) |framebuffer| {
                c.vkDestroyFramebuffer(logicalDevice, framebuffer, null);
            }
            self.allocator.free(self.framebuffers);
            for (self.imageViews) |imageView| {
                c.vkDestroyImageView(logicalDevice, imageView, null);
            }
            self.allocator.free(self.imageViews);
            self.allocator.free(self.images);

            c.vkDestroySwapchainKHR(logicalDevice, self.handle, null);
        }
    };
};
