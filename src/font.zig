const std = @import("std");

const c = @cImport({
    @cInclude("kb_text_shape.h");
    @cInclude("freetype/ftadvanc.h");
    @cInclude("freetype/ftbbox.h");
    @cInclude("freetype/ftbitmap.h");
    @cInclude("freetype/ftcolor.h");
    @cInclude("freetype/ftlcdfil.h");
    @cInclude("freetype/ftsizes.h");
    @cInclude("freetype/ftstroke.h");
    @cInclude("freetype/fttrigon.h");
    @cInclude("freetype/ftmm.h");
    @cInclude("freetype/ftsynth.h");
});

const Vec2 = @Vector(2, f32);

const FreetypeError = error{
    CannotOpenResource,
    UnknownFileFormat,
    InvalidFileFormat,
    InvalidVersion,
    LowerModuleVersion,
    InvalidArgument,
    UnimplementedFeature,
    InvalidTable,
    InvalidOffset,
    ArrayTooLarge,
    MissingModule,
    MissingProperty,
    InvalidGlyphIndex,
    InvalidCharacterCode,
    InvalidGlyphFormat,
    CannotRenderGlyph,
    InvalidOutline,
    InvalidComposite,
    TooManyHints,
    InvalidPixelSize,
    InvalidSVGDocument,
    InvalidHandle,
    InvalidLibraryHandle,
    InvalidDriverHandle,
    InvalidFaceHandle,
    InvalidSizeHandle,
    InvalidSlotHandle,
    InvalidCharMapHandle,
    InvalidCacheHandle,
    InvalidStreamHandle,
    TooManyDrivers,
    TooManyExtensions,
    OutOfMemory,
    UnlistedObject,
    CannotOpenStream,
    InvalidStreamSeek,
    InvalidStreamSkip,
    InvalidStreamRead,
    InvalidStreamOperation,
    InvalidFrameOperation,
    NestedFrameAccess,
    InvalidFrameRead,
    RasterUninitialized,
    RasterCorrupted,
    RasterOverflow,
    RasterNegativeHeight,
    TooManyCaches,
    InvalidOpcode,
    TooFewArguments,
    StackOverflow,
    CodeOverflow,
    BadArgument,
    DivideByZero,
    InvalidReference,
    DebugOpCode,
    ENDFInExecStream,
    NestedDEFS,
    InvalidCodeRange,
    ExecutionTooLong,
    TooManyFunctionDefs,
    TooManyInstructionDefs,
    TableMissing,
    HorizHeaderMissing,
    LocationsMissing,
    NameTableMissing,
    CMapTableMissing,
    HmtxTableMissing,
    PostTableMissing,
    InvalidHorizMetrics,
    InvalidCharMapFormat,
    InvalidPPem,
    InvalidVertMetrics,
    CouldNotFindContext,
    InvalidPostTableFormat,
    InvalidPostTable,
    DEFInGlyfBytecode,
    MissingBitmap,
    MissingSVGHooks,
    SyntaxError,
    StackUnderflow,
    Ignore,
    NoUnicodeGlyphName,
    GlyphTooBig,
    MissingStartfontField,
    MissingFontField,
    MissingSizeField,
    MissingFontboundingboxField,
    MissingCharsField,
    MissingStartcharField,
    MissingEncodingField,
    MissingBbxField,
    BbxTooBig,
    CorruptedFontHeader,
    CorruptedFontGlyphs,
};

fn ensureNoError(errorCode: c.FT_Error) FreetypeError!void {
    switch (errorCode) {
        c.FT_Err_Cannot_Open_Resource => return error.CannotOpenResource,
        c.FT_Err_Unknown_File_Format => return error.UnknownFileFormat,
        c.FT_Err_Invalid_File_Format => return error.InvalidFileFormat,
        c.FT_Err_Invalid_Version => return error.InvalidVersion,
        c.FT_Err_Lower_Module_Version => return error.LowerModuleVersion,
        c.FT_Err_Invalid_Argument => return error.InvalidArgument,
        c.FT_Err_Unimplemented_Feature => return error.UnimplementedFeature,
        c.FT_Err_Invalid_Table => return error.InvalidTable,
        c.FT_Err_Invalid_Offset => return error.InvalidOffset,
        c.FT_Err_Array_Too_Large => return error.ArrayTooLarge,
        c.FT_Err_Missing_Module => return error.MissingModule,
        c.FT_Err_Missing_Property => return error.MissingProperty,
        c.FT_Err_Invalid_Glyph_Index => return error.InvalidGlyphIndex,
        c.FT_Err_Invalid_Character_Code => return error.InvalidCharacterCode,
        c.FT_Err_Invalid_Glyph_Format => return error.InvalidGlyphFormat,
        c.FT_Err_Cannot_Render_Glyph => return error.CannotRenderGlyph,
        c.FT_Err_Invalid_Outline => return error.InvalidOutline,
        c.FT_Err_Invalid_Composite => return error.InvalidComposite,
        c.FT_Err_Too_Many_Hints => return error.TooManyHints,
        c.FT_Err_Invalid_Pixel_Size => return error.InvalidPixelSize,
        c.FT_Err_Invalid_SVG_Document => return error.InvalidSVGDocument,
        c.FT_Err_Invalid_Handle => return error.InvalidHandle,
        c.FT_Err_Invalid_Library_Handle => return error.InvalidLibraryHandle,
        c.FT_Err_Invalid_Driver_Handle => return error.InvalidDriverHandle,
        c.FT_Err_Invalid_Face_Handle => return error.InvalidFaceHandle,
        c.FT_Err_Invalid_Size_Handle => return error.InvalidSizeHandle,
        c.FT_Err_Invalid_Slot_Handle => return error.InvalidSlotHandle,
        c.FT_Err_Invalid_CharMap_Handle => return error.InvalidCharMapHandle,
        c.FT_Err_Invalid_Cache_Handle => return error.InvalidCacheHandle,
        c.FT_Err_Invalid_Stream_Handle => return error.InvalidStreamHandle,
        c.FT_Err_Too_Many_Drivers => return error.TooManyDrivers,
        c.FT_Err_Too_Many_Extensions => return error.TooManyExtensions,
        c.FT_Err_Out_Of_Memory => return error.OutOfMemory,
        c.FT_Err_Unlisted_Object => return error.UnlistedObject,
        c.FT_Err_Cannot_Open_Stream => return error.CannotOpenStream,
        c.FT_Err_Invalid_Stream_Seek => return error.InvalidStreamSeek,
        c.FT_Err_Invalid_Stream_Skip => return error.InvalidStreamSkip,
        c.FT_Err_Invalid_Stream_Read => return error.InvalidStreamRead,
        c.FT_Err_Invalid_Stream_Operation => return error.InvalidStreamOperation,
        c.FT_Err_Invalid_Frame_Operation => return error.InvalidFrameOperation,
        c.FT_Err_Nested_Frame_Access => return error.NestedFrameAccess,
        c.FT_Err_Invalid_Frame_Read => return error.InvalidFrameRead,
        c.FT_Err_Raster_Uninitialized => return error.RasterUninitialized,
        c.FT_Err_Raster_Corrupted => return error.RasterCorrupted,
        c.FT_Err_Raster_Overflow => return error.RasterOverflow,
        c.FT_Err_Raster_Negative_Height => return error.RasterNegativeHeight,
        c.FT_Err_Too_Many_Caches => return error.TooManyCaches,
        c.FT_Err_Invalid_Opcode => return error.InvalidOpcode,
        c.FT_Err_Too_Few_Arguments => return error.TooFewArguments,
        c.FT_Err_Stack_Overflow => return error.StackOverflow,
        c.FT_Err_Code_Overflow => return error.CodeOverflow,
        c.FT_Err_Bad_Argument => return error.BadArgument,
        c.FT_Err_Divide_By_Zero => return error.DivideByZero,
        c.FT_Err_Invalid_Reference => return error.InvalidReference,
        c.FT_Err_Debug_OpCode => return error.DebugOpCode,
        c.FT_Err_ENDF_In_Exec_Stream => return error.ENDFInExecStream,
        c.FT_Err_Nested_DEFS => return error.NestedDEFS,
        c.FT_Err_Invalid_CodeRange => return error.InvalidCodeRange,
        c.FT_Err_Execution_Too_Long => return error.ExecutionTooLong,
        c.FT_Err_Too_Many_Function_Defs => return error.TooManyFunctionDefs,
        c.FT_Err_Too_Many_Instruction_Defs => return error.TooManyInstructionDefs,
        c.FT_Err_Table_Missing => return error.TableMissing,
        c.FT_Err_Horiz_Header_Missing => return error.HorizHeaderMissing,
        c.FT_Err_Locations_Missing => return error.LocationsMissing,
        c.FT_Err_Name_Table_Missing => return error.NameTableMissing,
        c.FT_Err_CMap_Table_Missing => return error.CMapTableMissing,
        c.FT_Err_Hmtx_Table_Missing => return error.HmtxTableMissing,
        c.FT_Err_Post_Table_Missing => return error.PostTableMissing,
        c.FT_Err_Invalid_Horiz_Metrics => return error.InvalidHorizMetrics,
        c.FT_Err_Invalid_CharMap_Format => return error.InvalidCharMapFormat,
        c.FT_Err_Invalid_PPem => return error.InvalidPPem,
        c.FT_Err_Invalid_Vert_Metrics => return error.InvalidVertMetrics,
        c.FT_Err_Could_Not_Find_Context => return error.CouldNotFindContext,
        c.FT_Err_Invalid_Post_Table_Format => return error.InvalidPostTableFormat,
        c.FT_Err_Invalid_Post_Table => return error.InvalidPostTable,
        c.FT_Err_DEF_In_Glyf_Bytecode => return error.DEFInGlyfBytecode,
        c.FT_Err_Missing_Bitmap => return error.MissingBitmap,
        c.FT_Err_Missing_SVG_Hooks => return error.MissingSVGHooks,
        c.FT_Err_Syntax_Error => return error.SyntaxError,
        c.FT_Err_Stack_Underflow => return error.StackUnderflow,
        c.FT_Err_Ignore => return error.Ignore,
        c.FT_Err_No_Unicode_Glyph_Name => return error.NoUnicodeGlyphName,
        c.FT_Err_Glyph_Too_Big => return error.GlyphTooBig,
        c.FT_Err_Missing_Startfont_Field => return error.MissingStartfontField,
        c.FT_Err_Missing_Font_Field => return error.MissingFontField,
        c.FT_Err_Missing_Size_Field => return error.MissingSizeField,
        c.FT_Err_Missing_Fontboundingbox_Field => return error.MissingFontboundingboxField,
        c.FT_Err_Missing_Chars_Field => return error.MissingCharsField,
        c.FT_Err_Missing_Startchar_Field => return error.MissingStartcharField,
        c.FT_Err_Missing_Encoding_Field => return error.MissingEncodingField,
        c.FT_Err_Missing_Bbx_Field => return error.MissingBbxField,
        c.FT_Err_Bbx_Too_Big => return error.BbxTooBig,
        c.FT_Err_Corrupted_Font_Header => return error.CorruptedFontHeader,
        c.FT_Err_Corrupted_Font_Glyphs => return error.CorruptedFontGlyphs,
        else => std.debug.assert(errorCode == c.FT_Err_Ok),
    }
}

var freetypeLibrary: c.FT_Library = null;

handle: c.FT_Face,
allocator: std.mem.Allocator,
kbtsContext: *c.kbts_shape_context,
kbtsFont: *c.kbts_font,
key: u64,

shapingCache: ShapingCache,

const ShapingCache = LRU([]const u8, []ShapedGlyph, 256, std.hash_map.StringContext);

pub fn LRU(
    comptime Key: type,
    comptime Value: type,
    comptime capacity: usize,
    comptime Context: type,
) type {
    return struct {
        pub const Entry = struct {
            value: Value,
            key: Key,
            next: ?usize = null,
            prev: ?usize = null,
        };

        entries: [capacity]Entry,
        first: ?usize,
        last: ?usize,
        length: usize,
        entries_map: EntriesMap,

        const EntriesMap = std.HashMap(
            Key,
            usize,
            Context,
            std.hash_map.default_max_load_percentage,
        );

        pub fn init(allocator: std.mem.Allocator) error{OutOfMemory}!@This() {
            // TODO: even though this allocation is only done once, it would ideally be data from
            // the stack which would be much more efficient here, but there are no subsequent
            // allocations done, and we only use methods that assert enough capacity
            var entries_map = EntriesMap.init(allocator);
            try entries_map.ensureUnusedCapacity(capacity);
            return @This(){
                .entries = undefined,
                .first = null,
                .last = null,
                .length = 0,
                .entries_map = entries_map,
            };
        }

        pub fn deinit(self: *@This()) void {
            self.entries_map.deinit();
        }

        pub fn contains(self: *@This(), key: Key) bool {
            return self.entries_map.contains(key);
        }

        pub fn clear(self: *@This()) void {
            self.entries_map.clearRetainingCapacity();
            self.first = null;
            self.last = null;
            self.length = 0;
        }

        /// Gets the data without updating its recency
        pub fn peek(self: *@This(), key: Key) ?*const Entry {
            if (self.entries_map.get(key)) |index| {
                return &self.entries[index];
            } else {
                return null;
            }
        }

        fn join(self: *@This(), a: ?usize, b: ?usize) void {
            if (a != null) {
                self.entries[a.?].next = b;
            }
            if (b != null) {
                self.entries[b.?].prev = a;
            }
        }

        fn set_first(self: *@This(), index: usize) void {
            if (self.first != index) {
                const entry = &self.entries[index];
                self.join(entry.prev, entry.next);
                if (entry.prev != null and self.last == index) {
                    self.last = entry.prev.?;
                }

                if (self.first) |first| {
                    self.join(index, first);
                }
                entry.prev = null;
                self.first = index;
                if (self.last == null) {
                    self.last = index;
                }
            }
        }

        const PutResult = struct {
            index: usize,
            evicted: ?Entry,
        };

        pub fn put(self: *@This(), key: Key, value: Value) PutResult {
            if (self.entries_map.get(key)) |index| {
                self.entries[index].value = value;
                self.set_first(index);
                return .{ .index = index, .evicted = null };
            }

            const entry = Entry{
                .key = key,
                .value = value,
                .next = null,
                .prev = null,
            };
            if (self.length >= capacity) {
                std.debug.assert(self.last != null);
                std.debug.assert(self.first != null);

                const removed_least_recent_entry = self.entries[self.last.?];

                // since the capacity of the entries is full, we reuse the last entry's memory with
                // the one from this new one
                const new_entry_index = self.last.?;
                self.entries[new_entry_index].key = entry.key;
                self.entries[new_entry_index].value = entry.value;
                self.set_first(new_entry_index);
                // we remove before here to ensure the capacity of the hashmap is available for the
                // new entry's key
                _ = self.entries_map.remove(removed_least_recent_entry.key);
                self.entries_map.putAssumeCapacity(key, new_entry_index);

                return .{ .index = new_entry_index, .evicted = removed_least_recent_entry };
            } else {
                const new_entry_index = self.length;
                self.entries[new_entry_index] = entry;
                self.set_first(new_entry_index);
                self.length += 1;

                self.entries_map.putAssumeCapacity(key, new_entry_index);

                return .{ .index = new_entry_index, .evicted = null };
            }
        }

        pub fn print(self: @This()) void {
            var current = if (self.first) |first| self.entries[first] else null;
            var index: usize = 0;
            while (current) |entry| {
                std.debug.print("Entry {}: key = {any}, value = {s}\n", .{ index, entry.key, entry.value });
                current = if (entry.next) |next| self.entries[next] else null;
                index += 1;
            }
        }

        fn get_index(self: *@This(), key: Key) ?usize {
            if (self.entries_map.get(key)) |entry_index| {
                std.debug.assert(self.first != null);
                if (entry_index != self.first.?) {
                    self.set_first(entry_index);
                }
                return entry_index;
            } else {
                return null;
            }
        }

        pub fn getMut(self: *@This(), key: Key) ?*Entry {
            if (self.get_index(key)) |index| {
                return &self.entries[index];
            } else {
                return null;
            }
        }

        pub fn get(self: *@This(), key: Key) ?*const Entry {
            if (self.get_index(key)) |index| {
                return &self.entries[index];
            } else {
                return null;
            }
        }
    };
}

test "LRU cache - set_first" {
    const LRUIntString = LRU(i32, []const u8, 3, std.hash_map.AutoContext(i32));
    var lru = try LRUIntString.init(std.testing.allocator);
    defer lru.deinit();

    lru.entries[0] = LRUIntString.Entry{ .key = 1, .value = "one" };
    lru.entries[1] = LRUIntString.Entry{ .key = 2, .value = "two" };
    lru.entries[2] = LRUIntString.Entry{ .key = 3, .value = "three" };

    lru.first = 0;
    lru.last = 2;

    lru.set_first(2);

    try std.testing.expectEqual(2, lru.first.?);
    try std.testing.expectEqual(3, lru.entries[lru.first.?].key);
    try std.testing.expectEqualSlices(u8, "three", lru.entries[lru.first.?].value);
}

test "LRU Cache" {
    var lru = try LRU(i32, []const u8, 3, std.hash_map.AutoContext(i32)).init(std.testing.allocator);

    defer lru.deinit();

    _ = lru.put(1, "1");
    _ = lru.put(2, "2");
    _ = lru.put(3, "3");
    std.debug.print("After inserting all three entries:\n", .{});
    lru.print();

    const entry_2 = lru.get(2);
    try std.testing.expect(entry_2 != null);
    try std.testing.expectEqual(2, entry_2.?.key);
    try std.testing.expectEqualSlices(u8, "2", entry_2.?.value);
    try std.testing.expectEqual(entry_2.?, &lru.entries[lru.first.?]);
    std.debug.print("After accessing entry 2:\n", .{});
    lru.print();

    const entry_1 = lru.get(1);
    try std.testing.expect(entry_1 != null);
    try std.testing.expectEqual(1, entry_1.?.key);
    try std.testing.expectEqualSlices(u8, "1", entry_1.?.value);
    try std.testing.expectEqual(entry_1.?, &lru.entries[lru.first.?]);
    std.debug.print("After accessing entry 1:\n", .{});
    lru.print();

    const entry_3 = lru.get(3);
    try std.testing.expect(entry_3 != null);
    try std.testing.expectEqual(3, entry_3.?.key);
    try std.testing.expectEqualSlices(u8, "3", entry_3.?.value);
    try std.testing.expectEqual(entry_3.?, &lru.entries[lru.first.?]);
    std.debug.print("After accessing entry 3:\n", .{});
    lru.print();

    // Adding a new value should evict the least recently used value
    const entry_4 = lru.put(4, "4");
    std.debug.print("After adding the entry '4' beyond the capacity of the LRU:\n", .{});
    lru.print();
    try std.testing.expectEqual(entry_4, lru.first.?);
    // The entry for 2 should have been discarded completely
    try std.testing.expectEqual(entry_1.?, &lru.entries[lru.last.?]);
    try std.testing.expect(lru.get(2) == null);
}

test "LRU cache - update existing key" {
    var lru = try LRU(i32, []const u8, 3, std.hash_map.AutoContext(i32)).init(std.testing.allocator);
    defer lru.deinit();

    _ = lru.put(1, "one");
    _ = lru.put(2, "two");
    _ = lru.put(3, "three");

    // Update existing key should replace value and move to front
    const updated_index = lru.put(2, "TWO");

    const entry = lru.get(2);
    try std.testing.expect(entry != null);
    try std.testing.expectEqualSlices(u8, "TWO", entry.?.value);
    try std.testing.expectEqual(updated_index, lru.first.?);
    try std.testing.expectEqual(2, lru.entries[lru.first.?].key);
    try std.testing.expectEqual(3, lru.length);
}

test "LRU cache - empty cache operations" {
    var lru = try LRU(i32, []const u8, 3, std.hash_map.AutoContext(i32)).init(std.testing.allocator);
    defer lru.deinit();

    // Get from empty cache should return null
    try std.testing.expect(lru.get(1) == null);
    try std.testing.expect(lru.peek(1) == null);
    try std.testing.expectEqual(false, lru.contains(1));
    try std.testing.expectEqual(null, lru.first);
    try std.testing.expectEqual(null, lru.last);
    try std.testing.expectEqual(0, lru.length);
}

test "LRU cache - single item cache" {
    var lru = try LRU(i32, []const u8, 1, std.hash_map.AutoContext(i32)).init(std.testing.allocator);
    defer lru.deinit();

    _ = lru.put(1, "one");
    try std.testing.expectEqual(1, lru.length);
    try std.testing.expectEqual(0, lru.first.?);
    try std.testing.expectEqual(0, lru.last.?);

    const entry = lru.get(1);
    try std.testing.expect(entry != null);
    try std.testing.expectEqualSlices(u8, "one", entry.?.value);

    // Adding another item should evict the first
    _ = lru.put(2, "two");
    try std.testing.expectEqual(1, lru.length);
    try std.testing.expect(lru.get(1) == null);

    const entry2 = lru.get(2);
    try std.testing.expect(entry2 != null);
    try std.testing.expectEqualSlices(u8, "two", entry2.?.value);
}

test "LRU cache - multiple accesses same key" {
    var lru = try LRU(i32, []const u8, 3, std.hash_map.AutoContext(i32)).init(std.testing.allocator);
    defer lru.deinit();

    _ = lru.put(1, "one");
    _ = lru.put(2, "two");
    _ = lru.put(3, "three");

    // Access same key multiple times
    _ = lru.get(2);
    _ = lru.get(2);
    _ = lru.get(2);

    // Should still be at front
    try std.testing.expectEqual(1, lru.first.?);
    try std.testing.expectEqual(2, lru.entries[lru.first.?].key);

    // Add new item, key 2 was most recently used, so 1 should be evicted
    _ = lru.put(4, "four");
    try std.testing.expect(lru.get(1) == null);
    try std.testing.expect(lru.get(2) != null);
}

test "LRU cache - peek does not affect order" {
    var lru = try LRU(i32, []const u8, 3, std.hash_map.AutoContext(i32)).init(std.testing.allocator);
    defer lru.deinit();

    _ = lru.put(1, "one");
    _ = lru.put(2, "two");
    _ = lru.put(3, "three");

    // Peek at key 1 (currently at back)
    const peeked = lru.peek(1);
    try std.testing.expect(peeked != null);
    try std.testing.expectEqualSlices(u8, "one", peeked.?.value);

    // Key 3 should still be at front
    try std.testing.expectEqual(2, lru.first.?);
    try std.testing.expectEqual(3, lru.entries[lru.first.?].key);

    // Add new item, key 1 should be evicted (not moved to front by peek)
    _ = lru.put(4, "four");
    try std.testing.expect(lru.get(1) == null);
}

test "LRU cache - contains" {
    var lru = try LRU(i32, []const u8, 3, std.hash_map.AutoContext(i32)).init(std.testing.allocator);
    defer lru.deinit();

    _ = lru.put(1, "one");
    _ = lru.put(2, "two");

    try std.testing.expectEqual(true, lru.contains(1));
    try std.testing.expectEqual(true, lru.contains(2));
    try std.testing.expectEqual(false, lru.contains(3));
}

test "LRU cache - clear" {
    var lru = try LRU(i32, []const u8, 3, std.hash_map.AutoContext(i32)).init(std.testing.allocator);
    defer lru.deinit();

    _ = lru.put(1, "one");
    _ = lru.put(2, "two");
    _ = lru.put(3, "three");

    try std.testing.expectEqual(3, lru.length);

    lru.clear();

    try std.testing.expectEqual(0, lru.length);
    try std.testing.expectEqual(null, lru.first);
    try std.testing.expectEqual(null, lru.last);
    try std.testing.expect(lru.get(1) == null);
    try std.testing.expect(lru.get(2) == null);
    try std.testing.expect(lru.get(3) == null);

    // Should be able to add new items after clear
    _ = lru.put(4, "four");
    const entry = lru.get(4);
    try std.testing.expect(entry != null);
    try std.testing.expectEqualSlices(u8, "four", entry.?.value);
}

test "LRU cache - getMut allows modification" {
    var lru = try LRU(i32, []const u8, 3, std.hash_map.AutoContext(i32)).init(std.testing.allocator);
    defer lru.deinit();

    _ = lru.put(1, "one");

    const entry = lru.getMut(1);
    try std.testing.expect(entry != null);
    entry.?.value = "modified";

    const retrieved = lru.get(1);
    try std.testing.expect(retrieved != null);
    try std.testing.expectEqualSlices(u8, "modified", retrieved.?.value);
}

test "LRU cache - eviction order with mixed access" {
    var lru = try LRU(i32, []const u8, 3, std.hash_map.AutoContext(i32)).init(std.testing.allocator);
    defer lru.deinit();

    _ = lru.put(1, "one");
    _ = lru.put(2, "two");
    _ = lru.put(3, "three");

    // Access pattern: 1, 3, (2 not accessed)
    _ = lru.get(1);
    _ = lru.get(3);

    // Add new item, 2 should be evicted as least recently used
    _ = lru.put(4, "four");

    try std.testing.expect(lru.get(1) != null);
    try std.testing.expect(lru.get(2) == null);
    try std.testing.expect(lru.get(3) != null);
    try std.testing.expect(lru.get(4) != null);
}

pub fn init(allocator: std.mem.Allocator, name: []const u8, memory: []const u8) FreetypeError!@This() {
    if (freetypeLibrary == null) {
        try ensureNoError(c.FT_Init_FreeType(&freetypeLibrary));
        // Enable LCD filtering for subpixel rendering to reduce color fringes.
        // FreeType must be built with FT_CONFIG_OPTION_SUBPIXEL_RENDERING enabled.
        try ensureNoError(c.FT_Library_SetLcdFilter(freetypeLibrary, c.FT_LCD_FILTER_DEFAULT));
    }
    const kbtsContext = c.kbts_CreateShapeContext(null, null);
    var face: c.FT_Face = undefined;
    try ensureNoError(c.FT_New_Memory_Face(
        freetypeLibrary,
        memory.ptr,
        @intCast(memory.len),
        0,
        &face,
    ));
    // font rendering only supports full unicode charmaps for now
    std.debug.assert(face.*.charmap.*.encoding & c.FT_ENCODING_UNICODE != 0);

    const kbtsFont = c.kbts_ShapePushFontFromMemory(
        kbtsContext,
        @ptrCast(@alignCast(@constCast(memory.ptr))),
        @intCast(memory.len),
        0,
    );

    var wyHash = std.hash.Wyhash.init(0);
    wyHash.update(name);

    return @This(){
        .allocator = allocator,
        .shapingCache = try ShapingCache.init(allocator),
        .handle = face,
        .kbtsContext = kbtsContext.?,
        .kbtsFont = kbtsFont,
        .key = wyHash.final(),
    };
}

pub fn deinit(self: *@This()) void {
    for (self.shapingCache.entries) |entry| {
        self.allocator.free(entry.key);
        self.allocator.free(entry.value);
    }
    self.shapingCache.deinit();
    c.kbts_DestroyShapeContext(self.kbtsContext);
    ensureNoError(c.FT_Done_Face(self.handle)) catch @panic("Failed to done FT_Face");
}

pub const RasterizedGlyph = struct {
    bitmap: ?[]u8,
    left: c_int,
    top: c_int,
    width: c_uint,
    height: c_uint,
    pitch: c_int,
};

pub const ShapedGlyph = struct {
    index: c_ushort,
    utf8: c.kbts_encode_utf8,
    advance: Vec2,
    offset: Vec2,
};

pub const ShapingIterator = struct {
    run: ?c.kbts_run,
    glyph: [*c]c.kbts_glyph,
    kbtsContext: *c.kbts_shape_context,

    pub fn next(self: *@This()) ?ShapedGlyph {
        if (self.run) |*run| {
            if (c.kbts_GlyphIteratorNext(&run.Glyphs, @ptrCast(&self.glyph)) != 0) {
                var shapeCodepoint: c.kbts_shape_codepoint = undefined;
                if (c.kbts_ShapeGetShapeCodepoint(self.kbtsContext, self.glyph.*.UserIdOrCodepointIndex, &shapeCodepoint) == 0) {
                    std.log.err("Could not get original codeopint for glyph with user id {}", .{self.glyph.*.UserIdOrCodepointIndex});
                    return self.next();
                }

                const utf8 = c.kbts_EncodeUtf8(shapeCodepoint.Codepoint);
                return ShapedGlyph{
                    .index = self.glyph.*.Id,
                    .advance = .{ @floatFromInt(self.glyph.*.AdvanceX), @floatFromInt(self.glyph.*.AdvanceY) },
                    .offset = .{ @floatFromInt(self.glyph.*.OffsetX), @floatFromInt(self.glyph.*.OffsetY) },
                    // When not using llvm, if we don't set this in a variable,
                    // the index in ShapedGlyph becomes 0 because of some Zig bug
                    .utf8 = utf8,
                };
            }
        }
        var run: c.kbts_run = undefined;
        if (c.kbts_ShapeRun(self.kbtsContext, &run) != 0) {
            self.run = run;
            return self.next();
        }

        return null;
    }
};

pub fn shape(self: *@This(), text: []const u8) ![]ShapedGlyph {
    if (self.shapingCache.get(text)) |cache| {
        return cache.value;
    }

    // TODO: pass the language and direction down as styles
    c.kbts_ShapeBegin(self.kbtsContext, c.KBTS_DIRECTION_RTL, c.KBTS_LANGUAGE_DONT_KNOW);
    c.kbts_ShapeUtf8(self.kbtsContext, text.ptr, @intCast(text.len), c.KBTS_USER_ID_GENERATION_MODE_CODEPOINT_INDEX);
    c.kbts_ShapeEnd(self.kbtsContext);

    var glyphs = try self.allocator.alloc(ShapedGlyph, text.len); // worst case for all glyphs
    errdefer self.allocator.free(glyphs);
    var glyphCount: usize = 0;

    var iterator = ShapingIterator{
        .run = null,
        .glyph = undefined,
        .kbtsContext = self.kbtsContext,
    };
    while (iterator.next()) |shapedGlyph| {
        glyphs[glyphCount] = shapedGlyph;
        glyphCount += 1;
    }

    glyphs = try self.allocator.realloc(glyphs, glyphCount);
    const putResult = self.shapingCache.put(try self.allocator.dupe(u8, text), glyphs);
    if (putResult.evicted) |evicted| {
        self.allocator.free(evicted.key);
        self.allocator.free(evicted.value);
    }
    return glyphs;
}

pub fn unitsPerEm(self: @This()) c_ushort {
    return self.handle.*.units_per_EM;
}

pub fn ascent(self: @This()) f32 {
    return @floatFromInt(self.handle.*.ascender);
}

pub fn descent(self: @This()) f32 {
    return @floatFromInt(self.handle.*.descender);
}

/// Teturns line height in points coordinates, that is multiples of unitsPerEm.
///
/// It can simply be multiplied by the font size divided by unitsPerEm to get the line height in pixels.
pub fn lineHeight(self: @This()) f32 {
    return self.ascent() - self.descent();
}

/// Weight can go from 100 to 900 like CSS, but it can be higher or lower. Note
/// that the weight is clipped by the maximum and minimum values
pub fn setWeight(self: @This(), weight: c.FT_UInt, allocator: std.mem.Allocator) !void {
    var mm: [*c]c.FT_MM_Var = undefined;
    ensureNoError(c.FT_Get_MM_Var(self.handle, &mm)) catch |err| {
        if (err == error.InvalidArgument) {
            std.log.warn("Font does not support multiple masters, cannot set weight. This is most likely not a variable font, doing nothing.", .{});
            return;
        }
        return err;
    };
    defer ensureNoError(c.FT_Done_MM_Var(freetypeLibrary, mm)) catch |err| {
        std.log.err("Could not free MM_Var: {}", .{err});
    };

    const coords = try allocator.alloc(c.FT_Fixed, @intCast(mm.*.num_axis));
    defer allocator.free(coords);
    try ensureNoError(c.FT_Get_Var_Design_Coordinates(self.handle, mm.*.num_axis, coords.ptr));

    for (0..mm.*.num_axis) |i| {
        const a = &mm.*.axis[i];
        const w: c_ulong = @intCast('w');
        const g: c_ulong = @intCast('g');
        const h: c_ulong = @intCast('h');
        const t: c_ulong = @intCast('t');
        const wght = (w << 24) | (g << 16) | (h << 8) | t;
        if (a.*.tag == wght) {
            coords[i] = @max(@min(weight * 65536, a.*.maximum), a.*.minimum);
            break;
        }
    }
    try ensureNoError(c.FT_Set_Var_Design_Coordinates(self.handle, mm.*.num_axis, coords.ptr));
}

pub fn rasterize(
    self: @This(),
    glyphIndex: c_uint,
    dpi: [2]u32,
    size: c_long,
) FreetypeError!RasterizedGlyph {
    try ensureNoError(c.FT_Set_Char_Size(
        self.handle,
        0,
        size * 64,
        @intCast(dpi[0]),
        @intCast(dpi[1]),
    ));

    std.log.debug("glyph index {d}", .{glyphIndex});
    try ensureNoError(c.FT_Load_Glyph(self.handle, glyphIndex, c.FT_LOAD_TARGET_LCD));
    const glyph = self.handle.*.glyph;
    std.debug.assert(glyph != null);
    // Use LCD rendering mode for subpixel anti-aliasing
    // This produces a bitmap with 3x horizontal resolution (one byte per R, G, B subpixel)
    try ensureNoError(c.FT_Render_Glyph(glyph, c.FT_RENDER_MODE_LCD));

    return RasterizedGlyph{
        .bitmap = if (glyph.*.bitmap.buffer != null)
            glyph.*.bitmap.buffer[0..@intCast(@abs(glyph.*.bitmap.pitch) * glyph.*.bitmap.rows)]
        else
            null,
        .width = glyph.*.bitmap.width,
        .height = glyph.*.bitmap.rows,
        .left = glyph.*.bitmap_left,
        .top = glyph.*.bitmap_top,
        .pitch = glyph.*.bitmap.pitch,
    };
}

pub fn getGlyphIndex(self: @This(), charcode: c_ulong) c_uint {
    return c.FT_Get_Char_Index(self.handle, charcode);
}
