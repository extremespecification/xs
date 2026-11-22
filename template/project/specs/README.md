# Specs

One file per change. A spec is the main input people write: it states the result, its requirements and its invariants. Tasks derive from it. A `done` spec is history: a later change to the same feature gets a new spec that cites it.

Write a spec when one of the three signals of `PROTOCOL.md` §4 holds. Otherwise file a task directly.

## File name and number

`S<nn>-<short-slug>.md`, numbered with `next-id S`. A number is never reused or changed.

`S00-product.md` is a standing spec: the invariants true for every change, `S00 I<n>`. It stays `ready` and never closes; add to it when a rule outlives every feature.

## Format

One page. These sections, in this order:

```markdown
---
title: A sentence naming the outcome
owner: <name>                 # exactly one person
created: 2026-11-18
---

## Outcome

The observable result, in two or three sentences. For existing code, what changes from what is there.

## Boundaries

What is excluded.

## Requirements

- R1: one statement, verifiable by someone who did not write it.
- R2: ...

## Invariants

- I1: the rule. Why: what breaks without it. Test: `S<nn> I1 <name of the test>`.

## Decisions

- ADR 0007: the decision in five to ten words.

## Open

- <item>: question to the owner | spike (20 minutes) | task.
```

The spec holds no status and no Log: both live in the ledger. `xs status S<nn>` prints the status, the events and the Log.

## Rules

- Ids `R<n>` and `I<n>` are stable. Never renumber or reuse one; tasks, tests and commits cite them.
- Mark each guess `[ASSUMPTION]`. A spec with an unconfirmed assumption is not ready.
- An invariant names its test, and the test name starts with `S<nn> I<n>`, so that a later change finds it by searching the tests. Where a test name cannot hold spaces, write `s<nn>_i<n>_<name>`: `xs spec <id> done` matches in any case, spaces or underscores. A missing test is a p1 task, first in its chain, built by an implementer that does not build the feature. Its Log line records the mutation check: the test failed on a deliberate violation. `xs spec <id> done` refuses to close a spec whose named tests are not on `main`.
- For UI, record the selected prototype and the requirements; do not describe layout.
- To change the work, edit the spec, then amend or regenerate the tasks. Never edit only the task. A change to an invariant after `ready` needs the owner's approval, recorded with `xs spec <id> approved "line"`.
- The Log is `logs/S<nn>.md` in the ledger, append-only: one dated line per approval, decision, discovery, deviation or dismissed finding, written by `xs spec <id> approved|deviated|noted "line"`. Every agent of the chain reads it first.

## Readiness gate

Run `xs spec <id> ready` when every condition holds. It refuses a spec that fails one it can read, and lists each failure.

1. The outcome and each requirement are verifiable by someone who did not write them.
2. Each invariant names a test, or a p1 task exists for the missing test.
3. No `[ASSUMPTION]` remains unconfirmed, and no open item awaits the owner.
4. Each decision that two chains could make incompatibly is an ADR accepted with `xs adr <NNNN> accepted`.
5. The owner has approved, with a Log line written by `xs spec <id> approved "<what was approved>"`.

## Status

Set with `xs spec <id> opened|ready|done|dropped`; a spec with no event is `draft`.

- `draft`: being defined.
- `ready`: the gate holds; tasks may start.
- `done`: every task landed and every requirement has its proof; `xs spec <id> done` refuses while `main` lacks an invariant test the spec names.
- `dropped`: abandoned; the Log says why.
