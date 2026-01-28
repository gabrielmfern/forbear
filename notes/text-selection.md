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

