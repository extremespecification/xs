# Reference

Every command, setting and event of the toolset, on one page. The guides show them in use; [PROTOCOL.md](../PROTOCOL.md) states the rules behind them. `xs --help` prints the same list of commands.

## Commands

### Setup

| Command | Does |
|---|---|
| `xs install [--skills-dir DIR]` | links the skills into each agent tool found in your home (or into `DIR`) and applies its adapter: role definitions and hooks. Running it again changes nothing. |
| `xs init` | in a repo: adds `AGENTS.md`, `project/` and the adapters' files, keeping every file already there; creates the ledger. |
| `xs migrate` | once, in a repo that kept its tasks and `EVENTS.log` on `main`: moves them to the ledger. |
| `xs import-git [--dry-run]` | once, in a repo with history: records the events git can date. |

### Tasks

| Command | Does |
|---|---|
| `xs file [--type task\|bug\|prototype] [--priority p0\|p1\|p2\|p3] [--spec "S03 R2"] [--source TEXT] "title"` | files a task. |
| `xs ask [--priority …] [--spec …] "question"` | files a decision task for the owner. |
| `xs next` | the tasks ready to start, p1 first, and the WIP in use. |
| `xs start T12 --branch b [--run AGENT [--brief FILE]]` | claims T12 and creates the worktree `.xs/worktrees/b` from `main`; `--run` launches the agent `AGENTS.md` declares there, the brief on its input. |
| `xs close T12` | the worker closes T12 once its Done section holds the proof; it is `done` when it lands. |
| `xs answer T12 ["answer"]` | the owner answers a decision task and closes it. |
| `xs block T12 "reason"`, `xs unblock T12`, `xs drop T12 "why"` | set a task aside, bring it back, abandon it. |
| `xs review T12`, `xs reviewed T12 approve\|changes [--must-fix N]` | open a review round and record its verdict. |
| `xs void T12 KIND AT "reason"` | cancel a wrong event with a later one. |

### Agents and handoff

| Command | Does |
|---|---|
| `xs agent T12\|--branch b started\|stopped\|finished run=ID [key=value …]` | records an agent's life. `started`: `tool`, `model`, `effort`, `role`, `session`. `stopped`: `reason`, `resume_at`, `job`, `exit`. `finished`: `outcome` (default: the task's state). Hooks and `xs start --run` call it; call it yourself where no hook exists. |
| `xs handoff T12 --next "step" [--open "request"]…` | packages a started task for another session, account or tool: a brief, the branch's head, the uncommitted work as a patch, the owner's open requests, the agent's session. |
| `xs takeover T12` | in any tool: prepares the worktree, applies the patch once, prints the brief. |

### Specs, decisions, releases

| Command | Does |
|---|---|
| `xs spec S12 opened\|ready\|done\|dropped` | a spec's status; `ready` runs the readiness gate, `done` checks its invariant tests on `main`. |
| `xs spec S12 approved\|deviated\|noted "line"` | a dated line in the spec's Log, with its event. |
| `xs adr 0007 proposed\|accepted\|retired ["line"]`, `xs adr 0007 built "…"`, `xs adr 0007 amended "…"` | an ADR's status, as events; the file is never edited. |
| `xs release NAME [--commit SHA]`, `xs rollback NAME "reason"` | a release and its rollback. |
| `xs incident open SLUG "line" [--sev 1\|2\|3\|4]`, `xs incident resolve SLUG` | an incident and its severity (default 2; the scale is in [PROTOCOL §7](../PROTOCOL.md#7-landing)), for the time to restore. |

### Memory

| Command | Does |
|---|---|
| `xs idea [--source TEXT] "idea"` | one dated line in `IDEAS.md` of the ledger. |
| `xs propose --kind rule\|design\|knowledge --anchor PATH --evidence TEXT [--to FILE] [--scope S] [--replaces L3] "entry"` | an agent proposes an entry of memory. |
| `xs promote L3` | the owner accepts it: written in its destination, marked `(L3)`. |
| `xs recommend L3 holds\|retire "why"` | the curator's recommendation on a stale entry. |
| `xs checked L3 "check"`, `xs retire L3 "why"` | a check enforces it, or the owner removes it. |
| `xs repeated L3 "what"` | a correction the entry should have prevented. |
| `xs queue` | what waits for the owner: open questions and proposals. |
| `xs stale MAIN` | marks stale the memory entries whose anchor this branch changed since `MAIN`. |
| `xs load` | for a session-start hook: records a recall of every entry the session loads. |
| `xs search "words"` | the memory entries matching the words, best first; records each recall. |

### State and landing

| Command | Does |
|---|---|
| `xs status` | every open task with its agents, every spec, ADR and pending entry. |
| `xs status T12\|S03\|ADR-0007\|L02` | one entry: its files, its events, its Log. |
| `xs status --unlanded` | the tasks closed and not on `main`, and why. |
| `xs status --since 2026-11-24` | every event since then: the report. |
| `xs where [--preflight]` | worktrees, branches, tasks and files not on `main`; `--preflight` adds the checks before leaving a team running. In zsh, `where` is a builtin: use `xs where`. |
| `land [--queue] [--keep] [--dry-run]` | from a worktree: delivers the branch to the integrator, or to the forge's merge train. |
| `xs integrate` | the integrator; `land` starts it. |
| `xs sync` | with a forge's merge train: records as landed the closed tasks the forge merged, and as ejected, with the reason, those whose request it holds back (`gh` or `glab`). |
| `flow [--since D] [--until D] [--prompts N] [--explain]` | the seven core numbers, with their coverage. |
| `next-id S\|ADR` | the next free spec or ADR number across every branch and remote. |

## Settings in `AGENTS.md`

| Line | Values | Read by |
|---|---|---|
| `- WIP limit: N` | a number, or none | `xs start` |
| `- Spec approval: owner\|none` | default `owner` | `xs spec ready` |
| `- Merge train: local\|github\|gitlab` | default `local` | `land` |
| `- Merge gate: human` | while the checks do not cover the invariants | the team ([Adopt in a team](adopt-in-a-team.md)) |
| `- Thresholds: …` | e.g. `lead time p90 under 24 h` | the retrospective |
| `- Agent NAME: COMMAND` | a headless command reading the brief on its input | `xs start --run NAME` |

## Environment

| Variable | Default | Effect |
|---|---|---|
| `CHECK_CHANGE` | `make check-change`, if the Makefile has it | what a branch passes at delivery |
| `CHECK_GATE` | `make check` | what each round passes before `main` moves (`CHECK` is its old name) |
| `CHECK_RELEASE` | none | what `main` passes before a release |
| `MAIN` | `main` | the base branch |
| `LAND_FORGE` | the `Merge train` line | `github` or `gitlab`: overrides it |
| `XS_LEDGER` | `xs-ledger` | the ledger's branch |
| `XS_NO_PUSH` | unset | `1` keeps the ledger local in a team |
| `XS_LEDGER_SIGN` | unset | `1` signs the ledger's commits |
| `XS_BY` | `git config user.name` | the actor written on each event |
| `XS_SCOPE` | `project/<repo folder>` | the scope written on each event |
| `XS_HOME` | `~/.xs` | the person's local log of recalls |
| `XS_SESSION` | unset | names the session in a recall |
| `XS_GATE` | unset | `autonomous` lets the guard push feature branches and merge pull requests |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | unset | sends each agent run as an OTLP/HTTP span to `<endpoint>/v1/traces` |
| `OTEL_EXPORTER_OTLP_TRACES_ENDPOINT` | unset | the full traces URL, instead of the above |
| `OTEL_EXPORTER_OTLP_HEADERS` | unset | `key=value,…`, e.g. an authorization header |
| `OTEL_SERVICE_NAME` | `xs` | the span's service name |

## The ledger

The ledger is the branch `xs-ledger`, checked out at `.xs/ledger`: `EVENTS.log`, `tasks/`, `learnings/`, `logs/S<nn>.md` (the Log of each spec), `handoffs/` and `IDEAS.md`. Only `xs` writes it, one commit per command.

An event is one line:

```
<at> <scope> <subject> <kind> key=value ...
2026-11-24T09:12:03Z project/billing T42 task.closed status=closed by=ada
```

The line is the stable contract: a new kind is an addition, a changed one needs a migration.

| Kinds | Recorded by |
|---|---|
| `task.filed`, `question.asked`, `task.started`, `task.closed`, `question.answered`, `task.blocked`, `task.unblocked`, `task.dropped` | the task commands |
| `review.started`, `review.verdict` | `xs review`, `xs reviewed` |
| `landed`, `land.ejected` | the integrator, or `xs sync` with a forge |
| `agent.started`, `agent.stopped`, `agent.finished` | `xs agent`, its hooks, `xs start --run` |
| `task.handed_off`, `task.taken_over` | `xs handoff`, `xs takeover` |
| `spec.*`, `adr.*` | `xs spec`, `xs adr` |
| `learning.*`, `correction.repeated` | the memory commands |
| `released`, `rolled-back`, `incident.opened`, `incident.resolved` | `xs release`, `xs rollback`, `xs incident` |
| `event.voided` | `xs void` |

The reasons of `agent.stopped` are those of the Agent Client Protocol's `stopReason` (`end_turn`, `max_tokens`, `max_turn_requests`, `refusal`, `cancelled`) and three it does not carry: `limit`, `error`, `killed`.

## Hooks of the Claude Code adapter

| Hook | On | Does |
|---|---|---|
| `guard` | PreToolUse: Bash, Edit, Write, MultiEdit, NotebookEdit, Agent, Task | denies sweeping commits, killing by name, moving `main` outside `land`, and writing the integrator's queue or lock (`xs-queue`, `xs-integrate.lock`: by path for the file tools; a Bash command that names them may only read); asks before anything leaves the machine; refuses a spawn of a generic subagent (one with no role) that names no model, and sets a missing effort to `medium`; confines the read-only roles. Its JSON on stdin is tool-neutral: any client, an ACP client included, can ask it. |
| `lifecycle` | PreToolUse: Agent, Task; SubagentStop | records `agent.started` for a spawn whose prompt names a task, and `agent.finished`, or `agent.stopped reason=limit` when the agent's transcript ends on a usage limit. |

`xs install` registers both in `~/.claude/settings.json`.
