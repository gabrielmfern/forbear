## Component children slotting

Components can now accept children from their caller and slot them into a specific position within the component's own node tree, with no wrapper nodes.

### API

**Caller side** — same `fn(...)({ children })` pattern as elements:

```zig
Button()({
    text("Child 1");
    text("Child 2");
});
```

**Component side** — declare a slot and return the slot-end function:

```zig
fn Button() *const fn(void) void {
    component("Button")({
        element(.{})({
            text("Before");
            componentChildrenSlot();
            text("After");
        });
    });
    return componentChildrenSlotEnd();
}
```

Result tree: `element > [Before, Child1, Child2, After]`

### How it works

The core challenge is that the component body runs synchronously to completion before the caller's children block executes. The after-slot nodes ("After") are already in the tree by the time the caller's block runs.

The approach avoids any post-hoc splicing. Instead:

1. `componentChildrenSlot()` saves a snapshot of the parent stack and records the slot predecessor (the parent's last child at the moment of the call).

2. The component body continues, adding after-slot content normally.

3. `componentChildrenSlotEnd()` **detaches** the after-slot sibling chain from the parent and restores the parent stack to the slot-time snapshot. It returns an end function.

4. The caller's block runs. Since the parent stack is restored and the after-slot chain is detached, `putNode` naturally appends new children at the correct position — right after the slot predecessor.

5. The end function **reattaches** the after-slot chain and restores the parent stack to its pre-slotEnd state.

This means `element`, `text`, and `component` need no modifications — they always append to `parent.lastChild`, which is correct because the after-slot nodes were temporarily removed.

### Nesting

The slot states are stored as a stack (`componentChildrenSlotStates` in `FrameMeta`), so nested slotted components resolve independently and correctly.
