# Evidence

The observations behind the rules of `PROTOCOL.md`, cited there as `E<nn>`.

Source: several weeks of building about a dozen products with Claude Code, from desktop apps to open-source libraries, compared with earlier work on the same kind of products with and without agents. The figures are rounded on purpose: they show the size of a problem, not a benchmark.

Limit: no rule for teams or organizations has been measured yet. Observations from other teams are welcome.

| # | Observation |
|---|---|
| E01 | Most prompts to the agents were short: "yes", "go on", "where are we?", "commit". "Where are we?" and "commit" appear once agents work in the background; count them per landed task, not in total. |
| E02 | The largest time sinks were not hard bugs: finished work nobody could find, agents overwriting each other, teams stopped by the usage limit during the night, repeated screenshot exchanges on screens the agent had never opened. |
| E03 | A year earlier, prompts named files and line numbers and carried pasted logs. With agents, prompts moved from stating how to stating what and how good. |
| E04 | Teams of the strongest model at default effort reached the usage limit more than once in a night. One five-hour window held a handful of full cycles of plan, implement, review and fix. |
| E05 | Over a month, tens of thousands of lines of production data were pasted by hand, because the agents had no access to it. |
| E06 | Before the ledger, plans travelled between sessions by copy and paste and went missing. One strategy decision existed only in the memory of one session. |
| E07 | Decisions asked as numbered questions with a recommendation were recorded as ADRs within minutes of the answer. Badly formed questions came back as "I didn't understand". |
| E08 | A repo with no TODO comments in its source answered "what next?" from its p1 list. Most p1 tasks closed within a day; almost no p3 task did. |
| E09 | File paths cited in Done sections moved within days; test names did not. |
| E10 | Reviews and plans that filed one task per finding filed about twice the tasks the work needed. |
| E11 | One night closed as many tasks as it filed. |
| E12 | Without a status field, a repo lost track of what was built and needed an audit. Long specs held for backend contracts and went stale within hours for UI. |
| E13 | Branches each took "highest + 1" from their own view: renumbering commits every day, and ids with two meanings. |
| E14 | ADRs used as a UI and build journal grew to over a hundred in a few weeks. Agents searched them instead of reading them. |
| E15 | "Never edit an ADR" was broken in every repo that had the rule, sometimes by the owner's own decision. |
| E16 | An ADR committed as "Accepted" without its code led other code to rely on a property nothing implemented. An audit found a data-loss bug the next day. |
| E17 | A rules file grew to hundreds of lines, one incident at a time, and two copies of the same invariant diverged. Short files that refer elsewhere stayed accurate. |
| E18 | Memory files listing open tasks were wrong within a day. |
| E19 | Bare ids in reports were not understood. A gloss that named only the question led to the same decision taken twice. Long reports with jargon in the wrong language were a recurring time sink. |
| E20 | A team built a visualization for hours, through several critique rounds, before "stop everything, we're off the idea". A sketch would have shown the error in minutes. |
| E21 | On stateful logic without invariants or failing tests written first, review loops ran three rounds and each fix introduced new bugs. |
| E22 | A multi-day build across services failed on a call chain the owner already knew. |
| E23 | Untimed spikes took hours and were deleted. |
| E24 | Work in the wrong folder or on the wrong branch was among the commonest causes of rework. |
| E25 | Broad commits included another session's work more than once. |
| E26 | One formatter run with `--write` and an empty file list rewrote hundreds of files while other agents worked in them. |
| E27 | Client material that entered one repo required several history rewrites and restores from a backup. |
| E28 | "I did not open a browser" was among the commonest lines in agents' reports, and the source of days of polish rounds. |
| E29 | Independent reviews repeatedly found must-fix bugs the tests had missed. |
| E30 | "Is it on main?" recurred in almost every project. Finished work remained in worktrees. |
| E31 | The unattended runs that delivered had a target scored by code: a precision threshold, a token budget, a test suite. Those without one returned UI to redo. |
| E32 | A usage limit reached in the middle of the night left a team idle until morning. Disk, signing and sleep problems surfaced during the night. |
| E33 | Claude Code keys memory to the folder path: moving a repo orphaned its lessons. One copy rule covered UI text but not docs or subagents, and was requested again many times. Another was taught again in several repos. |
| E34 | A rule present in `AGENTS.md` from the first day was corrected several more times in the following two weeks. |
| E35 | In one project built with XS, ten ADRs were written on its first day. Two were rejected and replaced within hours and stayed as files beside their replacements; four were revised the same day; one held eleven settled points that were names and shapes, not architecture. Another repo of the same owner holds 131 ADRs. The ADR rules of `PROTOCOL.md` §3 reproduced E14 in a new project within a day. |
| E36 | In one product, about 350 tasks closed in two weeks; nine in ten closed in the same commit as their code, and only two of the 350 more than two hours after it. From filing to closing took half an hour at the median and over a day at p90, nearly all of it waiting before the first commit: p1 tasks under a day at p90, p3 tasks over a week, decisions up to eleven days. Only about 40 tasks ever recorded `doing`; 36 held a status outside the vocabulary, and 50 closed tasks had no closing date. 64 of 138 ADRs stayed Proposed. |
| E37 | The core numbers, computed from the events that the same product's git history held (about 1,700, imported in under a second), matched a hand analysis made on day sixteen and showed its findings a week earlier. Tasks filed per task closed stayed above one in every three-day window. Bugs filed per landed task rose from 0.27 to 0.67 by day eight and to 0.98 by day sixteen. Questions waiting for the owner grew from day five; ADRs proposed and not accepted from day eight, to 61. Cycle time was measurable on none of 400 landed tasks: git held no start. |
| E38 | In one product, an agent's memory held three entries after a week. None was a preference of the person alone: a project procedure, which belonged in `AGENTS.md`; a design rule the owner had given many times, which belonged in `DESIGN.md` and in a check; and the owner's writing guideline, which belonged to the person but was stored per project and per account, and was given again in another product the same week. The memory lived under one account's configuration, invisible to the owner's other accounts, other providers and teammates. |
| E39 | In one product, over five days, the owner asked for the state of the work 13 times in so many words and about 28 times counting indirect questions; eight agents stopped by a usage limit appeared in no status, and the promised resume after the reset was never scheduled. |
| E40 | In the same product, a long-lived night branch was merged into `main` by hand: two days of work left no `landed` event, and seven repair commits followed for checks the gate already ran. |
| E41 | In the same product, the owner moved a session to another account twice when its credits ran out: one session went on in two accounts, the request in progress was lost, and the next session rebuilt the state from the chat. |

## Time sinks by section

| Time sink | Section of `PROTOCOL.md` |
|---|---|
| Finished work left in worktrees; "is it on main?" | 7 |
| Wrong folder, branch or worktree | 5 |
| Agents in one tree breaking each other's files and tests | 5 |
| Teams stopped by the usage limit during a run | 2, 9 |
| UI exchanges on screens the agent never opened | 6 |
| A whole team building before the idea was agreed | 4 |
| Review loops on stateful code without invariants | 4 |
| The same correction repeated across sessions | 10 |
| Task numbers colliding between branches; work nobody could confirm as built | 3 |
| A person as the bridge to data agents could not read | 2 |
| Client code entering history | 5 |
| Long reports with jargon in the wrong language | 8 |
| Disk, signing or sleep problems found while no one answered | 9 |
| The state asked for by hand; work lost when a session moved to another account | 8 |

## Sources of the unmeasured rules

- BMAD method (`bmad-code-org/BMAD-METHOD`): finding triage and the three-round limit, neutral research questions, the `[ASSUMPTION]` marker, the test for a shared decision, the maintenance rules of `AGENTS.md`, the plan read by dependent work, the review of a whole batch.
- Extreme Programming: the name and the idea of turning a practice that works up to the maximum.
- DeepSeek [dsh-superagent](https://github.com/deepseek-ai/dsh-superagent-prototype): the criterion of judging each part by the human attention it costs.
