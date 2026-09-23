// is it possible that we do not keep nodes stored in memory at all and instead just render everything?
// I think the only thing we need to keep track of is the current stack, but then layouting has to happen on nodes afterwards

// we need the element function so that users can define the elements
// we need to do text shaping
// we need the Pool that's reset each frame

// there's no "renderer" we should just render based on vulkan structures, and just let the user do whatever!

init :: () {
}

Graphics :: struct {
};

// we don't need a render thread, we just need an easy way to just re-render
// when resizing rendering requires us to define the UI once again, so that
// should be easy to reach. probably will require us to have the user define a
// "render" function that does it

init :: (graphics: *Graphics) {
}

