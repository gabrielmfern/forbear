Currently our wrapping algorithm deals with glyphs, with different wrapping types, and with nodes on parents that have overflow wrap defined which is not sufficient to create components and reproduce the pattern for defining different text styles inside of a single piece of text. Like what can be done with `<span>`, or `<strong>`, and others.

To improve this we can actually merge all wrapping into just a single thing. We break up the entire tree into "segments", for nodes that have an `inline` style flag set to true, which we can use with the same algorithm as we do for wrapping glyhs by character, that is, place them sequentially and check if the current would overlfow the line, and then break.

For the above I basically already have most of the code and it's relatively simple, but it doesn't to be so simple to make this work in tandem with node placement in general, which is actually makes this so hard here. The big problem is that, if we want to reproduce behavior like what there is with `display: inline` in CSS/HTML we need this segmentation to be done going all the way down to the deepest nodes in a subtree, which means the placement of those atoms according to the wrapping needs to be done relative to a parent that can also be placed really based on the leafs, since all atoms can only be on the leafs.

It comes to mind now at te moment of writing this that we can, first, iterate throguh the entire tree breaking down what are the segments, perhaps in a list, and then we can iterate the entire tree again actually placing nodes, in which case we would already know the segments, and it would in theory be easier, though it is still not fully clear to me how to write the code for this.

I think it's hard to think through element placing from the standpoing


