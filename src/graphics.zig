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
    } else if (result == c.VK_ERROR_UNKNOWN) {
        return error.Unknown;
    }

    std.debug.assert(result == c.VK_SUCCESS);
}

fn validateLayers(layers: []const [*c]const u8, allocator: std.mem.Allocator) !void {
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

fn validateExtensions(extensions: []const [*c]const u8, allocator: std.mem.Allocator) !void {
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
physicalDevice: c.VkPhysicalDevice,

pub fn init(name: [*c]const u8, allocator: std.mem.Allocator) !@This() {
    const extensions: []const [*c]const u8 = &.{
        c.VK_KHR_SURFACE_EXTENSION_NAME,
        "VK_KHR_wayland_surface",
        c.VK_KHR_PORTABILITY_ENUMERATION_EXTENSION_NAME,
        c.VK_EXT_DEBUG_UTILS_EXTENSION_NAME,
    };

    const layers: []const [*c]const u8 = &.{
        "VK_LAYER_KHRONOS_validation",
    };

    try validateLayers(layers, allocator);

    try validateExtensions(extensions, allocator);

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
            .enabledLayerCount = layers.len,
            .ppEnabledLayerNames = layers.ptr,
            .enabledExtensionCount = extensions.len,
            .ppEnabledExtensionNames = extensions.ptr,
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

    var physicalDevicesLen: u32 = undefined;
    try ensureNoError(c.vkEnumeratePhysicalDevices(
        vulkanInstance,
        &physicalDevicesLen,
        null,
    ));
    const physicalDevices = try allocator.alloc(c.VkPhysicalDevice, @intCast(physicalDevicesLen));
    errdefer allocator.free(physicalDevices);
    try ensureNoError(c.vkEnumeratePhysicalDevices(
        vulkanInstance,
        &physicalDevicesLen,
        physicalDevices.ptr,
    ));

    var preferred: ?struct { device: c.VkPhysicalDevice, score: u32 } = null;
    for (physicalDevices) |device| {
        var deviceProperties: c.VkPhysicalDeviceProperties = undefined;
        c.vkGetPhysicalDeviceProperties(device, &deviceProperties);
        var deviceFeatures: c.VkPhysicalDeviceFeatures = undefined;
        c.vkGetPhysicalDeviceFeatures(device, &deviceFeatures);

        if (deviceFeatures.geometryShader == c.VK_FALSE) {
            continue;
        }

        var score: u32 = deviceProperties.limits.maxImageDimension2D;
        if (deviceProperties.deviceType != c.VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU) {
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

    return .{
        .vulkanInstance = vulkanInstance,
        .physicalDevice = preferred.?.device,
        .vulkanDebugMessenger = vulkanDebugMessenger,
    };
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
