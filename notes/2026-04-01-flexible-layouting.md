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

The grid-fitting and percentage sizing in particular would be solved by getting access to the previous frame. I don't know how this could feel in the end since it is using values for last frame there will be one frame with layout shift so I think experimenting first is the way to go here.

Tried it, and it does not feel good. It's really easy to just get into bugs with values infinitely increasing just because of padding or a margin. A measure step would feel so much better, but I don't know if it's posibble without having to write duplicated code.

Stepping back I think maybe I should focus in a single thing instead. Let's think about the pressing thing I want to do right now: the grid-like layouting. I need for the user to be able to access the value 

I need to know the size of the parent to determine the size of the children. Can't that be done at the end of the element then? No, because the parent might be growing too, meaning that it can't grow its children

The parent might also shrink too, so that means even if it's fit, the children can't grow at the moment that the layout is defined.

This narrows down our options quite a lot I feel. Even if I were to have the measure function it wouldn't know the final size, and we could never because its own parent wouldn't have the final size. It could be useful to measure text size anyway for exmaple, but that's already not much trouble since the font has shaping in it.

What if frames always run twice? Meaning they run once for fitting, and another time for you to do what right now is the top-to-bottom layouting step. This kind of already happens with the current layouting because it has to traverse the entire node tree from top-to-bottom. It's not the exact same thing, but this would mean the user has complete control over what I would say is trickiest about layouting because things have been measured already


I think running twice is the next thing I'm going to try in uhoh.com and see how it goes, here's how I see this happening:

```zig
fn App() {
  forbear.component("App")({
    forbear.element(.{
      .width = .fit,
    })({
      // uses the size and position of the previous node modified 
      // it being called during measurement marks this node to be measured actually
      const measurement = forbear.useMeasurement();
      forbear.element(.{
        .width = if (measurement.done) .{ .fixed = measurement.size[0] / 2.0 - 10.0 } else .fit,
        .padding = .inLine(5.0),
      })({});
      forbear.text("something else here");
    });
  });
}
```

```zig
forbear.frame(...)({
  forbear.measure()({
    App();
    forbear.layout();
  });

  // here forbear.useMeasurement() would return the values from the previous measure step, and then we can run the layout with those values
  // this also might allow for grow in userspace 🤔, and then maybe we can kill the layout function 🤞
  App();
  forbear.layout()
});
```

