const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;
const Strong = @import("../strong.zig").Strong;
const List = @import("../list.zig").List;
const ListItem = @import("../list.zig").ListItem;

pub fn HighLevelWaylandDesign() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("High-level Wayland design");
        });

        Paragraph(.{})({
            forbear.text("Your computer has ");
            Strong()({ forbear.text("input"); });
            forbear.text(" and ");
            Strong()({ forbear.text("output"); });
            forbear.text(" devices, which respectively are responsible for receiving information from you and displaying information to you. These input devices take the form of, for example:");
        });

        List()({
            ListItem()({ forbear.text("Keyboards"); });
            ListItem()({ forbear.text("Mice"); });
            ListItem()({ forbear.text("Touchpads"); });
            ListItem()({ forbear.text("Touch screens"); });
            ListItem()({ forbear.text("Drawing tablets"); });
        });

        Paragraph(.{})({
            forbear.text("Your output devices generally take the form of displays, on your desk or your laptop or mobile device. These resources are shared between all of your applications, and the role of the ");
            Strong()({ forbear.text("Wayland compositor"); });
            forbear.text(" is to dispatch input events to the appropriate ");
            Strong()({ forbear.text("Wayland client"); });
            forbear.text(" and to display their windows in their appropriate place on your outputs. The process of bringing together all of your application windows for display on an output is called ");
            Strong()({ forbear.text("compositing"); });
            forbear.text(" - and thus we call the software which does this the ");
            Strong()({ forbear.text("compositor"); });
            forbear.text(".");
        });

        Heading(.{ .level = 2 })({
            forbear.text("In practice");
        });

        Paragraph(.{})({
            forbear.text("There are many distinct software components in desktop ecosystem. There are tools like Mesa for rendering (and each of its drivers), the Linux KMS/DRM subsystem, buffer allocation with GBM, the userspace libdrm library, libinput and evdev, and much more still. Don't worry - expertise with most of these systems is not required for understanding Wayland, and in any case are largely beyond the scope of this book. In fact, the Wayland protocol is quite conservative and abstract, and a Wayland-based desktop could easily be built & run most applications without implicating any of this software. That being said, a surface-level understanding of what these pieces are and how they work is useful. Let's start from the bottom and work our way up.");
        });

        Heading(.{ .level = 2 })({
            forbear.text("The hardware");
        });

        Paragraph(.{})({
            forbear.text("A typical computer is equipped with a few important pieces of hardware. Outside of the box, we have your displays, keyboard, mouse, perhaps some speakers and a cute USB cup warmer. There are several components ");
            Strong()({ forbear.text("inside"); });
            forbear.text(" the box for interfacing with these devices. Your keyboard and mouse, for example, are probably plugged into USB ports, for which your system has a dedicated USB controller. Your displays are plugged into your GPU.");
        });

        Paragraph(.{})({
            forbear.text("These systems have their own jobs and state. For example, your GPU has state in the form of memory for storing pixel buffers in, and jobs like ");
            Strong()({ forbear.text("scanning out"); });
            forbear.text(" these buffers to your displays. Your GPU also provides a processor which is specially tuned to be good at highly parallel jobs (such as calculating the right color for each of the 2,073,600 pixels on a 1080p display), and bad at everything else. The USB controller has the unenviable job of implementing the legendarily dry USB specification for receiving input events from your keyboard, or instructing your coaster to assume a temperature carefully selected to at once avoid lawsuits and frustrate you with cold coffee.");
        });

        Paragraph(.{})({
            forbear.text("At this level, your hardware has little concept of what applications are running on your system. The hardware provides an interface with which it can be commanded to perform work, and does what it's told - regardless of who tells it so. For this reason, only one component is allowed to talk to it...");
        });

        Heading(.{ .level = 2 })({
            forbear.text("The kernel");
        });

        Paragraph(.{})({
            forbear.text("This responsibility falls onto the kernel. The kernel is a complex beast, so we'll focus on only the parts which are relevant to Wayland. Linux's job is to provide an abstraction over your hardware, so that it can be safely accessed by ");
            Strong()({ forbear.text("userspace"); });
            forbear.text(" - where our Wayland compositors run. For graphics, this is called the ");
            Strong()({ forbear.text("DRM"); });
            forbear.text(", or ");
            Strong()({ forbear.text("direct rendering manager"); });
            forbear.text(", which efficiently tasks the GPU with work from userspace. An important subsystem of DRM is ");
            Strong()({ forbear.text("KMS"); });
            forbear.text(", or ");
            Strong()({ forbear.text("kernel mode setting"); });
            forbear.text(", for enumerating your displays and setting properties such as their selected resolution (also known as their \"mode\"). Input devices are abstracted through an interface called ");
            Strong()({ forbear.text("evdev"); });
            forbear.text(".");
        });

        Paragraph(.{})({
            forbear.text("Most kernel interfaces are made available to userspace by way of special files in /dev. In the case of DRM, these files are in /dev/dri/, usually in the form of a primary node (e.g. card0) for privileged operations like modesetting, and a render node (e.g. renderD128), for unprivileged operations like rendering or video decoding. For evdev, the \"device nodes\" are /dev/input/event*.");
        });

        Heading(.{ .level = 2 })({
            forbear.text("Userspace");
        });

        Paragraph(.{})({
            forbear.text("Now, we enter userspace. Here, applications are isolated from the hardware and must work via the device nodes provided by the kernel.");
        });

        Heading(.{ .level = 3 })({
            forbear.text("libdrm");
        });

        Paragraph(.{})({
            forbear.text("Most Linux interfaces have a userspace counterpart which provides a pleasant(ish) C API for working with these device nodes. One such library is libdrm, which is the userspace portion of the DRM subsystem. libdrm is used by Wayland compositors to do modesetting and other DRM operations, but is generally not used by Wayland clients directly.");
        });

        Heading(.{ .level = 3 })({
            forbear.text("Mesa");
        });

        Paragraph(.{})({
            forbear.text("Mesa is one of the most important parts of the Linux graphics stack. It provides, among other things, vendor-optimized implementations of OpenGL (and Vulkan) for Linux and the ");
            Strong()({ forbear.text("GBM"); });
            forbear.text(" (Generic Buffer Management) library - an abstraction on top of libdrm for allocating buffers on the GPU. Most Wayland compositors will use both GBM and OpenGL via Mesa, and most Wayland clients will use at least its OpenGL or Vulkan implementations.");
        });

        Heading(.{ .level = 3 })({
            forbear.text("libinput");
        });

        Paragraph(.{})({
            forbear.text("Like libdrm abstracts the DRM subsystem, libinput provides the userspace end of evdev. It's responsible for receiving input events from the kernel from your various input devices, decoding them into a usable form, and passing them on to the Wayland compositor. The Wayland compositor requires special permissions to use the evdev files, forcing Wayland clients to go through the compositor to receive input events - which, for example, prevents keylogging.");
        });

        Heading(.{ .level = 3 })({
            forbear.text("(e)udev");
        });

        Paragraph(.{})({
            forbear.text("Dealing with the appearance of new devices from the kernel, configuring permissions for the resulting device nodes in /dev, and sending word of these changes to applications running on your system, is a responsibility that falls onto userspace. Most systems use udev (or eudev, a fork) for this purpose. Your Wayland compositor uses udev to enumerate input devices and GPUs, and to receive notifications when new ones appear or old ones are unplugged.");
        });

        Heading(.{ .level = 3 })({
            forbear.text("xkbcommon");
        });

        Paragraph(.{})({
            forbear.text("XKB, short for X keyboard, is the original keyboard handling subsystem of the Xorg server. Several years ago, it was extracted from the Xorg tree and made into an independent library for keyboard handling, and it no longer has any practical relationship with X. Libinput (along with the Wayland compositor) delivers keyboard events in the form of scancodes, whose precise meaning varies from keyboard to keyboard. It's the responsibility of xkbcommon to translate these scan codes into meaningful and generic key \"symbols\" - for example, converting 65 to XKB_KEY_Space. It also contains a state machine which knows that pressing \"1\" while shift is held emits \"!\".");
        });

        Heading(.{ .level = 3 })({
            forbear.text("pixman");
        });

        Paragraph(.{})({
            forbear.text("A simple library used by clients and compositors alike for efficiently manipulating pixel buffers, doing math with intersecting rectangles, and performing other similar ");
            Strong()({ forbear.text("pix"); });
            forbear.text("el ");
            Strong()({ forbear.text("man"); });
            forbear.text("ipulation tasks.");
        });

        Heading(.{ .level = 3 })({
            forbear.text("libwayland");
        });

        Paragraph(.{})({
            forbear.text("libwayland the most commonly used implementation of the Wayland protocol, is written in C, and handles much of the low-level wire protocol. It also provides a tool which generates high-level code from Wayland protocol definitions (which are XML files). We will be discussing libwayland in detail in chapter 1.3, and throughout this book.");
        });

        Heading(.{ .level = 3 })({
            forbear.text("...and all the rest.");
        });

        Paragraph(.{})({
            forbear.text("Each of the pieces mentioned so far are consistently found throughout the Linux desktop ecosystem. Beyond this, more components exist. Many graphical applications don't know about Wayland at all, choosing instead to allow libraries like GTK+, Qt, SDL, and GLFW - among many others - to deal with it. Many compositors choose software like wlroots to abstract more of their responsibilities, while others implement everything in-house.");
        });
    });
}
