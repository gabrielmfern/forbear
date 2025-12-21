// Minimal macOS window creation in pure C using the Objective-C runtime.
// Build: clang examples/macos_window_runtime.c -o macos_window -framework Cocoa

#include <objc/message.h>
#include <objc/objc.h>
#include <objc/runtime.h>

#include <stdlib.h>

extern void *objc_autoreleasePoolPush(void);
extern void objc_autoreleasePoolPop(void *pool);

typedef unsigned long NSUInteger;
typedef long NSInteger;

typedef struct {
  double x;
  double y;
} NSPoint;

typedef struct {
  double width;
  double height;
} NSSize;

typedef struct {
  NSPoint origin;
  NSSize size;
} NSRect;

static NSRect NSMakeRect(double x, double y, double w, double h) {
  NSRect r;
  r.origin.x = x;
  r.origin.y = y;
  r.size.width = w;
  r.size.height = h;
  return r;
}

enum {
  NSApplicationActivationPolicyRegular = 0,
};

enum {
  NSBackingStoreBuffered = 2,
};

enum {
  NSWindowStyleMaskBorderless = 0,
  NSWindowStyleMaskTitled = 1u << 0,
  NSWindowStyleMaskClosable = 1u << 1,
  NSWindowStyleMaskMiniaturizable = 1u << 2,
  NSWindowStyleMaskResizable = 1u << 3,
};

static SEL sel(const char *name) { return sel_registerName(name); }

static id nsstring(const char *cstr) {
  Class NSString = (Class)objc_getClass("NSString");
  return ((id(*)(Class, SEL, const char *))objc_msgSend)(
      NSString, sel("stringWithUTF8String:"), cstr);
}

static BOOL applicationShouldTerminateAfterLastWindowClosed(id self, SEL _cmd,
                                                            id application) {
  (void)self;
  (void)_cmd;
  (void)application;
  return YES;
}

static void createMenuBar(id app) {
  Class NSMenu = (Class)objc_getClass("NSMenu");
  Class NSMenuItem = (Class)objc_getClass("NSMenuItem");

  id menubar = ((id(*)(Class, SEL))objc_msgSend)(NSMenu, sel("new"));
  id appMenuItem = ((id(*)(Class, SEL))objc_msgSend)(NSMenuItem, sel("new"));

  ((void (*)(id, SEL, id))objc_msgSend)(menubar, sel("addItem:"), appMenuItem);
  ((void (*)(id, SEL, id))objc_msgSend)(app, sel("setMainMenu:"), menubar);

  id appMenu = ((id(*)(Class, SEL))objc_msgSend)(NSMenu, sel("new"));
  ((void (*)(id, SEL, id))objc_msgSend)(appMenuItem, sel("setSubmenu:"),
                                        appMenu);

  id quitTitle = nsstring("Quit");
  id keyEquivalent = nsstring("q");

  id quitItem = ((id(*)(Class, SEL))objc_msgSend)(NSMenuItem, sel("alloc"));
  quitItem = ((id(*)(id, SEL, id, SEL, id))objc_msgSend)(
      quitItem, sel("initWithTitle:action:keyEquivalent:"), quitTitle,
      sel("terminate:"), keyEquivalent);

  ((void (*)(id, SEL, id))objc_msgSend)(quitItem, sel("setTarget:"), app);
  ((void (*)(id, SEL, id))objc_msgSend)(appMenu, sel("addItem:"), quitItem);
}

int main(void) {
  void *pool = objc_autoreleasePoolPush();

  Class NSApplication = (Class)objc_getClass("NSApplication");
  id app = ((id(*)(Class, SEL))objc_msgSend)(NSApplication,
                                             sel("sharedApplication"));

  ((BOOL(*)(id, SEL, NSInteger))objc_msgSend)(
      app, sel("setActivationPolicy:"),
      (NSInteger)NSApplicationActivationPolicyRegular);

  // Create an application delegate at runtime.
  Class NSObject = (Class)objc_getClass("NSObject");
  Class AppDelegate = objc_allocateClassPair(NSObject, "MinimalAppDelegate", 0);
  if (AppDelegate) {
    class_addMethod(
        AppDelegate, sel("applicationShouldTerminateAfterLastWindowClosed:"),
        (IMP)applicationShouldTerminateAfterLastWindowClosed, "c@:@");
    objc_registerClassPair(AppDelegate);
  }

  id delegate = ((id(*)(Class, SEL))objc_msgSend)(AppDelegate, sel("new"));
  ((void (*)(id, SEL, id))objc_msgSend)(app, sel("setDelegate:"), delegate);

  createMenuBar(app);

  Class NSWindow = (Class)objc_getClass("NSWindow");

  const NSRect contentRect = NSMakeRect(0, 0, 800, 450);
  const NSUInteger styleMask =
      NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
      NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable;

  id window = ((id(*)(Class, SEL))objc_msgSend)(NSWindow, sel("alloc"));
  window = ((id(*)(id, SEL, NSRect, NSUInteger, NSUInteger, BOOL))objc_msgSend)(
      window, sel("initWithContentRect:styleMask:backing:defer:"), contentRect,
      styleMask, (NSUInteger)NSBackingStoreBuffered, NO);

  if (!window)
    abort();

  ((void (*)(id, SEL, id))objc_msgSend)(window, sel("setTitle:"),
                                        nsstring("Runtime Cocoa Window"));
  ((void (*)(id, SEL))objc_msgSend)(window, sel("center"));

  // Grab the content view and mark it as layer-backed, which is a good base
  // for Metal/OpenGL/Vulkan surfaces.
  id contentView = ((id(*)(id, SEL))objc_msgSend)(window, sel("contentView"));
  if (contentView)
    ((void (*)(id, SEL, BOOL))objc_msgSend)(contentView, sel("setWantsLayer:"),
                                            YES);

  ((void (*)(id, SEL, id))objc_msgSend)(window, sel("makeKeyAndOrderFront:"),
                                        nil);
  ((void (*)(id, SEL, BOOL))objc_msgSend)(
      app, sel("activateIgnoringOtherApps:"), YES);

  ((void (*)(id, SEL))objc_msgSend)(app, sel("run"));

  objc_autoreleasePoolPop(pool);
  return 0;
}
