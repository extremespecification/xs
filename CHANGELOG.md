# Changelog

Every release of XS, newest first. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow [Semantic Versioning](https://semver.org/). Until 1.0 the method may change between minor versions; the ledger's event format is the stable contract, and a change to it comes with a migration.

## [Unreleased]

### Toolset

- `xs` runs on Python 3.9, the `python3` of macOS: one f-string held a backslash in its expression, a syntax error before Python 3.12 that made `xs install` fail on a clean Mac. CI now runs 3.9 on macOS.
- `land` records the branch's tip in its queue entry, and the integrator ejects, with `land.ejected reason=moved`, a branch whose ref moved or was deleted since; it cherry-picks the recorded commit, never what the ref holds later, and after landing keeps a branch whose ref moved during the round. A raw write of another branch's ref after its `land` no longer reaches `main`. The pin is the commit `land` saw, not one a review recorded; it holds against an agent that can write refs, not one that can write the queue, so its boundary is an OS sandbox that denies every write to `xs-queue` and `xs-integrate.lock` in the git directory to the sessions that must not deliver: implementers, reviewers, conversations, every subagent (Claude Code's sandbox can). `land` and the integrator write both, so they run outside that sandbox: in the lead's session, or as a person or a service. The `guard` hook catches an ordinary edit of them, not a deliberate one: Edit, Write, MultiEdit and NotebookEdit of a path in a git dir (`xs install` extends the hook's matcher to them, in a group of the guard's own when its old group holds other hooks), and a Bash command with a path to them that does more than read or redirects anything. Local integrator only: with a forge's merge train, the forge decides what it merges. Entries queued before this change carry no tip and land the ref as it is.

## [0.1.0] - 2026-11-22

First public release.

### Method

- [PROTOCOL.md](PROTOCOL.md): seven principles, four levels of adoption, and every rule with its level and the evidence behind it ([EVIDENCE.md](EVIDENCE.md)).
- Routing on three risk signals: a request with one starts from a one-page spec, any other becomes a task.
- The readiness gate: every invariant bound to a named test, the owner's approval of the spec.
- The merge gate: `CHECK_CHANGE` on the branch, `CHECK_GATE` once per round, an independent review with no open `must-fix`, a person for each irreversible action.
- Sign-off lines when a spec closes: risk, size, security, what was not checked, trade-offs.
- Incidents and `p0`: a red `main` stops the line; severities 1 to 4.

### Toolset

- `xs`: the only writer of the ledger, the orphan branch `xs-ledger`. Tasks, specs, ADRs, memory entries, releases, incidents, agents' lives, handoff and takeover.
- `land` and the integrator: a local merge train that rebases queued branches together, runs the gate once per round and bisects a red round. With `Merge train: github|gitlab`, `land` queues in the forge's merge queue or train, and `xs sync` records what it merged and what it held back.
- `flow`: the seven core numbers, read from the ledger.
- `where`: what is not on `main` yet; `next-id`: the next free spec or ADR number.
- OpenTelemetry: each agent run exported as an OTLP span, with no dependency.

### Agents

- Skills of the open [Agent Skills](https://agentskills.io) standard: `lead`, `advisor`, `retro`, `curator`, and the roles `researcher`, `implementer`, `reviewer`.
- The Claude Code adapter: role definitions, the `guard` hook (a tool-neutral JSON contract) and the `lifecycle` hook.

[0.1.0]: https://github.com/extremespecification/xs/releases/tag/v0.1.0
