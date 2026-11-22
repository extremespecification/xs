---
name: retro
description: Run the retrospective of one cycle of Extreme Specification (XS). Distill from the transcripts of the agent sessions the corrections that repeat and the points where sessions stalled, measure the cycle with flow, check the rules of the previous cycle, sort the ideas, and propose rules for AGENTS.md, memory, skills, hooks or the method itself. Use every two weeks, or when the owner asks for a retrospective, to review past sessions, find recurring corrections, or asks "what do I keep repeating?".
compatibility: Requires python3. The transcript reader, scripts/digest.py, reads one tool's format today (Claude Code, ~/.claude/projects); for another tool, export its sessions to that format or add a reader. The rest of the procedure applies to any tool.
---

# Retro

The retrospective reviews one cycle: what the transcripts show, what the core numbers say, whether the rules of the previous cycle worked. The transcripts of the agent sessions record how the work went (for Claude Code, under `~/.claude/projects/`). Steps 1–4 distill them into rule proposals; steps 5–9 review the cycle. The curator (`skills/curator/`) handles the stale entries of memory and the corrections of each day; the retrospective handles the method. Run it every two weeks (`PROTOCOL.md` §10).

Claude Code deletes transcripts after 30 days unless `cleanupPeriodDays` in `~/.claude/settings.json` says otherwise: set it high before you need the history. Older periods survive in two places: `~/.claude/history.jsonl` (every prompt the owner typed, with project and time, no replies) and each repo's git history.

1. **Distill.** `python3 <this skill>/scripts/digest.py --out <scratch>/digest`, with `--match <project substring>` and `--since <YYYY-MM-DD>` to narrow it. If the owner works from more than one config dir (several accounts), pass each with `--projects`: a session copied or resumed under another account is counted once. It writes `stats.txt` and `chunks/*.txt`. Each session in a chunk has its title, time span, tool counts, the subagents spawned (type/model/effort) and every prompt the owner typed. Teammate reports and compaction summaries are labelled, never counted as the owner's words.

2. **Read `stats.txt` yourself**: how many prompts, their median length, how many carry a screenshot, the most frequent short ones. Short prompts repeated hundreds of times ("commit", "where are we?", "is it on main?") are the protocol's failures: work the owner had to do or ask for.

3. **Fan out readers**, one per chunk (about 180 KB each), in parallel, on a strong model at medium effort. Each reads its chunk in full and answers with evidence for every claim (session id, date, a short verbatim quote):
   1. How the owner phrases requests and escalates them.
   2. How work is defined, assigned, decided and recorded.
   3. Where time was lost: repeated corrections, frustration, interruptions, redone work, environment failures, and requests the owner made that were never carried out.
   4. What ran fast without intervention, and which techniques enabled it.
   5. Which rules emerged from corrections, across sessions and projects.
   6. How agents were used: models, effort, parallelism, outcome.
   7. Which development cycle was practised.

   Ask each for a top ten of candidate rules ranked by evidence, and the anti-patterns. Optionally add one reader for the files the work left behind (AGENTS.md history, the ledger's tasks, the ADR folder, skills, workflow scripts, memory).

4. **Synthesize.** Merge the readers' lists. Keep a rule if its correction occurred twice or more, in one project or several, or if it cost hours even once. For each: the rule in one prescriptive line, the evidence (a count, two quotes; quotes stay in this list for the owner, and what reaches the ledger is in your own words, with session id and date), and where it belongs: an entry of memory at its scope, proposed with `xs propose` (a rule, a design rule, knowledge, for the project, the team or the organization), the person's preferences (the owner), a skill (a procedure), a hook (must never happen). A correction the ledger already holds (`xs queue`, `xs search`, the `correction.repeated` events) is the curator's: count it, do not propose it again, and never record `xs repeated` yourself.

   A rule may target the method itself: `PROTOCOL.md`, a brief, a skill.

   Before you count a rule as broken, check who broke it. A rule set aside on the owner's order (a team told to go on without approvals) is an exception, not a violation: propose how to make it explicit and reviewable, never a check that would have blocked the order. Before you propose a check, read whether the gate already runs it; if it does, the failure came from a path that skipped the gate, and that path is the proposal. Two symptoms with one cause (a full disk and a slow gate, both from a build cache per worktree) are one proposal.

   Write each proposal in this form, and nothing it does not need:

   > **N. The rule, in one prescriptive line.** Evidence: the count, and for each occurrence cited its session id and date, with at most two short quotes. Destination. What it costs and what it might break. Recommendation.

   A proposal that sets a value (a threshold, a limit) states the value; one that asks the owner something writes the questions in full. A count comes from `stats.txt` or from a search you ran, never from a reader's summary alone; search for misspellings too.

5. **Measure.** Run `flow --since <date> --prompts <owner prompts from stats.txt>` in the repo and prepare one row of `project/METRICS.md` with the date and its core numbers, each with its coverage. Take every number from one run of `flow`, and keep its output beside the retrospective; never estimate one, and never mix runs (the ledger moves while other sessions work). For each number past a threshold of `AGENTS.md`, or with no threshold, run `flow --explain` and classify each task of the slowest tenth: too large, waiting for a person, stopped by the environment. The step is not optional: list the tasks with their cause. A cause found twice becomes a rule proposal in step 9.

6. **Check the previous cycle.** For each rule accepted in the previous cycle, state whether it was applied and whether its correction recurred. Read the recalls of the person's local log (`~/.xs/events.log`): an entry recalled and then violated does not work; an entry never recalled is a candidate to retire. On the first cycle there is no previous one: say so, and still report what the local log holds. A correction that recurred becomes a check: a lint rule, a test, a hook, a line in the reviewer skill (`skills/reviewer/SKILL.md`).

7. **Retire.** Propose the removal of each rule that a check now enforces (`xs checked`). Stale entries are the curator's. An audit never lengthens `AGENTS.md`.

8. **Sort the ideas.** List each line of `IDEAS.md` in the ledger (`.xs/ledger/IDEAS.md`) with a recommendation: make it a request, keep it, or drop it.

9. **Propose; do not write.** Check the list against this skill first: each item in the form of step 4, no item that adds a rule to `AGENTS.md` (a threshold is the owner's to set there, not a rule), no check the gate already runs, no number that `flow` did not print. Present the additions and the removals as one numbered list, each with a recommendation. Write only what the owner accepts, with the row of step 5, on a branch delivered with `land`: `main` moves only through `land`.

## Output

Present the retrospective in the owner's language, in this order and under these headings; what reaches the repo (entries of memory, skills, the row of `METRICS.md`) is written in the repo's language.

1. **Numbers**: the row of `METRICS.md`, its coverage, the slowest tenth with its causes.
2. **Went well**: what ran without the owner, and the techniques that enabled it.
3. **To improve**: where the time went, each point with its count, sessions and dates.
4. **Previous cycle**: each rule accepted last time, applied or not, recurred or not.
5. **Actions**: the numbered proposals of step 9, then the ideas of step 8, then what was not proposed and why.

Transcripts hold secrets, customer data and the owner's own words. The digest stays on this machine, in a scratch folder. Nothing from it goes into a public repo before the owner has read it.
