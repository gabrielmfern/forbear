- [x] text selection
    - Not doing it for now since it's not central to build the app I want yet
- [ ] find a way to avoid having to use `try` everwhere
- [ ] implement 10 examples of UI that I find inspiring
    - [ ] uhoh.com
    - [ ] https://x.com/60fpsdesign/status/2008787492561097035?s=20
    - [ ] https://ui.sh/
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
- [ ] page scrolling
- [ ] gradients
- [ ] blend multiply
- [ ] svg support
- [ ] linear gradient support
- [ ] maxWidth + preferredWidth grow support
- [ ] component children slotting
- [ ] support for underlined text

problems:
- vulkan error with multi sampling being disabled for text
- fps has been destroyed, lower than 165 for a non changing layout
    - we should start caching the layouts from the nodes
- can't make an element fully transparent?
- sea of parenthesis
    - having to try before actually calling the children block eating function
      lol
- had a hard time with `useFont`/`useImage` having the files contents in the
  arguments
- new `registerFont`/`registerImage` functions are now heavily repeated and
  there's really no type-safety in `useFont`/`useImage` 
- didn't really figure out that components can be used, and defined weird
  `render` functions all over the place
- could not figure out what `useNextEvent` was for, and just ignored it leaving
  it inplace
- created a utilty for px so that it didn't have to calculte the proper value
- forbear.text requires comptime fmt, so users can't plug in dynamic text
- not being able to center align just a single element, without affecting
  others


