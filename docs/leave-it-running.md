# Leave it running

Result: a team that works for hours while no person answers, with the same flow as by day, and a one-page report when the owner returns.

The rules are in [PROTOCOL §9](../PROTOCOL.md#9-leaving-the-factory-running). The procedure is the section "Leaving the team running" of `skills/lead/SKILL.md`. The flow is [Build and land](build-and-land.md), unchanged: every branch reaches `main` through `land`, and a spec waits for the owner's approval at any hour (unless `AGENTS.md` says `Spec approval: none`). What changes when nobody answers:

| | Someone answers | Nobody answers |
|---|---|---|
| Question for the owner | asked at once | a `decision` task, in the report |
| Blocked task | reported | set aside with a saved patch; the chain stops, others continue |

An irreversible action still stops for a person. The team continues with work that does not depend on it.

## Choose the work

Choose approved work whose outcome a program can score:

- "Precision and recall of the classifier above 80% on the held-out set."
- "Every p1 bug of S07 closed, with its regression test."

Visual polish needs a person and does not qualify. Select fewer tasks than the budget allows.

## Run the preflight

```sh
CHECK="make check" xs where --preflight
```

Resolve each warning. Expected last lines: `checks green on <branch>`, then a reminder to confirm the usage budget and the number of agents that run at once. A red base invalidates every result of the run.

Confirm by hand that the permission mode lets agents run without prompts, and that the usage budget and the quota of each model the product calls cover the run.

## Launch

> Work on S07 until I am back: close the five p1 bugs. Use the lead skill.

When a usage limit stops the team, the lead schedules the resume as a job and records it on the stopped agent, so that the status says when the work starts again:

```sh
xs agent T63 stopped run=implementer reason=limit resume_at=2026-11-24T05:00:00Z job=41
```

The resume reads `xs status`, the Log and the task files: "continue from the Log and the ledger". A stop by a limit with no job shows as `no resume scheduled` in `xs status`, and `flow --explain` counts the hours it cost.

## Hand a task over

When a session must stop before its task is done (its credits run out, or you move the work to another account or another tool), it hands the task over:

```sh
xs handoff T63 --next "make the retry test pass, then deliver with land" \
  --open "keep the old error message for API clients"
```

`xs handoff` writes `.xs/ledger/handoffs/T63-<time>.md` and commits it with the ledger: the task and its spec, the branch and its head, the uncommitted work as a patch, the requests you made that are not done yet, and a brief for whoever continues. The worktree is left as it was.

The next session, in any tool and under any account, runs:

```sh
xs takeover T63
```

It prepares the worktree, applies the patch once, refuses to apply it over other changes, warns when the branch moved since the handoff, and prints the brief. The same tool can also resume the session itself (the handoff names it); another tool starts from the brief. A session that stopped without a handoff is taken over by the lead from its transcript: it files with `xs file` each request left without an outcome.

## The report

The lead builds it from `xs status --since <the time you left>`, which lists every event since then, after `xs sync` when a forge lands the work.

```
Target: 5 of 5 p1 bugs closed, regression tests green.

Landed on main, green:
- T61 duplicate invoice numbers under concurrent creation, test `S07 I1 concurrent creation yields distinct numbers`
- T62 ...

Waiting for you:
1. T64 needs a unique index on invoice number, a migration of live data. Approve? I recommend yes.

Blocked:
- T65 the payment sandbox rejected every request after 02:10; patch saved, reason recorded with `xs block`.

New tasks:
- T66 retry policy of the email job is undocumented (p3)

Memory (curator):
2. L14 "invoices are numbered per tenant": stale, T61 changed its anchor; holds. I recommend promote.
```

At [level 4](../PROTOCOL.md#levels), the curator runs before the report, in a session of its own; its queue of memory entries (`L<nn>`) whose anchored code changed during the run is the last section.

A run that files more tasks than it closes was badly scoped: select fewer tasks for the next run.
