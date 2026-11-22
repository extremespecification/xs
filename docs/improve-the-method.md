# Improve the method

Result: one improvement cycle, with rule proposals approved or rejected by a person and the core numbers recorded in `project/METRICS.md`.

The rules are in [PROTOCOL §10](../PROTOCOL.md#10-improvement-loop). The procedure is the retrospective, `skills/retro/SKILL.md`; between retrospectives the curator (`skills/curator/SKILL.md`) handles the stale entries of memory. Run a cycle every two weeks.

## Prepare the transcripts

Some tools delete transcripts: Claude Code after 30 days by default. Set a longer retention before you need the history; for Claude Code, in `~/.claude/settings.json`:

```json
{ "cleanupPeriodDays": 365 }
```

## Run a cycle

> Run the retro on the last two weeks of this repo.

The skill runs the digest script:

```sh
python3 ~/xs/skills/retro/scripts/digest.py --out <scratch>/digest --match <repo> --since 2026-11-04
```

| Option | Effect |
|---|---|
| `--out DIR` | writes `stats.txt` and `chunks/*.txt` into `DIR` |
| `--match SUBSTR` | keeps only projects whose path contains `SUBSTR`; repeatable |
| `--since YYYY-MM-DD` | keeps only sessions after this date |
| `--projects DIR` | reads transcripts from `DIR` instead of `~/.claude/projects` |

The output stays on the local machine: transcripts contain secrets, customer data and personal messages.

## The numbers

The skill runs `flow` and appends one row to `project/METRICS.md`, for the period:

```markdown
| Cycle | Prompts per landed task | Lead time p50 / p90 | Waiting for the owner | Bugs per landed task | Filed per closed | Spec deviations | Repeated corrections |
|---|---|---|---|---|---|---|---|
| 2026-11-04 | 14.2 (412 / 29) | 0.9 h / 31 h | 6 questions, oldest 4 d | 0.67 | 1.8 | 0.5 | 2 |
| 2026-11-18 | 11.8 (354 / 30) | 0.6 h / 9 h | 2 questions, oldest 1 d | 0.40 | 1.1 | 0.2 | 0 |
```

`flow` computes them from `EVENTS.log` on the ledger branch `xs-ledger`, which `xs` and the integrator write. A number with no events says so. Two commands run once, in older repos: `xs import-git` records the events that git history can date, and `xs migrate` moves a `project/EVENTS.log` off `main`. No column has a target: the owner sets thresholds in `AGENTS.md` and reads each number as a question. Between cycles, the lead runs `flow` before every report.

## Decide

The skill proposes; you decide. It presents additions and removals as one numbered list, each with evidence and a recommendation:

```
1. Add to AGENTS.md: "Run migrations only through `make migrate`." Evidence: 4 corrections in 3 sessions. I recommend yes.
2. Convert rule 7 to a hook: "Never run prettier on the whole tree." Evidence: corrected twice after the rule existed. I recommend yes.
3. Retire rule 4: enforced by the lint rule added on 2026-11-06. I recommend yes.
```

Answer by number. The skill writes only the accepted items. A strong rule names an observable trigger: "Run migrations only through `make migrate`", not "Be careful with migrations".
