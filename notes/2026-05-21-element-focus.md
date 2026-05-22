Going again from the standpoint that we should be making these things using only the primitives that we already provide the users with from src/builtin.zig, we should do the same here. So I propsoe the following API:

```zig
// meant to be unique, only one
const FocusContext = forbear.createContext(opaque{}, struct {
  focused: ?u64,
  // currently there is no way to free this. if we provide the user with the
  // context's arena, this could work
  focusable: std.ArrayList(u64),

  arena: std.mem.Allocator,

  fn init() @This() {
    const arena = forbear.useScopeArena();
    return @This(){
      .focused = null,
      .focusable = .empty,
      .arena = arena,
    };
  }

  pub fn register(self: *@This(), key: u64) void {
    self.focusable.append(self.arena, key) catch |err| {
      forbear.handleFrameError(err);
    };
  }

  pub fn focus(self: *@This()) void {
    if (forbear.getParentNode(self)) |node| {
      self.focused = node.key;
    }
  }

  pub fn hasFocus(self: *const @This()) bool {
    if (forbear.getParentNode(self)) |node| {
      return self.focused == node.key;
    }
    return false;
  }

  /// Needs to run after all its nodes are already defined
  pub fn handleEvents(self: *@This()) void {
    // handles key events that move focus around through tab keying,
    // and also handles focus traps
  }
});
```

To make the allocation of the focusable array list and access to this arena there, we can introduce a new primtive. `useScopeArena()`. It would give the user the arena used for creating state, and/or context, and in this way would also free all of the user's data once the scope is gone for a frame.

