#ifdef LINUX
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
#endif

#ifdef WINDOWS
#define VK_USE_PLATFORM_WIN32_KHR 1
#include <vulkan/vulkan.h>
#endif

#ifdef MACOS
#define VK_USE_PLATFORM_METAL_EXT 1
#include <vulkan/vulkan.h>
#include <vulkan/vulkan_metal.h>
#include <objc/objc.h>
#include <objc/runtime.h>
#include <objc/message.h>

// Minimal CoreGraphics declarations for display queries. Including the real
// CoreGraphics headers fails translate-c because they use Objective-C
// nullability extensions on array parameters and ObjC blocks, which Clang
// rejects in plain C mode. We only need six symbols so we declare them by
// hand; the ABI types are stable on 64-bit macOS.
typedef double CGFloat;
typedef unsigned int CGDirectDisplayID;
typedef struct { CGFloat width; CGFloat height; } CGSize;
typedef struct CGDisplayMode *CGDisplayModeRef;

extern CGSize CGDisplayScreenSize(CGDirectDisplayID display);
extern size_t CGDisplayPixelsWide(CGDirectDisplayID display);
extern size_t CGDisplayPixelsHigh(CGDirectDisplayID display);
extern CGDisplayModeRef CGDisplayCopyDisplayMode(CGDirectDisplayID display);
extern void CGDisplayModeRelease(CGDisplayModeRef mode);
extern double CGDisplayModeGetRefreshRate(CGDisplayModeRef mode);
#endif

#include <freetype/ftadvanc.h>
#include <freetype/ftbbox.h>
#include <freetype/ftbitmap.h>
#include <freetype/ftcolor.h>
#include <freetype/ftlcdfil.h>
#include <freetype/ftsizes.h>
#include <freetype/ftstroke.h>
#include <freetype/fttrigon.h>
#include <freetype/ftmm.h>
#include <freetype/ftsynth.h>

#include <kb_text_shape.h>
#include <stb_image.h>
