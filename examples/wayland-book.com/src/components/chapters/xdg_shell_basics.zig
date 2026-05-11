const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;
const Strong = @import("../strong.zig").Strong;

pub fn XdgShellBasics() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("XDG shell basics");
        });

        Paragraph(.{})({
            forbear.text("The XDG (cross-desktop group) shell is a standard protocol extension for Wayland which describes the semantics for application windows. It defines two ");
            Strong()({ forbear.text("wl_surface"); });
            forbear.text(" roles: \"toplevel\", for your top-level application windows, and \"popup\", for things like context menus, dropdown menus, tooltips, and so on - which are children of top-level windows. With these together, you can form a tree of surfaces, with a toplevel at the top and popups or additional toplevels at the leaves. The protocol also defines a ");
            Strong()({ forbear.text("positioner"); });
            forbear.text(" interface, which is used for help positioning popups with limited information about the things around your window.");
        });

        Paragraph(.{})({
            forbear.text("xdg-shell, as a protocol ");
            Strong()({ forbear.text("extension"); });
            forbear.text(", is not defined in ");
            Strong()({ forbear.text("wayland.xml"); });
            forbear.text(". Instead you'll find it in the ");
            Strong()({ forbear.text("wayland-protocols"); });
            forbear.text(" package. It's probably installed at a path somewhat like ");
            Strong()({ forbear.text("/usr/share/wayland-protocols/stable/xdg-shell/xdg-shell.xml"); });
            forbear.text(" on your system.");
        });

        Heading(.{ .level = 2 })({
            forbear.text("xdg_wm_base");
        });

        Paragraph(.{})({
            Strong()({ forbear.text("xdg_wm_base"); });
            forbear.text(" is the only global defined by the specification, and it provides requests for creating each of the other objects you need. The most basic implementation starts by handling the \"ping\" event — when the compositor sends it, you should respond with a \"pong\" request in a timely manner to hint that you haven't become deadlocked. Another request deals with the creation of positioners, the objects mentioned earlier, and we'll save the details on these for chapter 10. The request we want to look into first is ");
            Strong()({ forbear.text("get_xdg_surface"); });
            forbear.text(".");
        });
    });
}
