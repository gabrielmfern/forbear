- [ ] find a way to avoid having to use `try` everwhere
- [ ] implement 10 examples of UI that I find inspiring
    - [ ] uhoh.com
    - [ ] https://wayland-book.com
- [x] implement scrolling 
- [ ] text selection
- [x] I need a way to define the percentage width that an element would take 
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
- [x] blend multiply
- [x] images are quite awkaward, specifically when it comes to sizing
    - lazily decompressing images causes huge frame drops for large images
    - we should probably have `forbear.image` instead of always using backgroundImage, and have its size calculated from the aspect ratio while filling up the parent
- [x] support for filter: grayscale()
- [x] element wrapping
- [ ] new `registerFont`/`registerImage` functions are now heavily repeated and there's really no type-safety in `useFont`/`useImage` 
    - is having lots of them bad? I understand having no type-safety though
- [ ] svg support
    - Some library for SVG rendering that we can then plop into a texture atlas?
- [ ] linear gradient support
- [ ] component children slotting

problems:
- image loading causes stutters, we should decompress images async, across frames to avoid this
    - is stb_image enough for this?
- when there's scaling in linux, the scale only drops in after some frames
- could not figure out what `useNextEvent` was for, and just ignored it leaving it in place
- created a utilty for px so that it didn't have to calculate the proper value
    - should we maybe have px as the default value? I've noticed that the DPI isn't as reliable as I thought, as it can be used for scaling for example
- grow parent, one fit child and one grow child, the grow doesn't behave as expected
- we need manual keying for loops of children
