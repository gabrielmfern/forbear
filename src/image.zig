const std = @import("std");
const stb_image = @cImport({
    @cInclude("stb_image.h");
});
const c = @import("c.zig").c;
const Graphics = @import("graphics.zig");

pub fn init(contents: []const u8, format: ImageFormat) !@This() {
    switch (format) {
        .png => {},
    }
}
