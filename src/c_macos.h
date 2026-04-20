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
