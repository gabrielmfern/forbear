const builtin = @import("builtin");

pub const Window = if (builtin.os.tag == .macos)
    @import("macos.zig")
else if (builtin.os.tag == .linux)
    @import("linux.zig")
else
    @compileError("Unsupported OS");
