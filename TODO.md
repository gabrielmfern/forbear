- [x] text selection
    - Not doing it for now since it's not central to build the app I want yet
- [ ] find a way to avoid having to use `try` everwhere
- [ ] implement 10 examples of UI that I find inspiring
    - [ ] uhoh.com
    - [ ] https://wayland-book.com
- [ ] implement scrolling 
- [ ] I need a way to define the percentage width that an element would take 
  of its parent
- [ ] a way to define children for components
    - most likely using a "slotting" solution where
      `forbear.componentChildrenSlot()` would mark the parent/path to slot
      component children into parent

## uhoh.com

- [x] fix where image should be transparent being white
    - Decided to not do it, it's caused by uhoh.com using blendMode: multiply
      which we don't do at all
- [x] fix image anti aliasing to look more like the browser
- [x] what do I need to have variant fonts?
- [x] text wrapping
- [x] fix button hovering issue in the button (uhoh.com has this too)
- [x] text wrapping only breaking at the beginning of characters 
- [x] wrapped text should also conform to parent alignment
- [x] fix parts of shadow that draw nothing going over parent borders

missing things for the entire uhoh.com website:
- [x] forbear.text requires comptime fmt, so users can't plug in dynamic text
- [x] vulkan error with multi sampling being disabled for text
- [x] page scrolling
- [x] fps has been destroyed, lower than 165 for a non changing layout
    - we could start caching the layouts from the nodes
- [x] maxWidth/maxHeight to limit a growing element's size
- [x] allow to center align just a single element, without affecting others
- [x] startup is slow
- [x] can't make an element fully transparent?
- [ ] blend multiply
- [ ] images are quite awkaward, specifically when it comes to sizing
    - lazily decompressing images causes huge frame drops for large images
    - we should probably have `forbear.image` instead of always using backgroundImage, and have its size calculated from the aspect ratio while filling up the parent
- [ ] support for filter: grayscale()
- [ ] after something like one frame the size of things seem to change
- [ ] new `registerFont`/`registerImage` functions are now heavily repeated and there's really no type-safety in `useFont`/`useImage` 
    - is having lots of them bad? I understand having no type-safety though
- [ ] svg support
    - Some library for SVG rendering that we can then plop into a texture atlas?
- [ ] gradients
- [ ] linear gradient support
- [ ] component children slotting
- [ ] support for underlined text

problems:
- sea of parenthesis
    - having to try before actually calling the children block eating function lol
- too many try statements makes things much uglier and harder to read
- components usage is confusing
- could not figure out what `useNextEvent` was for, and just ignored it leaving it in place
- created a utilty for px so that it didn't have to calculate the proper value
    - should we maybe have px as the default value? I've noticed that the DPI isn't as reliable as I thought, as it can be used for scaling for example
- you can't recognize an image by quickly scanning the code, because it only allows for a background image
- names for style properties are too long and cumbersome to write and read
    - paddingBlock, paddingInline, marginBlock, marginInline, horizontalAlignment, verticalAlignment, etc
    - we could define a single property for most of them, just like in CSS, and to fill the need for shorthands define functions that allow for common usecases
        - e.g., `.inline(10)`, `.block(10)`, `.all(10)`, etc.

