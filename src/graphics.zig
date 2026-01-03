const std = @import("std");
const builtin = @import("builtin");

const zmath = @import("zmath");

const c = @import("c.zig").c;
const Font = @import("text.zig").Font;
const layouting = @import("layouting.zig");
const LayoutBox = layouting.LayoutBox;
const countTreeSize = layouting.countTreeSize;
const LayoutTreeIterator = layouting.LayoutTreeIterator;
const Window = @import("window/root.zig");

const Vec4 = @Vector(4, f32);
const Vec3 = @Vector(3, f32);
const Vec2 = @Vector(2, f32);

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
    Unknown,
};

pub fn ensureNoError(result: c.VkResult) !void {
    switch (result) {
        c.VK_ERROR_EXTENSION_NOT_PRESENT => return error.ExtensioNotPresent,
        c.VK_ERROR_INCOMPATIBLE_DRIVER => return error.IncompatibleDriver,
        c.VK_ERROR_INITIALIZATION_FAILED => return error.InitializationFailed,
        c.VK_ERROR_LAYER_NOT_PRESENT => return error.LayerNotPresent,
        c.VK_ERROR_OUT_OF_DEVICE_MEMORY => return error.OutOfDeviceMemory,
        c.VK_ERROR_OUT_OF_HOST_MEMORY => return error.OutOfHostMemory,
        c.VK_ERROR_VALIDATION_FAILED => return error.ValidationFailed,
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
        else => {
            if (builtin.os.tag == .linux) {
                switch (result) {
                    c.VK_ERROR_INCOMPATIBLE_DISPLAY_KHR => return error.IncompatibleDriver,
                    else => {},
                }
            }
        },
    }

    std.debug.assert(result == c.VK_SUCCESS);
}

fn logInstanceExtensions(allocator: std.mem.Allocator, requested: []const [*c]const u8) !void {
    var count: u32 = 0;
    try ensureNoError(c.vkEnumerateInstanceExtensionProperties(null, &count, null));

    const available = try allocator.alloc(c.VkExtensionProperties, @intCast(count));
    defer allocator.free(available);

    try ensureNoError(c.vkEnumerateInstanceExtensionProperties(null, &count, available.ptr));

    std.log.info("Requested Vulkan instance extensions ({d}):", .{requested.len});
    for (requested) |ext| {
        std.log.info("  {s}", .{std.mem.span(ext)});
    }

    std.log.info("Available Vulkan instance extensions ({d}):", .{available.len});
    for (available) |ext| {
        const name = std.mem.sliceTo(ext.extensionName[0..], 0);
        std.log.info("  {s}", .{name});
    }

    for (requested) |ext| {
        const required_name = std.mem.span(ext);
        var found = false;
        for (available) |avail| {
            const avail_name = std.mem.sliceTo(avail.extensionName[0..], 0);
            if (std.mem.eql(u8, avail_name, required_name)) {
                found = true;
                break;
            }
        }
        if (!found) {
            std.log.err("Missing required Vulkan instance extension: {s}", .{required_name});
        }
    }
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

const Device = struct {
    physicalDevice: c.VkPhysicalDevice,
    queueFamilies: []c.VkQueueFamilyProperties,
    deviceProperties: c.VkPhysicalDeviceProperties,
    availableDeviceExtensions: []c.VkExtensionProperties,
};

allocator: std.mem.Allocator,
application_name: [:0]const u8,

vulkanInstance: c.VkInstance,
vulkanDebugMessenger: c.VkDebugUtilsMessengerEXT,

devices: []Device,

pub fn init(application_name: [:0]const u8, allocator: std.mem.Allocator) !Graphics {
    const instanceCreateFlags: c.VkInstanceCreateFlags = switch (builtin.os.tag) {
        // MoltenVK needs the portability enumeration extension + flag.
        .macos => c.VK_INSTANCE_CREATE_ENUMERATE_PORTABILITY_BIT_KHR,
        else => 0,
    };

    const instanceExtensions: []const [*c]const u8 = &(.{
        c.VK_KHR_SURFACE_EXTENSION_NAME,
        c.VK_EXT_DEBUG_UTILS_EXTENSION_NAME,
    } ++ switch (builtin.os.tag) {
        .linux => .{
            "VK_KHR_wayland_surface",
        },
        .macos => .{
            c.VK_KHR_PORTABILITY_ENUMERATION_EXTENSION_NAME,
                // "VK_EXT_metal_surface",
        },
        else => .{},
    });

    // Emit helpful diagnostics when instance creation fails.
    try logInstanceExtensions(allocator, instanceExtensions);

    // Only enable validation layers when they're actually available.
    // Tools like RenderDoc may override `VK_LAYER_PATH` which can hide system layers.
    var instanceLayersBuf: [1][*c]const u8 = undefined;
    var instanceLayers: []const [*c]const u8 = &.{};
    {
        var layerCount: u32 = 0;
        try ensureNoError(c.vkEnumerateInstanceLayerProperties(&layerCount, null));

        const availableLayers = try allocator.alloc(c.VkLayerProperties, @intCast(layerCount));
        defer allocator.free(availableLayers);

        try ensureNoError(c.vkEnumerateInstanceLayerProperties(&layerCount, availableLayers.ptr));

        const validationLayerName = "VK_LAYER_KHRONOS_validation";
        var hasValidationLayer = false;
        for (availableLayers) |layer| {
            const name = std.mem.sliceTo(layer.layerName[0..], 0);
            if (std.mem.eql(u8, name, validationLayerName)) {
                hasValidationLayer = true;
                break;
            }
        }

        if (hasValidationLayer) {
            instanceLayersBuf[0] = validationLayerName;
            instanceLayers = instanceLayersBuf[0..1];
        } else {
            std.log.warn("Vulkan validation layer not found; continuing without it", .{});
        }
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
                .pEngineName = "No Engine",
                .engineVersion = c.VK_MAKE_VERSION(1, 0, 0),
                .apiVersion = c.VK_API_VERSION_1_2,
            },
            .enabledLayerCount = @intCast(instanceLayers.len),
            .ppEnabledLayerNames = if (instanceLayers.len > 0) instanceLayers.ptr else null,
            .enabledExtensionCount = @intCast(instanceExtensions.len),
            .ppEnabledExtensionNames = instanceExtensions.ptr,
        },
        null,
        &vulkanInstance,
    ));
    std.debug.assert(vulkanInstance != null);
    errdefer c.vkDestroyInstance(vulkanInstance, null);

    var vulkanDebugMessenger: c.VkDebugUtilsMessengerEXT = null;
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

    if (debugMessengerResult == c.VK_ERROR_EXTENSION_NOT_PRESENT) {
        std.log.warn("VK_EXT_debug_utils not present; continuing without debug messenger", .{});
        vulkanDebugMessenger = null;
    } else {
        try ensureNoError(debugMessengerResult);
        std.debug.assert(vulkanDebugMessenger != null);
        errdefer DestroyDebugUtilsMessengerEXT(vulkanInstance, vulkanDebugMessenger, null);
    }

    var physicalDevicesLen: u32 = undefined;
    try ensureNoError(c.vkEnumeratePhysicalDevices(vulkanInstance, &physicalDevicesLen, null));
    const physicalDevices = try allocator.alloc(c.VkPhysicalDevice, @intCast(physicalDevicesLen));
    defer allocator.free(physicalDevices);
    try ensureNoError(c.vkEnumeratePhysicalDevices(
        vulkanInstance,
        &physicalDevicesLen,
        physicalDevices.ptr,
    ));

    const devices = try allocator.alloc(Device, physicalDevices.len);
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

    if (self.vulkanDebugMessenger != null) {
        DestroyDebugUtilsMessengerEXT(self.vulkanInstance, self.vulkanDebugMessenger, null);
    }
    c.vkDestroyInstance(self.vulkanInstance, null);
}

const QueueIndices = struct {
    graphics: u32,
    presentation: u32,
};

const Graphics = @This();

pub fn initRenderer(
    self: *Graphics,
    window: *const Window,
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
        // .macos => {
        //     const caMetalLayer = window.handle.nativeMetalLayer();
        //     if (caMetalLayer == null) return error.NullNativeView;
        //     try ensureNoError(c.vkCreateMetalSurfaceEXT(
        //         self.vulkanInstance,
        //         &c.VkMetalSurfaceCreateInfoEXT{
        //             .sType = c.VK_STRUCTURE_TYPE_METAL_SURFACE_CREATE_INFO_EXT,
        //             .pNext = null,
        //             .flags = 0,
        //             .pLayer = caMetalLayer,
        //         },
        //         null,
        //         &vulkanSurface,
        //     ));
        // },
        else => @compileError("Unsupported platform"),
    }
    std.debug.assert(vulkanSurface != null);
    errdefer c.vkDestroySurfaceKHR(self.vulkanInstance, vulkanSurface, null);

    return try Renderer.init(vulkanSurface, self, window.width, window.height, window.scale);
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

pub const TextureAtlas = struct {
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

    pub fn init(
        logicalDevice: c.VkDevice,
        physicalDevice: c.VkPhysicalDevice,
        allocator: std.mem.Allocator,
        commandPool: c.VkCommandPool,
        graphicsQueue: c.VkQueue,
    ) !@This() {
        const extent = c.VkExtent3D{
            .width = 4096,
            .height = 4096,
            .depth = 1,
        };

        var image: c.VkImage = undefined;
        try ensureNoError(c.vkCreateImage(logicalDevice, &c.VkImageCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO,
            .imageType = c.VK_IMAGE_TYPE_2D,
            .extent = extent,
            .mipLevels = 1,
            .arrayLayers = 1,
            .format = c.VK_FORMAT_R8_UNORM,
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
                .format = c.VK_FORMAT_R8_UNORM,
                .components = c.VkComponentMapping{
                    .r = c.VK_COMPONENT_SWIZZLE_IDENTITY,
                    .g = c.VK_COMPONENT_SWIZZLE_IDENTITY,
                    .b = c.VK_COMPONENT_SWIZZLE_IDENTITY,
                    .a = c.VK_COMPONENT_SWIZZLE_IDENTITY,
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

        const free_rectangle = FreeRectangle{
            .u = 0,
            .v = 0,
            .width = extent.width,
            .height = extent.height,
        };

        var free_rectangles = try std.ArrayList(FreeRectangle).initCapacity(allocator, 1);
        free_rectangles.appendAssumeCapacity(free_rectangle);

        var imageData: ?*anyopaque = undefined;
        try ensureNoError(c.vkMapMemory(logicalDevice, memory, 0, memRequirements.size, 0, &imageData));
        const imageDataSlice: []u8 = @as([*c]u8, @ptrCast(@alignCast(imageData)))[0..@intCast(memRequirements.size)];
        @memset(imageDataSlice, 0);

        return @This(){
            .image = image,
            .imageView = imageView,
            .memory = memory,
            .mapped = imageDataSlice,
            .rowPitch = @intCast(subresourceLayout.rowPitch),

            .capacityExtent = extent,
            .freeRectangles = free_rectangles,
        };
    }

    pub fn getBestFreeRectangle(
        self: *@This(),
        wantedWidth: usize,
        wantedHeight: usize,
    ) ?usize {
        var bestRectangleIndex: ?usize = null;
        var bestAreaDifference: usize = @intCast(std.math.maxInt(usize));

        const required_area = wantedWidth * wantedHeight;
        for (self.freeRectangles.items, 0..) |freeRectangle, index| {
            if (freeRectangle.width >= wantedWidth and freeRectangle.height >= wantedHeight) {
                const freeArea = freeRectangle.width * freeRectangle.height;
                const areaDifference = freeArea - required_area;
                if (areaDifference < bestAreaDifference) {
                    bestAreaDifference = areaDifference;
                    bestRectangleIndex = index;
                }
            }
        }

        return bestRectangleIndex;
    }

    pub const TextureCoordinates = struct {
        u: f32,
        v: f32,
        w: f32,
        h: f32,
    };

    pub fn upload(
        self: *@This(),
        data: ?[]u8,
        uploadWidth: usize,
        uploadHeight: usize,
        pitch: usize,
        allocator: std.mem.Allocator,
    ) !TextureCoordinates {
        if (data != null) {
            std.debug.assert(pitch * uploadHeight <= data.?.len);
        }
        // No free rectangles available in the texture atlas
        std.debug.assert(self.freeRectangles.items.len > 0);

        const padding = 1;
        const freeRectangleIndex = self.getBestFreeRectangle(
            @intCast(uploadWidth + padding),
            @intCast(uploadHeight + padding),
        ) orelse return error.MaximumTextureAtlasSizeReached;
        const freeRectangle = self.freeRectangles.orderedRemove(freeRectangleIndex);
        std.log.debug("Uploading glyph to texture atlas at ({d}, {d}) size ({d}x{d})", .{
            freeRectangle.u,
            freeRectangle.v,
            uploadWidth,
            uploadHeight,
        });
        // we share the remaining space in the free rectangle in a way that this first one has the
        // most area
        if (freeRectangle.width > uploadWidth + padding) {
            try self.freeRectangles.append(
                allocator,
                FreeRectangle{
                    .u = freeRectangle.u + uploadWidth + padding,
                    .v = freeRectangle.v,
                    .width = freeRectangle.width - (uploadWidth + padding),
                    .height = freeRectangle.height,
                },
            );
        }
        if (freeRectangle.height > uploadHeight + padding) {
            try self.freeRectangles.append(
                allocator,
                FreeRectangle{
                    .u = freeRectangle.u,
                    .v = freeRectangle.v + uploadHeight + padding,
                    .width = uploadWidth + padding,
                    .height = freeRectangle.height - (uploadHeight + padding),
                },
            );
        }

        for (0..uploadHeight) |y| {
            const dest_start = (freeRectangle.v + y) * self.rowPitch + freeRectangle.u;
            if (data != null) {
                const src_start = y * pitch;
                @memcpy(
                    self.mapped[dest_start .. dest_start + uploadWidth],
                    data.?[src_start .. src_start + uploadWidth],
                );
            } else {
                @memset(self.mapped[dest_start .. dest_start + uploadWidth], 0);
            }
        }

        return .{
            .u = @as(f32, @floatFromInt(freeRectangle.u)),
            .v = @as(f32, @floatFromInt(freeRectangle.v)),
            .w = @as(f32, @floatFromInt(uploadWidth)),
            .h = @as(f32, @floatFromInt(uploadHeight)),
        };
    }

    fn width(self: @This()) usize {
        return @as(usize, @intCast(self.capacityExtent.width));
    }

    fn height(self: @This()) usize {
        return @as(usize, @intCast(self.capacityExtent.height));
    }

    pub fn deinit(self: *@This(), logicalDevice: c.VkDevice, allocator: std.mem.Allocator) void {
        c.vkUnmapMemory(logicalDevice, self.memory);
        self.freeRectangles.deinit(allocator);
        c.vkFreeMemory(logicalDevice, self.memory, null);
        c.vkDestroyImageView(logicalDevice, self.imageView, null);
        c.vkDestroyImage(logicalDevice, self.image, null);
    }
};

pub const Buffer = struct {
    handle: c.VkBuffer,
    memory: c.VkDeviceMemory,
    size: c.VkDeviceSize,

    pub fn init(
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

    pub fn copyFrom(
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

    pub fn set(self: @This(), logicalDevice: c.VkDevice, data: []const u8) !void {
        if (data.len != @as(usize, @intCast(self.size))) {
            return error.BufferSizeDataMismatch;
        }
        var vertexBufferData: ?*anyopaque = undefined;
        try ensureNoError(c.vkMapMemory(logicalDevice, self.memory, 0, data.len, 0, &vertexBufferData));
        @memcpy(@as([*c]u8, @ptrCast(@alignCast(vertexBufferData)))[0..data.len], data);
        c.vkUnmapMemory(logicalDevice, self.memory);
    }

    pub fn deinit(self: @This(), logicalDevice: c.VkDevice) void {
        c.vkFreeMemory(logicalDevice, self.memory, null);
        c.vkDestroyBuffer(logicalDevice, self.handle, null);
    }
};

pub const Model = struct {
    vertexBuffer: Buffer,
    vertexCount: u32,

    pub fn init(
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

    pub fn deinit(self: @This(), logicalDevice: c.VkDevice) void {
        self.vertexBuffer.deinit(logicalDevice);
    }
};

pub const ElementRenderingData = extern struct {
    modelViewProjectionMatrix: zmath.Mat,
    backgroundColor: Vec4,
    size: [2]f32,
    borderRadius: f32,
};

const ElementsPipeline = struct {
    pipelineLayout: c.VkPipelineLayout,
    graphicsPipeline: c.VkPipeline,

    shaderBufferDescriptorSetLayout: c.VkDescriptorSetLayout,
    descriptorPool: c.VkDescriptorPool,
    descriptorSets: [maxFramesInFlight]c.VkDescriptorSet,

    elementModel: Model,

    shaderBuffers: [maxFramesInFlight]Buffer,
    shaderBuffersMapped: [maxFramesInFlight][]ElementRenderingData,

    const elementVertexShader: []const u32 = @ptrCast(@alignCast(@embedFile("element_vertex_shader")));
    const elementFragmentShader: []const u32 = @ptrCast(@alignCast(@embedFile("element_fragment_shader")));

    pub fn init(
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

        var shaderBufferDescriptorSetLayout: c.VkDescriptorSetLayout = undefined;
        try ensureNoError(c.vkCreateDescriptorSetLayout(
            logicalDevice,
            &c.VkDescriptorSetLayoutCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
                .pNext = null,
                .flags = 0,
                .bindingCount = 1,
                .pBindings = &c.VkDescriptorSetLayoutBinding{
                    .binding = 0,
                    .descriptorType = c.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
                    .descriptorCount = 1,
                    .stageFlags = c.VK_SHADER_STAGE_VERTEX_BIT,
                    .pImmutableSamplers = null,
                },
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

        const elementModel = try Model.init(
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

        const initialElementCapacity = 1;

        var shaderBuffers: [maxFramesInFlight]Buffer = undefined;
        var shaderBuffersMapped: [maxFramesInFlight][]ElementRenderingData = undefined;
        for (0..maxFramesInFlight) |i| {
            const buffer = try Buffer.init(
                logicalDevice,
                physicalDevice,
                @sizeOf(ElementRenderingData) * initialElementCapacity,
                c.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT,
                c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
            );
            shaderBuffers[i] = buffer;
            var storageBufferData: ?*anyopaque = undefined;
            try ensureNoError(c.vkMapMemory(logicalDevice, buffer.memory, 0, buffer.size, 0, &storageBufferData));
            shaderBuffersMapped[i] = @as([*]ElementRenderingData, @ptrCast(@alignCast(storageBufferData)))[0..initialElementCapacity];
        }

        var descriptorPool: c.VkDescriptorPool = undefined;
        try ensureNoError(c.vkCreateDescriptorPool(logicalDevice, &c.VkDescriptorPoolCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO,
            .poolSizeCount = 1,
            .maxSets = maxFramesInFlight,
            .pPoolSizes = &c.VkDescriptorPoolSize{
                .type = c.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
                .descriptorCount = maxFramesInFlight,
            },
            .flags = 0,
            .pNext = null,
        }, null, &descriptorPool));

        var descriptorSets: [maxFramesInFlight]c.VkDescriptorSet = undefined;
        try ensureNoError(c.vkAllocateDescriptorSets(logicalDevice, &c.VkDescriptorSetAllocateInfo{
            .sType = c.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO,
            .descriptorPool = descriptorPool,
            .descriptorSetCount = maxFramesInFlight,
            .pSetLayouts = &([1]c.VkDescriptorSetLayout{shaderBufferDescriptorSetLayout} ** maxFramesInFlight),
        }, &descriptorSets));

        for (shaderBuffers, 0..) |buffer, i| {
            const bufferInfo = c.VkDescriptorBufferInfo{
                .buffer = buffer.handle,
                .offset = 0,
                .range = c.VK_WHOLE_SIZE,
            };

            const descriptorWrite = c.VkWriteDescriptorSet{
                .sType = c.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
                .pNext = null,
                .dstSet = descriptorSets[i],
                .dstBinding = 0,
                .dstArrayElement = 0,
                .descriptorCount = 1,
                .descriptorType = c.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
                .pImageInfo = null,
                .pBufferInfo = &bufferInfo,
                .pTexelBufferView = null,
            };

            c.vkUpdateDescriptorSets(logicalDevice, 1, &descriptorWrite, 0, null);
        }

        return ElementsPipeline{
            .pipelineLayout = pipelineLayout,
            .graphicsPipeline = graphicsPipeline,
            .elementModel = elementModel,

            .shaderBufferDescriptorSetLayout = shaderBufferDescriptorSetLayout,
            .shaderBuffers = shaderBuffers,
            .shaderBuffersMapped = shaderBuffersMapped,
            .descriptorSets = descriptorSets,
            .descriptorPool = descriptorPool,
        };
    }

    pub fn resizeElementsCapacity(self: *@This(), logicalDevice: c.VkDevice, physicalDevice: c.VkPhysicalDevice, newCapacity: usize) !void {
        std.log.debug("increasing concurrent element capacity from {d} to {d}", .{ self.shaderBuffersMapped[0].len, newCapacity });
        for (self.shaderBuffers) |buffer| {
            c.vkUnmapMemory(logicalDevice, buffer.memory);
            buffer.deinit(logicalDevice);
        }

        for (0..maxFramesInFlight) |i| {
            const buffer = try Buffer.init(
                logicalDevice,
                physicalDevice,
                @sizeOf(ElementRenderingData) * newCapacity,
                c.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT,
                c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
            );
            self.shaderBuffers[i] = buffer;
            var storageBufferData: ?*anyopaque = undefined;
            try ensureNoError(c.vkMapMemory(logicalDevice, buffer.memory, 0, buffer.size, 0, &storageBufferData));
            self.shaderBuffersMapped[i] = @as([*]ElementRenderingData, @ptrCast(@alignCast(storageBufferData)))[0..newCapacity];
        }

        for (self.shaderBuffers, 0..) |buffer, i| {
            const bufferInfo = c.VkDescriptorBufferInfo{
                .buffer = buffer.handle,
                .offset = 0,
                .range = c.VK_WHOLE_SIZE,
            };

            const descriptorWrite = c.VkWriteDescriptorSet{
                .sType = c.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
                .pNext = null,
                .dstSet = self.descriptorSets[i],
                .dstBinding = 0,
                .dstArrayElement = 0,
                .descriptorCount = 1,
                .descriptorType = c.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
                .pImageInfo = null,
                .pBufferInfo = &bufferInfo,
                .pTexelBufferView = null,
            };

            c.vkUpdateDescriptorSets(logicalDevice, 1, &descriptorWrite, 0, null);
        }
    }

    pub fn deinit(self: @This(), logicalDevice: c.VkDevice) void {
        c.vkDestroyDescriptorPool(logicalDevice, self.descriptorPool, null);

        for (self.shaderBuffers) |buffer| {
            c.vkUnmapMemory(logicalDevice, buffer.memory);
            buffer.deinit(logicalDevice);
        }

        c.vkDestroyDescriptorSetLayout(logicalDevice, self.shaderBufferDescriptorSetLayout, null);
        self.elementModel.deinit(logicalDevice);
        c.vkDestroyPipeline(logicalDevice, self.graphicsPipeline, null);
        c.vkDestroyPipelineLayout(logicalDevice, self.pipelineLayout, null);
    }
};

const TextPipeline = struct {
    pipelineLayout: c.VkPipelineLayout,
    graphicsPipeline: c.VkPipeline,

    descriptorSetLayout: c.VkDescriptorSetLayout,
    descriptorPool: c.VkDescriptorPool,
    descriptorSets: [maxFramesInFlight]c.VkDescriptorSet,

    fontTextureAtlas: TextureAtlas,
    glyphRenderingDataCache: std.AutoHashMap(GlyphRenderingKey, GlyphRenderingData),
    sampler: c.VkSampler,

    glyphModel: Model,

    shaderBuffers: [maxFramesInFlight]Buffer,
    shaderBuffersMapped: [maxFramesInFlight][]GlypRenderingShaderData,

    const GlyphRenderingData = struct {
        textureCoordinates: TextureAtlas.TextureCoordinates,
        bitmapWidth: u32,
        bitmapHeight: u32,
        bitmapLeft: i32,
        bitmapTop: i32,
    };

    const GlyphRenderingKey = struct {
        fontSize: u32,
        glyphIndex: u32,
        fontKey: u64,
    };

    pub const GlypRenderingShaderData = extern struct {
        modelViewProjectionMatrix: zmath.Mat,
        color: Vec4,
        uvOffset: [2]f32,
        uvSize: [2]f32,
    };

    const textVertexShader: []const u32 = @ptrCast(@alignCast(@embedFile("text_vertex_shader")));
    const textFragmentShader: []const u32 = @ptrCast(@alignCast(@embedFile("text_fragment_shader")));

    pub fn init(
        logicalDevice: c.VkDevice,
        physicalDevice: c.VkPhysicalDevice,
        graphicsQueue: c.VkQueue,
        commandPool: c.VkCommandPool,
        renderPass: c.VkRenderPass,
        allocator: std.mem.Allocator,
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

        var pipelineLayout: c.VkPipelineLayout = undefined;
        try ensureNoError(c.vkCreatePipelineLayout(
            logicalDevice,
            &c.VkPipelineLayoutCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO,
                .pNext = null,
                .flags = 0,
                .setLayoutCount = 1,
                .pSetLayouts = &descriptorSetLayout,
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

        const glyphModel = try Model.init(
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

        const initialGlyphCapacity = 1;

        var shaderBuffers: [maxFramesInFlight]Buffer = undefined;
        var shaderBuffersMapped: [maxFramesInFlight][]GlypRenderingShaderData = undefined;
        for (0..maxFramesInFlight) |i| {
            const buffer = try Buffer.init(
                logicalDevice,
                physicalDevice,
                @sizeOf(GlypRenderingShaderData) * initialGlyphCapacity,
                c.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT,
                c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
            );
            shaderBuffers[i] = buffer;
            var storageBufferData: ?*anyopaque = undefined;
            try ensureNoError(c.vkMapMemory(logicalDevice, buffer.memory, 0, buffer.size, 0, &storageBufferData));
            shaderBuffersMapped[i] = @as([*]GlypRenderingShaderData, @ptrCast(@alignCast(storageBufferData)))[0..initialGlyphCapacity];
        }

        var fontTextureAtlas = try TextureAtlas.init(
            logicalDevice,
            physicalDevice,
            allocator,
            commandPool,
            graphicsQueue,
        );
        errdefer fontTextureAtlas.deinit(logicalDevice, allocator);

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
            .borderColor = c.VK_BORDER_COLOR_INT_OPAQUE_BLACK,
            .unnormalizedCoordinates = c.VK_FALSE,
            .compareEnable = c.VK_FALSE,
            .compareOp = c.VK_COMPARE_OP_ALWAYS,
            .mipmapMode = c.VK_SAMPLER_MIPMAP_MODE_LINEAR,
            .mipLodBias = 0.0,
            .minLod = 0.0,
            .maxLod = 0.0,
            .pNext = null,
            .flags = 0,
        }, null, &sampler));

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

        for (0..maxFramesInFlight) |i| {
            const bufferInfo = c.VkDescriptorBufferInfo{
                .buffer = shaderBuffers[i].handle,
                .offset = 0,
                .range = c.VK_WHOLE_SIZE,
            };

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
                    .dstBinding = 0,
                    .dstArrayElement = 0,
                    .descriptorCount = 1,
                    .descriptorType = c.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
                    .pImageInfo = null,
                    .pBufferInfo = &bufferInfo,
                    .pTexelBufferView = null,
                },
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
            .pipelineLayout = pipelineLayout,
            .graphicsPipeline = graphicsPipeline,
            .glyphModel = glyphModel,

            .descriptorSetLayout = descriptorSetLayout,
            .shaderBuffers = shaderBuffers,
            .shaderBuffersMapped = shaderBuffersMapped,
            .descriptorSets = descriptorSets,
            .descriptorPool = descriptorPool,

            .glyphRenderingDataCache = std.AutoHashMap(GlyphRenderingKey, GlyphRenderingData).init(allocator),
            .fontTextureAtlas = fontTextureAtlas,
            .sampler = sampler,
        };
    }

    pub fn resizeGlyphsCapacity(self: *@This(), logicalDevice: c.VkDevice, physicalDevice: c.VkPhysicalDevice, newCapacity: usize) !void {
        std.log.debug("increasing concurrent glyph capacity from {d} to {d}", .{ self.shaderBuffersMapped[0].len, newCapacity });
        for (self.shaderBuffers) |buffer| {
            c.vkUnmapMemory(logicalDevice, buffer.memory);
            buffer.deinit(logicalDevice);
        }

        for (0..maxFramesInFlight) |i| {
            const buffer = try Buffer.init(
                logicalDevice,
                physicalDevice,
                @sizeOf(GlypRenderingShaderData) * newCapacity,
                c.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT,
                c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
            );
            self.shaderBuffers[i] = buffer;
            var storageBufferData: ?*anyopaque = undefined;
            try ensureNoError(c.vkMapMemory(logicalDevice, buffer.memory, 0, buffer.size, 0, &storageBufferData));
            self.shaderBuffersMapped[i] = @as([*]GlypRenderingShaderData, @ptrCast(@alignCast(storageBufferData)))[0..newCapacity];
        }

        for (0..maxFramesInFlight) |i| {
            const bufferInfo = c.VkDescriptorBufferInfo{
                .buffer = self.shaderBuffers[i].handle,
                .offset = 0,
                .range = c.VK_WHOLE_SIZE,
            };

            const imageInfo = c.VkDescriptorImageInfo{
                .imageLayout = c.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
                .imageView = self.fontTextureAtlas.imageView,
                .sampler = self.sampler,
            };

            const descriptorWrites = [_]c.VkWriteDescriptorSet{
                .{
                    .sType = c.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
                    .pNext = null,
                    .dstSet = self.descriptorSets[i],
                    .dstBinding = 0,
                    .dstArrayElement = 0,
                    .descriptorCount = 1,
                    .descriptorType = c.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
                    .pImageInfo = null,
                    .pBufferInfo = &bufferInfo,
                    .pTexelBufferView = null,
                },
                .{
                    .sType = c.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
                    .pNext = null,
                    .dstSet = self.descriptorSets[i],
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
    }

    pub fn deinit(self: *@This(), logicalDevice: c.VkDevice, allocator: std.mem.Allocator) void {
        c.vkDestroySampler(logicalDevice, self.sampler, null);
        c.vkDestroyDescriptorPool(logicalDevice, self.descriptorPool, null);
        self.fontTextureAtlas.deinit(logicalDevice, allocator);
        self.glyphRenderingDataCache.deinit();

        for (self.shaderBuffers) |buffer| {
            c.vkUnmapMemory(logicalDevice, buffer.memory);
            buffer.deinit(logicalDevice);
        }

        c.vkDestroyDescriptorSetLayout(logicalDevice, self.descriptorSetLayout, null);
        self.glyphModel.deinit(logicalDevice);
        c.vkDestroyPipeline(logicalDevice, self.graphicsPipeline, null);
        c.vkDestroyPipelineLayout(logicalDevice, self.pipelineLayout, null);
    }
};

const maxFramesInFlight = 2;

pub const Renderer = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    graphics: *const Graphics,

    physicalDevice: c.VkPhysicalDevice,
    logicalDevice: c.VkDevice,
    graphicsQueue: c.VkQueue,
    graphicsQueueFamilyIndex: u32,
    presentationQueue: c.VkQueue,
    presentationQueueFamilyIndex: u32,

    surface: c.VkSurfaceKHR,
    swapchain: Swapchain,
    swapchainFramebuffers: []c.VkFramebuffer,

    elementsPipeline: ElementsPipeline,
    textPipeline: TextPipeline,
    renderPass: c.VkRenderPass,

    commandPool: c.VkCommandPool,
    commandBuffers: [maxFramesInFlight]c.VkCommandBuffer,
    commandBuffersAllocated: bool,

    inFlightFences: [maxFramesInFlight]c.VkFence,
    imageAvailableSemaphores: [maxFramesInFlight]c.VkSemaphore,
    renderFinishedSemaphores: []c.VkSemaphore,

    currentFrame: usize,

    pub fn recreateSwapchain(self: *Self, width: u32, height: u32, scale: u32) !void {
        _ = c.vkDeviceWaitIdle(self.logicalDevice);
        self.swapchain.deinit(self.logicalDevice);
        destroyFramebuffers(self.swapchainFramebuffers, self.logicalDevice, self.allocator);

        self.swapchain = try Swapchain.init(
            self.physicalDevice,
            self.logicalDevice,
            self.presentationQueueFamilyIndex,
            self.presentationQueue,
            self.graphicsQueueFamilyIndex,
            self.graphicsQueue,
            self.surface,
            (width * scale) / 120,
            (height * scale) / 120,
            self.allocator,
        );
        errdefer self.swapchain.deinit(self.logicalDevice);

        self.swapchainFramebuffers = try createFramebuffers(self.logicalDevice, self.renderPass, self.swapchain, self.allocator);
    }

    pub fn viewportSize(self: *Self) Vec2 {
        return .{ @floatFromInt(self.swapchain.extent.width), @floatFromInt(self.swapchain.extent.height) };
    }

    fn init(
        surface: c.VkSurfaceKHR,
        graphics: *const Graphics,
        width: u32,
        height: u32,
        scale: u32,
    ) !Renderer {
        const requiredDeviceExtensions: []const [*c]const u8 = &(.{
            c.VK_KHR_SWAPCHAIN_EXTENSION_NAME,
        } ++ switch (builtin.os.tag) {
            // .macos => .{
            //     "VK_KHR_portability_subset",
            // },
            else => .{},
        });

        var preferred: ?struct {
            device: Device,
            graphicsQueueFamilyIndex: u32,
            presentationQueueFamilyIndex: u32,
            score: usize,
        } = null;
        blk: for (graphics.devices) |device| {
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
                    continue :blk;
                }
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
        try ensureNoError(c.vkCreateDevice(
            physicalDevice,
            &c.VkDeviceCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
                .pNext = &c.VkPhysicalDeviceVulkan12Features{
                    .sType = c.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_2_FEATURES,
                    .bufferDeviceAddress = c.VK_TRUE,
                    .shaderInt8 = c.VK_TRUE,
                },
                .flags = 0,
                .queueCreateInfoCount = @intCast(queueCreateInfos.len),
                .pQueueCreateInfos = queueCreateInfos.ptr,
                .pEnabledFeatures = &c.VkPhysicalDeviceFeatures{
                    .shaderInt16 = c.VK_TRUE,
                    .shaderInt64 = c.VK_TRUE,
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

        const swapchain = try Swapchain.init(
            physicalDevice,
            logicalDevice,
            presentationQueueFamilyIndex,
            presentationQueue,
            graphicsQueueFamilyIndex,
            graphicsQueue,
            surface,
            (width * scale) / 120,
            (height * scale) / 120,
            graphics.allocator,
        );
        errdefer swapchain.deinit(logicalDevice);

        const renderPassDependencies: []const c.VkSubpassDependency = &.{
            c.VkSubpassDependency{
                .srcSubpass = c.VK_SUBPASS_EXTERNAL,
                .dstSubpass = 0,
                .srcStageMask = c.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
                .srcAccessMask = 0,
                .dstStageMask = c.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
                .dstAccessMask = c.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT,
            },
        };

        var renderPass: c.VkRenderPass = undefined;
        try ensureNoError(c.vkCreateRenderPass(
            logicalDevice,
            &c.VkRenderPassCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO,
                .attachmentCount = 1,
                .pAttachments = &c.VkAttachmentDescription{
                    .format = swapchain.surfaceFormat.format,
                    .samples = c.VK_SAMPLE_COUNT_1_BIT,
                    .loadOp = c.VK_ATTACHMENT_LOAD_OP_CLEAR,
                    .storeOp = c.VK_ATTACHMENT_STORE_OP_STORE,
                    .stencilLoadOp = c.VK_ATTACHMENT_LOAD_OP_DONT_CARE,
                    .stencilStoreOp = c.VK_ATTACHMENT_STORE_OP_DONT_CARE,
                    .initialLayout = c.VK_IMAGE_LAYOUT_UNDEFINED,
                    .finalLayout = c.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR,
                    .flags = 0,
                },
                .subpassCount = 1,
                .pSubpasses = &c.VkSubpassDescription{
                    .pipelineBindPoint = c.VK_PIPELINE_BIND_POINT_GRAPHICS,
                    .colorAttachmentCount = 1,
                    .pColorAttachments = &c.VkAttachmentReference{
                        .attachment = 0,
                        .layout = c.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
                    },
                },
                .flags = 0,
                .dependencyCount = @intCast(renderPassDependencies.len),
                .pDependencies = renderPassDependencies.ptr,
            },
            null,
            &renderPass,
        ));
        errdefer c.vkDestroyRenderPass(logicalDevice, renderPass, null);

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

        const elementsPipeline = try ElementsPipeline.init(
            logicalDevice,
            physicalDevice,
            graphicsQueue,
            commandPool,
            renderPass,
        );
        errdefer elementsPipeline.deinit(logicalDevice);

        var textPipeline = try TextPipeline.init(
            logicalDevice,
            physicalDevice,
            graphicsQueue,
            commandPool,
            renderPass,
            graphics.allocator,
        );
        errdefer textPipeline.deinit(logicalDevice, graphics.allocator);

        const framebuffers = try createFramebuffers(logicalDevice, renderPass, swapchain, graphics.allocator);
        errdefer destroyFramebuffers(framebuffers, logicalDevice, graphics.allocator);

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
                },
                null,
                &inFlightFences[i],
            ));

            try ensureNoError(c.vkCreateSemaphore(
                logicalDevice,
                &c.VkSemaphoreCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO,
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

        const swapchain_images = swapchain.images;
        const renderFinishedSemaphores = try graphics.allocator.alloc(c.VkSemaphore, swapchain_images.len);
        errdefer graphics.allocator.free(renderFinishedSemaphores);

        for (renderFinishedSemaphores) |*semaphore| {
            try ensureNoError(c.vkCreateSemaphore(
                logicalDevice,
                &c.VkSemaphoreCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO,
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

            .physicalDevice = physicalDevice,
            .logicalDevice = logicalDevice,
            .graphicsQueue = graphicsQueue,
            .graphicsQueueFamilyIndex = graphicsQueueFamilyIndex,
            .presentationQueue = presentationQueue,
            .presentationQueueFamilyIndex = presentationQueueFamilyIndex,

            .surface = surface,
            .swapchain = swapchain,
            .swapchainFramebuffers = framebuffers,

            .elementsPipeline = elementsPipeline,
            .textPipeline = textPipeline,
            .renderPass = renderPass,

            .commandPool = commandPool,
            .commandBuffers = commandBuffers,
            .commandBuffersAllocated = true,

            .inFlightFences = inFlightFences,
            .imageAvailableSemaphores = imageAvailableSemaphores,
            .renderFinishedSemaphores = renderFinishedSemaphores,

            .currentFrame = 0,
        };
    }

    pub fn setupResizingHandler(self: *Self, window: *Window) void {
        window.setResizeHandler(
            (struct {
                fn handler(_: *Window, new_width: u32, new_height: u32, new_scale: u32, data: *anyopaque) void {
                    recreateSwapchain(@ptrCast(@alignCast(data)), new_width, new_height, new_scale) catch |err| {
                        std.log.err("Failed to recreate swapchain on window resize {}", .{err});
                        @panic("Failed to recreate swapchain on window resize");
                    };
                }
            }).handler,
            @ptrCast(@alignCast(self)),
        );
    }

    pub fn deinit(self: *Self) void {
        _ = c.vkDeviceWaitIdle(self.logicalDevice);

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
        destroyFramebuffers(self.swapchainFramebuffers, self.logicalDevice, self.allocator);
        self.elementsPipeline.deinit(self.logicalDevice);
        self.textPipeline.deinit(self.logicalDevice, self.allocator);
        c.vkDestroyRenderPass(self.logicalDevice, self.renderPass, null);
        self.swapchain.deinit(self.logicalDevice);
        c.vkDestroyDevice(self.logicalDevice, null);
        c.vkDestroySurfaceKHR(self.graphics.vulkanInstance, self.surface, null);
    }

    pub fn drawFrame(self: *Self, rootLayoutBox: *const LayoutBox) !void {
        try ensureNoError(c.vkWaitForFences(
            self.logicalDevice,
            1,
            &self.inFlightFences[self.currentFrame],
            c.VK_TRUE,
            std.math.maxInt(u64),
        ));
        try ensureNoError(c.vkResetFences(self.logicalDevice, 1, &self.inFlightFences[self.currentFrame]));

        var imageIndex: u32 = undefined;
        try ensureNoError(c.vkAcquireNextImageKHR(
            self.logicalDevice,
            self.swapchain.handle,
            std.math.maxInt(u64),
            self.imageAvailableSemaphores[self.currentFrame],
            null,
            &imageIndex,
        ));

        try ensureNoError(c.vkResetCommandBuffer(self.commandBuffers[self.currentFrame], 0));

        try ensureNoError(c.vkBeginCommandBuffer(self.commandBuffers[self.currentFrame], &c.VkCommandBufferBeginInfo{
            .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
            .pNext = null,
            .flags = 0,
            .pInheritanceInfo = null,
        }));

        const framebuffers = self.swapchainFramebuffers;
        const framebuffer_index: usize = @intCast(imageIndex);

        c.vkCmdBeginRenderPass(
            self.commandBuffers[self.currentFrame],
            &c.VkRenderPassBeginInfo{
                .sType = c.VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO,
                .pNext = null,
                .renderPass = self.renderPass,
                .framebuffer = framebuffers[framebuffer_index],
                .renderArea = c.VkRect2D{
                    .offset = c.VkOffset2D{ .x = 0, .y = 0 },
                    .extent = self.swapchain.extent,
                },
                .clearValueCount = 1,
                .pClearValues = &c.VkClearValue{
                    .color = c.VkClearColorValue{
                        .float32 = .{ 0.0, 0.0, 0.0, 1.0 },
                    },
                },
            },
            c.VK_SUBPASS_CONTENTS_INLINE,
        );

        c.vkCmdBindPipeline(
            self.commandBuffers[self.currentFrame],
            c.VK_PIPELINE_BIND_POINT_GRAPHICS,
            self.elementsPipeline.graphicsPipeline,
        );

        c.vkCmdSetViewport(self.commandBuffers[self.currentFrame], 0, 1, &[_]c.VkViewport{c.VkViewport{
            .x = 0.0,
            .y = 0.0,
            .width = @floatFromInt(self.swapchain.extent.width),
            .height = @floatFromInt(self.swapchain.extent.height),
            .minDepth = 0.0,
            .maxDepth = 1.0,
        }});

        c.vkCmdSetScissor(self.commandBuffers[self.currentFrame], 0, 1, &[_]c.VkRect2D{c.VkRect2D{
            .offset = c.VkOffset2D{ .x = 0, .y = 0 },
            .extent = self.swapchain.extent,
        }});

        const projectionMatrix = zmath.orthographicOffCenterRh(
            0.0,
            @floatFromInt(self.swapchain.extent.width),
            @floatFromInt(self.swapchain.extent.height),
            0.0,
            -1000.0,
            1000.0,
        );

        const layoutBoxCount = countTreeSize(rootLayoutBox);
        if (layoutBoxCount > self.elementsPipeline.shaderBuffersMapped[0].len) {
            try self.elementsPipeline.resizeElementsCapacity(
                self.logicalDevice,
                self.physicalDevice,
                try std.math.ceilPowerOfTwo(usize, layoutBoxCount),
            );
        }
        var layoutTreeIterator = try LayoutTreeIterator.init(self.allocator, rootLayoutBox);
        defer layoutTreeIterator.deinit();
        var totalGlyphCount: usize = 0;
        var i: usize = 0;
        while (try layoutTreeIterator.next()) |layoutBox| {
            if (layoutBox.children != null and layoutBox.children.? == .glyphs) {
                totalGlyphCount += layoutBox.children.?.glyphs.len;
            }
            self.elementsPipeline.shaderBuffersMapped[self.currentFrame][i] = ElementRenderingData{
                .modelViewProjectionMatrix = zmath.mul(
                    zmath.mul(
                        zmath.scaling(layoutBox.size[0], layoutBox.size[1], 1.0),
                        zmath.translation(layoutBox.position[0], layoutBox.position[1], 0.0),
                    ),
                    projectionMatrix,
                ),
                .backgroundColor = layoutBox.style.backgroundColor,
                .size = layoutBox.size,
                .borderRadius = layoutBox.style.borderRadius,
            };
            i += 1;
        }

        c.vkCmdBindDescriptorSets(
            self.commandBuffers[self.currentFrame],
            c.VK_PIPELINE_BIND_POINT_GRAPHICS,
            self.elementsPipeline.pipelineLayout,
            0,
            1,
            &self.elementsPipeline.descriptorSets[self.currentFrame],
            0,
            null,
        );

        c.vkCmdBindVertexBuffers(self.commandBuffers[self.currentFrame], 0, 1, &self.elementsPipeline.elementModel.vertexBuffer.handle, &@intCast(0));
        c.vkCmdDraw(self.commandBuffers[self.currentFrame], self.elementsPipeline.elementModel.vertexCount, @intCast(layoutBoxCount), 0, 0);

        if (totalGlyphCount > 0) {
            if (totalGlyphCount > self.textPipeline.shaderBuffersMapped[0].len) {
                try self.textPipeline.resizeGlyphsCapacity(
                    self.logicalDevice,
                    self.physicalDevice,
                    try std.math.ceilPowerOfTwo(usize, totalGlyphCount),
                );
            }

            var layoutTreeIteratorForText = try LayoutTreeIterator.init(self.allocator, rootLayoutBox);
            defer layoutTreeIteratorForText.deinit();
            var glyphIndex: usize = 0;
            while (try layoutTreeIteratorForText.next()) |layoutBox| {
                if (layoutBox.children) |children| {
                    if (children == .glyphs) {
                        for (children.glyphs) |glyph| {
                            const glyphRenderingKey = TextPipeline.GlyphRenderingKey{
                                .fontKey = layoutBox.style.font.key,
                                .fontSize = layoutBox.style.fontSize,
                                .glyphIndex = glyph.index,
                            };
                            const glyphRenderingData = blk: {
                                if (self.textPipeline.glyphRenderingDataCache.get(glyphRenderingKey)) |data| {
                                    break :blk data;
                                } else {
                                    const rasterizedGlyph = try layoutBox.style.font.rasterize(
                                        glyph.index,
                                        72, // @TODO: take this from the window
                                        72,
                                        @intCast(layoutBox.style.fontSize),
                                    );

                                    const textureCoordinates = try self.textPipeline.fontTextureAtlas.upload(
                                        rasterizedGlyph.bitmap,
                                        @intCast(rasterizedGlyph.width),
                                        @intCast(rasterizedGlyph.height),
                                        @intCast(@abs(rasterizedGlyph.pitch)),
                                        self.allocator,
                                    );
                                    const data = TextPipeline.GlyphRenderingData{
                                        .bitmapTop = @intCast(rasterizedGlyph.top),
                                        .bitmapLeft = @intCast(rasterizedGlyph.left),
                                        .bitmapWidth = @intCast(rasterizedGlyph.width),
                                        .bitmapHeight = @intCast(rasterizedGlyph.height),
                                        .textureCoordinates = textureCoordinates,
                                    };
                                    try self.textPipeline.glyphRenderingDataCache.put(glyphRenderingKey, data);
                                    break :blk data;
                                }
                            };

                            const left: f32 = @floatFromInt(glyphRenderingData.bitmapLeft);
                            const top: f32 = @floatFromInt(glyphRenderingData.bitmapTop);
                            const width: f32 = @floatFromInt(glyphRenderingData.bitmapWidth);
                            const height: f32 = @floatFromInt(glyphRenderingData.bitmapHeight);

                            const unitsPerEm: f32 = @floatFromInt(layoutBox.style.font.unitsPerEm());
                            const fontSize: f32 = @floatFromInt(layoutBox.style.fontSize);
                            const pixelAscent = (layoutBox.style.font.ascent() / unitsPerEm) * fontSize;

                            self.textPipeline.shaderBuffersMapped[self.currentFrame][glyphIndex] = TextPipeline.GlypRenderingShaderData{
                                .modelViewProjectionMatrix = zmath.mul(
                                    zmath.mul(
                                        zmath.scaling(width, height, 1.0),
                                        zmath.translation(
                                            layoutBox.position[0] + glyph.position[0] + left,
                                            layoutBox.position[1] + glyph.position[1] + pixelAscent - top,
                                            0.0,
                                        ),
                                    ),
                                    projectionMatrix,
                                ),
                                .color = layoutBox.style.color,
                                .uvOffset = .{
                                    glyphRenderingData.textureCoordinates.u / @as(f32, @floatFromInt(self.textPipeline.fontTextureAtlas.capacityExtent.width)),
                                    glyphRenderingData.textureCoordinates.v / @as(f32, @floatFromInt(self.textPipeline.fontTextureAtlas.capacityExtent.height)),
                                },
                                .uvSize = .{
                                    glyphRenderingData.textureCoordinates.w / @as(f32, @floatFromInt(self.textPipeline.fontTextureAtlas.capacityExtent.width)),
                                    glyphRenderingData.textureCoordinates.h / @as(f32, @floatFromInt(self.textPipeline.fontTextureAtlas.capacityExtent.height)),
                                },
                            };
                            glyphIndex += 1;
                        }
                    }
                }
            }

            c.vkCmdBindPipeline(
                self.commandBuffers[self.currentFrame],
                c.VK_PIPELINE_BIND_POINT_GRAPHICS,
                self.textPipeline.graphicsPipeline,
            );

            c.vkCmdBindDescriptorSets(
                self.commandBuffers[self.currentFrame],
                c.VK_PIPELINE_BIND_POINT_GRAPHICS,
                self.textPipeline.pipelineLayout,
                0,
                1,
                &self.textPipeline.descriptorSets[self.currentFrame],
                0,
                null,
            );

            c.vkCmdBindVertexBuffers(self.commandBuffers[self.currentFrame], 0, 1, &self.textPipeline.glyphModel.vertexBuffer.handle, &@intCast(0));
            c.vkCmdDraw(self.commandBuffers[self.currentFrame], self.textPipeline.glyphModel.vertexCount, @intCast(totalGlyphCount), 0, 0);
        }

        c.vkCmdEndRenderPass(self.commandBuffers[self.currentFrame]);

        try ensureNoError(c.vkEndCommandBuffer(self.commandBuffers[self.currentFrame]));

        const waitSemaphores: []const c.VkSemaphore = &.{self.imageAvailableSemaphores[self.currentFrame]};
        const renderFinishedSemaphores = self.renderFinishedSemaphores;
        const signalSemaphores: []const c.VkSemaphore = &.{renderFinishedSemaphores[framebuffer_index]};
        const waitStages: []const c.VkPipelineStageFlags = &.{c.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT};

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
                .pCommandBuffers = &self.commandBuffers[self.currentFrame],
                .signalSemaphoreCount = @intCast(signalSemaphores.len),
                .pSignalSemaphores = signalSemaphores.ptr,
            },
            self.inFlightFences[self.currentFrame],
        ));

        try ensureNoError(c.vkQueuePresentKHR(self.presentationQueue, &c.VkPresentInfoKHR{
            .sType = c.VK_STRUCTURE_TYPE_PRESENT_INFO_KHR,
            .waitSemaphoreCount = @intCast(signalSemaphores.len),
            .pWaitSemaphores = signalSemaphores.ptr,
            .swapchainCount = 1,
            .pSwapchains = &self.swapchain.handle,
            .pImageIndices = &imageIndex,
            .pResults = null,
        }));

        self.currentFrame = (self.currentFrame + 1) % maxFramesInFlight;
    }

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

    fn querySwapchainSupport(surface: c.VkSurfaceKHR, device: c.VkPhysicalDevice, allocator: std.mem.Allocator) !SwapchainSupportDetails {
        var capabilities: c.VkSurfaceCapabilitiesKHR = undefined;
        try ensureNoError(c.vkGetPhysicalDeviceSurfaceCapabilitiesKHR(
            device,
            surface,
            &capabilities,
        ));

        var formatsLen: u32 = 0;
        try ensureNoError(c.vkGetPhysicalDeviceSurfaceFormatsKHR(
            device,
            surface,
            &formatsLen,
            null,
        ));
        const formats = try allocator.alloc(c.VkSurfaceFormatKHR, @intCast(formatsLen));
        errdefer allocator.free(formats);
        try ensureNoError(c.vkGetPhysicalDeviceSurfaceFormatsKHR(
            device,
            surface,
            &formatsLen,
            formats.ptr,
        ));

        var presentModesLen: u32 = 0;
        try ensureNoError(c.vkGetPhysicalDeviceSurfacePresentModesKHR(
            device,
            surface,
            &presentModesLen,
            null,
        ));
        const presentModes = try allocator.alloc(c.VkPresentModeKHR, @intCast(presentModesLen));
        errdefer allocator.free(presentModes);
        try ensureNoError(c.vkGetPhysicalDeviceSurfacePresentModesKHR(
            device,
            surface,
            &presentModesLen,
            presentModes.ptr,
        ));

        return .{
            .capabilities = capabilities,
            .formats = formats,
            .presentModes = presentModes,
            .allocator = allocator,
        };
    }

    const Swapchain = struct {
        handle: c.VkSwapchainKHR,
        surfaceFormat: c.VkSurfaceFormatKHR,
        presentMode: c.VkPresentModeKHR,
        extent: c.VkExtent2D,

        images: []c.VkImage,
        imageViews: []c.VkImageView,

        allocator: std.mem.Allocator,

        fn init(
            physicalDevice: c.VkPhysicalDevice,
            logicalDevice: c.VkDevice,
            presentationQueueFamilyIndex: u32,
            presentationQueue: c.VkQueue,
            graphicsQueueFamilyIndex: u32,
            graphicsQueue: c.VkQueue,
            surface: c.VkSurfaceKHR,
            width: u32,
            height: u32,
            allocator: std.mem.Allocator,
        ) !Swapchain {
            const swapchainSupportDetails = try querySwapchainSupport(surface, physicalDevice, allocator);
            defer swapchainSupportDetails.deinit();

            var surfaceFormat: c.VkSurfaceFormatKHR = swapchainSupportDetails.formats[0];
            for (swapchainSupportDetails.formats) |availableFormat| {
                if (availableFormat.format == c.VK_FORMAT_B8G8R8A8_SRGB and
                    availableFormat.colorSpace == c.VK_COLOR_SPACE_SRGB_NONLINEAR_KHR)
                {
                    surfaceFormat = availableFormat;
                    break;
                }
            }

            var presentMode: c.VkPresentModeKHR = c.VK_PRESENT_MODE_FIFO_KHR;
            for (swapchainSupportDetails.presentModes) |availablePresentMode| {
                if (availablePresentMode == c.VK_PRESENT_MODE_MAILBOX_KHR) {
                    presentMode = availablePresentMode;
                    break;
                }
            }

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
                    .imageSharingMode = if (presentationQueue == graphicsQueue)
                        c.VK_SHARING_MODE_EXCLUSIVE
                    else
                        c.VK_SHARING_MODE_CONCURRENT,
                    .queueFamilyIndexCount = if (presentationQueueFamilyIndex == graphicsQueueFamilyIndex) 0 else 2,
                    .pQueueFamilyIndices = if (presentationQueueFamilyIndex == graphicsQueueFamilyIndex)
                        null
                    else
                        &[_]u32{ graphicsQueueFamilyIndex, presentationQueueFamilyIndex },
                    .preTransform = swapchainSupportDetails.capabilities.currentTransform,
                    .compositeAlpha = c.VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR,
                    .presentMode = presentMode,
                    .clipped = c.VK_TRUE,
                    .oldSwapchain = null,
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
                            .r = c.VK_COMPONENT_SWIZZLE_IDENTITY,
                            .g = c.VK_COMPONENT_SWIZZLE_IDENTITY,
                            .b = c.VK_COMPONENT_SWIZZLE_IDENTITY,
                            .a = c.VK_COMPONENT_SWIZZLE_IDENTITY,
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
                .allocator = allocator,
            };
        }

        fn deinit(self: Swapchain, logicalDevice: c.VkDevice) void {
            for (self.imageViews) |imageView| {
                c.vkDestroyImageView(logicalDevice, imageView, null);
            }
            self.allocator.free(self.imageViews);
            self.allocator.free(self.images);

            c.vkDestroySwapchainKHR(logicalDevice, self.handle, null);
        }
    };

    fn createFramebuffers(
        logicalDevice: c.VkDevice,
        renderPass: c.VkRenderPass,
        swapchain: Swapchain,
        allocator: std.mem.Allocator,
    ) ![]c.VkFramebuffer {
        const imageViews = swapchain.imageViews;

        const swapchainFramebuffers = try allocator.alloc(c.VkFramebuffer, imageViews.len);
        errdefer {
            for (swapchainFramebuffers) |framebuffer| {
                if (framebuffer != null) {
                    c.vkDestroyFramebuffer(logicalDevice, framebuffer, null);
                }
            }
            allocator.free(swapchainFramebuffers);
        }

        for (swapchainFramebuffers) |*framebuffer| {
            framebuffer.* = null;
        }

        for (imageViews, 0..) |imageView, i| {
            try ensureNoError(c.vkCreateFramebuffer(
                logicalDevice,
                &c.VkFramebufferCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO,
                    .pNext = null,
                    .flags = 0,
                    .renderPass = renderPass,
                    .attachmentCount = 1,
                    .pAttachments = &imageView,
                    .width = swapchain.extent.width,
                    .height = swapchain.extent.height,
                    .layers = 1,
                },
                null,
                &swapchainFramebuffers[i],
            ));
        }

        return swapchainFramebuffers;
    }

    fn destroyFramebuffers(
        swapchainFramebuffers: []c.VkFramebuffer,
        logicalDevice: c.VkDevice,
        allocator: std.mem.Allocator,
    ) void {
        for (swapchainFramebuffers) |framebuffer| {
            c.vkDestroyFramebuffer(logicalDevice, framebuffer, null);
        }
        allocator.free(swapchainFramebuffers);
    }
};
