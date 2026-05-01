# Contributing to forbear

Thanks for considering a contribution. forbear is early, opinionated, and changing fast — so PRs are welcome but please open an issue first for anything non-trivial.

## Read this before submitting code

forbear is source-available with commercial terms (see [LICENSE](./LICENSE)). For the project to remain workable as it evolves — including calibrating commercial terms, negotiating with companies, and potentially relicensing in the future — I need broad rights over contributed code. By submitting a pull request, patch, or any other code contribution to this repository, you agree to the following:

> You grant Gabriel Miranda ("the copyright holder") and successors a perpetual, worldwide, irrevocable, royalty-free, sublicensable license to use, copy, modify, prepare derivative works of, publicly display, publicly perform, distribute, and relicense your contribution as part of forbear, under the current forbear License or any future license terms (including more permissive open-source licenses, more restrictive commercial licenses, or both in parallel).
>
> You confirm that the contribution is your original work, or that you have permission from its rights holder to submit it under these terms. You include a patent grant covering any patents you control that are necessarily infringed by your contribution, on the same scope as the copyright grant above.
>
> You waive any claim to royalties, fees, or other compensation arising from the inclusion of your contribution in forbear or in any product distributed by the copyright holder.

This is an inline "mini-CLA." A formal Contributor License Agreement will be put in place at some point, and contributors at that time will be asked to re-affirm. If these terms are unacceptable to you, please don't submit code — but issues, bug reports, design discussions, and feedback are welcome regardless, and don't fall under this agreement.

## Sign your commits (DCO)

Every commit should include a Developer Certificate of Origin sign-off line. Use `-s` when committing:

```
git commit -s -m "your message"
```

This adds `Signed-off-by: Your Name <your-email>` to the commit, which serves as your attestation that you have the right to submit the work under the project license.

The DCO sign-off complements (does not replace) the contribution agreement above.

## Pull request process

1. **Open an issue first** for non-trivial changes — design changes, new public APIs, anything touching the rendering or layout systems. Cheap conversations beat expensive rewrites.
2. **Match the existing code style.** See [AGENTS.md](./AGENTS.md) for codebase conventions.
3. **Add tests** for new behavior. See `src/tests.zig` and the `test_runner.zig` for the testing setup.
4. **Run the checks** before submitting:
   ```
   zig build check
   zig build test
   ```
5. **Keep PRs focused.** One change per PR. Refactors and behavior changes in separate PRs.

## What's good to contribute right now

The [TODO.md](./TODO.md) and [open questions](./notes/open-questions.md) are the best starting points. Smaller, well-scoped wins are easier to merge than sweeping changes — forbear's API surface is still being shaped, and I want to be careful about additions.

If you're considering something substantial, please reach out before sinking time into it: **gabriel.readme@hey.com**.

## What this project is not yet ready for

- Cosmetic refactors with no behavior change.
- Adding dependencies. The dependency list is intentionally small.
- Big API renames or restructurings. The API will change, but on my own timeline.

## Questions

Open an issue, or email **gabriel.readme@hey.com**.
