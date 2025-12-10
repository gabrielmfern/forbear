pub const c = @cImport({
    @cInclude("wayland-client.h");
    @cInclude("wayland-cursor.h");
    @cInclude("xkbcommon/xkbcommon.h");
    @cInclude("wayland-egl.h");
    @cInclude("xdg-shell-client-protocol.h");
    @cInclude("EGL/egl.h");
    @cInclude("sys/mman.h");
    @cInclude("fcntl.h");
    @cInclude("errno.h");

    @cInclude("vulkan/vulkan.h");
    @cInclude("vulkan/vulkan_wayland.h");
});
