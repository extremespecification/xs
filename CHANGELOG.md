# Changelog

Every release of XS, newest first. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow [Semantic Versioning](https://semver.org/). Until 1.0 the method may change between minor versions; the ledger's event format is the stable contract, and a change to it comes with a migration.

## [Unreleased]

### Toolset

- `land` records the branch's tip in its queue entry, and the integrator ejects, with `land.ejected reason=moved`, a branch whose tip moved since; it cherry-picks the recorded commit, never what the ref holds later. A raw write of another branch's ref between its review and the round no longer reaches `main`. Entries queued before this change carry no tip and land as before.

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
