# Working rules

Rules for anyone working in this repo, human or agent. The repo follows Extreme Specification (XS). What <project> is lives in `README.md`, the architecture in `ARCHITECTURE.md`, the words we use in `CONTEXT.md`, the look in `DESIGN.md`; create each when first needed. This file holds rules only: knowledge goes in those files or in an ADR.

## Stack

<language, runtime, package manager>. `make` lists the commands of a working day. `make check-change` proves a change on its own branch (lint, types, the tests of what it touches); `make check` is the gate a round of changes passes before `main` (every test, every invariant); `make check-release` is what `main` passes before a release (end to end).

## Gate

A change lands when `make check` is green on the integrator's round, rebased on `main`, and an independent review leaves no must-fix open. Deliver with `land --queue` and go on; the integrator rebases, runs the gate and moves `main`. Irreversible actions always require a person: a migration or deletion of live data, a release or publication, a rewrite of history, a change to a public contract, an expense.

## Rules

1. **Work with an unstated outcome, a wide footprint or a touched invariant starts from a spec** in `project/specs/`, written as its README says, numbered with `next-id S`. Edit the spec, never the tasks derived from it. The lead appends decisions and discoveries to its Log with `xs spec <id> noted|deviated "line"`.
2. **Never weaken or delete an invariant test.** Its name starts with `S<nn> I<n>` (or `s<nn>_i<n>` where names have no spaces). An invariant without a test is a p1 task.
3. **Side work and deferred work become tasks** in the ledger (`.xs/ledger/tasks/`), written as its README says, filed with `xs file`. Never a code comment or a line in a doc.
4. **Decisions are ADRs** in `project/adr/`, only for what constrains code. Search them before a structural change; changing one means a new ADR. Code relies on an ADR only once `xs status ADR-<NNNN>` says `built yes`.
5. **Done means landed**: on `main`, through the gate above, `make check` green, verified by running it. Every report says where the work is: branch, commits, landed or not. A task or ADR number always comes with five to ten words saying what it is, and a closed decision with its answer.
6. **One worktree per parallel agent**, under `.xs/worktrees/<branch>`. Never push, publish or touch `main` unless told.
7. **Commit only explicit paths**: `git commit -m "<msg>" -- <path>...`. Never `-a`, never `git add -A` or `git add .`, nothing left staged. Formatters run on the files you changed, never on the whole tree.
8. **Every fix has a test that fails without it.** UI changes are checked in a real browser at the target width before they are reported; say what you could not check.
9. **Reuse before you add**: design-system components and tokens, existing modules. A new component is a change to `DESIGN.md`.
10. **No compatibility before the first release**: formats change in place; no migrations, versions or fallbacks for old data.
11. **No real personal or customer data in the repo.** Fixtures and evals are invented, and data an agent generates is checked by another agent before it is committed.
12. **Commits**: author <name and email>; trailers <none | Co-Authored-By ...>; signing <on | off for agents>. Message: <style, e.g. a conventional prefix, a sentence saying the behaviour, the task id>.
13. **A task's state changes only through `xs`**: `file`, `start` (the coordinator only), `close` (when its Done section holds the proof), `block`, `drop`. State is the ledger's events: read it with `xs status`; never write a `status:` line or edit `EVENTS.log`.
14. **What you learn is classified before it is written.** Write directly only a preference of your person. Propose a rule, a design rule or knowledge with `xs propose`, with its anchor and evidence; the owner promotes it. A line marked `(L<nn>, stale: ...)` is unverified until its owner confirms it.

## Scopes

This repo reads, before its own rules, the rules of: <none | the organization's and the team's shared repos, by path or URL>. A narrower scope overrides a wider one only where the wider rule says so.

## Limits

Set by the owner from the project's earlier cycles; empty means none. `xs start` reads the WIP limit; the retrospective reads the thresholds.

- WIP limit: <none | the number of tasks doing at once>
- Spec approval: <owner | none> (`xs spec ready` asks for the owner's approval unless none)
- Merge train: <local | github | gitlab> (`land` queues in the local integrator, or in the forge's merge queue or train)
- Thresholds: <none | e.g. "lead time p90 under 24 h", "filed per closed under 1.2">

## Agents

The headless command of each agent the coordinator launches with `xs start <id> --branch <b> --run <name>`, in the task's worktree, the brief on its input. Model and tool are chosen here.

- Agent implementer: <the headless command of your agent tool, reading the brief on its input, with its model>

## Maintaining this file

- One rule, one line, one copy. State the observable trigger.
- Keep a rule that works. Remove a rule once a check enforces it.
- An audit never lengthens this file.

## Where a test goes

- **Unit**: pure logic of one file, next to it (`make unit`, seconds; no network, no processes).
- **Integration**: one module against real dependencies, in `test/integration/` (`make integration`).
- **End to end**: a whole flow, in `test/e2e/` (`make e2e`).
