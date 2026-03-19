---
name: trees-of-things
description: Models tree state with a flat pool of Thing records plus parent/child/sibling links. Use when implementing ownership, containment, equipment, scene graphs, or "move without copy" behavior via detach+append link rewiring.
---

# Trees of Things

## Use This Skill When

- Working with trees
- Representing ownership/location as tree links instead of duplicated data
- Implementing events like "A steals B" or "item moves from container X to Y"
- Explaining why moving entities should be link rewiring, not object copying

## Core Model

Use one flat storage pool for all entities, then express structure with links:

- `ThingId` identifies a stable slot in `Things`
- `Thing` stores normal payload fields (`kind`, position, stats, etc.)
- Parent/child/sibling links encode containment and ordering
- `null` means "no link"
- Any relationship can be absent independently: no parent, no children, no previous sibling, and no next sibling are all valid states

Ownership is represented by where a node is linked, not by duplicating payload.

## Invariants

- A live node has at most one parent.
- Reparenting must detach from the old parent before appending to the new one.
- `appendChild(new_parent, child)` must work for both first-time attach and move.
- `alloc` and moves keep identity stable: IDs do not change.
- Tree traversals skip dead IDs (`isAlive` guard).

## Required Operations

Implement and reuse these operations:

1. `alloc(kind)` -> create one node in the pool and return stable ID.
2. `get(id)` -> mutate/read payload in place.
3. `appendChild(parent, child)` -> detach child from old parent, then append under `parent`.
4. `children(parent)` iterator -> traverse direct children in order.
5. `isAlive(id)` -> guard traversal and debug dumps.

Treat `appendChild` as the canonical move primitive.

## Contrived Scenario Template

Use this exact storyline when you need to demonstrate the design:

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

## Output Expectations

When using this skill in responses or code:

1. Emphasize "link surgery in one flat pool."
2. Explicitly state that moved objects are not duplicated.
3. Show move operations as detach+append semantics.
4. Prefer small, direct examples over extra abstraction.
