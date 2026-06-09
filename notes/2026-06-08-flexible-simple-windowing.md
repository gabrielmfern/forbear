it's hard to imagine the ideal world in this to then work backwards, I think it's actually easier to think of the ideals principles to help me think of the ideal-world API

want:
- The user should be able to change it completely if they want to

don't want:
- artificial abstraction that makes it harder to understand the operating system interals

some facts:
- we need some standardized interface that can be called from forbear itself to get event information
- the handle to the native window is needed to create the vulkan swapchain

## ideas

### 1. a struct for each window's operating system

it could be a different struct for each operating system, and I just let the user pick the one and then pass down the handle instead of the struct itself which would also let the user just not use the builtin struct and do it from scratch if they wanted to. 

this does not pave the way for us to have windows as nodes unfortunately, but also, windows as nodes don't seems to just push against the idea of the user writing their own windowing code, or doing anything they want with the native window


