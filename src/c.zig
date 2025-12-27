const builtin = @import("builtin");
pub const c = @cImport({
    // if (builtin.os.tag == .linux) {
    @cDefine("VK_USE_PLATFORM_WAYLAND_KHR", "1");
    // }
    // if (builtin.os.tag == .macos) {
    //     @cDefine("VK_USE_PLATFORM_METAL_EXT", "1");
    // }

    @cInclude("vulkan/vulkan.h");

    // if (builtin.os.tag == .linux) {
    @cInclude("wayland-client.h");
    @cInclude("wayland-cursor.h");
    @cInclude("xkbcommon/xkbcommon.h");
    @cInclude("xdg-shell-client-protocol.h");

    @cInclude("vulkan/vulkan_wayland.h");
    // }
    // if (builtin.os.tag == .macos) {
    //     @cInclude("objc/objc.h");
    //     @cInclude("objc/runtime.h");
    //     @cInclude("objc/message.h");
    //
    //     @cInclude("vulkan/vulkan_metal.h");
    // }
});
