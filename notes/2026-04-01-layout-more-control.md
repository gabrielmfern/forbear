Purpose: users can choose how width, height are calculated

Ideally I want to use nodes as values and then I can layout it the same as the root. But that would not be enough to understand growth. 

Considering I kind of want to easure an entire layout, but I don't want to write it twice, I could have a new primtiive like:

```zig
forbear.measure()({
  forbear.element(.{
    .width = .fit,
  })({
    // what value would this take the first run
    const width = forbear.useParentWidth();
    forbear.element(.{
      .width = .{ .fixed = width / 2 - 10 },
    })({});
    forbear.text("something else here");
  });
});
```

The idea of this would be that the code block there runs twice during the UI creation, and the second run is the final one which uses the values of the previous one to let you do whatever you want with the given sizes.

But, in reality the trick of passing a block doesn't really let you call it twice because it isn't code being passed down, it's just a trick to make sure the code runs after the first function, and before the second function so we can run code at the start and end of the thing, not necessarily control when the thing runs.o

This is also not really a solution for layout animations, but it would solve the problem around percetange sizing, or grid sizing, for example.

But, I think that for layout animations the solution is going to be based on having access to the previous frame's node size and position. That's it hoesntly, since it's the actual result of the layouting, and all of the rest about styling is just details either around rendering or how to resolve position and sizing. Then, also maybe letting the use rmanually add keys to elements, this way they can define two nodes in separate places but have them with the same key.

Almost certianly that's going to be an API then.

Let's actually go back to first principles. What am I trying to achieve that's not already possible?

- Layout animations: 
    - animating layout-calculated values
    - animating the deletion of elements in a list
    - animating the creation of an element in a list
    - animating the reordering of an element from one place in the tree to the other
- Percentage sizing: allowing for more flexible control of children sizes that the current sizing .percentage doesn't give
- Grid-like layouting: sharing the sizes of a parent among the children

It doesn't seem like there's a single solution to all of these problems. Right now I'm only particularly thinking about the Grid-like layouts, I don't want to move the children's size controls over to the parent, I want to keep it in the children.
