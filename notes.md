## TODO

- [x] draw things the screen
- [x] support for text nodes
- [x] implement macos-opengl backend
- [x] get at least a proof-of-concept working for forbear from JSX
- [x] layout nodes
- [ ] do double buffering in wayland
- [ ] fix error when screenshotting wayland program: ```could not send wayland message: 11```
- [ ] fix wayland window rendering as fast as possible without any vsync
    - we should be using wayland's `frame` to render
- [ ] handle wayland topbars protocol (this doesn't address gnome unfortunately)
- [ ] draw rounded corners
- [ ] draw in the z order
- [ ] draw background images 
    - I'm removing aspect ratio sizings and instead we should draw images by clipping them into the given node,
      keeping its aspect ratio
- [x] account for font weight on kbts as well 
- [ ] we're using the single kbts_context which uses the font in the top of the stack
- [ ] program just doesn't do anything if the atlas is full
- [ ] glyphs are sitting on fractional pixels on the texture atlas
- [ ] subpixel text rendering
- [ ] wayland is not handling window scale
- [ ] handling the weird edge case of window decorations for Gnome :/
- [ ] handle window scales changing at runtime
- [ ] macos window resizing freezes (and the same will happen for windows) the rendering
    - this will require some drastic changes that allows us to run the UI definition every time the resize event comes back in macos and windows  
- [ ] a macos program without a menu bar is a horrible experience (ex: cmd+q doesn't work)
    - how can we do this in a cross platform manner? perhaps a component that makes changes to the window to render the menu items?
- [ ] windows backend
- [ ] build a calculator through the jsx adapter 

## introspection 

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

I think having functions by themselves run on data makes it much easier to have the program be cross-platform and have support for multiple rendering APIs, but it still is not quite perfect. Two things are still missing on what I've already written:
1. the user being able to pick any backend with a different graphics API themselves
2. lots of duplicated code between the same graphics API being used on different operating systems

for simplicity's sake, I would be fine assuming we only use OpenGL for the time being then, in the long term, we can think of how to organize things towrads supporting multiple graphics APIs.

but basically the model is that we can have each graphics API for each platform, but there are platform specific details for each graphics API, so it's not just as simple as saying "this code for opengl" "this code for linux".

