# Getting started

Result: a repo prepared for XS at [level 3](../PROTOCOL.md#levels), the ledger included, and one task built, reviewed and landed by the lead agent.

Level 1 needs no installation: write a spec as [`template/project/specs/README.md`](../template/project/specs/README.md) says, bind each invariant to a test, and let the agents build. Install the tools below when agents start working in parallel.

Duration: about ten minutes, excluding the build.

Requirements: git 2.30 or later, bash, python3 3.9 or later, and a coding agent that reads skills (the open Agent Skills standard, `SKILL.md`).

## 1. Install the tools

```sh
git clone https://github.com/extremespecification/xs.git ~/xs
echo 'export PATH="$HOME/xs/scripts:$PATH"' >> ~/.zshrc && export PATH="$HOME/xs/scripts:$PATH"
xs install
```

`xs install` links the skills into the skills folder of each agent tool it finds in your home, and applies the tool's adapter from `adapters/` when there is one (role definitions, the `guard` hook). For another tool, add `--skills-dir <its skills folder>`. Running it again changes nothing.

Verify the installation:

```sh
~/xs/test.sh
```

Expected output, last line: `test.sh: ok`.

## 2. Prepare the repo

At the root of the repo, on a clean `main`:

```sh
xs init
```

`xs init` prepares two places and keeps every file the repo already has:

- **On `main`**: `AGENTS.md`, the numbered rules every agent reads; the files your tools' adapters need; a `.gitignore` line for `.xs/`, where the worktrees and the ledger's checkout live; and `project/`, with `specs/` and `adr/` (Architecture Decision Records), each with a README that gives its format, and `S00`, the standing spec of the invariants of the whole product.
- **In the ledger**: the branch `xs-ledger`, checked out at `.xs/ledger`, with `tasks/`, `IDEAS.md` and `EVENTS.log`. Only `xs` commits to it, and none of it reaches `main`.

When the repo already has an `AGENTS.md`, `xs init` leaves it alone and says so: merge XS's rules into it by hand.

Replace each `<...>` placeholder in `AGENTS.md`: the stack and the commit conventions. Define `make check`: the command a change passes before it lands.

Commit the result with explicit paths:

```sh
git add AGENTS.md .gitignore project   # and the adapter files xs init named
git commit -m "Adopt Extreme Specification"
```

Run `xs where` (in zsh, a bare `where` is a builtin). Expected output: the repo folder, the current branch, no worktree other than the main checkout and the ledger's (`.xs/ledger`, labelled `never lands`), and the free disk space.

## 3. Land a first task

Choose a change with none of the three signals of [PROTOCOL §4](../PROTOCOL.md#routing). A bug fix with a clear reproduction in one module qualifies.

Open your coding agent in the repo and state the request:

> Fix the date column of the invoice table: it shows UTC instead of the user's time zone. Use the lead skill.

The lead follows `skills/lead/SKILL.md`. It states the location, finds no signal, files `.xs/ledger/tasks/T01-invoice-dates-in-user-time-zone.md`, builds, has a reviewer read the diff, reruns the checks, lands with `land` and reports.

Expected report:

```
Landed: invoice dates in the user's time zone, test green (T01)
Running: none
Waiting for you: none
New tasks: none
```

Verify the result:

```sh
git log -1 --format='%h %s' main
xs status T01
grep -A4 '^## Done' .xs/ledger/tasks/T01-*.md
```

`xs status T01` starts with `T01: done` and lists its events, the last one `landed` with the commit on `main`. The task file contains a Done section that names the test proving the fix.

## Next step

For a change with one or more signals, read [Define a spec](define-a-spec.md).
