# Adapters

XS needs from an agent tool only what the open Agent Skills standard gives: it reads `AGENTS.md` and loads the skills in `skills/`. An adapter adds what one tool can do beyond that, and nothing of the method lives only here.

| Folder | What it holds |
|---|---|
| `claude-code/` | `agents/`: the three roles as named agents, with model and tools; `guard`: a hook that denies broad commits and whole-tree formatters; `template/CLAUDE.md`: the tool's pointer to `AGENTS.md` |

`xs install` applies the adapter of each tool it finds in your home, and `xs init` copies its `template/` into the repo. An adapter for another tool is a folder beside these, with the same parts where the tool has them; `tools()` in `scripts/xs` names the folder each tool is found by.
