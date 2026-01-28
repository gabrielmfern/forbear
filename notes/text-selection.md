Selection Primitives

- Select text content within elements
- Select replaced elements (images, video, canvas) as atomic units
- Select empty elements that have layout/dimensions
- Support selection across multiple elements and nodes

Selection API

- Define selections using start and end positions (equivalent to Range objects)
- Each selection has: start container, start offset, end container, end offset
- Support querying current selection state
- Support programmatic selection creation and modification

Visual Rendering

- Render selection highlight over selected text
- Render selection highlight over replaced elements as single boxes
- Render selection regions across element boundaries
- Highlight selection even for empty elements with layout properties

User Interactions

- Click: Set cursor position
- Click and drag: Create selection from start to end point
- Double-click: Select entire word
- Triple-click: Select entire line/block
- Shift+arrow keys: Expand/contract selection across boundaries
- Shift+click: Extend selection from current cursor to clicked position
- Shift+End/Home: Extend selection to line boundaries
- Ctrl/Cmd+A: Select all content

Selection Boundaries

- Selections can span from before an element's opening to after its closing
- Empty <span> or <div> with display properties create selection boundaries
- Selections respect contenteditable region boundaries
- Block elements create selection regions based on their layout box

Edge Cases

- Preserve selection state during content updates
- Handle selections in nested elements
- Support selection of whitespace
- Handle zero-width elements gracefully

kb_text_shape Integration

Glyph-to-Character Mapping:
- Each `kbts_glyph` has `UserIdOrCodepointIndex` field
- When using context API (kbts_ShapeUtf8), this is a codepoint index
- Call `kbts_ShapeGetShapeCodepoint(Context, Glyph.UserIdOrCodepointIndex, &ShapeCodepoint)` to get:
  - `Codepoint` - Unicode codepoint value
  - `UserId` - depends on generation mode passed to kbts_ShapeUtf8

User ID Generation Modes (passed to kbts_ShapeUtf8):
- `KBTS_USER_ID_GENERATION_MODE_CODEPOINT_INDEX` - UserId increments by 1 per codepoint (0, 1, 2...)
- `KBTS_USER_ID_GENERATION_MODE_SOURCE_INDEX` - UserId is byte offset in source UTF-8 string

Ligature Handling:
- `LigatureComponentCount` - how many codepoints were merged (e.g., 2 for "fi" ligature)
- Ligature covers codepoints: [UserIdOrCodepointIndex, UserIdOrCodepointIndex + LigatureComponentCount - 1]
- To get byte offsets for each codepoint in ligature:
  1. Use SOURCE_INDEX generation mode
  2. Call kbts_ShapeGetShapeCodepoint for each index in the range
  3. Each ShapeCodepoint.UserId gives that codepoint's byte offset

Cursor Positioning Within Ligatures:
- kb_text_shape does NOT expose OpenType ligature caret table (GDEF LigatureCaretList)
- Fallback: divide advance width equally by component count
  - component_width = glyph.AdvanceX / glyph.LigatureComponentCount
  - caret position for component i = glyph_x + (i * component_width)

Hit Testing (click to cursor position):
- For each glyph, calculate its x-range: [glyph_x, glyph_x + AdvanceX]
- For ligatures, subdivide into LigatureComponentCount regions
- Map click x-coordinate to the appropriate codepoint index
- Use ShapeCodepoint.UserId to get byte offset if needed

