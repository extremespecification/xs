# Briefs

The standing instructions of each role live in its skill, `skills/<role>/SKILL.md`. A brief adds only what belongs to one task. Copy one, replace each `<...>`, delete what does not apply. Mark each guess `[ASSUMPTION]`.

## Researcher

Answer these questions about <repo> at <path>:

1. <neutral factual question: "which modules write to table X?", never "where should we add Y?">
2. <...>

## Implementer

Implement <task id and its five words> in <repo>.

- Worktree: <path>, branch <branch>. <read-only symlinks, if any>.
- Read first: <the task>, <the spec and its Log>, <ADRs>, the Done sections of <preceding tasks>.
- Contract: <file>. Never edit it; report what it lacks.
- Done when: <the Done when of the task, and the `R<n>` it serves>. Quality bar: <"like the existing X">.
- Invariants that must hold: <`I<n>` and the name of each test>.
- Pointers (verify each): <file>: <what is there, what to change>.
- Run what you built: <the browser at 1440 and 390 wide, both themes | the built app | a real sample>. Save screenshots to <dir>.
- Commit style: <message style, signing, trailers>.
- Checks: <typecheck>, <unit tests>, <integration tests of what you touched>.
- Close: when the Done when holds, write the Done section in <the task file in `.xs/ledger/tasks/`> and run `xs close <task id>`; commit only the work, on the branch. Never change the task's state otherwise.
- Stop after: <the slice>.

## Reviewer

Review branch <branch> in <worktree> against <base>, for <task id and its five words> (<task path>).

## Fix (implementer)

Fix these findings on <branch> in <worktree>:

<findings, each with severity, file and line, reproduction>

## Breaker (reviewer, cheapest model)

Spawn the reviewer with the cheapest model passed on the spawn: it overrides the strongest model of the role's definition.


Break <feature> in <worktree>, running at <url or command>. Try <N> cases, including <cases from the domain>. Save reproductions in <dir>.
