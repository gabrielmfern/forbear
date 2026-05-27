- How should we handle multiple windows?
    - We will define Windows with nodes

- How can we get the size of an element before actually rendering it?
    - This is important for doing things like virtual scrolling
    - Also important for placing elements at the center, when doing so
      manually. Or at the edges, as well 
    - Or just generally laying out elements that depend on the size of other
      elements
    - We have a new useNodeMeasurement, we could have a node invisible, or have
      it absolutely placed and just fit the content, or grow to get that size

- How can I avoid the foot guns of not calling the returning parent stack popping function from `forbear.element`?
    - Zig already helps with this because it forces you to deal with the return value

- Should maxWidth and maxHeight overwrite the preferredWidth/preferreHeight?
    - https://github.com/gabrielmfern/forbear/pull/25#discussion_r2804268067
- Should justification be inherited?

- How can we do layout animations that animate the layout-calcualted position of an element?

- How can we let users define new events in a component?
    - There's a way to emit events, but the component isn't really a node, it's just a functoin, so that complicates things
    - It would work with returning values for simple events (like clicked), but that wouldn't be the same DX as dealing with other events, and it doesn't work very well with component slotting

- How can we let the user have full access to the platform code so that they can extend it directly instead of having to rely on our abstractions?
