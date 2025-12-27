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
    InvalidExternalHandle,
    MemoryMapFailed,
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

pub const Vertex = extern struct {
    position: @Vector(3, f32),
    color: @Vector(3, f32),

    fn getBindingDescription() c.VkVertexInputBindingDescription {
        return c.VkVertexInputBindingDescription{
            .binding = 0,
            .stride = @sizeOf(@This()),
            .inputRate = c.VK_VERTEX_INPUT_RATE_VERTEX,
        };
    }

    fn getATtributeDescriptions() [2]c.VkVertexInputAttributeDescription {
        return .{
            c.VkVertexInputAttributeDescription{
                .binding = 0,
                .location = 0,
                .format = c.VK_FORMAT_R32G32B32_SFLOAT,
                .offset = @offsetOf(@This(), "position"),
            },
            c.VkVertexInputAttributeDescription{
                .binding = 0,
                .location = 1,
                .format = c.VK_FORMAT_R32G32B32_SFLOAT,
                .offset = @offsetOf(@This(), "color"),
            },
        };
    }
};

const triangle_vertices = [_]Vertex{
    .{ .position = .{ 0.0, -0.5, 0.0 }, .color = .{ 1.0, 0.0, 0.0 } },
    .{ .position = .{ 0.5, 0.5, 0.0 }, .color = .{ 0.0, 1.0, 0.0 } },
    .{ .position = .{ -0.5, 0.5, 0.0 }, .color = .{ 0.0, 0.0, 1.0 } },
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
    const instanceExtensions: []const [*c]const u8 = &(.{
        c.VK_KHR_SURFACE_EXTENSION_NAME,
        c.VK_KHR_PORTABILITY_ENUMERATION_EXTENSION_NAME,
        c.VK_EXT_DEBUG_UTILS_EXTENSION_NAME,
    } ++ switch (builtin.os.tag) {
        .linux => .{
            "VK_KHR_wayland_surface",
        },
        .macos => .{
            "VK_EXT_metal_surface",
        },
        else => .{},
    });

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
                .pApplicationName = application_name.ptr,
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
    errdefer c.vkDestroyInstance(vulkanInstance, null);

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
        null,
        &vulkanDebugMessenger,
    ));
    std.debug.assert(vulkanDebugMessenger != null);
    errdefer DestroyDebugUtilsMessengerEXT(vulkanInstance, vulkanDebugMessenger, null);

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

    DestroyDebugUtilsMessengerEXT(self.vulkanInstance, self.vulkanDebugMessenger, null);
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
    vertexShaderCode: []const u32,
    fragmentShaderCode: []const u32,
) !Renderer {
    const width = window.width.*;
    const height = window.height.*;

    var vulkanSurface: c.VkSurfaceKHR = undefined;
    switch (builtin.os.tag) {
        .linux => {
            try ensureNoError(c.vkCreateWaylandSurfaceKHR(
                self.vulkanInstance,
                &c.VkWaylandSurfaceCreateInfoKHR{
                    .sType = c.VK_STRUCTURE_TYPE_WAYLAND_SURFACE_CREATE_INFO_KHR,
                    .pNext = null,
                    .flags = 0,
                    .display = window.handle.wlDisplay,
                    .surface = window.handle.wlSurface,
                },
                null,
                &vulkanSurface,
            ));
        },
        .macos => {
            const caMetalLayer = window.handle.nativeMetalLayer();
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
        else => @compileError("Unsupported platform"),
    }
    std.debug.assert(vulkanSurface != null);
    errdefer c.vkDestroySurfaceKHR(self.vulkanInstance, vulkanSurface, null);

    return try Renderer.init(vulkanSurface, self, width, height, vertexShaderCode, fragmentShaderCode);
}

pub const Renderer = struct {
    const Self = @This();

    const maxFramesInFlight = 2;

    allocator: std.mem.Allocator,
    graphics: *const Graphics,

    physicalDevice: c.VkPhysicalDevice,
    logicalDevice: c.VkDevice,
    graphicsQueue: c.VkQueue,
    presentationQueue: c.VkQueue,

    surface: c.VkSurfaceKHR,
    swapchain: Swapchain,
    swapchainFramebuffers: []c.VkFramebuffer,

    pipelineLayout: c.VkPipelineLayout,
    renderPass: c.VkRenderPass,
    graphicsPipeline: c.VkPipeline,

    commandPool: c.VkCommandPool,
    commandBuffers: [maxFramesInFlight]c.VkCommandBuffer,
    commandBuffersAllocated: bool,

    vertexBuffer: c.VkBuffer,
    vertexBufferMemory: c.VkDeviceMemory,

    inFlightFences: [maxFramesInFlight]c.VkFence,
    imageAvailableSemaphores: [maxFramesInFlight]c.VkSemaphore,
    renderFinishedSemaphores: []c.VkSemaphore,

    currentFrame: usize,

    // pub fn recreateSwapchain(self: *Self, width: u32, height: u32) !void {
    //     self.destroyFramebuffers();
    //     self.destroySwapchain();
    //
    //     try self.createSwapchain(width, height);
    //     errdefer self.destroySwapchain();
    //
    //     try self.createFramebuffers();
    //     errdefer self.destroyFramebuffers();
    // }

    fn init(
        surface: c.VkSurfaceKHR,
        graphics: *const Graphics,
        width: u32,
        height: u32,
        vertexShaderCode: []const u32,
        fragmentShaderCode: []const u32,
    ) !Renderer {
        const requiredDeviceExtensions: []const [*c]const u8 = &(.{
            c.VK_KHR_SWAPCHAIN_EXTENSION_NAME,
        } ++ switch (builtin.os.tag) {
            .macos => .{
                "VK_KHR_portability_subset",
            },
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

        const queueCreateInfos: []const c.VkDeviceQueueCreateInfo = if (preferred.?.graphicsQueueFamilyIndex == preferred.?.presentationQueueFamilyIndex) &.{.{
            .sType = c.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
            .pNext = null,
            .flags = 0,
            .queueFamilyIndex = preferred.?.graphicsQueueFamilyIndex,
            .queueCount = 1,
            .pQueuePriorities = &@as(f32, 1.0),
        }} else &.{
            .{
                .sType = c.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
                .pNext = null,
                .flags = 0,
                .queueFamilyIndex = preferred.?.graphicsQueueFamilyIndex,
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
            preferred.?.device.physicalDevice,
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
        c.vkGetDeviceQueue(logicalDevice, preferred.?.graphicsQueueFamilyIndex, 0, &graphicsQueue);
        var presentationQueue: c.VkQueue = undefined;
        c.vkGetDeviceQueue(logicalDevice, preferred.?.presentationQueueFamilyIndex, 0, &presentationQueue);

        const swapchain = try Swapchain.init(
            preferred.?.device.physicalDevice,
            logicalDevice,
            preferred.?.presentationQueueFamilyIndex,
            presentationQueue,
            preferred.?.graphicsQueueFamilyIndex,
            graphicsQueue,
            surface,
            width,
            height,
            graphics.allocator,
        );
        errdefer swapchain.deinit(logicalDevice);

        var vertexShaderModule: c.VkShaderModule = undefined;
        try ensureNoError(c.vkCreateShaderModule(
            logicalDevice,
            &c.VkShaderModuleCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO,
                .pNext = null,
                .flags = 0,
                .codeSize = @sizeOf(u32) * vertexShaderCode.len,
                .pCode = vertexShaderCode.ptr,
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
                .codeSize = @sizeOf(u32) * fragmentShaderCode.len,
                .pCode = fragmentShaderCode.ptr,
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

        var pipelineLayout: c.VkPipelineLayout = undefined;
        try ensureNoError(c.vkCreatePipelineLayout(
            logicalDevice,
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
        errdefer c.vkDestroyPipelineLayout(logicalDevice, pipelineLayout, null);

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
        errdefer c.vkDestroyPipeline(logicalDevice, graphicsPipeline, null);
        // self.pipelineLayout = pipelineLayout;
        // self.renderPass = renderPass;
        // self.graphicsPipeline = graphicsPipeline;

        const framebuffers = try createFramebuffers(logicalDevice, renderPass, swapchain, graphics.allocator);
        errdefer destroyFramebuffers(framebuffers, logicalDevice, graphics.allocator);

        var commandPool: c.VkCommandPool = undefined;
        try ensureNoError(c.vkCreateCommandPool(
            logicalDevice,
            &c.VkCommandPoolCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
                .pNext = null,
                .flags = c.VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT,
                .queueFamilyIndex = preferred.?.graphicsQueueFamilyIndex,
            },
            null,
            &commandPool,
        ));
        errdefer c.vkDestroyCommandPool(logicalDevice, commandPool, null);

        var vertexBuffer: c.VkBuffer = undefined;
        try ensureNoError(c.vkCreateBuffer(
            logicalDevice,
            &c.VkBufferCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
                .pNext = null,
                .flags = 0,
                .size = @sizeOf(Vertex) * 3,
                .usage = c.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT,
                .sharingMode = c.VK_SHARING_MODE_EXCLUSIVE,
                .queueFamilyIndexCount = 0,
                .pQueueFamilyIndices = null,
            },
            null,
            &vertexBuffer,
        ));
        errdefer c.vkDestroyBuffer(logicalDevice, vertexBuffer, null);

        var bufferMemoryRequirements: c.VkMemoryRequirements = undefined;
        c.vkGetBufferMemoryRequirements(logicalDevice, vertexBuffer, &bufferMemoryRequirements);
        var vertexBufferMemory: c.VkDeviceMemory = undefined;
        try ensureNoError(c.vkAllocateMemory(
            logicalDevice,
            &c.VkMemoryAllocateInfo{
                .sType = c.VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
                .pNext = null,
                .allocationSize = bufferMemoryRequirements.size,
                .memoryTypeIndex = try findMemoryType(
                    bufferMemoryRequirements.memoryTypeBits,
                    c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
                    preferred.?.device.physicalDevice,
                ),
            },
            null,
            &vertexBufferMemory,
        ));
        errdefer c.vkFreeMemory(logicalDevice, vertexBufferMemory, null);

        try ensureNoError(c.vkBindBufferMemory(logicalDevice, vertexBuffer, vertexBufferMemory, 0));

        var data: [3]Vertex = undefined;
        try ensureNoError(c.vkMapMemory(
            logicalDevice,
            vertexBufferMemory,
            0,
            @sizeOf(Vertex) * 3,
            0,
            @ptrCast(@alignCast(&data)),
        ));
        @memcpy(&data, &triangle_vertices);
        c.vkUnmapMemory(logicalDevice, vertexBufferMemory);

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

            .physicalDevice = preferred.?.device.physicalDevice,
            .logicalDevice = logicalDevice,
            .graphicsQueue = graphicsQueue,
            .presentationQueue = presentationQueue,

            .surface = surface,
            .swapchain = swapchain,
            .swapchainFramebuffers = framebuffers,

            .pipelineLayout = pipelineLayout,
            .renderPass = renderPass,
            .graphicsPipeline = graphicsPipeline,

            .commandPool = commandPool,
            .commandBuffers = commandBuffers,
            .commandBuffersAllocated = true,

            .vertexBuffer = vertexBuffer,
            .vertexBufferMemory = vertexBufferMemory,

            .inFlightFences = inFlightFences,
            .imageAvailableSemaphores = imageAvailableSemaphores,
            .renderFinishedSemaphores = renderFinishedSemaphores,

            .currentFrame = 0,
        };
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
        c.vkFreeMemory(self.logicalDevice, self.vertexBufferMemory, null);
        c.vkDestroyBuffer(self.logicalDevice, self.vertexBuffer, null);
        c.vkDestroyCommandPool(self.logicalDevice, self.commandPool, null);
        destroyFramebuffers(self.swapchainFramebuffers, self.logicalDevice, self.allocator);
        c.vkDestroyPipeline(self.logicalDevice, self.graphicsPipeline, null);
        c.vkDestroyRenderPass(self.logicalDevice, self.renderPass, null);
        c.vkDestroyPipelineLayout(self.logicalDevice, self.pipelineLayout, null);
        self.swapchain.deinit(self.logicalDevice);
        c.vkDestroyDevice(self.logicalDevice, null);
        c.vkDestroySurfaceKHR(self.graphics.vulkanInstance, self.surface, null);
    }

    pub fn drawFrame(self: *Self) !void {
        const device = self.logicalDevice;

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
            self.graphicsPipeline,
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

        const buffers = [_]c.VkBuffer{self.vertexBuffer.?};
        const offsets = [_]c.VkDeviceSize{0};
        c.vkCmdBindVertexBuffers(self.commandBuffers[self.currentFrame], 0, 1, &buffers, &offsets);

        c.vkCmdDraw(self.commandBuffers[self.currentFrame], 3, 1, 0, 0);
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

    fn destroyPipeline(self: *Self) void {
        if (self.graphicsPipeline) |pipeline| {
            c.vkDestroyPipeline(self.graphics.logicalDevice, pipeline, null);
            self.graphicsPipeline = null;
        }

        if (self.renderPass) |render_pass| {
            c.vkDestroyRenderPass(self.graphics.logicalDevice, render_pass, null);
            self.renderPass = null;
        }

        if (self.pipelineLayout) |pipeline_layout| {
            c.vkDestroyPipelineLayout(self.graphics.logicalDevice, pipeline_layout, null);
            self.pipelineLayout = null;
        }
    }

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

    fn createCommandPool(self: *Self) !void {
        var commandPool: c.VkCommandPool = undefined;
        try ensureNoError(c.vkCreateCommandPool(
            self.graphics.logicalDevice,
            &c.VkCommandPoolCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
                .pNext = null,
                .flags = c.VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT,
                .queueFamilyIndex = self.graphics.graphicsQueueFamilyIndex,
            },
            null,
            &commandPool,
        ));

        self.commandPool = commandPool;
    }

    fn destroyCommandPool(self: *Self) void {
        if (self.commandPool) |command_pool| {
            c.vkDestroyCommandPool(self.graphics.logicalDevice, command_pool, null);
            self.commandPool = null;
        }
    }

    fn createVertexBuffer(self: *Self) !void {
        var vertexBuffer: c.VkBuffer = undefined;
        try ensureNoError(c.vkCreateBuffer(
            self.graphics.logicalDevice,
            &c.VkBufferCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
                .pNext = null,
                .flags = 0,
                .size = @sizeOf(Vertex) * 3,
                .usage = c.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT,
                .sharingMode = c.VK_SHARING_MODE_EXCLUSIVE,
                .queueFamilyIndexCount = 0,
                .pQueueFamilyIndices = null,
            },
            null,
            &vertexBuffer,
        ));
        self.vertexBuffer = vertexBuffer;

        var bufferMemoryRequirements: c.VkMemoryRequirements = undefined;
        c.vkGetBufferMemoryRequirements(self.graphics.logicalDevice, self.vertexBuffer.?, &bufferMemoryRequirements);
        var vertexBufferMemory: c.VkDeviceMemory = undefined;
        try ensureNoError(c.vkAllocateMemory(
            self.graphics.logicalDevice,
            &c.VkMemoryAllocateInfo{
                .sType = c.VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
                .pNext = null,
                .allocationSize = bufferMemoryRequirements.size,
                .memoryTypeIndex = try self.findMemoryType(
                    bufferMemoryRequirements.memoryTypeBits,
                    c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
                ),
            },
            null,
            &vertexBufferMemory,
        ));
        self.vertexBufferMemory = vertexBufferMemory;

        try ensureNoError(c.vkBindBufferMemory(self.graphics.logicalDevice, self.vertexBuffer.?, self.vertexBufferMemory.?, 0));

        var data: [3]Vertex = undefined;
        try ensureNoError(c.vkMapMemory(
            self.graphics.logicalDevice,
            self.vertexBufferMemory.?,
            0,
            @sizeOf(Vertex) * 3,
            0,
            @ptrCast(@alignCast(&data)),
        ));
        @memcpy(&data, &triangle_vertices);
        c.vkUnmapMemory(self.graphics.logicalDevice, self.vertexBufferMemory.?);
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

    fn destroyVertexBuffer(self: *Self) void {
        c.vkDestroyBuffer(self.graphics.logicalDevice, self.vertexBuffer.?, null);
        c.vkFreeMemory(self.graphics.logicalDevice, self.vertexBufferMemory.?, null);
    }

    fn allocateCommandBuffers(self: *Self) !void {
        try ensureNoError(c.vkAllocateCommandBuffers(
            self.graphics.logicalDevice,
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
            c.vkFreeCommandBuffers(self.graphics.logicalDevice, self.commandPool, maxFramesInFlight, &self.commandBuffers);
            self.commandBuffersAllocated = false;
            self.commandBuffers = .{null} ** maxFramesInFlight;
        }
    }

    fn createSyncObjects(self: *Self) !void {
        for (0..maxFramesInFlight) |i| {
            try ensureNoError(c.vkCreateFence(
                self.graphics.logicalDevice,
                &c.VkFenceCreateInfo{
                    .sType = c.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO,
                    .flags = c.VK_FENCE_CREATE_SIGNALED_BIT,
                },
                null,
                &self.inFlightFences[i],
            ));

            try ensureNoError(c.vkCreateSemaphore(
                self.graphics.logicalDevice,
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
                self.graphics.logicalDevice,
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
                    c.vkDestroySemaphore(self.graphics.logicalDevice, semaphore, null);
                }
            }
            self.allocator.free(render_finished_semaphores);
            self.renderFinishedSemaphores = null;
        }

        for (0..maxFramesInFlight) |i| {
            if (self.imageAvailableSemaphores[i] != null) {
                c.vkDestroySemaphore(self.graphics.logicalDevice, self.imageAvailableSemaphores[i], null);
                self.imageAvailableSemaphores[i] = null;
            }
            if (self.inFlightFences[i] != null) {
                c.vkDestroyFence(self.graphics.logicalDevice, self.inFlightFences[i], null);
                self.inFlightFences[i] = null;
            }
        }
    }
};
