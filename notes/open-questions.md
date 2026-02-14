- How should we handle multiple windows?
    - Defining windows with nodes?
- Should forbear have a context menu by default?
    - How would that be configured?
    - How can users replace it if they want?
    - How can users style it however they prefer?
    - Would it give for a bad experience considering it's not going to be the
      native styling for the OS? 
- How should event handling be done in a way that's not horrible DX?
    - Zig forces us to manually allocate the memory, which is not all that bad,
      but having to define a struct to then define the function is horrible
    - I feel like the only to improve this is building a second "language" that
      is transpiled to Zig, like what React does with JSX
- How can we get the size of an element before actually rendering it?
    - This is important for doing things like virtual scrolling
    - Also important for placing elements at the center, when doing so manually. Or at the edges, as well 
    - Or just generally laying out elements that depend on the size of other
      elements
- How can we do layout animations that animate the position of an element?
- How can I avoid the foot guns of not calling the returning parent stack popping function from `forbear.element`?
- Should maxWidth and maxHeight overwrite the preferredWidth/preferreHeight?
    - https://github.com/gabrielmfern/forbear/pull/25#discussion_r2804268067
- Should alignment be inherited?
