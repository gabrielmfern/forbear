const std = @import("std");
const c = @import("c.zig").c;

fn CreateDebugUtilsMessengerEXT(
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

fn DestroyDebugUtilsMessengerEXT(
    instance: c.VkInstance,
    debugMessenger: c.VkDebugUtilsMessengerEXT,
    pAllocator: [*c]const c.VkAllocationCallbacks,
) void {
    const func: c.PFN_vkDestroyDebugUtilsMessengerEXT = @ptrCast(@alignCast(c.vkGetInstanceProcAddr(instance, "vkDestroyDebugUtilsMessengerEXT")));
    if (func != null) {
        func.?(instance, debugMessenger, pAllocator);
    }
}

const VulkanError = error{
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
    Unknown,
};

fn ensureNoError(result: c.VkResult) !void {
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
    } else if (result == c.VK_ERROR_UNKNOWN) {
        return error.Unknown;
    }

    std.debug.assert(result == c.VK_SUCCESS);
}

fn validateInstanceLayers(layers: []const [*c]const u8, allocator: std.mem.Allocator) !void {
    var availableLayersLen: u32 = 0;
    try ensureNoError(c.vkEnumerateInstanceLayerProperties(
        &availableLayersLen,
        null,
    ));
    const availableLayers = try allocator.alloc(c.VkLayerProperties, @intCast(availableLayersLen));
    defer allocator.free(availableLayers);
    try ensureNoError(c.vkEnumerateInstanceLayerProperties(
        &availableLayersLen,
        availableLayers.ptr,
    ));

    std.log.debug("available layers:", .{});
    for (availableLayers) |layer| {
        std.log.debug("  - {s}", .{layer.layerName});
    }

    for (layers) |layer| {
        const layerSlice: []const u8 = std.mem.span(layer);
        var isLayerSupported = false;
        for (availableLayers) |availableLayer| {
            if (std.mem.eql(
                u8,
                availableLayer.layerName[0..layerSlice.len],
                layerSlice,
            )) {
                isLayerSupported = true;
                break;
            }
        }
        if (isLayerSupported == false) {
            std.log.err("layer {s} is not supported", .{layer});
            return error.LayerNotSupported;
        }
    }
}

fn validateInstanceExtensions(extensions: []const [*c]const u8, allocator: std.mem.Allocator) !void {
    var availableExtensionsLen: u32 = 0;
    try ensureNoError(c.vkEnumerateInstanceExtensionProperties(
        null,
        &availableExtensionsLen,
        null,
    ));
    const availableExtensions = try allocator.alloc(c.VkExtensionProperties, @intCast(availableExtensionsLen));
    defer allocator.free(availableExtensions);
    try ensureNoError(c.vkEnumerateInstanceExtensionProperties(
        null,
        &availableExtensionsLen,
        availableExtensions.ptr,
    ));

    std.log.debug("available extensions:", .{});
    for (availableExtensions) |extension| {
        std.log.debug("  - {s}", .{extension.extensionName});
    }

    for (extensions) |extension| {
        const extensionSlice: []const u8 = std.mem.span(extension);
        var isExtensionSupported = false;
        for (availableExtensions) |availableExtension| {
            if (std.mem.eql(
                u8,
                availableExtension.extensionName[0..extensionSlice.len],
                extensionSlice,
            )) {
                isExtensionSupported = true;
                break;
            }
        }
        if (isExtensionSupported == false) {
            std.log.err("extension {s} is not supported", .{extension});
            return error.ExtensionNotSupported;
        }
    }
}

vulkanInstance: c.VkInstance,
vulkanDebugMessenger: c.VkDebugUtilsMessengerEXT,

pub fn init(name: [*c]const u8, allocator: std.mem.Allocator) !@This() {
    const instanceExtensions: []const [*c]const u8 = &.{
        c.VK_KHR_SURFACE_EXTENSION_NAME,
        "VK_KHR_wayland_surface",
        c.VK_KHR_PORTABILITY_ENUMERATION_EXTENSION_NAME,
        c.VK_EXT_DEBUG_UTILS_EXTENSION_NAME,
    };

    const instanceLayers: []const [*c]const u8 = &.{
        "VK_LAYER_KHRONOS_validation",
    };

    try validateInstanceLayers(instanceLayers, allocator);

    try validateInstanceExtensions(instanceExtensions, allocator);

    var vulkanInstance: c.VkInstance = undefined;
    try ensureNoError(c.vkCreateInstance(
        &c.VkInstanceCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
            .flags = c.VK_INSTANCE_CREATE_ENUMERATE_PORTABILITY_BIT_KHR,
            .pNext = null,
            .pApplicationInfo = &c.VkApplicationInfo{
                .sType = c.VK_STRUCTURE_TYPE_APPLICATION_INFO,
                .pNext = null,
                .pApplicationName = name,
                .applicationVersion = c.VK_MAKE_VERSION(1, 0, 0),
                .pEngineName = "No Engine",
                .engineVersion = c.VK_MAKE_VERSION(1, 0, 0),
                .apiVersion = c.VK_API_VERSION_1_0,
            },
            .enabledLayerCount = instanceLayers.len,
            .ppEnabledLayerNames = instanceLayers.ptr,
            .enabledExtensionCount = instanceExtensions.len,
            .ppEnabledExtensionNames = instanceExtensions.ptr,
        },
        // TODO: define a proper allocator here using an allocator from the outside
        null,
        &vulkanInstance,
    ));
    errdefer c.vkDestroyInstance(
        vulkanInstance,
        // TODO: define a proper allocator here using an allocator from the outside
        null,
    );

    std.debug.assert(vulkanInstance != null);

    var vulkanDebugMessenger: c.VkDebugUtilsMessengerEXT = undefined;
    try ensureNoError(CreateDebugUtilsMessengerEXT(
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
        // TODO: define a proper allocator here using an allocator from the outside
        null,
        &vulkanDebugMessenger,
    ));
    errdefer DestroyDebugUtilsMessengerEXT(
        vulkanInstance,
        vulkanDebugMessenger,
        // TODO: define a proper allocator here using an allocator from the outside
        null,
    );
    std.debug.assert(vulkanDebugMessenger != null);

    return .{
        .vulkanInstance = vulkanInstance,
        .vulkanDebugMessenger = vulkanDebugMessenger,
    };
}

const Graphics = @This();

const Swapchain = struct {
    swapchain: c.VkSwapchainKHR,

    pub fn deinit(self: @This(), device: Device) void {
        c.vkDestroySwapchainKHR(
            device.logicalDevice,
            self.swapchain,
            // TODO: define a proper allocator here using an allocator from the outside
            null,
        );
    }
};

const Device = struct {
    physicalDevice: c.VkPhysicalDevice,

    logicalDevice: c.VkDevice,
    graphicsQueue: c.VkQueue,
    graphicsQueueFamilyIndex: u32,
    presentationQueue: c.VkQueue,
    presentationQueueFamilyIndex: u32,

    swapchainSupportDetails: SwapchainSupportDetails,

    pub fn createSwapchain(
        self: @This(),
        surface: c.VkSurfaceKHR,
        width: u32,
        height: u32,
    ) !Swapchain {
        var surfaceFormat: c.VkSurfaceFormatKHR = self.swapchainSupportDetails.formats[0];
        for (self.swapchainSupportDetails.formats) |availableFormat| {
            if (availableFormat.format == c.VK_FORMAT_B8G8R8A8_SRGB and
                availableFormat.colorSpace == c.VK_COLOR_SPACE_SRGB_NONLINEAR_KHR)
            {
                surfaceFormat = availableFormat;
                break;
            }
        }
        var presentMode: c.VkPresentModeKHR = c.VK_PRESENT_MODE_FIFO_KHR;
        for (self.swapchainSupportDetails.presentModes) |availablePresentMode| {
            if (availablePresentMode == c.VK_PRESENT_MODE_MAILBOX_KHR) {
                presentMode = availablePresentMode;
                break;
            }
        }
        var swapExtent: c.VkExtent2D = self.swapchainSupportDetails.capabilities.currentExtent;
        if (swapExtent.width == std.math.maxInt(u32)) {
            swapExtent = c.VkExtent2D{
                .width = std.math.clamp(
                    width,
                    self.swapchainSupportDetails.capabilities.minImageExtent.width,
                    self.swapchainSupportDetails.capabilities.maxImageExtent.width,
                ),
                .height = std.math.clamp(
                    height,
                    self.swapchainSupportDetails.capabilities.minImageExtent.height,
                    self.swapchainSupportDetails.capabilities.maxImageExtent.height,
                ),
            };
        }
        var imageCount: u32 = self.swapchainSupportDetails.capabilities.minImageCount + 1;
        if (self.swapchainSupportDetails.capabilities.maxImageCount > 0 and imageCount > self.swapchainSupportDetails.capabilities.maxImageCount) {
            imageCount = self.swapchainSupportDetails.capabilities.maxImageCount;
        }
        var swapchain: c.VkSwapchainKHR = undefined;
        try ensureNoError(c.vkCreateSwapchainKHR(
            self.logicalDevice,
            &c.VkSwapchainCreateInfoKHR{
                .sType = c.VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR,
                .surface = surface,
                .minImageCount = imageCount,
                .imageFormat = surfaceFormat.format,
                .imageColorSpace = surfaceFormat.colorSpace,
                .imageExtent = swapExtent,
                .imageArrayLayers = 1,
                .imageUsage = c.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT,
                .imageSharingMode = if (self.presentationQueue == self.graphicsQueue)
                    c.VK_SHARING_MODE_EXCLUSIVE
                else
                    c.VK_SHARING_MODE_CONCURRENT,
                .queueFamilyIndexCount = if (self.presentationQueueFamilyIndex == self.graphicsQueueFamilyIndex) 0 else 2,
                .pQueueFamilyIndices = if (self.presentationQueueFamilyIndex == self.graphicsQueueFamilyIndex)
                    null
                else
                    &[_]u32{ self.graphicsQueueFamilyIndex, self.presentationQueueFamilyIndex },
                .preTransform = self.swapchainSupportDetails.capabilities.currentTransform,
                .compositeAlpha = c.VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR,
                .presentMode = presentMode,
                .clipped = c.VK_TRUE,
                // TODO: write out the logic for recreating the swapchain once the surface is resized and use the old one here
                .oldSwapchain = null,
            },
            // TODO: define a proper allocator here using an allocator from the outside
            null,
            &swapchain,
        ));

        return Swapchain{
            .swapchain = swapchain,
        };
    }

    pub fn deinit(self: @This()) void {
        self.swapchainSupportDetails.deinit();
        c.vkDestroyDevice(
            self.logicalDevice,
            // TODO: define a proper allocator here using an allocator from the outside
            null,
        );
    }
};

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

fn querySwapchainSupport(
    device: c.VkPhysicalDevice,
    surface: c.VkSurfaceKHR,
    allocator: std.mem.Allocator,
) !SwapchainSupportDetails {
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

pub fn chooseBestDevice(
    self: @This(),
    surface: c.VkSurfaceKHR,
    allocator: std.mem.Allocator,
) !Device {
    var physicalDevicesLen: u32 = undefined;
    try ensureNoError(c.vkEnumeratePhysicalDevices(
        self.vulkanInstance,
        &physicalDevicesLen,
        null,
    ));
    const physicalDevices = try allocator.alloc(
        c.VkPhysicalDevice,
        @intCast(physicalDevicesLen),
    );
    errdefer allocator.free(physicalDevices);
    try ensureNoError(c.vkEnumeratePhysicalDevices(
        self.vulkanInstance,
        &physicalDevicesLen,
        physicalDevices.ptr,
    ));

    const requiredDeviceExtensions: []const [*c]const u8 = &.{
        c.VK_KHR_SWAPCHAIN_EXTENSION_NAME,
    };

    var preferred: ?struct {
        device: c.VkPhysicalDevice,
        features: c.VkPhysicalDeviceFeatures,
        swapchainSupport: SwapchainSupportDetails,
        queues: QueueIndices,
        score: u32,
    } = null;
    blk: for (physicalDevices) |device| {
        var deviceProperties: c.VkPhysicalDeviceProperties = undefined;
        c.vkGetPhysicalDeviceProperties(device, &deviceProperties);
        var deviceFeatures: c.VkPhysicalDeviceFeatures = undefined;
        c.vkGetPhysicalDeviceFeatures(device, &deviceFeatures);

        if (deviceFeatures.geometryShader == c.VK_FALSE) {
            continue;
        }

        const queueIndices = try getQueueIndices(device, surface, allocator);
        if (queueIndices == null) {
            continue;
        }

        var score: u32 = deviceProperties.limits.maxImageDimension2D;
        if (deviceProperties.deviceType == c.VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU) {
            score += 1000;
        }

        var availableDeviceExtensionsLen: u32 = 0;
        try ensureNoError(c.vkEnumerateDeviceExtensionProperties(
            device,
            null,
            &availableDeviceExtensionsLen,
            null,
        ));
        const availableDeviceExtensions = try allocator.alloc(
            c.VkExtensionProperties,
            @intCast(availableDeviceExtensionsLen),
        );
        try ensureNoError(c.vkEnumerateDeviceExtensionProperties(
            device,
            null,
            &availableDeviceExtensionsLen,
            availableDeviceExtensions.ptr,
        ));
        defer allocator.free(availableDeviceExtensions);

        for (requiredDeviceExtensions) |extension| {
            const extensionSlice = std.mem.span(extension);
            var supported = false;
            for (availableDeviceExtensions) |availableExtension| {
                const availableExtensionSlice = availableExtension.extensionName[0..extensionSlice.len];
                if (std.mem.eql(
                    u8,
                    availableExtensionSlice,
                    extensionSlice,
                )) {
                    supported = true;
                    break;
                }
            }
            if (supported == false) {
                continue :blk;
            }
        }

        const swapchainSupport = try querySwapchainSupport(device, surface, allocator);
        if (swapchainSupport.formats.len == 0 or swapchainSupport.presentModes.len == 0) {
            continue;
        }

        if (preferred) |currentPreferred| {
            if (score > currentPreferred.score) {
                preferred = .{
                    .device = device,
                    .features = deviceFeatures,
                    .queues = queueIndices.?,
                    .swapchainSupport = swapchainSupport,
                    .score = score,
                };
            }
        } else {
            preferred = .{
                .device = device,
                .features = deviceFeatures,
                .queues = queueIndices.?,
                .swapchainSupport = swapchainSupport,
                .score = score,
            };
        }
    }

    if (preferred == null) {
        std.log.err("no suitable physical device found", .{});
        return error.NoSuitablePhysicalDevice;
    }

    const physicalDevice = preferred.?.device;
    const graphicsQueueIndex = preferred.?.queues.graphics;
    const presentationQueueIndex = preferred.?.queues.presentation;

    const queueCreateInfos: []const c.VkDeviceQueueCreateInfo = if (graphicsQueueIndex == presentationQueueIndex) &.{.{
        .sType = c.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
        .pNext = null,
        .flags = 0,
        .queueFamilyIndex = graphicsQueueIndex,
        .queueCount = 1,
        .pQueuePriorities = &@as(f32, 1.0),
    }} else &.{ .{
        .sType = c.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
        .pNext = null,
        .flags = 0,
        .queueFamilyIndex = graphicsQueueIndex,
        .queueCount = 1,
        .pQueuePriorities = &@as(f32, 1.0),
    }, .{
        .sType = c.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
        .pNext = null,
        .flags = 0,
        .queueFamilyIndex = presentationQueueIndex,
        .queueCount = 1,
        .pQueuePriorities = &@as(f32, 1.0),
    } };

    var logicalDevice: c.VkDevice = undefined;
    try ensureNoError(c.vkCreateDevice(
        physicalDevice,
        &c.VkDeviceCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
            .pNext = null,
            .flags = 0,
            .queueCreateInfoCount = @intCast(queueCreateInfos.len),
            // YOU ARE HERE: you were going to add the creation info for the presentation queue
            .pQueueCreateInfos = queueCreateInfos.ptr,
            .pEnabledFeatures = null,
            .ppEnabledExtensionNames = requiredDeviceExtensions.ptr,
            .enabledExtensionCount = @intCast(requiredDeviceExtensions.len),

            // These are deprecated, and we don't need them
            .enabledLayerCount = 0,
            .ppEnabledLayerNames = null,
        },
        // TODO: define a proper allocator here using an allocator from the outside
        null,
        &logicalDevice,
    ));
    std.debug.assert(logicalDevice != null);

    var graphicsQueue: c.VkQueue = undefined;
    c.vkGetDeviceQueue(logicalDevice, graphicsQueueIndex, 0, &graphicsQueue);
    std.debug.assert(graphicsQueue != null);

    var presentationQueue: c.VkQueue = undefined;
    c.vkGetDeviceQueue(logicalDevice, presentationQueueIndex, 0, &presentationQueue);
    std.debug.assert(presentationQueue != null);

    return .{
        .physicalDevice = physicalDevice,

        .swapchainSupportDetails = preferred.?.swapchainSupport,

        .logicalDevice = logicalDevice,
        .graphicsQueueFamilyIndex = graphicsQueueIndex,
        .graphicsQueue = graphicsQueue,
        .presentationQueueFamilyIndex = presentationQueueIndex,
        .presentationQueue = presentationQueue,
    };
}

const QueueIndices = struct {
    graphics: u32,
    presentation: u32,
};

fn getQueueIndices(
    device: c.VkPhysicalDevice,
    surface: c.VkSurfaceKHR,
    allocator: std.mem.Allocator,
) !?QueueIndices {
    var queueFamiliesLen: u32 = undefined;
    c.vkGetPhysicalDeviceQueueFamilyProperties(
        device,
        &queueFamiliesLen,
        null,
    );

    const queueFamilies = try allocator.alloc(
        c.VkQueueFamilyProperties,
        @intCast(queueFamiliesLen),
    );
    defer allocator.free(queueFamilies);
    c.vkGetPhysicalDeviceQueueFamilyProperties(
        device,
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
            device,
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

pub fn createWaylandSurface(
    self: @This(),
    wlDisplay: *c.wl_display,
    wlSurface: *c.wl_surface,
) !c.VkSurfaceKHR {
    var surface: c.VkSurfaceKHR = undefined;

    try ensureNoError(c.vkCreateWaylandSurfaceKHR(
        self.vulkanInstance,
        &c.VkWaylandSurfaceCreateInfoKHR{
            .sType = c.VK_STRUCTURE_TYPE_WAYLAND_SURFACE_CREATE_INFO_KHR,
            .display = wlDisplay,
            .surface = wlSurface,
        },
        // TODO: define a proper allocator here using an allocator from the outside
        null,
        &surface,
    ));

    return surface;
}

pub fn deinit(self: @This()) void {
    DestroyDebugUtilsMessengerEXT(
        self.vulkanInstance,
        self.vulkanDebugMessenger,
        // TODO: define a proper allocator here using an allocator from the outside
        null,
    );
    c.vkDestroyInstance(
        self.vulkanInstance,
        // TODO: define a proper allocator here using an allocator from the outside
        null,
    );
}
