- How should we handle multiple windows?
    - Defining windows with nodes?
- Should forbear have a context menu by default?
    - How would that be configured?
    - How can users replace it if they want?
    - How can users style it however they prefer?
    - Would it give for a bad experience considering it's not going to be the
      native styling for the OS? 
- How should event handling be done in a way that's not horrible DX?
    - Zig forces us to manually allocate the memory, which is not all that bad,
      but having to define a struct to then define the function is horrible
    - I feel like the only to improve this is building a second "language" that
      is transpiled to Zig, like what React does with JSX
 
