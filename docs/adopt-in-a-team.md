# Adopt in a team

Result: a repo where several people own specs and code, approve specs and land work through pull requests.

Status: experimental. Evidence: none. [EVIDENCE.md](../EVIDENCE.md) holds no measurement of a team; every rule on this page was designed, not measured. Record the core numbers of [Improve the method](improve-the-method.md) from the first week to measure the effect.

This page assumes [level 3](../PROTOCOL.md#levels), the ledger of events, and adds rules to [PROTOCOL.md](../PROTOCOL.md); `land` delivers through pull requests, in the forge's merge train. An irreversible action requires a person under every rule here ([PROTOCOL §6](../PROTOCOL.md#gate)).

## 1. Assign ownership

Create `project/OWNERS`; the template does not ship it. The last matching line applies:

```
*                Ada
project/adr/     Ada
src/billing/     Lin
src/web/         Sam
```

Override the default in the `owner` field of a spec, task or ADR. The team writes `project/OWNERS`.

## 2. Approve specs

List the approvers in the spec header:

```yaml
owner: Ada
approvers: [Lin]
```

Add an approver when the spec touches an area another person owns, defines an invariant another area relies on, or produces a shared ADR. Each approver records approval with `xs spec <id> approved "<what>"`, which writes the Log line `- 2026-11-18: approved by Lin: <what>` in the ledger. A spec is `ready` only when the owner and every approver have approved it. `xs spec <id> ready` checks the owner's approval; the lead checks the others in the spec's Log. A change to an invariant after `ready` requires the same approvals.

## 3. Address decisions

A `decision` task names who decides in `for:`: the owner of the artifact concerned.

```yaml
type: decision
for: Lin
```

## 4. Coordinate work

- **Ids.** Task and memory numbers come from the one ledger: `xs file` and `xs propose` number them, so two clones never collide. Spec and ADR numbers come from `next-id S` and `next-id ADR`, which fetch every remote and read remote branches.
- **Locks.** When `main` has an upstream, `xs` pulls the ledger before each command and pushes it after. The pushed claim is the lock: a rejected push is undone, pulled and run again, and a task a colleague claimed meanwhile is refused as "claimed elsewhere"; choose another with `xs next`. `XS_NO_PUSH=1` keeps the ledger local. The ledger's commits are unsigned unless `XS_LEDGER_SIGN=1`.
- **Visibility.** `xs where` lists the branches of every remote that have commits not on `main`. Run it before starting work.

## 5. Land through pull requests

The merge gate stays autonomous: a pull request merges when the [merge gate](../PROTOCOL.md#gate) holds.

- Write `- Merge train: github` (or `gitlab`) in `AGENTS.md`. `land` pushes the branch, opens the pull or merge request and queues it in the forge's merge queue or train; `xs sync` records what the forge merged and what it held back ([Build and land](build-and-land.md#with-a-forge)). A review by the forge's own agent, such as GitLab Duo's, can be the independent review of the merge gate: its unresolved findings count as `must-fix` until the lead triages them. Enable the merge queue (GitHub) or merge trains (GitLab) on `main`, with rebase merges.

- Export `XS_GATE=autonomous` in every agent session. The `guard` hook then permits the push of a feature branch and the merge of a pull request. It still asks a person for a push that names `main`, a push from `main`, a forced push, a merge with `--admin` and a publication.
- Protect `main` on the git host: require a pull request and green checks. Claims go to the ledger, so a protected `main` does not block them. Protect `xs-ledger` against force pushes. The hook prevents mistakes on one machine; it is not a security boundary.
- Enforce in CI what code can check: `make check` as a required status. `xs close` already refuses a task without a Done section.
- Require a human code owner in `CODEOWNERS` for the paths that hold irreversible actions: migrations, public API schemas, release configuration.

### Human gate

Write `Merge gate: human` in `AGENTS.md` while the checks do not yet cover the invariants of the repo. Leave `XS_GATE` unset: every push and every merge asks a person, and each pull request requires one human approval.

Move to the autonomous gate when two conditions hold:

1. Every invariant of the active specs has a test in `make check`.
2. Over the last two cycles, human reviewers found no `must-fix` that the reviewer agent missed.

## 6. Observe the team

Each agent's start, stop and end is an event of the ledger, the same for every tool ([Build and land](build-and-land.md#follow-the-agents)). To see them beside the rest of your systems, set in every session that runs `xs`:

```sh
export OTEL_EXPORTER_OTLP_ENDPOINT=https://otel.example.com
export OTEL_EXPORTER_OTLP_HEADERS="authorization=Bearer%20<token>"
```

Each agent run becomes a span named by the OpenTelemetry GenAI conventions (`invoke_agent`, `gen_ai.request.model`, `gen_ai.conversation.id`), one trace per task. The exporter needs no library; when it fails, the command does not, and the ledger keeps the event.

## 7. Ledger outside git

A team that tracks work in an issue tracker has two options. The simpler keeps the ledger on the branch `xs-ledger` and mirrors it: a script publishes status and links to the tracker, in one direction, so each fact keeps one writer. The other keeps the ledger in the tracker, when the tracker has the properties of [the ledger](../PROTOCOL.md#3-ledger). Either way, `xs`, the integrator, `flow` and `next-id` read files; a store other than files needs equivalents.

## 8. Scale to an organization

| Element | Rule |
|---|---|
| Ownership | `OWNERS` maps paths to teams; each team names one person per artifact |
| Shared ADRs and invariants | one shared repository; cite them as `<repo>#ADR 0012` and `<repo>#S04 I3` |
| Spec approval | one approver from each affected team |
| Ids across repos | qualified by repo: `billing#T42` |
| Merge gate | enforced by branch protection on every repository |
| Metrics | one `METRICS.md` per team, each with its own thresholds; compare each team with its own past, never teams with each other |
| Scopes | rules and knowledge of the organization and of each team live in one shared repository each, with the same layout as a project; a project's `AGENTS.md` names them under Scopes, and a session reads them before the project's own. A narrower scope overrides a wider one only where the wider rule says so |
| Memory | an entry is proposed to the scope it belongs to and promoted by that scope's owner; a person's preferences live in one file of the person, referenced by every account and provider, never copied per project |

Introduce the organization level one team at a time.

## Checklist

- [ ] `project/OWNERS` lists an owner for every path.
- [ ] `AGENTS.md` states the merge gate.
- [ ] `AGENTS.md` names the merge train, and the forge merges with rebase.
- [ ] `main` is protected on the git host, and `xs-ledger` against force pushes.
- [ ] Every agent session on the autonomous gate exports `XS_GATE=autonomous`.
- [ ] `make check` runs every invariant test and is a required status.
- [ ] `project/METRICS.md` has a first row.
