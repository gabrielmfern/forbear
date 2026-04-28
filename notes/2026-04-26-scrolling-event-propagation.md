I've already set my mind on useScrolling on how it listen to the events, but now we have the problem of when an ancestor of a node also has useScrolling which means both of them scroll at once. 

My initial shallow thought on how to fix this was adding support for context/providers just like what React has.

I think we can still have a context to fix this, but we have to change how we do events as a default. The big problem is that the events handling as-is, is going to happen top-to-bottom, just like the UI is defined, instead of bottom-to-top, making it impossible to stop propagation, as the one higher up in the tree will have handled it first than the one deeper in the tree.

We can just handle events after, the entire UI is defined. This means the useScrolling needs to receive a scrollOffset state pointer to set, instead of just returning it, which is quite fine.  Then the provider can just have a flag to know whether or not the scroll of this frame has been handled or not, and the following useScrolling calls can just not handle it anymore.


