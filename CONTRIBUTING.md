# Contributing to XS

XS is a method first and a toolset second. Both kinds of contribution are welcome; they are judged differently.

## A rule of the method

Every rule in `PROTOCOL.md` carries its principle, its level and its evidence. A proposal for a new rule, or for changing or removing one, states:

1. **The rule**, in one prescriptive line, in the form of the section it belongs to.
2. **The evidence**: what you observed, how often, in what kind of project. Figures may be rounded; they show the size of a problem, not a benchmark. Never paste transcripts, customer data or names: describe what happened in your own words. A rule with no observation behind it says `Evidence: none`, and says so honestly.
3. **The check**, if one can enforce it: a test, a hook, a gate condition. Once a check enforces a rule, the rule leaves `AGENTS.md`.
4. **What it costs** and what it might break.

Open an issue with these four points (the "Rule proposal" template) before a pull request. Evidence from teams is the most valuable kind: no rule for teams has been measured yet.

## The toolset

The scripts are deliberately small and have no dependencies beyond git, bash and python3's standard library. Keep it that way.

- **Portable**: macOS and Linux. No flag only GNU or only BSD accepts: write `sed -i.bak`, never a bare `sed -i`; write `grep -E 'a|b'`, never `grep 'a\|b'`.
- **One runnable check per behavior.** `test.sh` runs every script end to end in temporary repos, and the adapters' `--selftest`s. A new behavior adds the smallest assertion that fails without it; break your change on purpose once to see the assertion fail.
- **The ledger's contract is stable**: an event line is `<at> <scope> <subject> <kind> key=value ...`. A new event kind is an addition; a changed one needs a migration.
- **An adapter for another agent tool** is a folder beside `adapters/claude-code/`: its role definitions and its hooks. The guard's JSON on stdin is tool-neutral.

```sh
bash test.sh        # must print "test.sh: ok"
```

## Pull requests

One change per pull request, with the proposal it implements linked. Commit explicit paths. CI runs `test.sh` on Ubuntu and macOS.

## Security

Report a vulnerability privately, never in an issue: [SECURITY.md](SECURITY.md).

## Conduct

Be precise and be kind. Criticize rules and code, not people.
