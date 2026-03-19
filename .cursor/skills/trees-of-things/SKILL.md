---
name: trees-of-things
description: Models ownership and containment with a flat pool of stable-ID thing records plus parent/child/sibling links. Use when implementing inventories, equipment, scene graphs, reparenting, or move-without-copy behavior via detach+append link rewiring.
---

# Trees of Things

## Use This Skill When

- Representing ownership, containment, equipment, inventory, or scene-graph structure as links instead of duplicated payload
- Nodes need stable handles/IDs even when they move between parents
- Implementing reparenting events like "A steals B" or "item moves from container X to Y"
- Explaining why moving entities should be link rewiring, not object copying
- Reviewing code that currently copies subtree payload when only the relationship changed

## Core Model

Use one flat storage pool for all entities, then express structure with links:

- `id` is the stable slot index in the flat array (integer handle, not a pointer)
- each thing record stores normal payload fields (`kind`, position, stats, etc.)
- Parent/child/sibling links encode containment and ordering
- `null` means "no link"
- Any relationship can be absent independently: no parent, no children, no previous sibling, and no next sibling are all valid states
- The pool storage is allocated as one flat array up front; nodes are not individually heap-allocated

Ownership is represented by where a node is linked, not by duplicating payload.

## Reference Shape

Use a record layout in this family:

- `parent`
- `firstChild`
- `lastChild`
- `prevSibling`
- `nextSibling`
- `alive`
- payload fields like `kind`, `name`, `stats`, `transform`, etc.

Do not spread link mutation across unrelated systems. Keep structural links on the thing record itself and mutate them through a small set of helpers.

## Invariants

- A live node has at most one parent.
- Slot claims and moves keep identity stable: IDs do not change.
- Tree traversals skip dead IDs (`isAlive` guard).
- A detached node has `parent = null`, `prevSibling = null`, and `nextSibling = null`.
- `firstChild` and `lastChild` must agree with the sibling chain they bound.
- Sibling pointers stay reciprocal: if `a.nextSibling == b`, then `b.prevSibling == a`.
- Reparenting must detach from the old parent before appending to the new one.
- `appendChild(newParent, child)` must work for both first-time attach and move.
- A node cannot become a child of itself or any of its descendants.
- Dead or freed nodes must not remain linked into a live tree.

## Required Operations

Implement and reuse these operations:

1. `claim(kind)` -> reserve/reuse a free slot in the pool and return a stable ID (no per-node heap allocation).
   - Use naming like `claim`, `claimSlot`, or `createInPool` to avoid heap-allocation confusion.
2. `get(id)` -> mutate/read payload in place.
3. `isAlive(id)` -> guard traversal and debug dumps.
4. `detach(child)` -> remove `child` from its current parent/sibling chain and normalize its links.
5. `appendChild(parent, child)` -> detach child from old parent, then append under `parent`.
6. `children(parent)` iterator -> traverse direct children in order.
7. `release(id)` / `free(id)` -> mark a slot reusable only after it has been detached and cleared.

Treat `detach` + `appendChild` as the canonical structural mutation path. Do not duplicate link surgery logic in gameplay/UI/application code.

## Implementation Guidance

- Centralize all parent/child/sibling rewiring in a few helpers.
- Prefer one canonical path for moves instead of separate "attach" and "move" codepaths.
- Never copy payload just to change ownership.
- If slot reuse exists, clear structural links before reusing the slot.
- If you need ordering among children, append/prepend by link updates rather than rebuilding arrays of descendants.

## Example Scenario

- world contains wizard, troll, rat, moonbeam
- wizard owns backpack
- backpack owns sword
- sword owns ruby
- troll wears hat
- troll steals backpack (`appendChild(troll, backpack)`)
- rat steals ruby (`appendChild(rat, ruby)`)
- wizard reclaims backpack (`appendChild(wizard, backpack)`)

At each step, the same IDs are moved. Nothing is copied or recreated.

## Dump/Debug Pattern

When explaining behavior, print the tree after each event:

- `dumpTree(things, root, depth)` recursively prints `id` + `kind`
- use `children(id)` iterator for traversal
- show snapshots before and after each reparent operation

This makes identity-preserving moves obvious.

## Pitfalls And Tests

When implementing or reviewing this pattern, check these cases:

- moving a node that already has a parent
- moving the first, middle, and last child
- moving an entire subtree and confirming descendants stay attached
- calling `appendChild(parent, child)` when `child` is already under `parent`
- rejecting attempts to create cycles by parenting a node under its descendant
- freeing a node and ensuring dead IDs do not appear in traversal or dumps
- reclaiming a freed slot without inheriting stale links

## Output Expectations

When using this skill in responses or code:

1. Emphasize "link surgery in one flat pool."
2. Explicitly state that moved objects are not duplicated.
3. Show move operations as detach+append semantics.
4. Prefer small, direct examples over extra abstraction.
5. Name the invariants that keep the structure valid, not just the happy path.
6. When proposing code, keep link mutation in dedicated helpers instead of scattering pointer/index edits inline.
