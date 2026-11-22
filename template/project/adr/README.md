# Decisions

One file per decision that constrains the code: architecture, data, contracts, behaviour a user relies on. Layout and copy go to `DESIGN.md`; build steps and progress go to tasks. If an agent cannot tell from the ADR whether a change follows it, the ADR is not yet a decision.

Test before writing one: could two task chains make this choice in incompatible ways? If not, the choice belongs in the spec or the task. Accept every such decision before the parallel chains start.

`NNNN-the-decision-as-a-sentence.md`, numbered with `next-id ADR` (`0007-the-log-is-the-truth-the-graph-holds-the-relations.md`).

```markdown
# The decision as a sentence

## Decision

What we do from now on, in a few paragraphs or a numbered list. Concrete enough that an agent can tell whether code follows it.

## Why

What goes wrong otherwise. The options we rejected, one line each, with the reason.

## Consequences

What changes: files, docs, and the tasks opened to do it (T<nn>, T<nn>).
```

- Under a page. A long ADR is a design doc or a plan; split the decision out of it.
- The file is never edited after it is accepted, and holds no state. Changing a decision means a new ADR that names the one it replaces, and `xs adr <old> amended "ADR <NNNN> (what changed)"`.
- Its state is events in the ledger: `xs adr <NNNN> proposed|accepted|retired ["line"]`, `xs adr <NNNN> built "no|partly|yes (T<nn>)"` and `xs adr <NNNN> amended "ADR <NNNN> (what changed)"`. `xs status ADR-<NNNN>` prints it.
- An accepted decision is not yet built. Until `xs adr <NNNN> built "yes (...)"` is recorded, code must not rely on the decision; write it in the future tense ("the profile will carry …").
- A decision task (`type: decision`, in the ledger's `tasks/`) closes with its ADR.
- Search the ADRs before a structural change. If code and an ADR disagree, one of them is a bug: say which.
