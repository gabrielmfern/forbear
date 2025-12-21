const std = @import("std");
const c = @import("c.zig").c;
const builtin = @import("builtin");
const Window = @import("window/root.zig");

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
    Unknown,
};

pub fn ensureNoError(result: c.VkResult) !void {
    if (result == c.VK_ERROR_EXTENSION_NOT_PRESENT) {
        return error.ExtensioNotPresent;
    } else if (result == c.VK_ERROR_INCOMPATIBLE_DRIVER) {
        return error.IncompatibleDriver;
    } else if (result == c.VK_ERROR_INITIALIZATION_FAILED) {
        return error.InitializationFailed;
    } else if (result == c.VK_ERROR_LAYER_NOT_PRESENT) {
        return error.LayerNotPresent;
    } else if (result == c.VK_ERROR_OUT_OF_DEVICE_MEMORY) {
        return error.OutOfDeviceMemory;
    } else if (result == c.VK_ERROR_OUT_OF_HOST_MEMORY) {
        return error.OutOfHostMemory;
    } else if (result == c.VK_ERROR_VALIDATION_FAILED) {
        return error.ValidationFailed;
    } else if (result == c.VK_ERROR_FEATURE_NOT_PRESENT) {
        return error.FeatureNotPresent;
    } else if (result == c.VK_ERROR_DEVICE_LOST) {
        return error.DeviceLost;
    } else if (result == c.VK_ERROR_TOO_MANY_OBJECTS) {
        return error.TooManyObjects;
    } else if (result == c.VK_ERROR_NATIVE_WINDOW_IN_USE_KHR) {
        return error.NativeWindowInUse;
    } else if (result == c.VK_ERROR_SURFACE_LOST_KHR) {
        return error.SurfaceLost;
    } else if (result == c.VK_ERROR_COMPRESSION_EXHAUSTED_EXT) {
        return error.CompressionExhausted;
    } else if (result == c.VK_ERROR_INVALID_OPAQUE_CAPTURE_ADDRESS_KHR) {
        return error.InvalidOpaqueCaptureAddress;
    } else if (result == c.VK_ERROR_INVALID_SHADER_NV) {
        return error.InvalidShaderNv;
    } else if (result == c.VK_ERROR_INVALID_VIDEO_STD_PARAMETERS_KHR) {
        return error.InvalidVideoStdParameters;
    } else if (result == c.VK_ERROR_FULL_SCREEN_EXCLUSIVE_MODE_LOST_EXT) {
        return error.FullScreenExclusiveModeLost;
    } else if (result == c.VK_ERROR_OUT_OF_DATE_KHR) {
        return error.OutOfDate;
    } else if (result == c.VK_ERROR_UNKNOWN) {
        return error.Unknown;
    }

    if (builtin.os.tag == .linux) {
        if (result == c.VK_ERROR_PRESENT_TIMING_QUEUE_FULL_EXT) {
            return error.PresentTimingQueueFullExt;
        }
    }

    std.debug.assert(result == c.VK_SUCCESS);
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

allocator: std.mem.Allocator,
application_name: [:0]const u8,

vulkanInstance: c.VkInstance,
vulkanDebugMessenger: c.VkDebugUtilsMessengerEXT,

physicalDevice: c.VkPhysicalDevice,
logicalDevice: c.VkDevice,

graphicsQueueFamilyIndex: u32,
presentationQueueFamilyIndex: u32,

graphicsQueue: c.VkQueue,
presentationQueue: c.VkQueue,

pub fn init(application_name: [:0]const u8, allocator: std.mem.Allocator) !*Graphics {
    const self = try allocator.create(Graphics);
    errdefer allocator.destroy(self);

    self.* = .{
        .allocator = allocator,
        .application_name = application_name,
        .vulkanInstance = null,
        .vulkanDebugMessenger = null,
        .physicalDevice = null,
        .logicalDevice = null,
        .graphicsQueueFamilyIndex = 0,
        .presentationQueueFamilyIndex = 0,
        .graphicsQueue = null,
        .presentationQueue = null,
    };

    try self.createInstance();
    errdefer self.destroyInstance();

    try self.createDebugMessenger();
    errdefer self.destroyDebugMessenger();

    try self.pickPhysicalDevice();

    return self;
}

pub fn deinit(self: *Graphics) void {
    if (self.logicalDevice) |device| {
        _ = c.vkDeviceWaitIdle(device);
        c.vkDestroyDevice(device, null);
        self.logicalDevice = null;
    }

    self.destroyDebugMessenger();
    self.destroyInstance();

    const allocator = self.allocator;
    allocator.destroy(self);
}

pub fn ensureDeviceForSurface(self: *Graphics, surface: c.VkSurfaceKHR) !void {
    const indices = try self.findQueueFamiliesForSurface(surface) orelse return error.NoSuitableQueueFamilies;

    if (self.logicalDevice != null) {
        if (indices.graphics != self.graphicsQueueFamilyIndex or indices.presentation != self.presentationQueueFamilyIndex) {
            return error.DifferentQueueFamiliesForSurface;
        }

        var supportsPresentation: u32 = c.VK_FALSE;
        try ensureNoError(c.vkGetPhysicalDeviceSurfaceSupportKHR(
            self.physicalDevice,
            self.presentationQueueFamilyIndex,
            surface,
            &supportsPresentation,
        ));
        if (supportsPresentation != c.VK_TRUE) {
            return error.SurfaceNotSupportedByPresentationQueue;
        }

        return;
    }

    self.graphicsQueueFamilyIndex = indices.graphics;
    self.presentationQueueFamilyIndex = indices.presentation;

    const requiredDeviceExtensions: []const [*c]const u8 = switch (builtin.os.tag) {
        .macos => &.{
            c.VK_KHR_SWAPCHAIN_EXTENSION_NAME,
            "VK_KHR_portability_subset",
        },
        else => &.{
            c.VK_KHR_SWAPCHAIN_EXTENSION_NAME,
        },
    };

    const queueCreateInfos: []const c.VkDeviceQueueCreateInfo = if (self.graphicsQueueFamilyIndex == self.presentationQueueFamilyIndex) &.{.{
        .sType = c.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
        .pNext = null,
        .flags = 0,
        .queueFamilyIndex = self.graphicsQueueFamilyIndex,
        .queueCount = 1,
        .pQueuePriorities = &@as(f32, 1.0),
    }} else &.{
        .{
            .sType = c.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
            .pNext = null,
            .flags = 0,
            .queueFamilyIndex = self.graphicsQueueFamilyIndex,
            .queueCount = 1,
            .pQueuePriorities = &@as(f32, 1.0),
        },
        .{
            .sType = c.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
            .pNext = null,
            .flags = 0,
            .queueFamilyIndex = self.presentationQueueFamilyIndex,
            .queueCount = 1,
            .pQueuePriorities = &@as(f32, 1.0),
        },
    };

    var logicalDevice: c.VkDevice = undefined;
    try ensureNoError(c.vkCreateDevice(
        self.physicalDevice,
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

    std.debug.assert(logicalDevice != null);
    self.logicalDevice = logicalDevice;

    c.vkGetDeviceQueue(self.logicalDevice, self.graphicsQueueFamilyIndex, 0, &self.graphicsQueue);
    std.debug.assert(self.graphicsQueue != null);

    c.vkGetDeviceQueue(self.logicalDevice, self.presentationQueueFamilyIndex, 0, &self.presentationQueue);
    std.debug.assert(self.presentationQueue != null);
}

const QueueIndices = struct {
    graphics: u32,
    presentation: u32,
};

fn findQueueFamiliesForSurface(self: *Graphics, surface: c.VkSurfaceKHR) !?QueueIndices {
    var queueFamiliesLen: u32 = undefined;
    c.vkGetPhysicalDeviceQueueFamilyProperties(
        self.physicalDevice,
        &queueFamiliesLen,
        null,
    );

    const queueFamilies = try self.allocator.alloc(
        c.VkQueueFamilyProperties,
        @intCast(queueFamiliesLen),
    );
    defer self.allocator.free(queueFamilies);

    c.vkGetPhysicalDeviceQueueFamilyProperties(
        self.physicalDevice,
        &queueFamiliesLen,
        queueFamilies.ptr,
    );

    var graphics: ?u32 = null;
    var presentation: ?u32 = null;

    for (queueFamilies, 0..) |queueFamily, index| {
        if ((queueFamily.queueFlags & c.VK_QUEUE_GRAPHICS_BIT) != 0) {
            graphics = @intCast(index);
        }

        var supportsPresentation: u32 = c.VK_FALSE;
        try ensureNoError(c.vkGetPhysicalDeviceSurfaceSupportKHR(
            self.physicalDevice,
            @intCast(index),
            surface,
            &supportsPresentation,
        ));

        if (supportsPresentation == c.VK_TRUE) {
            presentation = @intCast(index);
        }

        if (graphics != null and presentation != null) {
            return .{
                .graphics = graphics.?,
                .presentation = presentation.?,
            };
        }
    }

    return null;
}

fn destroyDebugMessenger(self: *Graphics) void {
    if (self.vulkanDebugMessenger) |debug_messenger| {
        DestroyDebugUtilsMessengerEXT(self.vulkanInstance, debug_messenger, null);
        self.vulkanDebugMessenger = null;
    }
}

fn destroyInstance(self: *Graphics) void {
    if (self.vulkanInstance) |instance| {
        c.vkDestroyInstance(instance, null);
        self.vulkanInstance = null;
    }
}

fn createInstance(self: *Graphics) !void {
    const instanceExtensions: []const [*c]const u8 = switch (builtin.os.tag) {
        .linux => &.{
            c.VK_KHR_SURFACE_EXTENSION_NAME,
            "VK_KHR_wayland_surface",
            c.VK_KHR_PORTABILITY_ENUMERATION_EXTENSION_NAME,
            c.VK_EXT_DEBUG_UTILS_EXTENSION_NAME,
        },
        .macos => &.{
            c.VK_KHR_SURFACE_EXTENSION_NAME,
            "VK_EXT_metal_surface",
            c.VK_KHR_PORTABILITY_ENUMERATION_EXTENSION_NAME,
            c.VK_EXT_DEBUG_UTILS_EXTENSION_NAME,
        },
        else => &.{
            c.VK_KHR_SURFACE_EXTENSION_NAME,
            c.VK_KHR_PORTABILITY_ENUMERATION_EXTENSION_NAME,
            c.VK_EXT_DEBUG_UTILS_EXTENSION_NAME,
        },
    };

    const instanceLayers: []const [*c]const u8 = &.{
        "VK_LAYER_KHRONOS_validation",
    };

    var vulkanInstance: c.VkInstance = undefined;
    try ensureNoError(c.vkCreateInstance(
        &c.VkInstanceCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
            .flags = c.VK_INSTANCE_CREATE_ENUMERATE_PORTABILITY_BIT_KHR,
            .pNext = null,
            .pApplicationInfo = &c.VkApplicationInfo{
                .sType = c.VK_STRUCTURE_TYPE_APPLICATION_INFO,
                .pNext = null,
                .pApplicationName = self.application_name.ptr,
                .applicationVersion = c.VK_MAKE_VERSION(1, 0, 0),
                .pEngineName = "No Engine",
                .engineVersion = c.VK_MAKE_VERSION(1, 0, 0),
                .apiVersion = c.VK_API_VERSION_1_2,
            },
            .enabledLayerCount = instanceLayers.len,
            .ppEnabledLayerNames = instanceLayers.ptr,
            .enabledExtensionCount = instanceExtensions.len,
            .ppEnabledExtensionNames = instanceExtensions.ptr,
        },
        null,
        &vulkanInstance,
    ));

    std.debug.assert(vulkanInstance != null);
    self.vulkanInstance = vulkanInstance;
}

fn createDebugMessenger(self: *Graphics) !void {
    var vulkanDebugMessenger: c.VkDebugUtilsMessengerEXT = undefined;
    try ensureNoError(CreateDebugUtilsMessengerEXT(
        self.vulkanInstance,
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

                    const message = std.mem.span(callbackData.*.pMessage);
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
    ));

    std.debug.assert(vulkanDebugMessenger != null);
    self.vulkanDebugMessenger = vulkanDebugMessenger;
}

fn pickPhysicalDevice(self: *Graphics) !void {
    var physicalDevicesLen: u32 = undefined;
    try ensureNoError(c.vkEnumeratePhysicalDevices(
        self.vulkanInstance,
        &physicalDevicesLen,
        null,
    ));

    const physicalDevices = try self.allocator.alloc(
        c.VkPhysicalDevice,
        @intCast(physicalDevicesLen),
    );
    defer self.allocator.free(physicalDevices);

    try ensureNoError(c.vkEnumeratePhysicalDevices(
        self.vulkanInstance,
        &physicalDevicesLen,
        physicalDevices.ptr,
    ));

    const requiredDeviceExtensions: []const [*c]const u8 = switch (builtin.os.tag) {
        .macos => &.{
            c.VK_KHR_SWAPCHAIN_EXTENSION_NAME,
            "VK_KHR_portability_subset",
        },
        else => &.{
            c.VK_KHR_SWAPCHAIN_EXTENSION_NAME,
        },
    };

    var preferred: ?struct {
        device: c.VkPhysicalDevice,
        score: u32,
    } = null;

    blk: for (physicalDevices) |device| {
        var deviceProperties: c.VkPhysicalDeviceProperties = undefined;
        c.vkGetPhysicalDeviceProperties(device, &deviceProperties);

        var availableDeviceExtensionsLen: u32 = 0;
        try ensureNoError(c.vkEnumerateDeviceExtensionProperties(
            device,
            null,
            &availableDeviceExtensionsLen,
            null,
        ));

        const availableDeviceExtensions = try self.allocator.alloc(
            c.VkExtensionProperties,
            @intCast(availableDeviceExtensionsLen),
        );
        defer self.allocator.free(availableDeviceExtensions);

        try ensureNoError(c.vkEnumerateDeviceExtensionProperties(
            device,
            null,
            &availableDeviceExtensionsLen,
            availableDeviceExtensions.ptr,
        ));

        for (requiredDeviceExtensions) |extension| {
            const extensionSlice = std.mem.span(extension);
            var supported = false;
            for (availableDeviceExtensions) |availableExtension| {
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

        var score: u32 = deviceProperties.limits.maxImageDimension2D;
        if (deviceProperties.deviceType == c.VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU) {
            score += 1000;
        }

        if (preferred) |currentPreferred| {
            if (score > currentPreferred.score) {
                preferred = .{ .device = device, .score = score };
            }
        } else {
            preferred = .{ .device = device, .score = score };
        }
    }

    if (preferred == null) {
        std.log.err("no suitable physical device found", .{});
        return error.NoSuitablePhysicalDevice;
    }

    self.physicalDevice = preferred.?.device;
}

const Graphics = @This();

pub fn initRenderer(
    self: *Graphics,
    window: *Window,
    vertex_shader_code: []const u32,
    fragment_shader_code: []const u32,
    allocator: std.mem.Allocator,
) !*Renderer {
    switch (builtin.os.tag) {
        .linux => return Renderer.initWayland(
            self,
            window.handle.wlDisplay,
            window.handle.wlSurface,
            window.width.*,
            window.height.*,
            vertex_shader_code,
            fragment_shader_code,
            allocator,
        ),
        .macos => return Renderer.initCocoa(
            self,
            window.handle.nativeMetalLayer(),
            window.width.*,
            window.height.*,
            vertex_shader_code,
            fragment_shader_code,
            allocator,
        ),

        else => return error.UnsupportedPlatform,
    }
}

pub const Renderer = struct {
    const Self = @This();

    const maxFramesInFlight = 2;

    allocator: std.mem.Allocator,
    ctx: *Graphics,

    surface: c.VkSurfaceKHR,

    surfaceFormat: c.VkSurfaceFormatKHR,
    presentMode: c.VkPresentModeKHR,
    swapchainExtent: c.VkExtent2D,

    swapchain: c.VkSwapchainKHR,
    swapChainImages: ?[]c.VkImage,
    imageViews: ?[]c.VkImageView,

    pipelineLayout: c.VkPipelineLayout,
    renderPass: c.VkRenderPass,
    graphicsPipeline: c.VkPipeline,

    swapchainFramebuffers: ?[]c.VkFramebuffer,

    commandPool: c.VkCommandPool,
    commandBuffers: [maxFramesInFlight]c.VkCommandBuffer,
    commandBuffersAllocated: bool,

    inFlightFences: [maxFramesInFlight]c.VkFence,
    imageAvailableSemaphores: [maxFramesInFlight]c.VkSemaphore,
    renderFinishedSemaphores: ?[]c.VkSemaphore,

    currentFrame: usize,

    pub fn initWayland(
        ctx: *Graphics,
        wlDisplay: *c.wl_display,
        wlSurface: *c.wl_surface,
        width: u32,
        height: u32,
        vertex_shader_code: []const u32,
        fragment_shader_code: []const u32,
        allocator: std.mem.Allocator,
    ) !*Self {
        const self = try allocator.create(Self);
        errdefer allocator.destroy(self);

        self.* = .{
            .allocator = allocator,
            .ctx = ctx,
            .surface = null,
            .surfaceFormat = undefined,
            .presentMode = undefined,
            .swapchainExtent = undefined,
            .swapchain = null,
            .swapChainImages = null,
            .imageViews = null,
            .pipelineLayout = null,
            .renderPass = null,
            .graphicsPipeline = null,
            .swapchainFramebuffers = null,
            .commandPool = null,
            .commandBuffers = .{null} ** maxFramesInFlight,
            .commandBuffersAllocated = false,
            .inFlightFences = .{null} ** maxFramesInFlight,
            .imageAvailableSemaphores = .{null} ** maxFramesInFlight,
            .renderFinishedSemaphores = null,
            .currentFrame = 0,
        };

        var vulkanSurface: c.VkSurfaceKHR = undefined;
        try ensureNoError(c.vkCreateWaylandSurfaceKHR(
            self.ctx.vulkanInstance,
            &c.VkWaylandSurfaceCreateInfoKHR{
                .sType = c.VK_STRUCTURE_TYPE_WAYLAND_SURFACE_CREATE_INFO_KHR,
                .pNext = null,
                .flags = 0,
                .display = wlDisplay,
                .surface = wlSurface,
            },
            null,
            &vulkanSurface,
        ));

        std.debug.assert(vulkanSurface != null);
        self.surface = vulkanSurface;
        errdefer self.destroySurface();

        try self.commonSetup(width, height, vertex_shader_code, fragment_shader_code);

        return self;
    }

    pub fn initCocoa(
        ctx: *Graphics,
        caMetalLayer: ?*anyopaque,
        width: u32,
        height: u32,
        vertex_shader_code: []const u32,
        fragment_shader_code: []const u32,
        allocator: std.mem.Allocator,
    ) !*Self {
        if (caMetalLayer == null) return error.NullNativeView;

        const self = try allocator.create(Self);
        errdefer allocator.destroy(self);

        self.* = .{
            .allocator = allocator,
            .ctx = ctx,
            .surface = null,
            .surfaceFormat = undefined,
            .presentMode = undefined,
            .swapchainExtent = undefined,
            .swapchain = null,
            .swapChainImages = null,
            .imageViews = null,
            .pipelineLayout = null,
            .renderPass = null,
            .graphicsPipeline = null,
            .swapchainFramebuffers = null,
            .commandPool = null,
            .commandBuffers = .{null} ** maxFramesInFlight,
            .commandBuffersAllocated = false,
            .inFlightFences = .{null} ** maxFramesInFlight,
            .imageAvailableSemaphores = .{null} ** maxFramesInFlight,
            .renderFinishedSemaphores = null,
            .currentFrame = 0,
        };

        var vulkanSurface: c.VkSurfaceKHR = undefined;
        try ensureNoError(c.vkCreateMetalSurfaceEXT(
            self.ctx.vulkanInstance,
            &c.VkMetalSurfaceCreateInfoEXT{
                .sType = c.VK_STRUCTURE_TYPE_METAL_SURFACE_CREATE_INFO_EXT,
                .pNext = null,
                .flags = 0,
                .pLayer = caMetalLayer,
            },
            null,
            &vulkanSurface,
        ));

        std.debug.assert(vulkanSurface != null);
        self.surface = vulkanSurface;
        errdefer self.destroySurface();

        try self.commonSetup(width, height, vertex_shader_code, fragment_shader_code);

        return self;
    }

    fn commonSetup(
        self: *Self,
        width: u32,
        height: u32,
        vertex_shader_code: []const u32,
        fragment_shader_code: []const u32,
    ) !void {
        try self.ctx.ensureDeviceForSurface(self.surface);

        try self.createSwapchain(width, height);
        errdefer self.destroySwapchain();

        try self.createPipeline(vertex_shader_code, fragment_shader_code);
        errdefer self.destroyPipeline();

        try self.createFramebuffers();
        errdefer self.destroyFramebuffers();

        try self.createCommandPool();
        errdefer self.destroyCommandPool();

        try self.allocateCommandBuffers();
        errdefer self.freeCommandBuffers();

        try self.createSyncObjects();
        errdefer self.destroySyncObjects();
    }

    pub fn deinit(self: *Self) void {
        if (self.ctx.logicalDevice) |device| {
            _ = c.vkDeviceWaitIdle(device);
        }

        self.destroySyncObjects();
        self.freeCommandBuffers();
        self.destroyCommandPool();
        self.destroyFramebuffers();
        self.destroyPipeline();
        self.destroySwapchain();
        self.destroySurface();

        const allocator = self.allocator;
        allocator.destroy(self);
    }

    pub fn drawFrame(self: *Self) !void {
        const device = self.ctx.logicalDevice;

        try ensureNoError(c.vkWaitForFences(
            device,
            1,
            &self.inFlightFences[self.currentFrame],
            c.VK_TRUE,
            std.math.maxInt(u64),
        ));
        try ensureNoError(c.vkResetFences(device, 1, &self.inFlightFences[self.currentFrame]));

        var imageIndex: u32 = undefined;
        try ensureNoError(c.vkAcquireNextImageKHR(
            device,
            self.swapchain,
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

        const framebuffers = self.swapchainFramebuffers orelse return error.FramebuffersNotInitialized;
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
                    .extent = self.swapchainExtent,
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
            self.graphicsPipeline,
        );

        c.vkCmdSetViewport(self.commandBuffers[self.currentFrame], 0, 1, &[_]c.VkViewport{c.VkViewport{
            .x = 0.0,
            .y = 0.0,
            .width = @floatFromInt(self.swapchainExtent.width),
            .height = @floatFromInt(self.swapchainExtent.height),
            .minDepth = 0.0,
            .maxDepth = 1.0,
        }});

        c.vkCmdSetScissor(self.commandBuffers[self.currentFrame], 0, 1, &[_]c.VkRect2D{c.VkRect2D{
            .offset = c.VkOffset2D{ .x = 0, .y = 0 },
            .extent = self.swapchainExtent,
        }});

        c.vkCmdDraw(self.commandBuffers[self.currentFrame], 3, 1, 0, 0);
        c.vkCmdEndRenderPass(self.commandBuffers[self.currentFrame]);

        try ensureNoError(c.vkEndCommandBuffer(self.commandBuffers[self.currentFrame]));

        const waitSemaphores: []const c.VkSemaphore = &.{self.imageAvailableSemaphores[self.currentFrame]};
        const render_finished_semaphores = self.renderFinishedSemaphores orelse return error.SyncObjectsNotInitialized;
        const signalSemaphores: []const c.VkSemaphore = &.{render_finished_semaphores[framebuffer_index]};
        const waitStages: []const c.VkPipelineStageFlags = &.{c.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT};

        try ensureNoError(c.vkQueueSubmit(
            self.ctx.graphicsQueue,
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

        try ensureNoError(c.vkQueuePresentKHR(self.ctx.presentationQueue, &c.VkPresentInfoKHR{
            .sType = c.VK_STRUCTURE_TYPE_PRESENT_INFO_KHR,
            .waitSemaphoreCount = @intCast(signalSemaphores.len),
            .pWaitSemaphores = signalSemaphores.ptr,
            .swapchainCount = 1,
            .pSwapchains = &self.swapchain,
            .pImageIndices = &imageIndex,
            .pResults = null,
        }));

        self.currentFrame = (self.currentFrame + 1) % maxFramesInFlight;
    }

    fn destroySurface(self: *Self) void {
        if (self.surface) |surface| {
            c.vkDestroySurfaceKHR(self.ctx.vulkanInstance, surface, null);
            self.surface = null;
        }
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

    fn querySwapchainSupport(self: *Self, device: c.VkPhysicalDevice) !SwapchainSupportDetails {
        var capabilities: c.VkSurfaceCapabilitiesKHR = undefined;
        try ensureNoError(c.vkGetPhysicalDeviceSurfaceCapabilitiesKHR(
            device,
            self.surface,
            &capabilities,
        ));

        var formatsLen: u32 = 0;
        try ensureNoError(c.vkGetPhysicalDeviceSurfaceFormatsKHR(
            device,
            self.surface,
            &formatsLen,
            null,
        ));
        const formats = try self.allocator.alloc(c.VkSurfaceFormatKHR, @intCast(formatsLen));
        errdefer self.allocator.free(formats);
        try ensureNoError(c.vkGetPhysicalDeviceSurfaceFormatsKHR(
            device,
            self.surface,
            &formatsLen,
            formats.ptr,
        ));

        var presentModesLen: u32 = 0;
        try ensureNoError(c.vkGetPhysicalDeviceSurfacePresentModesKHR(
            device,
            self.surface,
            &presentModesLen,
            null,
        ));
        const presentModes = try self.allocator.alloc(c.VkPresentModeKHR, @intCast(presentModesLen));
        errdefer self.allocator.free(presentModes);
        try ensureNoError(c.vkGetPhysicalDeviceSurfacePresentModesKHR(
            device,
            self.surface,
            &presentModesLen,
            presentModes.ptr,
        ));

        return .{
            .capabilities = capabilities,
            .formats = formats,
            .presentModes = presentModes,
            .allocator = self.allocator,
        };
    }

    fn createSwapchain(self: *Self, width: u32, height: u32) !void {
        const swapchainSupportDetails = try self.querySwapchainSupport(self.ctx.physicalDevice);
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
            self.ctx.logicalDevice,
            &c.VkSwapchainCreateInfoKHR{
                .sType = c.VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR,
                .surface = self.surface,
                .minImageCount = imageCount,
                .imageFormat = surfaceFormat.format,
                .imageColorSpace = surfaceFormat.colorSpace,
                .imageExtent = swapchainExtent,
                .imageArrayLayers = 1,
                .imageUsage = c.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT,
                .imageSharingMode = if (self.ctx.presentationQueue == self.ctx.graphicsQueue)
                    c.VK_SHARING_MODE_EXCLUSIVE
                else
                    c.VK_SHARING_MODE_CONCURRENT,
                .queueFamilyIndexCount = if (self.ctx.presentationQueueFamilyIndex == self.ctx.graphicsQueueFamilyIndex) 0 else 2,
                .pQueueFamilyIndices = if (self.ctx.presentationQueueFamilyIndex == self.ctx.graphicsQueueFamilyIndex)
                    null
                else
                    &[_]u32{ self.ctx.graphicsQueueFamilyIndex, self.ctx.presentationQueueFamilyIndex },
                .preTransform = swapchainSupportDetails.capabilities.currentTransform,
                .compositeAlpha = c.VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR,
                .presentMode = presentMode,
                .clipped = c.VK_TRUE,
                .oldSwapchain = null,
            },
            null,
            &swapchain,
        ));
        errdefer c.vkDestroySwapchainKHR(self.ctx.logicalDevice, swapchain, null);

        std.debug.assert(swapchain != null);
        self.swapchain = swapchain;
        self.surfaceFormat = surfaceFormat;
        self.presentMode = presentMode;
        self.swapchainExtent = swapchainExtent;

        var swapChainImagesLen: u32 = 0;
        try ensureNoError(c.vkGetSwapchainImagesKHR(
            self.ctx.logicalDevice,
            self.swapchain,
            &swapChainImagesLen,
            null,
        ));

        const swapChainImages = try self.allocator.alloc(c.VkImage, @intCast(swapChainImagesLen));
        errdefer self.allocator.free(swapChainImages);

        try ensureNoError(c.vkGetSwapchainImagesKHR(
            self.ctx.logicalDevice,
            self.swapchain,
            &swapChainImagesLen,
            swapChainImages.ptr,
        ));
        self.swapChainImages = swapChainImages;

        const imageViews = try self.allocator.alloc(c.VkImageView, swapChainImages.len);
        errdefer {
            for (imageViews) |imageView| {
                if (imageView != null) {
                    c.vkDestroyImageView(self.ctx.logicalDevice, imageView, null);
                }
            }
            self.allocator.free(imageViews);
        }

        for (imageViews) |*imageView| {
            imageView.* = null;
        }

        for (swapChainImages, 0..) |image, i| {
            try ensureNoError(c.vkCreateImageView(
                self.ctx.logicalDevice,
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

        self.imageViews = imageViews;
    }

    fn destroySwapchain(self: *Self) void {
        if (self.imageViews) |image_views| {
            for (image_views) |image_view| {
                c.vkDestroyImageView(self.ctx.logicalDevice, image_view, null);
            }
            self.allocator.free(image_views);
            self.imageViews = null;
        }

        if (self.swapChainImages) |swapchain_images| {
            self.allocator.free(swapchain_images);
            self.swapChainImages = null;
        }

        if (self.swapchain) |swapchain| {
            c.vkDestroySwapchainKHR(self.ctx.logicalDevice, swapchain, null);
            self.swapchain = null;
        }
    }

    fn createPipeline(self: *Self, vertex_shader_code: []const u32, fragment_shader_code: []const u32) !void {
        var vertexShaderModule: c.VkShaderModule = undefined;
        try ensureNoError(c.vkCreateShaderModule(
            self.ctx.logicalDevice,
            &c.VkShaderModuleCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO,
                .pNext = null,
                .flags = 0,
                .codeSize = @sizeOf(u32) * vertex_shader_code.len,
                .pCode = vertex_shader_code.ptr,
            },
            null,
            &vertexShaderModule,
        ));
        defer c.vkDestroyShaderModule(self.ctx.logicalDevice, vertexShaderModule, null);

        var fragmentShaderModule: c.VkShaderModule = undefined;
        try ensureNoError(c.vkCreateShaderModule(
            self.ctx.logicalDevice,
            &c.VkShaderModuleCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO,
                .pNext = null,
                .flags = 0,
                .codeSize = @sizeOf(u32) * fragment_shader_code.len,
                .pCode = fragment_shader_code.ptr,
            },
            null,
            &fragmentShaderModule,
        ));
        defer c.vkDestroyShaderModule(self.ctx.logicalDevice, fragmentShaderModule, null);

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

        var pipelineLayout: c.VkPipelineLayout = undefined;
        try ensureNoError(c.vkCreatePipelineLayout(
            self.ctx.logicalDevice,
            &c.VkPipelineLayoutCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO,
                .pNext = null,
                .flags = 0,
                .setLayoutCount = 0,
                .pSetLayouts = null,
                .pushConstantRangeCount = 0,
                .pPushConstantRanges = null,
            },
            null,
            &pipelineLayout,
        ));
        errdefer c.vkDestroyPipelineLayout(self.ctx.logicalDevice, pipelineLayout, null);

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
            self.ctx.logicalDevice,
            &c.VkRenderPassCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO,
                .attachmentCount = 1,
                .pAttachments = &c.VkAttachmentDescription{
                    .format = self.surfaceFormat.format,
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
        errdefer c.vkDestroyRenderPass(self.ctx.logicalDevice, renderPass, null);

        var graphicsPipeline: c.VkPipeline = undefined;
        try ensureNoError(c.vkCreateGraphicsPipelines(
            self.ctx.logicalDevice,
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
                    .vertexBindingDescriptionCount = 0,
                    .pVertexBindingDescriptions = null,
                    .vertexAttributeDescriptionCount = 0,
                    .pVertexAttributeDescriptions = null,
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
                .pDepthStencilState = null,
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
        errdefer c.vkDestroyPipeline(self.ctx.logicalDevice, graphicsPipeline, null);

        self.pipelineLayout = pipelineLayout;
        self.renderPass = renderPass;
        self.graphicsPipeline = graphicsPipeline;
    }

    fn destroyPipeline(self: *Self) void {
        if (self.graphicsPipeline) |pipeline| {
            c.vkDestroyPipeline(self.ctx.logicalDevice, pipeline, null);
            self.graphicsPipeline = null;
        }

        if (self.renderPass) |render_pass| {
            c.vkDestroyRenderPass(self.ctx.logicalDevice, render_pass, null);
            self.renderPass = null;
        }

        if (self.pipelineLayout) |pipeline_layout| {
            c.vkDestroyPipelineLayout(self.ctx.logicalDevice, pipeline_layout, null);
            self.pipelineLayout = null;
        }
    }

    fn createFramebuffers(self: *Self) !void {
        const imageViews = self.imageViews orelse return error.ImageViewsNotInitialized;

        const swapchainFramebuffers = try self.allocator.alloc(c.VkFramebuffer, imageViews.len);
        errdefer {
            for (swapchainFramebuffers) |framebuffer| {
                if (framebuffer != null) {
                    c.vkDestroyFramebuffer(self.ctx.logicalDevice, framebuffer, null);
                }
            }
            self.allocator.free(swapchainFramebuffers);
        }

        for (swapchainFramebuffers) |*framebuffer| {
            framebuffer.* = null;
        }

        for (imageViews, 0..) |imageView, i| {
            try ensureNoError(c.vkCreateFramebuffer(
                self.ctx.logicalDevice,
                &c.VkFramebufferCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO,
                    .pNext = null,
                    .flags = 0,
                    .renderPass = self.renderPass,
                    .attachmentCount = 1,
                    .pAttachments = &imageView,
                    .width = self.swapchainExtent.width,
                    .height = self.swapchainExtent.height,
                    .layers = 1,
                },
                null,
                &swapchainFramebuffers[i],
            ));
        }

        self.swapchainFramebuffers = swapchainFramebuffers;
    }

    fn destroyFramebuffers(self: *Self) void {
        if (self.swapchainFramebuffers) |framebuffers| {
            for (framebuffers) |framebuffer| {
                c.vkDestroyFramebuffer(self.ctx.logicalDevice, framebuffer, null);
            }
            self.allocator.free(framebuffers);
            self.swapchainFramebuffers = null;
        }
    }

    fn createCommandPool(self: *Self) !void {
        var commandPool: c.VkCommandPool = undefined;
        try ensureNoError(c.vkCreateCommandPool(
            self.ctx.logicalDevice,
            &c.VkCommandPoolCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
                .pNext = null,
                .flags = c.VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT,
                .queueFamilyIndex = self.ctx.graphicsQueueFamilyIndex,
            },
            null,
            &commandPool,
        ));

        self.commandPool = commandPool;
    }

    fn destroyCommandPool(self: *Self) void {
        if (self.commandPool) |command_pool| {
            c.vkDestroyCommandPool(self.ctx.logicalDevice, command_pool, null);
            self.commandPool = null;
        }
    }

    fn allocateCommandBuffers(self: *Self) !void {
        try ensureNoError(c.vkAllocateCommandBuffers(
            self.ctx.logicalDevice,
            &c.VkCommandBufferAllocateInfo{
                .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
                .pNext = null,
                .commandPool = self.commandPool,
                .level = c.VK_COMMAND_BUFFER_LEVEL_PRIMARY,
                .commandBufferCount = maxFramesInFlight,
            },
            &self.commandBuffers,
        ));

        self.commandBuffersAllocated = true;
    }

    fn freeCommandBuffers(self: *Self) void {
        if (self.commandBuffersAllocated and self.commandPool != null) {
            c.vkFreeCommandBuffers(self.ctx.logicalDevice, self.commandPool, maxFramesInFlight, &self.commandBuffers);
            self.commandBuffersAllocated = false;
            self.commandBuffers = .{null} ** maxFramesInFlight;
        }
    }

    fn createSyncObjects(self: *Self) !void {
        for (0..maxFramesInFlight) |i| {
            try ensureNoError(c.vkCreateFence(
                self.ctx.logicalDevice,
                &c.VkFenceCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO,
                    .flags = c.VK_FENCE_CREATE_SIGNALED_BIT,
                },
                null,
                &self.inFlightFences[i],
            ));

            try ensureNoError(c.vkCreateSemaphore(
                self.ctx.logicalDevice,
                &c.VkSemaphoreCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO,
                },
                null,
                &self.imageAvailableSemaphores[i],
            ));
        }

        const swapchain_images = self.swapChainImages orelse return error.SwapchainNotInitialized;
        const renderFinishedSemaphores = try self.allocator.alloc(c.VkSemaphore, swapchain_images.len);
        errdefer self.allocator.free(renderFinishedSemaphores);

        for (renderFinishedSemaphores) |*semaphore| {
            semaphore.* = null;
        }

        for (renderFinishedSemaphores) |*semaphore| {
            try ensureNoError(c.vkCreateSemaphore(
                self.ctx.logicalDevice,
                &c.VkSemaphoreCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO,
                },
                null,
                semaphore,
            ));
        }

        self.renderFinishedSemaphores = renderFinishedSemaphores;
    }

    fn destroySyncObjects(self: *Self) void {
        if (self.renderFinishedSemaphores) |render_finished_semaphores| {
            for (render_finished_semaphores) |semaphore| {
                if (semaphore != null) {
                    c.vkDestroySemaphore(self.ctx.logicalDevice, semaphore, null);
                }
            }
            self.allocator.free(render_finished_semaphores);
            self.renderFinishedSemaphores = null;
        }

        for (0..maxFramesInFlight) |i| {
            if (self.imageAvailableSemaphores[i] != null) {
                c.vkDestroySemaphore(self.ctx.logicalDevice, self.imageAvailableSemaphores[i], null);
                self.imageAvailableSemaphores[i] = null;
            }
            if (self.inFlightFences[i] != null) {
                c.vkDestroyFence(self.ctx.logicalDevice, self.inFlightFences[i], null);
                self.inFlightFences[i] = null;
            }
        }
    }
};
