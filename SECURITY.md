# Security

## Reporting a vulnerability

Report it privately through [GitHub's private vulnerability reporting](https://github.com/extremespecification/xs/security/advisories/new), not in a public issue. Include the version or commit, the steps to reproduce and what an attacker gains. You will get an answer within a week.

## Scope

In scope: the scripts (`scripts/`), the hooks of the adapters (`adapters/`), and anything `xs init` copies into a repo (`template/`). For example: a command injected through a task title or an event value, a ledger write outside `.xs/ledger`, an OTLP export that leaks more than it states.

Out of scope: the `guard` hook as a sandbox. It prevents mistakes of agents on one machine; it is not a security boundary, as [Adopt in a team](docs/adopt-in-a-team.md) states. Protect `main` and the ledger on the git host.

## Supported versions

The latest release only, until 1.0.
