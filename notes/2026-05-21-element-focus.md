## 1.

Going again from the standpoint that we should be making these things using
only the primitives that we already provide the users with from
src/builtin.zig, we should do the same here. So I propsoe the following API:

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

  pub fn register(self: *@This()) void {
    // get parent node's key and append it 
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

To make the allocation of the focusable array list and access to this arena
there, we can introduce a new primtive. `useScopeArena()`. It would give the
user the arena used for creating state, and/or context, and in this way would
also free all of the user's data once the scope is gone for a frame.

One problem that arises with this is the fact that, for focused nodes, we will
need to handle keyboard events. ANd currently, there's no way to "consume"
events like you can in the browser by "stopping propagation" which is just not
a concept that we can have where event handling is directly intertwined inside
of rendering code, and it's all in the order that UI is defined in.

## 2.

Each focusable registers a **predicate** instead of a flag — "do you consume
this specific key combo?". Hotkeys yield only when the focused widget's
predicate returns true for the hotkey's combo.

```zig
const ConsumesFn = fn (comptime event: Event, result: forbear.OnResult(event)) bool;

const Focus = struct {
  key: u64,
  consumes: *const ConsumesFn,
};

const FocusContext = forbear.createContext(opaque{}, struct {
  focused: ?Focus,
  focusable: std.ArrayList(Focus),
  arena: std.mem.Allocator,

  const Focusable = struct {
    key: u64,
    consumes: ?ConsumesFn,
  };

  pub fn register(self: *@This(), consumes: ConsumesFn) void {
    // ...
  }

  pub fn consumes(self: *const @This(), comptime eventTag: Event, result: forbear.OnResult(eventTag)) bool {
    // check if the current focused node consumes
  }

  // ...same functions as 1.
});
```

Component side — every focusable describes its own appetite for keys:

```zig
// something like a new seInput
focus.register(node.key, .{ 
  .consumes = (struct {
    fn consumes(comptime event: forbear.Event, result: forbear.OnResult(event)) bool {
      // check that the key is text
      // check if left, right, backspace, other input keys
    }
  }).consumes,
});
```

```zig
// on a button — focusable so tab indexing accounts for it
focus.register(node.key, .{ 
  .consumes = (struct {
    fn consumes(comptime event: forbear.Event, result: forbear.OnResult(event)) bool {
      // check for space, enter
    }
  }).consumes,
});
```

Hotkey handling code — one state query:

```zig
const focus = forbear.useContext(FocusContext);
if (forbear.on(.keyDown)) |keys| {
  if (!focus.consumes(.keyDown, keys)) {
    // ...
  }
}
```

