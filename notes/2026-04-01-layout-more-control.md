Purpose: users can choose how width, height are calculated

Ideally I want to use nodes as values and then I can layout it the same as the root. But that would not be enough to understand growth. 

Considering I kind of want to easure an entire layout, but I don't want to write it twice, I could have a new primtiive like:

```zig
forbear.measureable()({
  // we would not be able to run this twice which is the whole idea of this
  forbear.element(.{
    .width = .fit,
  })({
    // what value would this take the first run
    // at first run this could be the 
    const width = forbear.useParentWidth();
    forbear.element(.{
      .width = .{ .fixed = width / 2 - 10 },
    })({});
    forbear.text("something else here");
  });
});
```

