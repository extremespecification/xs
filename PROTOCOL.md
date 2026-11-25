# Extreme Specification (XS)

A method for autonomous programming. People specify; agents build, verify and integrate.

The name follows Extreme Programming. XP took each practice that worked and turned it up to the maximum: if review helps, review all the time (pair programming); if tests help, write them first (TDD). Writing code was the bottleneck. With agents, code is cheap and human attention is scarce, so XS turns up the specification:

- **Minimal**: one page per change.
- **Verifiable**: every requirement has an id, every invariant has a test.
- **Current**: the spec records decisions and discoveries while the work goes on.

XP preferred conversation to written specifications. XS reverses that on purpose: agents do not attend the conversation, so what it decides must be written down. "Extreme" refers to the rigor of the spec, not its length.

Each rule below is one imperative statement, the principle it derives from, the level that adopts it, and one line of evidence. `EVIDENCE.md` holds the full data under the cited number. The evidence comes from building products with Claude Code. Rules marked "Evidence: none" were adopted from the BMAD method or designed, and have not yet been measured. Rules for teams live in `docs/adopt-in-a-team.md` and are experimental.

## 0. Principles

| # | Principle |
|---|---|
| P1 | Human attention is the scarce resource. Spend it on intent, taste and decisions; record all three in the spec. |
| P2 | State lives in the ledger. Each fact has one place and one writer. A fact a tool can record has the tool as its writer, never an agent. |
| P3 | A claim is not a proof. Accept a result only with the command that reproduces it. |
| P4 | Specify in proportion to the risk. Decide what is costly to change before building it; skip the spec when nothing is. |
| P5 | Work counts only when landed. Isolate code in workspaces and conversations in sessions; integrate both. |
| P6 | A repeated correction becomes a rule, then a check. |
| P7 | The method measures itself. Every number comes from an event the ledger recorded while the work was done. The work never changes shape to be measured, and a number is a question for the owner, never a target for an agent. |

### Levels

XS is adopted in four levels. Each level is complete on its own. A project moves to the next level when its symptom appears, never by calendar.

| Level | Adds | Principles | Adopt it when |
|---|---|---|---|
| 1. Spec | the one-page spec with invariants bound to tests, the readiness gate, routing, proof and review, the gate of irreversible actions; no scripts | P1, P3, P4 | always: this is XS |
| 2. Land | a workspace per chain, `land` and its integrator, `where`, `next-id`, the `guard` hook, parallel agents | P5 | agents work in parallel, or "is it on main?" comes up twice (E30) |
| 3. Ledger | the ledger off `main` and state through `xs`, the event log, `flow`, the advisor, a factory left running | P2, P7 | work is lost between sessions (E06), or the owner cannot say where the time goes (E36) |
| 4. Memory and scale | entries of memory, scopes, search, the retrospective, the curator, team and organization repos | P6 | the same correction is given twice (E33), or a second team adopts XS |

- **Adopt a level whole.** `land` without the `guard` hook keeps the failure the hook prevents. (P5) Evidence: none.
- **Apply a rule that names a script by hand until its level introduces the script.** At level 1, keep a task's state by hand in its file and close it by adding its Done section; from level 3, `xs` records each state as an event in the ledger and the file keeps only the text. (P2) Evidence: none.

## 1. Vocabulary

| Term | Definition |
|---|---|
| Spec | The one-page document that states a change: its outcome, requirements and invariants. The main input people write. |
| Requirement | A verifiable statement in a spec, identified as `R<n>`. |
| Invariant | A rule of the domain that must hold after every change, identified as `I<n>` in its spec and bound to a test whose name starts with `S<nn> I<n>`, in any case, with spaces or underscores. Invariants of the whole product live in `S00`, a spec that never closes. |
| Decision | A choice that constrains code, recorded as an ADR. |
| Task | One deliverable, derived from a spec or filed directly. |
| Chain | An ordered sequence of tasks that touch the same files. Chains run in parallel; tasks in a chain run in order. |
| Ledger | The durable record of the state and of every transition, readable by agents as text. The reference toolset keeps it as files in git. |
| Event | One transition of an entry of the ledger, with its time, its scope and its writer: a task filed, started, closed; a spec approved; a change landed or ejected (`land.ejected`). |
| Scope | Whom an entry or an event belongs to: an organization, a team, a project or a person. |
| Anchor | The file, path, spec or ADR an entry of memory depends on. |
| Coordinator | Whoever decides which task starts, when and with which agent: the lead, or a person. |
| Retrospective | The review of one cycle, every two weeks: the core numbers, the rules of the previous cycle, the ideas, and the proposals that follow. The owner decides each proposal. The `retro` skill runs it. |
| Workspace | An isolated copy of the code where one chain runs, on its own branch. The reference toolset uses a git worktree; a container or a cloud agent's machine serves the same purpose. |
| Owner | The person accountable for one artifact. Each artifact has exactly one. |
| Lead | The agent session that turns specs into tasks, briefs agents, verifies and lands. |
| Main | The shared line every change lands on: `main` in the reference toolset. |
| Gate | The conditions a change satisfies before it reaches `main`: `CHECK_CHANGE` green on its branch, `CHECK_GATE` green on the round, no open `must-fix`, a person for each irreversible action. `CHECK_RELEASE` guards a release, not the gate. |
| Integrator | The one process per repository that moves `main` (`xs integrate`): it takes the delivered branches in rounds and lands or ejects each. |
| Ejected | Returned by the integrator, or held back by the forge's merge train, intact, with a `land.ejected` event and its reason: `conflict`, `red` or `moved`; from a forge also `changes-requested` or `closed`. |
| Landed | Present on `main`, with the gate satisfied. |

## 2. Roles

### People

| Role | Does | Never |
|---|---|---|
| Owner | states intent, sets the quality bar by reference, answers numbered questions, approves specs and irreversible actions, performs the actions agents cannot (captcha, login, 2FA, cloud console) | runs a command an agent could run; carries data an agent could read |

### Agents

| Role | Model | Does | Never |
|---|---|---|---|
| Advisor | strongest, its own session | reasons with the owner: challenges the idea, retrieves prior work, drafts the spec; during the work, answers any question of the owner with a full view of the ledger, the code and the running work, and records decisions and ideas in the ledger | briefs agents; edits source code; approves its own draft |
| Lead | strongest, one session | routes requests and discoveries, derives tasks from specs, briefs agents, verifies their work, lands it, reports | trusts a result it did not check |
| Researcher | fast | answers neutral factual questions about existing code, with file and line | proposes a design |
| Implementer | fast | builds one task in its own workspace, with tests, and runs the result; fixes the findings routed to patch | pushes, merges, touches `main` |
| Reviewer | strongest, high effort | reads the diff without prior context, reports findings by severity; on a breaker brief, attempts to break the result | edits code |
| Curator | strongest, its own session, unattended | reads the diff that made each memory entry stale and recommends to keep, amend or retire it (`xs recommend`, `xs propose --replaces`); proposes each correction of the owner that no session recorded; when its brief asks for a bootstrap, proposes at most ten items from git history: architecture questions, domain terms, tasks for rules no test binds | promotes or retires entries, edits `AGENTS.md`, `DESIGN.md` or `CONTEXT.md`, copies transcript text into the ledger, describes what the code does, edits code |

`skills/researcher`, `skills/implementer` and `skills/reviewer` define the three agent roles; `adapters/<tool>/` holds what one tool needs beyond the standard, such as role definitions with their model and tools. The lead, the advisor and the curator run as skills, in separate sessions: the lead in the main session, because only the main session spawns agents; the advisor in a session of its own, because it converses with the owner; the curator in a session of its own, unattended, because its context starts empty each run.

- **Ask about running work in the advisor, never in the lead's session.** The advisor reads the ledger, the code and the open branches; the lead keeps its context for the chains. (P1; level 3) Evidence (E01): "where are we?" was among the commonest prompts; none for the separation.

- **Grant each agent only the tools its Never column allows.** A reviewer without write tools cannot edit code. A tool limit prevents mistakes, not misuse: an agent with Bash can still write files, so the guard hook of the adapter denies the researcher every command outside a list that reads, and the reviewer every write outside a temporary directory and every git command that changes the repo. The guard reads a tool call as JSON (`tool_name`, `tool_input`, `agent_type`) and answers allow, ask or deny: a client that drives agents over the Agent Client Protocol answers each `session/request_permission` with it, so the same rules hold for every agent. (P6; level 2) Evidence: none.
- **Set model and effort on every spawn.** The guard refuses a general-purpose spawn without a model and gives one without an effort `medium`. (P1; level 2) Evidence (E04): teams at default effort reached the usage limit more than once in a night; in one project 90 spawns of 108 had no effort.
- **Execute a change with no risk signal in the lead session, without a team**: a team costs time and tokens a small change does not repay. It is filed, started and closed with `xs`, and lands with `land`, like every change. (P1, P4, P5; level 2) Evidence (E04): one five-hour window held a handful of full cycles.
- **Establish agent access before the work**: read-only credentials, an MCP server, a sanitized dump. Where access is impossible, deliver one paste-ready command and read its output. (P1; level 1) Evidence (E05): tens of thousands of lines of production data were pasted by hand in a month.

## 3. Ledger

Every durable fact lives in the ledger, each fact in one place with one writer. (P2) Evidence (E06): plans carried between sessions by copy and paste went missing.

A store is the ledger when it is: (1) append-only and durable: an event is never changed or lost, a wrong one is cancelled by a later one; (2) identified: each entry has an id that is never reused; (3) atomic on claims: two writers cannot claim the same entry; (4) written by the tool: each event is stamped by the tool that runs the transition, with its time and its writer, never typed by an agent; (5) the source of state: the state of every entry derives from its events alone, and agents can read it as text; (6) anchored to the code: a `landed` event names the commit on `main`. For each kind of event it names the one source that holds it: the store itself, or a forge, a pipeline or an incident tool it reads. The ledger is not on the line of the code: `main` holds the product and its decisions, and a change of state never moves it. (P2, P5) Evidence (E36): with the state in files on `main`, statuses drifted outside the vocabulary and few tasks ever recorded `doing`.

The reference toolset keeps the ledger on `xs-ledger`, a branch with no history in common with `main`, checked out once at `.xs/ledger` and committed only by `xs`, one commit per command. Agents may edit the text of a task or an entry there; `xs` commits it with the next event about it. `xs status` prints the state of every entry. In a team, `xs` pulls the ledger before each command and pushes it after. A database, or a tracker with a text view, qualifies as well when it has the six properties; the tables below name the paths of the reference toolset.

| Artifact | Path | Holds | Writer |
|---|---|---|---|
| Spec | `project/specs/S<nn>-slug.md`, on `main` | outcome, requirements, invariants, decisions | its owner; changed through a branch and `land`, like code |
| Log of a spec | `logs/S<nn>.md`, in the ledger | dated lines: approvals, decisions, discoveries, deviations | the lead, with `xs spec <id> approved\|deviated\|noted` |
| Task | `tasks/T<nn>-slug.md`, in the ledger | one deliverable and its proof; no state | the lead files it, the worker writes its Done section; its state only through `xs` |
| ADR | `project/adr/NNNN-sentence.md`, on `main` | one decision that constrains code, frozen whole | the lead, on the owner's answer; its state only through `xs adr` |
| Rules | `AGENTS.md` | rules of the repo, numbered | the lead, on the owner's approval |
| Ideas | `IDEAS.md`, in the ledger | ideas not yet decided, one dated line each, with its source | the advisor; the owner removes a line when it becomes a request or is dropped |
| Events | `EVENTS.log`, in the ledger | every transition, one append-only line each: `<at> <scope> <subject> <kind> key=value ...`; the state of every entry derives from them | `xs`, run by the owner, the lead, the agents and the hooks; the integrator; for releases and incidents, `xs` until a pipeline or an incident tool writes them. [docs/reference.md](docs/reference.md#the-ledger) lists every kind |
| Metrics | `project/METRICS.md` | the core numbers of §10, one row per cycle | the retrospective, from `flow` |
| Learnings | `learnings/L<nn>-slug.md`, in the ledger | an entry of memory proposed for a destination: its text, kind, scope, anchor and evidence | `xs propose`; its state only through `xs` |
| Preferences | one file of the person, outside every repo, referenced by each provider's configuration | preferences of one person across repos, accounts and providers | that person, or an agent on that person's word |
| Recalls | `~/.xs/events.log`, local | one `learning.recalled` per read of an entry; never in git | `xs load`, `xs search` |

### Specs

- **Edit the spec, never the task derived from it.** Regenerate or amend the tasks after the edit. Ids `R<n>` and `I<n>` are stable and never reused. (P2; level 1) Evidence: none.
- **Never reopen a `done` spec.** A later change gets a new spec that cites it; the invariants stay in force through their tests. (P2; level 1) Evidence: none.

### Tasks

- **Record side work and deferred work as a task.** Never as a code comment or a line in a document. (P2; level 1) Evidence (E08): one repo kept zero TODO comments.
- **Record an idea in `IDEAS.md` of the ledger with `xs idea`, never in an agent's memory.** An idea is not yet work: it becomes a task only when the owner makes it a request. (P2; level 3) Evidence (E18): memory files listing open work were wrong within a day; (E08): p3 tasks rarely closed.
- **Set `priority` when filing**: `p0` for an incident, `p1` to `p3` for the rest (`tasks/README.md` of the ledger). (P1; level 1) Evidence (E08): most p1 tasks closed within a day; almost no p3 task did.
- **Change a task's state only through `xs`**: `file`, `start`, `close`, `block`, `drop`. Each records its event in the ledger; a task file holds no state, and `xs` refuses one that does. The states are `todo`, `doing`, `blocked`, `closed` (finished, its proof written, not yet on `main`), `done` (landed, or closed with nothing to land: no branch, or a branch already on `main`) and `dropped`. (P2, P6; level 3) Evidence (E36): about 40 of 350 tasks ever recorded `doing`; 36 held a status outside the vocabulary.
- **Start a task only as its coordinator, with `xs start`**: it records the claim in the ledger and creates the workspace from `main` in one step, and does nothing more when run again. The worker never changes the task's state, except to close it. A task whose `after:` tasks are not yet done or dropped is not ready: `xs next` does not list it, and `xs start` refuses it, unless the task before it is doing or closed on the same branch, the chain it continues. In a team, the claim counts once the ledger is pushed; a claim pushed first by another clone refuses it. (P2, P5; level 3) Evidence: none.
- **Close the task with `xs close` once its Done section holds the proof**: the command that proves it, cited by test name. `xs close` refuses a task without a Done section, or with a type or priority outside the vocabulary. The task is `done` when the integrator lands its branch; the `landed` event names the commit. (P3; level 1) Evidence (E09): one file path in six moved within three days.
- **Split by deliverable, not by finding.** (P1; level 1) Evidence (E10): one task per finding filed about twice the tasks the work needed.
- **Cite the requirements and invariants the task serves** in its `spec` field. (P2; level 1) Evidence: none.
- **Review p3 tasks weekly: promote or close.** (P5; level 3) Evidence (E08): almost no p3 task closed on its own.
- **Assign numbers from one source.** Tasks and entries take theirs from the ledger, which `xs` numbers; specs and ADRs from `next-id`, which reads every branch. (P5; level 2) Evidence (E13): renumbering commits every day; ids with two meanings.

### Decisions

- **Ask numbered, decidable questions, each with a recommendation. Record the answer as an ADR in the same turn.** File the question with `xs ask` and close it with `xs answer`. (P1; level 1) Evidence (E07): ADRs landed within minutes of the answer.
- **Write an ADR only for a decision that two chains could make incompatibly**, or that constrains architecture, data, contracts or behaviour users rely on. Layout and copy belong in the design document; progress belongs in tasks. (P4; level 1) Evidence (E14): over a hundred ADRs in a few weeks, many about UI; agents searched them instead of reading them. Against it (E35): in a new project, the ADR rules of this section still produced ten ADRs on the first day; they have not yet prevented E14.
- **Freeze the ADR whole.** Its status, `Built` and `Amended by` are events, recorded with `xs adr <nnnn> proposed|accepted|amended|built|retired` and read with `xs status ADR-<nnnn>`. A changed decision is a new ADR. (P2; level 1) Evidence (E15): "never edit" was broken in every repo that had it, through the header that stayed editable.
- **Rely on an ADR only when it is built: yes** (`xs adr <nnnn> built "yes (T<nn>)"`). (P3; level 1) Evidence (E16): code relied on an unbuilt decision; an audit found a data-loss bug.

### Rules of the repo

- **Keep `AGENTS.md` to numbered rules, one copy each.** Knowledge belongs in the project documents (`ARCHITECTURE.md`, `DESIGN.md`, `CONTEXT.md`, created when first needed) or in an ADR. (P2; level 1) Evidence (E17): a rules file of hundreds of lines; two copies of one invariant diverged.
- **State each rule with an observable trigger.** (P6; level 4) Evidence: none.
- **Keep a rule that works. Remove a rule that a check now enforces.** An audit never lengthens the file. (P6; level 4) Evidence: none.
- **Classify what you learn before writing it.** Write directly only a preference of your person. Propose every other kind to its destination with `xs propose`, with its anchor and its evidence: a rule to `AGENTS.md`, a design rule to `DESIGN.md`, knowledge to `CONTEXT.md`. A decision is a question (`xs ask`), an idea goes to `IDEAS.md`, status goes to a task. (P2, P6; level 4) Evidence (E18): memory files listing open tasks were wrong within a day; (E38): a week of an agent's memory held no preference of the person alone.
- **Promote an entry only on the word of the owner of its destination** (`xs promote`). The advisor presents the queue (`xs queue`) with the questions. (P1, P2; level 4) Evidence: none.
- **Treat an entry marked stale as unverified.** `land` marks an entry stale when the change touches its anchor; its owner confirms it with `xs promote` or removes it with `xs retire`. The curator records how to resolve each (`xs recommend`, or `xs propose --replaces`, whose promotion retires the stale entry), and `xs queue` shows it. (P3; level 4) Evidence (E18); none for the curator.
- **Load rules and preferences whole, by scope, at the start of a session**: the organization, the team that owns the project, the project, the person. A narrower scope overrides a wider one only where the wider rule says so. (P2; level 4) Evidence: none.
- **Read the ledger through its loading and its search** (`xs load`, `xs search`), so that every read is recorded as a recall. (P2; level 4) Evidence: none.

### Memory between agents

Agents do not communicate with each other. The ledger carries the memory; the lead transfers it.

- **Append to the Log of the spec** each decision, discovery and deviation, as one dated line, with `xs spec <id> approved|deviated|noted "line"`. Never edit a line. The Log lives in the ledger, so no chain ever conflicts on it. (P2; level 1) Evidence: none.
- **Route point 5 of every report before the next spawn**: each item becomes a task, a rule or a Log line. (P2; level 2) Evidence: none.
- **After a compaction, restore the state from `xs status`, the Log and the task files**, not from the chat. (P2; level 1) Evidence (E06).
- **Accompany every id with five to ten words, and every closed decision with its answer.** (P1; level 1) Evidence (E19): bare ids were not understood; one decision was taken twice.

## 4. Definition

Every request changes an existing system; a new feature is a change to an empty one. Definition is the phase before launch. Its output is a spec that satisfies the readiness gate.

### Routing

Evaluate three signals for each request:

1. **Intent gap**: the outcome or its boundaries are not stated.
2. **Wide footprint**: the work spans more than one module, service or chain.
3. **Invariant touched**: the work changes code bound to an invariant. Search the invariant tests, named `S<nn> I<n> ...`, that cover the modules the work touches.

An irreversible action is not a signal: it stops for a person on every route (§6).

- **When a signal cannot be ruled out, it holds.** (P4; level 1) Evidence: none.
- **With no signal, file a task and build.** Mark each guess `[ASSUMPTION]` in the task; list the assumptions in the report for confirmation. (P4; level 1) Evidence: none.
- **With one or more signals, write a spec first.** (P4; level 1) Evidence (E20): a team built for hours before "stop everything, we're off the idea".
- **Route each task an agent discovers before the next spawn.** With no signal it enters the backlog as `todo`; with a signal it becomes a `decision` task for the owner of the artifact. (P4; level 2) Evidence: none.
- **Run the first task of a new pattern attended**: the first task that adds a dependency, a module or a data path. Launch the remaining tasks of that pattern after the owner has seen the first result. (P4; level 2) Evidence: none.

### Steps

1. **Pair.** The owner reasons with the advisor, in its own session. The advisor challenges the idea, asks numbered questions, each with a recommendation, and retrieves prior work across projects, documentation and papers, until the outcome and the boundaries are stated.
2. **Research.** For existing code, brief a researcher with neutral factual questions. Exclude the intended change from the brief. Require file and line for each answer.
3. **Draft.** Write the spec on one page. Mark each guess `[ASSUMPTION]`. Settle each open item with a question to the owner, a spike of at most 20 minutes, or a task.
4. **Fix.** Record each invariant with its test. Record as an ADR each decision that two chains could make incompatibly.
5. **Split.** Derive the tasks, each citing its `R<n>` and `I<n>`. Group them into chains. Reserve the ids.
6. **Check the gate.**

Evidence for steps 1 and 2: none. Evidence for step 4 (E21): without invariants, review loops ran three rounds and each fix introduced new bugs.

### Spec format

`project/specs/S<nn>-slug.md`, one page:

| Section | Content |
|---|---|
| Header | `owner`; the status (`draft`, `ready`, `done`, `dropped`) is in the ledger, set with `xs spec <id> ready\|done\|dropped` |
| Outcome | the observable result, in two or three sentences; for existing code, what changes from what is there |
| Boundaries | what is excluded |
| Requirements | `R<n>`: one verifiable statement each |
| Invariants | `I<n>`: the rule, the reason, the name of the test, which starts with `S<nn> I<n>` |
| Decisions | the ADRs this spec depends on or produced |
| Open | unresolved items, each with its route |

The Log of the spec, dated lines and append-only, lives in the ledger (§3).

### Readiness gate

A spec is `ready` when every condition holds:

1. The outcome and each requirement are verifiable by someone who did not write them.
2. Each invariant names a test. A missing test is a p1 task placed first in its chain, built by an implementer that does not build the feature.
3. No `[ASSUMPTION]` remains unconfirmed, and no open item awaits the owner.
4. Each decision that two chains could make incompatibly is an accepted ADR.
5. The owner has approved, recorded with `xs spec <id> approved`: a dated Log line and its event. A repo may waive this condition with `Spec approval: none` in `AGENTS.md`; the default is `owner`.

`xs spec <id> ready` refuses a spec that fails what the text can show, and lists every failure: an empty outcome, a requirement with no id or with a word such as "fast", an invariant with no test named `S<nn> I<n>`, an `[ASSUMPTION]`, an open item with no route, a decision with no accepted ADR, no approval by the spec's owner. Whether the outcome is verifiable by someone else stays a judgment. (P3; level 3) Evidence: none.

Approval of the spec is the principal human decision in XS, at any hour: a spec drafted while the owner is away waits for approval, and the team takes the next approved work. After it, the work proceeds without a person until an irreversible action (§6), a decision the spec did not settle, or the first task of a new pattern.

### By kind of work

- **New or unclear UI, product or concept**: build a prototype with at most four options, as a task like any other (`xs file --type prototype`). The owner selects one by answering a decision task (`xs ask`, `xs answer`); the spec that builds it cites that task. (P4; level 1) Evidence (E12, E20): long UI specs went stale within hours; a sketch would have caught the error in ten minutes.
- **Live UI iteration with the owner** is one task: open it, iterate, close it with screenshots as proof. A new component or pattern updates the design document. (P4; level 1) Evidence: none.
- **Stateful logic** (sync, money, parsers): start no other task of the chain before its invariant tests have landed. (P4; level 1) Evidence (E21).
- **Migrations**: build a parity harness against the old code. Keep the old path as default behind a flag until parity holds. (P3; level 1) Evidence: practice observed.
- **Features that cross services**: the agent writes the flow as it understands it; the owner corrects it. (P4; level 1) Evidence (E22): a multi-day build failed on a call chain the owner knew.
- **Spikes**: limit each to 20 minutes. (P4; level 1) Evidence (E23): untimed spikes took hours and were deleted.
- **Evals that decide**: use sets of real size, scored by code, with a held-out set, written by a different agent from the one scored. (P3; level 1) Evidence: none.

## 5. Isolation

- **Give each chain its own workspace and branch.** The reference toolset creates a git worktree under `.xs/worktrees/<branch>`. (P5; level 2) Evidence (E24).
- **State the repo folder, the base branch and the landing target before any work.** (P5; level 2) Evidence (E24): wrong folder or branch was among the commonest causes of rework.
- **Commit explicit paths and run formatters on named files.** A tool with hooks enforces both through its adapter's `guard`; `template/AGENTS.md` states them for every agent. (P5; level 2) Evidence (E25, E26): broad commits included another session's work; one `--write` with an empty file list rewrote hundreds of files.
- **Run one dev server per agent, on its own port.** Never stop a server another agent started: kill the PID you started, never a name; the guard denies `pkill` and `killall`. (P5; level 2) Evidence: one `pkill -f` stopped the demos of other sessions.
- **Keep client code and data outside the repo from the first day.** (P5; level 1) Evidence (E27): one product required several history rewrites.

## 6. Verification

### Proof

- **Ship with every fix a test that fails without it.** Revert the fix once to confirm. (P3; level 1) Evidence (E29).
- **Run what was built**: the browser at the target width and in both themes, the built app, a real sample. State in every report what was not verified. (P3; level 1) Evidence (E28): "I did not open a browser" was among the commonest lines in reports.
- **Run a mutation check on each new invariant test**: violate the invariant once in the workspace, confirm that the test fails, restore the code, and record one Log line in the spec (`xs spec <id> noted`). A test that survives the violation does not protect the invariant. (P3; level 1) Evidence: none; the same proof as reverting a fix once.
- **Close a spec only when each invariant test it names exists on `main`.** `xs spec <id> done` refuses otherwise. (P3; level 1) Evidence: none.
- **Rerun the checks of the change in the lead session before delivering it.** (P3; level 2) Evidence (E29).
- **Take numbers from code, never from a model's summary.** (P3; level 1) Evidence: none.
- **Reuse the design system.** A new component is a change to the design document. (P2; level 1) Evidence: none.

### Review

- **Review every change with an agent that did not write it**, on a stronger model, read-only. (P3; level 1) Evidence (E29): reviews found must-fix bugs the tests had missed.
- **Triage each finding before fixing.** Reproduce it; rate it `must-fix`, `should-fix` or `nit`; route it: patch, defer to a task, or ask the owner. Dismiss a finding only with a written reason. (P3; level 1) Evidence: none.
- **Stop after three review rounds on one change.** A third round with must-fix findings indicates a defect in the spec: return to Definition. When the owner is not there to answer, block the rest of the chain and continue with another chain. From level 3 the lead records each round with `xs review <task>` and its verdict with `xs reviewed <task> approve|changes --must-fix <n>`: `xs` counts the rounds, so the third is read from the ledger, not remembered. (P4; level 1) Evidence (E21) shows the loops; the limit of three comes from BMAD and is not measured.

### Gate

The gate is autonomous: no person approves the merge, because the approval took place on the spec. Three checks, commands of the repo, are each named by what it guarantees:

| Check | Guarantees | Runs |
|---|---|---|
| `CHECK_CHANGE` | the change stands on its own: lint, types, the tests of what it touches | on the branch as it is, at delivery |
| `CHECK_GATE` (default `make check`; `CHECK` is its old name) | `main` stays whole: every test, every invariant test | once per round of the integrator, before `main` moves |
| `CHECK_RELEASE` | the whole system behaves as promised to its users: end to end, migrations on sample data | on `main`, before a release; never by the integrator |

A change reaches `main` when every condition holds:

1. `CHECK_CHANGE` is green on its branch, and `CHECK_GATE` on the round of the integrator that carries it.
2. An independent review reports no open `must-fix`.
3. A person has approved each irreversible action in the change.

- **Put each test in the check of what it protects, not of how long it takes.** (P3; level 2) Evidence: none.

- **Stop the line when `main` is red.** A red `main` blocks every agent, so it is an incident: `xs incident open main-red "<check>" --sev 2` and a `p0` bug task, `xs file --type bug --priority p0`. Nothing else is delivered until `main` is green; the integrator would eject every branch as `red` anyway. The fix goes through the gate like any change, and `xs incident resolve main-red` records the time to restore. A failure in production follows the same rule with its severity. (P5; level 2) Evidence: none.

  | Severity | When | Priority |
  |---|---|---|
  | `--sev 1` | the product fails its users, data is at risk, or security is breached | `p0` |
  | `--sev 2` | `main` is red, or a core flow fails for some users with no workaround | `p0` |
  | `--sev 3` | a flow is degraded and a workaround exists | `p1` |
  | `--sev 4` | a minor fault | `p2` |

- **Require a person for every irreversible action**: a migration or deletion of live data, a release or publication, a rewrite of history, a change to a public contract, an expense. This rule has no opt-out. (P4; level 1) Evidence (E27).

## 7. Landing

- **Land every finished task in the same session**, or state that it is not landed and where it is. (P5; level 2) Evidence (E30): "is it on main?" recurred in almost every project.
- **Commit what agents left uncommitted.** (P5; level 2) Evidence: none.
- **Deliver every change with `land`; the worker never waits for the gate.** `land` runs its refusals and `CHECK_CHANGE` on the branch as it is, without a rebase, and queues the branch. A worker delivers with `land --queue`, which returns at once, and takes its next task; plain `land` waits for the outcome. With pull requests, the forge records the merge. (P3, P5; level 2) Evidence (E30).
- **Move `main` only through the integrator, one per repository.** The guard denies a merge, rebase, cherry-pick or pull on `main` and any command that sets `main` by hand. Each round, in a workspace of its own:
  1. Put every queued branch, in order, on top of `main`, at the commit `land` recorded in the queue: the branch's tip when `land` ran, before `CHECK_CHANGE`. Eject a branch whose ref no longer points to that commit, moved or deleted since `land` (`moved`): what it points to now passed no check. Eject a branch that conflicts. The pin holds against an agent that can write refs but not the queue: the guard must deny agents every write to `xs-queue` and `xs-integrate.lock` in the git directory. `land` pins what it delivers, not what the review approved: the lead runs `land` on the commit the review saw.
  2. Run `CHECK_GATE` once on the round.
  3. Green: fast-forward `main` to the round, a compare-and-swap that fails if `main` moved meanwhile; rebuild the round and retry, three times at most. Only code moves `main`, with the marks of the entries of memory whose anchor the round changed. Record one `landed` event per task the round lands, in the ledger. Remove the workspace and the branch of what landed, unless its ref moved during the round: then keep both, and say so.
  4. Red: try the first half alone and leave the rest for the next round, down to the branch that fails. Eject it with the log of the gate.

  (P3, P5; level 2) Evidence: none.
- **Hand an ejected branch back to its chain.** An ejection records `land.ejected` in the ledger with `reason=conflict`, `reason=red` or `reason=moved` and leaves the branch intact; its task stays `closed`. The lead gives it to an implementer with the conflicting files or the log of the gate, then delivers it again. A `moved` branch is reset to the commit `land` delivered (`git branch -f <branch> <commit>`, both in the reason) or reviewed again, since someone wrote its ref after `land`. A task ejected twice is blocked with `xs block`, never delivered a third time. (P5; level 2) Evidence: none.
- **Confirm with `xs where` that no finished work remains unlanded**: it lists the tasks closed and not on `main`, and why an ejected one was ejected. (P5; level 2) Evidence (E30).
- **Read the commit conventions from `AGENTS.md`**: identity, trailers, signing. Resolve signing before a team is left running. (P1; level 2) Evidence (E32).
- **Develop on the trunk.** Every branch lives for one task or one chain and reaches `main` through `land`, at any hour; no long-lived integration branch collects work before `main`. (P5; level 2) Evidence (E40).
- **With a forge, `land` uses its merge train**: it pushes the branch, opens the pull or merge request, and queues it in the forge's merge queue (GitHub) or merge train (GitLab), which rebuilds and gates each candidate on top of the ones ahead of it as the local integrator does. The line `Merge train: github|gitlab` of `AGENTS.md` chooses it (`LAND_FORGE` overrides it). The forge moves `main`, so `xs sync` records a `landed` event for each closed task whose branch the forge merged, and a `land.ejected` event, with the reason, for each request the forge holds back (`red`, `changes-requested`, `conflict`, `closed`); run it before each report. (P5; level 2) Evidence: none.

## 8. Reporting

- **Report in the owner's language, in plain words.** (P1; level 1) Evidence (E19).
- **Use one status format, one line per item**: landed, running, waiting for you (numbered decisions, each with a recommendation), new tasks (with priority). "Waiting for you" is a view, not a status: the open decision tasks and the blocked tasks that wait for the owner (`flow` counts them as "waiting for the owner"). (P1; level 1) Evidence (E01, E07).
- **Record each agent's life as events, the same for every tool**: `agent.started` (tool, model, effort, role, the session's id), `agent.stopped` (why, and when a usage limit resets, with the id of the job that resumes), `agent.finished` (the task's state). `xs start --run` and the adapters' hooks write them; the lead writes them with `xs agent` where no hook exists. The reasons of a stop are those of the Agent Client Protocol (`end_turn`, `max_tokens`, `max_turn_requests`, `refusal`, `cancelled`) and three it does not carry: `limit`, `error`, `killed`. `xs status` shows what runs and what stopped; with `OTEL_EXPORTER_OTLP_ENDPOINT` set, each run also goes out as an OpenTelemetry span named by the GenAI conventions. The owner reads the status and never asks for it; the lead writes one line only when it changes. (P1, P2; level 2) Evidence (E39).
- **Hand a task over through the ledger, never through a chat.** A session that stops before its task is done (its credits run out, the owner moves it to another account or tool) runs `xs handoff T12 --next "<step>" --open "<request>"...`: the brief, the branch's head and the uncommitted work as a patch go into the ledger, with each request of the owner not yet done. The next session, in any tool, runs `xs takeover T12`, which prepares the worktree, applies the patch and prints the brief. The same tool may resume the session itself (ACP `session/load`); another tool starts from the brief. A session that stopped without a handoff is taken over by the lead from its transcript. (P2; level 2) Evidence (E41).
- **Close a spec with its sign-off lines**: the risk (`low`, `medium`, `high`, by fixed criteria, with the reason), the size in numbers, the trust boundaries crossed and what was checked about them, what was not checked, and the trade-offs made for the owner. The reviewer rates risk and security on each change; the lead joins them, in at most two lines, because the technical sign-off is a person's. (P1, P3; level 1) Evidence: none.
- **Report what changed since the last report** (`xs status --since <time>`), in the format above. (P1; level 1) Evidence (E01).
- **Publish long reports as a page**, not in the chat. (P1; level 1) Evidence (E19).
- **Save screenshots to a file and pass the path.** Images pasted to the lead do not reach other agents. (P2; level 1) Evidence: none.

## 9. Leaving the factory running

The factory runs at any hour with the same flow. These rules apply whenever a team works while no person answers.


- **Launch only with a target scored by code.** (P3; level 3) Evidence (E31): runs with a numeric target delivered; runs without one returned UI to redo.
- **Run `xs where --preflight` before leaving a team running**: disk, Docker, sleep prevention, signing, a green base. Confirm the permission mode and the model quota by hand. (P4; level 3) Evidence (E32).
- **Set a budget**: the cycles that fit the usage window and the agents that run at once. (P1; level 3) Evidence (E04).
- **Schedule the resume after the usage reset as a job, and give its id in the report.** A resume promised and not scheduled does not happen. (P1; level 3) Evidence (E32): a limit reached in the night left the team idle until morning, twice, once after the owner had asked for the resume.
- **Record a blocked task with `xs block` and a saved patch**, block the tasks after it in its chain, then continue with another chain. Leave the workspace in place; never discard its changes. (P5; level 3) Evidence: none.
- **Report on one page when the owner returns** (`xs status`): what landed and is green, what awaits a decision, which tasks were filed, the curator's queue, and each core number of `flow` that moved. (P1; level 3) Evidence (E11, E37).

## 10. Improvement loop

The method improves itself: transcripts produce rule proposals, the owner approves them, and the core numbers measure the effect.

- **Convert a correction given twice into a rule on the same day**, at the scope it belongs to: proposed with `xs propose` for an organization, a team or a project, in the person's preferences for the person, in a skill for a procedure, in a hook for a prohibition. A correction an existing entry should have prevented is recorded with `xs repeated`. (P6; level 4) Evidence (E33): one rule was taught again in several repos.
- **Convert a correction repeated after its rule exists into a check**: a lint rule, a test, a hook, a line in the reviewer definition; then record it with `xs checked`, which removes the entry from its destination. (P6; level 4) Evidence (E34): one written rule was corrected several more times in two weeks.
- **Run the retrospective (`retro`) every two weeks**, and record in `project/METRICS.md` the core numbers that `flow` computes, each with its coverage: owner prompts per landed task; lead time from filing to `main`; questions waiting for the owner; bugs filed per landed task; tasks filed per task closed; spec deviations per approved spec; corrections repeated after their rule exists. (P3, P7; level 4) Evidence (E01, E37); none for the cadence.
- **Run `flow` before every report**, and name a core number only when it crossed a threshold or moved since the last report, as a question for the owner. (P1, P7; level 3) Evidence (E37): the numbers showed on day five and day eight what a two-week cycle would have reported on day fourteen.
- **Take every number from the ledger's events**, computed by `flow`, with its coverage. Never from a date an agent typed or a model's summary. (P2, P3; level 3) Evidence (E36).
- **Read every other measure only to explain a core number that moved**: `flow --explain`. (P1; level 3) Evidence: none.
- **State no threshold in the protocol.** The owner sets each in `AGENTS.md`, from the project's earlier cycles, and revises it at the retrospective. Without one, the retrospective explains the slowest tenth. (P7; level 3) Evidence: none; a fixed target was rejected for depending on team, project and moment.
- **Never brief an agent with a process number as its goal.** A target scored by code (§9) scores the product, not the process. (P7; level 3) Evidence: none.
- **Aggregate by project, team or organization; never by person or agent. Compare a team with its own past.** (P7; level 3) Evidence: none.
- **Sort `IDEAS.md` of the ledger at each retrospective.** The owner turns each idea into a request, keeps it, or drops it; a request goes through routing like any other. (P2; level 4) Evidence: none.
- **Submit every proposal to the owner. The retrospective and the curator propose; a person decides.** Proposals may target `PROTOCOL.md`, the agents and the skills. (P1; level 4) Evidence: none.

The numbers have limits. Owner prompts count prompts, not reading time: they do not yet measure the attention a spec or a report costs. Lead time starts at filing, not at the need. Bugs per landed task stand for the change failure rate until `xs release` and `xs rollback` record a production. Time to restore, a diagnostic of `flow --explain`, covers only the incidents recorded with `xs incident`. Cycle time covers only tasks started with `xs start`.
