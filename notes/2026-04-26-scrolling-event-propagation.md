I've already set my mind on useScrolling on how it listen to the events, but now we have the problem of when an ancestor of a node also has useScrolling which means both of them scroll at once. 

My initial shallow thought on how to fix this was adding support for context/providers just like what React has.

I think we can still have a context to fix this, but we have to change how we do events as a default. The big problem is that the events handling as-is, is going to happen top-to-bottom, just like the UI is defined, instead of bottom-to-top, making it impossible to stop propagation, as the one higher up in the tree will have handled it first than the one deeper in the tree.

We can just handle events after, the entire UI is defined. This means the useScrolling needs to receive a scrollOffset state pointer to set, instead of just returning it, which is quite fine.  Then the provider can just have a flag to know whether or not the scroll of this frame has been handled or not, and the following useScrolling calls can just not handle it anymore.

No, this misses component slots. Beacuse, even if I call the children slotting before the event handling on a component, the children slotting event handling will still happen AFTER the one that happens on the parent component, which means the children will still be affected by the parent component's scroll handling.

Since we need some way to run code after the slotted children are done, we need the user to define some sort of closure to be called after, which I don't think there is a way to get done with a good DX. the end function of the component is there already, so maybe we could use it somehow so that the user can define things there, but then state and other stuff wouldn't be reachable form there

Alright one more idea. I think we can revert the code that does events after elements are created here, because we can previously know what are the elements from the context, and understand what are the elements and their depths before to then check at those specific points and know whether or not we should apply scrolling based on the context's decision that would be done in a single place imperatively instead of declaratively.

