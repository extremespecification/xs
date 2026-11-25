# Build and land

Result: every task of a `ready` spec built, reviewed, verified and on `main`, and the spec set to `done`.

The rules are in [PROTOCOL §5 to §8](../PROTOCOL.md#5-isolation). The procedure is steps 4 to 7 of `skills/lead/SKILL.md`; the briefs are in `skills/lead/briefs.md`. This guide applies them to S04.

## Start the build

> Build S04. Use the lead skill.

The lead refuses to start while S04 is not `ready`.

## Plan the team

The lead dispatches the first task of each chain with `xs start`, from any worktree:

```sh
xs next
xs start T41 --branch export-core
xs start T44 --branch export-ui
```

`xs start` records the claim in the ledger and creates the chain's worktree from `main`; nothing is committed on `main`. The chain's next task starts on the same branch, in the same worktree. Running it again changes nothing. It refuses a task held on another branch, a task whose spec is not `ready`, a task whose `after:` tasks are still open, and a start past the WIP limit of `AGENTS.md`. If the repo has a remote, `xs start` pushes the claim with the ledger; when another clone claimed the task first, it refuses with "claimed elsewhere".

`--run <agent>` also launches, in the worktree, the headless command that `AGENTS.md` declares for that agent, with the brief on its input. The launch follows the claim, so repeating `xs start --run` launches the agent again.

T43, next in `export-core`, adds the first background job of the repo: a new pattern. The lead runs it attended and shows you the result before launching other jobs.

### Follow the agents

Each agent's life is in the ledger: `xs status` lists, under each task, the agents that run and those that stopped, with the reason.

```
$ xs status
T42 doing on export-core p2 Export endpoint streams the CSV for a date range
  agent implementer running since 2026-11-19T09:14:02Z, implementer, claude-code, sonnet, medium
T43 doing on export-ui p2 Background export above 50,000 rows with an email link
  agent implementer stopped at 2026-11-19T10:02:40Z: limit, resumes at 2026-11-19T14:00:00Z (job 41)
```

With Claude Code, the adapter's `lifecycle` hook records these events when the lead spawns an agent whose prompt names the task, and when the agent ends. `xs start --run` records them for the agent it launches. In any other tool, the lead records them with `xs agent`. You read the status; you do not ask for it.

With `OTEL_EXPORTER_OTLP_ENDPOINT` set, each run also goes to your observability tool as a span named by the OpenTelemetry GenAI conventions: one trace per task, one span per run, with the model, the effort and the reason it ended.

## The cycle of one task

An implementer builds the task and reports in five points. The lead routes the report. A new reviewer reads the diff. The lead triages each finding; an implementer on the Fix brief patches the ones routed to patch. The lead reruns the checks. Review and fix repeat for at most three rounds ([PROTOCOL §6](../PROTOCOL.md#review)).

### Route the report

Point 5 of the implementer's report lists deviations, gaps and leftovers. The lead routes each before the next spawn:

| Item from T42 | Signal | Destination |
|---|---|---|
| `billing/totals.py` rounds per line; the ledger rounds per invoice | invariant touched (S04 I1) | a question to Ada, then a Log line |
| The export reuses a date parser with no test | none | T45, `todo`, p3 |
| Agents keep formatting the whole tree | none | a rule proposal for `AGENTS.md` |

A discovered task with a signal becomes a `decision` task for the owner of the artifact. Only the lead writes the Log, with `xs spec S04 noted|deviated|approved "line"`.

## Land

### Close the task first

Before delivering, the implementer writes the Done section in `.xs/ledger/tasks/T42-export-endpoint-streams-csv.md` and runs `xs close T42`, which records `task.closed` in the ledger with the task file. The commits on the branch hold only the work.

```markdown
## Done

- Proof: `pytest -k "S04 I1"`.
- Checked by hand: the file opens in Excel 16 with accents intact. Not checked: Numbers on macOS.
```

```
$ xs close T42
T42 closed: it is done once the integrator lands its branch
```

### Deliver the branch

The lead verifies the [merge gate](../PROTOCOL.md#gate), then runs `land` in the worktree:

```sh
land
```

`land` delivers the branch to the integrator. It refuses when the branch has uncommitted or untracked files, when it has nothing `main` lacks, when it runs on `main` or on the ledger, and when `CHECK_CHANGE` fails on the branch as it is. It does not ask you to rebase. The integrator (`xs integrate`, one per repository) works in rounds, in a worktree of its own:

1. **Rebase.** It puts every queued branch, in order, on top of `main`, at the commit `land` recorded in the queue (the branch's tip when `land` ran), and ejects a branch that conflicts. A branch whose ref moved or was deleted after `land` is ejected as `moved`: what it points to now passed no check. The pin holds while agents cannot write `xs-queue` and `xs-integrate.lock` in the git directory. The boundary is an OS sandbox that denies the agents' processes every write to `xs-queue` and `xs-integrate.lock` in the git directory (Claude Code's sandbox can); the `guard` hook catches an ordinary edit of them, not a deliberate one. A branch deleted after `land` is ejected the same way, with or without a pinned commit.
2. **Gate.** It runs `CHECK_GATE` once on the round.
3. **Land, when green.** It fast-forwards `main` to the round, records one `landed` event per task with the commit on `main`, and the task becomes `done`. On `main` it commits only the code, and the marks of the memory entries the round made stale. It removes the worktrees and branches of what landed; a branch whose ref moved during the round is kept, with its worktree, and the outcome says so.
4. **Bisect, when red.** It tries the first half of the round alone and leaves the rest for the next round, down to the branch that fails, which it ejects with the gate's log.

An ejection records `land.ejected` with its reason; the task stays `closed`, its branch stays as it was, and `xs status` and `xs where` show why. A `moved` branch is reset to the commit `land` delivered, `git branch -f <branch> <commit>` as the reason prints it, or reviewed again; then it is delivered again.

`land` waits for the outcome; `land --queue` returns at once and starts an integrator if none runs, so that the agent goes on with its next task. With tens of agents, deliver with `--queue`: the gate then runs once per round, not once per branch. `land --dry-run` runs the refusals and `CHECK_CHANGE`, prints what would be queued, and stops: nothing is queued and `main` does not move.

The three checks, named by what they guarantee, not by how long they take:

| Variable | Default | Guarantees | Runs |
|---|---|---|---|
| `CHECK_CHANGE` | `make check-change`, when the Makefile has it | the change stands on its own: lint, types, the tests of what it touches | on the branch, at delivery |
| `CHECK_GATE` | `make check` | `main` stays whole: every test and every invariant `S<nn> I<n>`, on the round | once per round, before `main` |
| `CHECK_RELEASE` | none | the whole system behaves as promised to its users: end to end, fuzzing, migrations on sample data | on `main`, before a release |

A test goes in the level of what it protects, not of how long it takes. `CHECK` is the old name of `CHECK_GATE`. `MAIN=<branch>` lands on another branch.

### With a forge

When the team lands through GitHub or GitLab, write the line `- Merge train: github` (or `gitlab`) in `AGENTS.md`. `land` then runs its refusals and `CHECK_CHANGE` as before, pushes the branch, opens the pull or merge request and queues it in GitHub's merge queue or GitLab's merge train, which rebuilds each candidate on top of the ones ahead of it and merges it when the required checks pass: the integrator's work, done by the forge. Merge with rebase, not squash: `xs sync` recognizes the merged work by its patches.

The forge, not `xs`, moves `main`. Run `xs sync` before each report: it fetches `main` and records a `landed` event for each closed task whose branch the forge merged. It also asks the forge, through `gh` or `glab`, about each request still open, and records `land.ejected` with the reason when the forge holds it back: `red`, `changes-requested`, `conflict` or `closed`. The lead treats it as an ejection by the integrator.

```
$ xs sync
T42 landed by the forge (export-core)
T43 ejected by the forge (export-bg): red
```

### Close the spec

When T44 lands, the lead runs `xs spec S04 done` and `xs where`. `xs spec S04 done` refuses while `main` lacks one of the invariant tests S04 names. Expected output of `xs where`: no worktree and no branch of S04 remain.

## One chain end to end

Chain `export-core`, as recorded in the Log of S04, `.xs/ledger/logs/S04.md` (`xs status S04` prints it):

```
- 2026-11-19: T41 landed: three invariant tests S04 I1–I3, red as expected before T42.
- 2026-11-19: T42 discovery: billing/totals.py rounds per line; the ledger rounds per invoice. S04 I1 fails by 0.01 on 3 of 400 invoices.
- 2026-11-19: decision by Ada: export per-invoice totals, as the ledger does. R2 unchanged.
- 2026-11-19: T42 review round 1: must-fix, the organization filter is applied after the stream starts (I3). Fixed; test `S04 I3 export excludes other organizations` now covers streaming.
- 2026-11-19: T42 review round 2: no must-fix. Finding "use pandas" dismissed: adds a dependency for a 30-line writer.
- 2026-11-19: T42 landed.
- 2026-11-20: T43 landed. Breaker: an export of 120,000 rows completed in 94 seconds.
```

The rounding discovery came from point 5 of the implementer's report. The lead asked the owner instead of patching: it touched an invariant. The Breaker line comes from a reviewer on the Breaker brief (`skills/lead/briefs.md`), which tries to break the running feature; that reviewer runs on the cheapest model.

## Report

```
Landed: invoice CSV export endpoint, invariants green (T42); background export above 50,000 rows (T43)
Running: Export CSV button, in review (T44)
Waiting for you: none
New tasks: T45 date parser of the export has no test (p3)
```

When T44 lands, the spec is done and the Landed line carries two more, for the owner's technical sign-off:

```
Landed: S04 invoice CSV export (T42–T44), 3/3 invariant tests green, 5 review rounds
Risk: high, exports data across organizations (9 files, no migration). Security: the export endpoint checks the organization before streaming (I3). Not checked: exports above 120,000 rows
Trade-off: per-invoice totals, as the ledger does, so line totals may differ by a cent
```
