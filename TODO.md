- [x] text selection
    - Not doing it for now since it's not central to build the app I want yet
- [ ] find a way to avoid having to use `try` everwhere
- [ ] implement 10 examples of UI that I find inspiring
    - [ ] uhoh.com
    - [ ] https://x.com/60fpsdesign/status/2008787492561097035?s=20
    - [ ] https://ui.sh/
- [ ] implement scrolling 
- [ ] I need a way to define the width that an element should take up on the
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
- [ ] wrapped text should also conform to parent alignment
- [ ] fix parts of shadow that draw nothing going over parent borders

