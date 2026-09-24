right now we have window creation from scratch using our own wayland communication and buffer creation, not libwayland, implemented. it works well enough to play with at least, such that I already have a checkboard pattern rendering and handling resizing as well, that is without double buffering so looking very ugly.

what I need to figure out:
- how nodes are going to be stored in RAM
- how are we going to be doing layouting
- how state is going to be stored ideally avoiding the heap
- how are we going to performantly output a "draw list" to then pass down over to any kind of backend (be it opengl, vulkan, directx, metal, or software rendering) and avoid getting tied to one thing 
    - code does not look to be much simpler with software rendering up until now. I am also not familiar with software rendering in general so this might actually be much harder in that scenario
    - the state machine in opengl trips me up in an insane amount which really makes me not feel very good about implementing it at first. I think it might be the best option for the first version of forbear though since it will include the compatibility for basically everything, including MacOS at the same time that it uses a much lower amount of RAM than Vulkan.
    - vulkan has tons of setup work, but the previous version used it and I'm msotly happy with what we had there

what's basically figured out already:
- the API to define nodes: `node`, `text`, `component` functions
- the API for transitions: `transition`
- text rendering with freetype and kb_text_shape with a texture atlas

direction of rewrite: how can I make things simpler?
