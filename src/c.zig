const builtin = @import("builtin");

pub const c = @cImport({
    switch (builtin.os.tag) {
        .linux => {
            @cDefine("VK_USE_PLATFORM_WAYLAND_KHR", "1");
        },
        .windows => {
            @cDefine("VK_USE_PLATFORM_WIN32_KHR", "1");
        },
        .macos => {
            @cDefine("VK_USE_PLATFORM_METAL_EXT", "1");
        },
        else => {},
    }

    @cInclude("vulkan/vulkan.h");

    switch (builtin.os.tag) {
        .linux => {
            @cInclude("vulkan/vulkan_wayland.h");

            @cInclude("malloc.h");

            @cInclude("wayland-client.h");
            @cInclude("wayland-cursor.h");
            @cInclude("xkbcommon/xkbcommon.h");
            @cInclude("xdg-shell-client-protocol.h");
            @cInclude("fractional-scale-v1-client-protocol.h");
            @cInclude("viewporter-client-protocol.h");
            @cInclude("xdg-decoration-unstable-v1-client-protocol.h");
        },
        .macos => {
            @cInclude("objc/objc.h");
            @cInclude("objc/runtime.h");
            @cInclude("objc/message.h");

            @cInclude("vulkan/vulkan_metal.h");

            @cInclude("CoreGraphics/CoreGraphics.h");
        },
        else => {},
    }
});
