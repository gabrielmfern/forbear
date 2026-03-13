---
name: api-design
description: Philosophy for creating, maintaining or refactoring APIs. 
---

# API Design

## Philosophy

Use these principles as strong defaults:
1. Start from the ideal design, then work down into real-world constraints.
   Example: first define the clean API shape, then adapt for runtime limits,
   legacy systems, and deadlines.
2. Prefer small, composable parts over one large surface full of unknowns.
   Example: separate a parser, validator, and transport layer so each can be
   replaced independently.
3. Avoid multiple sources of truth. Example: if pagination state exists in a
   request object, do not duplicate it in global mutable state.
4. Do back-of-the-napkin performance math before finalizing an API. Performance
   is more important than developer experience when they conflict. Example:
   estimate QPS, payload size, and memory growth to catch bottlenecks early.
5. Leverage familiarity when possible. Example: reuse naming and patterns users
   already know from standard libraries or widely adopted frameworks.
6. APIs should be beautiful and intention-revealing. Careful thought should be
   visible at a glance. Keep interfaces concise with as few characters as
   practical, but prioritize readability over write-speed or clever shorthand.
   Example: prefer client.users.list({ limit: 20 }) over either verbose
   ceremony or cryptic abbreviations like c.u.l({ l: 20 }).

These principles can be bent when trade-offs clearly justify it, but avoid
breaking several at once and almost never all of them at the same time. When
you choose to break one, explain why, what is gained, what is lost, and how to
mitigate risk.

