- [x] find a way to avoid having to use `try` everwhere
- [x] implement scrolling 
- [x] I need a way to define the percentage width that an element would take 
  of its parent
- [ ] text selection
- [ ] svg support

## deal breakers

- [x] keying is not really stable for elements that can be removed or added back in
  - we need manual keying for loops of children
- [ ] error handling is very bad. current treatment makes all user code for UI run when there was an error, which is basically having to deal with two things at once in one place, which is very difficult. Ideally we should have someting similar to React with error boundaries, but that requires a lot of thought to adapt to Zig's API
- [ ] stutters drops when images load in
    - we should decompress images async, across frames to avoid this
        - is stb_image enough for this?
        - how can we show the image while it's being decompressed?
- [ ] MacOS's windowing is vibe coded and needs a proper rewrite

## example work

### [x] uhoh.com

- [x] fix image anti aliasing to look more like the browser
- [x] what do I need to have variant fonts?
- [x] text wrapping
- [x] fix button hovering issue in the button (uhoh.com has this too)
- [x] text wrapping only breaking at the beginning of characters 
- [x] wrapped text should also conform to parent alignment
- [x] fix parts of shadow that draw nothing going over parent borders
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
- [x] component children slotting
    - most likely using a "slotting" solution where
        `forbear.componentChildrenSlot()` would mark the parent/path to slot
        component children into parent
- [x] feature equivalent to display: grid in css
- [x] linear gradient support
- [x] images look really bad
- [x] support for manual line breaks (`\n`/`\r` in text)
- [x] blend mode darken
- [x] support for dashed borders

### [ ] wayland-book.com

- [x] support for placing elements manually, but relative to their parent still
- [x] per element clipping
- [x] per element scrolling
    - I want to have a Scrolling component the user can just plop into their code and it just works 🤔
    - Another option is a useScrolling
- [x] scroll bar 🤔
- [x] add back and forward buttons
- [x] being able to style the same text in different ways for separate parts
- [ ] add code blocks
- [ ] finishg bringing over all of the content into the app
- [ ] add svg rendering
    - back and forward buttons need it

### [ ] mini Slack app, that just shows a list of channels and messages, and allows you to send messages

## problems

- elements can be hovered where they have been clipped
- when there's scaling in linux, the scale only drops in after some frames
- new `registerFont`/`registerImage` functions are now heavily repeated and there's really no type-safety in `useFont`/`useImage` 
    - is having lots of them bad? I understand having no type-safety though
- useState with primitive values required dereferencing pointers all the time, which is commonly forgotten and therefore reduces development speeds
- 
