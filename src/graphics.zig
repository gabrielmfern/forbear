const std = @import("std");
const c = @cImport({
    @cInclude("vulkan/vulkan.h");
});

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

vulkanInstance: c.VkInstance,
vulkanDebugMessenger: c.VkDebugUtilsMessengerEXT,
availableLayers: []c.VkLayerProperties,

pub fn init(name: [*c]const u8, allocator: std.mem.Allocator) !@This() {
    const extensions: []const [*c]const u8 = &.{
        c.VK_KHR_surface,
        "VK_KHR_wayland_surface",
        c.VK_KHR_PORTABILITY_ENUMERATION_EXTENSION_NAME,
        c.VK_EXT_DEBUG_UTILS_EXTENSION_NAME,
    };

    const layers: []const [*c]const u8 = &.{
        "VK_LAYER_KHRONOS_validation",
    };

    // std.debug.assert(c.vkEnumerateInstanceLayerProperties != null);
    // std.debug.assert(c.vkGetDeviceProcAddr != null);

    var availableLayersLen: u32 = 0;
    try ensureNoError(c.vkEnumerateInstanceLayerProperties(&availableLayersLen, null));
    const availableLayers = try allocator.alloc(c.VkLayerProperties, @intCast(availableLayersLen));
    try ensureNoError(c.vkEnumerateInstanceLayerProperties(&availableLayersLen, availableLayers.ptr));

    for (layers) |layer| {
        const layerSlice: []const u8 = std.mem.span(layer);
        var isLayerSupported = false;
        for (availableLayers) |availableLayer| {
            if (std.mem.eql(u8, availableLayer.layerName[0..], layerSlice)) {
                isLayerSupported = true;
                break;
            }
        }
        if (isLayerSupported == false) {
            return error.LayerNotSupported;
        }
    }

    var vulkanInstance: c.VkInstance = undefined;
    // TODO: define a proper allocator here using an allocator from the outside
    try ensureNoError(c.vkCreateInstance(
        &c.VkInstanceCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
            .flags = c.VK_INSTANCE_CREATE_ENUMERATE_PORTABILITY_BIT_KHR,
            .pApplicationInfo = &c.VkApplicationInfo{
                .sType = c.VK_STRUCTURE_TYPE_APPLICATION_INFO,
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
        null,
        &vulkanInstance,
    ));

    std.debug.assert(vulkanInstance != null);

    var vulkanDebugMessenger: c.VkDebugUtilsMessengerEXT = undefined;
    try ensureNoError(CreateDebugUtilsMessengerEXT(
        vulkanInstance,
        &c.VkDebugUtilsMessengerCreateInfoEXT{
            .sType = c.VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT,
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
                        std.log.debug("{s}", .{message});
                    } else if (messageSeverity == c.VK_DEBUG_UTILS_MESSAGE_SEVERITY_INFO_BIT_EXT) {
                        std.log.info("{s}", .{message});
                    } else if (messageSeverity == c.VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT) {
                        std.log.warn("{s}", .{message});
                    } else if (messageSeverity == c.VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT) {
                        std.log.err("{s}", .{message});
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
    std.debug.assert(vulkanDebugMessenger != null);

    return .{
        .vulkanInstance = vulkanInstance,
        .vulkanDebugMessenger = vulkanDebugMessenger,
        .availableLayers = availableLayers,
    };
}

pub fn deinit(self: @This()) void {
    // TODO: define a proper allocator here using an allocator from the outside
    DestroyDebugUtilsMessengerEXT(self.vulkanInstance, self.vulkanDebugMessenger, null);
    // TODO: define a proper allocator here using an allocator from the outside
    c.vkDestroyInstance(self.vulkanInstance, null);
}
