
I'm thinking about keying now. It's been in my to-do list to make it stable across if statements, and for-loops for some time now. I'm coming back to this mainly because of the way I'm reworking events for per-element scrolling in a way that satisfies me. 

My initial thoughts are:
- we can make it stable across if-statements if we use `@returnAddress` as keys instead of the index in the node tree
- as for loops, the only reliable way I can think of is for the user to define the key themselves. we can enforce this sort of thing with some build helper, like what React has with linting

When actually implementing this, one problem arises. Since the `component` helper is used from inside components, the @returnAddress that it has is tied to that. To solve this, we can make `component` an inline function, this is the only one that's going to be inline, all the other ones should be noinline. In turn, the actual function for the component the user defines, needs to be noinline, which is quite annoying. 

To avoid the user having to do noinline on their components, we can enforce that they always pass a key manually. They can then pass @src, which is going to be unqiue regardless of their function being inlined or not. This also means we don't need to use `inline` or `noinline` for `fn component()`.

Actually going back to this, the same problem remains for `component` because the src is as unqiue as the returnAddres when component is inline. We can differentiate between component instances with the component keys wrapping the instance, and the amount of node ancestors.

I'm dumb, @returnAddress won't be stable for the components because they're functions, and the compiler might decide to inline the user's function. Meaning that, it can be unstable breaking silently for the user unless they're always using noinline. Since we're going to force the user to do something either way (since @src has to be called from the user's side), I think we can go for doing @src as it's only required for components, not all elements.
