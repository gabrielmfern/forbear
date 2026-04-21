// Include wayland headers BEFORE vulkan to avoid translate-c naming collisions
// (vulkan_wayland.h forward-declares struct wl_display/wl_surface, causing suffixed names)
#include <wayland-client.h>
#include <wayland-cursor.h>

#define VK_USE_PLATFORM_WAYLAND_KHR 1
#include <vulkan/vulkan.h>
#include <vulkan/vulkan_wayland.h>
#include <malloc.h>
#include <xkbcommon/xkbcommon.h>
#include <xdg-shell-client-protocol.h>
#include <fractional-scale-v1-client-protocol.h>
#include <viewporter-client-protocol.h>
#include <xdg-decoration-unstable-v1-client-protocol.h>
