# Tasks

One markdown file per work item: something to build, fix or decide. Work found on the side, or deferred, lands here, not in a code comment or a line of a doc. This folder lives in the ledger, the branch `xs-ledger`, checked out at `.xs/ledger`: only `xs` commits to it.

## File name and number

`T<nn>-<short-slug>.md`. A task keeps its file name for life, and a number is never reused or changed: commit messages cite it, and a renumbered id makes every citation false.

`xs file` and `xs ask` number the task themselves, from the one ledger: two branches never collide.

## Frontmatter

```yaml
---
title: A short sentence naming the work
type: task            # task | bug | decision
priority: p2          # p0 | p1 | p2 | p3, set when the task is filed
created: 2026-11-08
source: ARCHITECTURE.md §5 Known limits   # where it came from: a doc section, a commit, a review, a session
spec: S03 R2 I1       # the spec, requirements and invariants it serves; omit on the no-signal route
owner: <name>         # the person accountable
after: T41            # optional: the tasks, comma-separated, that must be done or dropped first
---
```

- The status is not in the file: it derives from the task's events. `xs status` lists every task; `xs status T<nn>` prints one with its events.
  - `todo`: not started. A task an agent discovers is filed as `todo` only when no routing signal holds; otherwise it is a `decision` task.
    A `todo` with `after:` waits: `xs next` leaves it out and `xs start` refuses it until each task it names is `done` or `dropped`, or is `doing` or `closed` on the branch the task starts on: the chain it continues.
  - `doing`: in progress on a branch. Only the coordinator sets it, with `xs start <id> --branch <branch>`, which also creates the worktree from `main`.
  - `blocked`: cannot proceed; `xs block <id> "reason"` writes the cause in one line, including an external party it waits for. Save partial work as `T<nn>-<slug>.patch` next to the task file.
  - `closed`: the worker finished; the Done section holds the proof. The code is not yet on `main`. A task with no branch, or whose branch is already on `main`, has nothing to land: `xs close` makes it `done`.
  - `done`: on `main`: the integrator recorded `landed`. A decision task is `done` when the owner answers it.
  - `dropped`: will not be done; `xs drop <id> "why"` writes why, or names the task that took the work over.
- `priority`:
  - `p0`: an incident: `main` is red, or production fails its users. It stops the line: nothing else lands until it is fixed. Open the incident too (`xs incident open`).
  - `p1`: the core flow gives a wrong or unsafe result, the tests or CI cannot be trusted, or a decision blocks such work.
  - `p2`: needed for the next release or the next feature of the core.
  - `p3`: structure, polish, later. The lead reviews p3 every week: promote it or close it.
- `type: decision` is a question for the owner, not code. It closes with an ADR in `project/adr/`.

## Body

Short (a few hundred words at most). These sections, in this order:

- **What**: the work, in a few lines.
- **Why**: what goes wrong without it.
- **Where**: files and doc sections.
- **Blocked by** (only when blocked): what it waits for.
- **Done when**: what is true when it is finished, checkable by someone who did not write it.

Cite the doc or the code for every fact; mark each guess `[ASSUMPTION]`. A task derived from a spec is regenerated or amended when the spec changes: edit the spec first. One task per deliverable (a screen, a module, a command), not one per finding: a review's twelve notes on one screen are one task.

## Closing

Close a task with `xs close <id>` once its **Done** section, written in this file, holds:

- the command that proves it, by test name rather than file path (`node --test --test-name-pattern "vault seals"`), since files move;
- what was looked at by hand, if anything, and what was not checked.

`xs close` refuses a task without a Done section, and one whose `type` or `priority` is outside the lists above or that holds a `status:` line. The task is then `closed`; it is `done` when the integrator lands its branch, and the `landed` event names the commit on `main`. Update the line of any doc that listed it as a limit. Never delete a task file: done ones stay as history.

Task status lives in the ledger and nowhere else: not in memory files, not in a README list. Point to `xs status` instead.

## State and events

A task's state changes only through `xs`: `file`, `ask`, `start`, `close`, `answer`, `block`, `unblock`, `drop`; the integrator adds `landed`. Each appends one line to `EVENTS.log` in the ledger, the history the metrics read (`flow`), and commits it with the task file: edit the text of a task here freely, and `xs` commits it with the next event about it. `xs` refuses an `EVENTS.log` edited by hand. A wrong event is never edited: `xs void <id> <kind> <at> "reason"` cancels it with a later one, and `flow` skips both. Write the body of the task by hand, as before.

For a repo with history, `xs import-git --dry-run` prints the events git can date (births, closings, landings, and exits: a file removed, a task dropped) without writing them; run it without `--dry-run` once you have read them. A repo that kept its tasks and `EVENTS.log` on `main` moves them here once with `xs migrate`.
