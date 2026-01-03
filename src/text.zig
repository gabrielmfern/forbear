const std = @import("std");

const c = @import("c.zig").c;

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

pub const Font = struct {
    handle: c.FT_Face,
    kbtsContext: *c.kbts_shape_context,
    kbtsFont: *c.kbts_font,

    pub fn init(memory: []const u8) FreetypeError!Font {
        if (freetypeLibrary == null) {
            try ensureNoError(c.FT_Init_FreeType(&freetypeLibrary));
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

        return @This(){
            .handle = face,
            .kbtsContext = kbtsContext.?,
            .kbtsFont = kbtsFont,
        };
    }

    pub fn deinit(self: @This()) void {
        c.kbts_DestroyShapeContext(self.kbtsContext);
        c.FT_Done_Face(self.handle);
    }

    const Glyph = struct {
        bitmap: ?[]u8,
        width: c_uint,
        height: c_uint,
        left: c_int,
        top: c_int,
        advanceX: c_long,
        advanceY: c_long,
    };

    pub const ShapedGlyph = struct {
        index: c_ushort,
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
                    return ShapedGlyph{
                        .index = self.glyph.*.Id,
                        .advance = .{ @floatFromInt(self.glyph.*.AdvanceX), @floatFromInt(self.glyph.*.AdvanceY) },
                        .offset = .{ @floatFromInt(self.glyph.*.OffsetX), @floatFromInt(self.glyph.*.OffsetY) },
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

    pub fn shape(self: @This(), text: []const u8) !ShapingIterator {
        // TODO: pass the language and direction down as styles
        c.kbts_ShapeBegin(self.kbtsContext, c.KBTS_DIRECTION_DONT_KNOW, c.KBTS_LANGUAGE_ENGLISH);
        c.kbts_ShapeUtf8(self.kbtsContext, text.ptr, @intCast(text.len), c.KBTS_USER_ID_GENERATION_MODE_CODEPOINT_INDEX);
        c.kbts_ShapeEnd(self.kbtsContext);

        return ShapingIterator{
            .run = null,
            .glyph = undefined,
            .kbtsContext = self.kbtsContext,
        };
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

    /// returns line height in points coordinates, that is multiples of units_per_em
    ///
    /// it can simply be multiplied by the font size divided by units_per_em to get the line height in pixels
    pub fn lineHeight(self: @This()) f32 {
        return self.ascent() - self.descent();
    }

    pub fn rasterize(
        self: @This(),
        glyphIndex: c_uint,
        horizontalResolution: c_uint,
        verticalResolution: c_uint,
        size: c_long,
    ) FreetypeError!Glyph {
        try ensureNoError(c.FT_Set_Char_Size(
            self.handle,
            0,
            size * 64,
            horizontalResolution,
            verticalResolution,
        ));

        try ensureNoError(c.FT_Load_Glyph(self.handle, glyphIndex, c.FT_LOAD_COMPUTE_METRICS | c.FT_LOAD_MONOCHROME));
        const glyph = self.handle.*.glyph;
        std.debug.assert(glyph != null);
        try ensureNoError(c.FT_Render_Glyph(glyph, c.FT_RENDER_MODE_NORMAL));

        return Glyph{
            .bitmap = if (glyph.*.bitmap.buffer == null)
                null
            else
                glyph.*.bitmap.buffer[0..@intCast(glyph.*.bitmap.width * glyph.*.bitmap.rows)],
            .width = glyph.*.bitmap.width,
            .height = glyph.*.bitmap.rows,
            .left = glyph.*.bitmap_left,
            .top = glyph.*.bitmap_top,
            .advanceX = glyph.*.advance.x,
            .advanceY = glyph.*.advance.y,
        };
    }

    pub fn getGlyphIndex(self: @This(), charcode: c_ulong) c_uint {
        return c.FT_Get_Char_Index(self.handle, charcode);
    }
};
