How others do it: 
**Tree of styled inline nodes**
- HTML/CSS: `display: inline` elements, which exist in contrast to `display: block` for elements like `<span>`, `<strong>`, `<u>`, etc.
- Flutter: `RichText` with a root `TextSpan` and child `TextSpan`s, each with its own `TextStyle`. The whole tree is shaped as one paragraph so wrapping works across style changes.
- React Native: nested `<Text>` components — inner `Text` inherits and overrides styles, parent owns wrapping.
- SwiftUI: `Text("a ").bold() + Text("b").foregroundColor(.red)` — concatenation builds one logical text block that wraps as a unit.

**Single string + attribute ranges**
- NSAttributedString / TextKit (Cocoa): one `NSString` plus attributes keyed by `NSRange`.
- egui: `LayoutJob` — a string plus a `Vec<LayoutSection>` mapping byte ranges to `TextFormat`.
- GPUI (Zed): `StyledText` with `HighlightStyle` applied over ranges of a single string.
- Qt: `QTextLayout` with `QTextFormatRange`.
- Skia ParagraphBuilder: builder where you `pushStyle`/`addText`/`popStyle`; produces style runs over one paragraph.
- Raddebugger: per-UI_Box list of strings + styles — same shape as attribute-range, structured as parallel arrays.

**Non-solution: Dear ImGui** — `TextColored`, `SameLine()`, `PushStyleColor`. No real wrapping across mixed-style runs; `TextWrapped` only handles a single style.

## inline nodes approach

HTML/CSS does this through `display: inline` elements, which exist in contrast to `display: block` for elements like `<span>`, `<strong>`, `<u>`, etc.

Currently our wrapping algorithm deals with glyphs, with different wrapping types, and with nodes on parents that have overflow wrap defined which is not sufficient to create components and reproduce the pattern for defining different text styles inside of a single piece of text. Like what can be done with `<span>`, or `<strong>`, and others.

To improve this we can actually merge all wrapping into just a single thing. We break up the entire tree into "segments", for nodes that have an `inline` style flag set to true, which we can use with the same algorithm as we do for wrapping glyhs by character, that is, place them sequentially and check if the current would overlfow the line, and then break.

For the above I basically already have most of the code and it's relatively simple, but it doesn't to be so simple to make this work in tandem with node placement in general, which is actually makes this so hard here. The big problem is that, if we want to reproduce behavior like what there is with `display: inline` in CSS/HTML we need this segmentation to be done going all the way down to the deepest nodes in a subtree, which means the placement of those atoms according to the wrapping needs to be done relative to a parent that can also be placed really based on the leafs, since all atoms can only be on the leafs.

It comes to mind now at te moment of writing this that we can, first, iterate throguh the entire tree breaking down what are the segments, perhaps in a list, and then we can iterate the entire tree again actually placing nodes, in which case we would already know the segments, and it would in theory be easier, though it is still not fully clear to me how to write the code for this.

I think it's hard to think through element placing from the standpoing

I've come to decide we should abandon this idea. Though it is an interesting DX for the specific usecase of defining nodes it introduces such weird behavior that makes this not look like it's worth it to me at all. The main thing for me is that we would need to just ignore certain styles of inline nodes, which is one of the things I heavily dislike about CSS and HTML.

## Text-specific styles

Raddebugger as an inspiration, defines a list of strings for any UI_Box which have styles specific to them, this way the same-wrapped piece of text can have styles.

### `text()` as a scope that collects styled runs

```zig
forbear.text(.{})({
  forbear.write("Wayland is a ");
  Strong({ 
    forbear.write("display server protocol"); 
  });
  forbear.write(", successor to ");
  Em({ 
    forbear.write("X.Org"); 
  });
});

pub fn Strong() *const fn(void) void {
  return forbear.textStyle(.{ .fontWeight = 700 });
}
pub fn Em() *const fn(void) void {
  return forbear.textStyle(.{ .fontStyle = .italic });
}
```

Pros:
- DX is very much like HTML
- `Strong`/`Em` stay as real reusable components, same shape as the rest of the codebase.
- Composes with control flow naturally — you can `if`/`for`/`switch` inside the `text()` block and each branch just writes more spans.
- Base style only spelled once; nested scopes layer overrides on top.

Cons:
- Can easily confuse users making them write an element down inside of text, which is invalid, or use the "style helpers" as elements or components.
- Feels a little repetitive with the node tree, because we will need to track down the enabled styles from scopes like the ones in the example
- Requires implicit per-frame state (a "current text builder") that `write` and `textStyle` push into — same shape as the existing hook/component scope stack, but one more thing to maintain.
- Compile-time enforcement that `Strong` only works inside `text()` is hard to express in Zig; the violation likely shows up as a runtime panic or just wrong output.
- Style inheritance through scope makes it less obvious at the call site which styles apply to a given `write`.

### declarative spans (egui/Flutter shape)

```zig
forbear.richText(.{ .spans = &.{
  .{ .text = "Wayland is a " },
  .{ .text = "display server protocol", .style = .{ .fontWeight = 700 } },
  .{ .text = ", successor to " },
  .{ .text = "X.Org", .style = .{ .fontStyle = .italic } },
}});
```

Pros:
- No implicit scope state — the spans are just data, easy to pass around, build dynamically, or come from i18n.
- Trivial to implement: one array, one shape pass, no stack to maintain.
- Impossible to misuse: you can't write a normal element inside a span list.

Cons:
- Loses the nestable `Strong()`/`Em()` component DX that HTML has.
- Verbose for long text — every span is a struct literal.
- Sharing a base style across spans means repeating the style block or constructing a base variable manually
- Does not have composaibility, so you can't use a component that defines itself styles that you'd reuse.
- Reusing styles is a different pattern that just doing components, which is the more elegant DX.
- Not as easy to mix with control-flow (if statements, for-loops, etc.)

### SwiftUI-style concatenation

```zig
forbear.text(.{})(
  forbear.run("Wayland is a ")
    .append(forbear.run("display server protocol").bold())
    .append(forbear.run(", successor to "))
    .append(forbear.run("X.Org").italic()),
);
```

Pros:
- Reads close to prose, no separate style block per span.
- No scope state — the chain is the data.

Cons:
- Awkward in Zig without method chaining ergonomics; every `.bold()` etc. needs an explicit method on a builder type.
- Hard to mix with control flow (loops, conditional spans) without breaking the chain.


