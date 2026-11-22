# Define a spec

Result: a one-page spec with status `ready`, its tasks filed and grouped into chains, its shared decisions accepted.

The rules are in [PROTOCOL §4](../PROTOCOL.md#4-definition). The procedure is step 3 of `skills/lead/SKILL.md`. This guide applies both to one request.

## The request

> Accountants need to export invoices to CSV for their monthly close.

All three signals of [PROTOCOL §4](../PROTOCOL.md#routing) hold:

- **Intent gap**: which invoices, which columns and which format are not stated.
- **Wide footprint**: the work spans the API, a background job and the UI.
- **Invariant touched**: the export reads invoice totals; a search of the tests finds `S02 I1 invoice total equals sum of lines`.

Ask the lead to define the spec:

> Define a spec for the invoice CSV export. Use the lead skill.

## The steps applied

### 1. Pair

The owner opens the advisor in a session of its own (`skills/advisor/SKILL.md`). It asks numbered questions, each with a recommendation:

```
1. Which invoices: a) one month, b) a date range, c) a saved filter? I recommend b.
2. Credit notes: a) included as negative rows, b) excluded? I recommend a: the close needs them.
3. Exports above 50,000 rows run as a background job with an email link? I recommend yes.
4. Encoding: UTF-8 with BOM, for Excel? I recommend yes.
```

Answer by number: `1 b, 2 a, 3 yes, 4 yes`.

### 2. Research

The lead briefs a researcher with neutral questions and excludes the intended change. "How are amounts stored: type and scale?" is neutral. "Can we use floats for the CSV amounts?" is biased.

### 3. Draft

The lead writes `project/specs/S04-invoice-csv-export.md`, number from `next-id S`, and marks each guess:

```
- R5: The file name is `invoices-<from>-<to>.csv`. [ASSUMPTION]
```

It settles each open item by one route:

- "Is `invoices-<from>-<to>.csv` right?" goes to the owner as a question.
- "Does the job runner support jobs longer than 10 minutes?" becomes a 20-minute spike, recorded as a Log line with `xs spec S04 noted "..."`.
- "Column order for future fields" becomes a note for the tasks.

### 4. Fix

Each invariant names its test. The test name starts with `S04 I<n>`, or `s04_i<n>` in a language without spaces in names, so that a later change finds it by searching the tests:

```
- I1: The sum of exported totals equals the sum of invoice totals for the same range.
  Why: the accountant reconciles the CSV against the ledger.
  Test: `S04 I1 export totals match ledger for a mixed month`.
```

Ask of each choice: could two chains make it incompatibly? The amount format (`1234.50`, no thousands separator) passes: the endpoint and the job both write amounts, so it becomes ADR 0012. The 50,000-row threshold does not: one chain owns it, so it stays a requirement.

### 5. Split

The lead derives one task per deliverable, cites the `R<n>` and `I<n>` each serves, files each with `xs file --spec "S04 R2 I1" "title"`, which numbers it, and groups tasks that touch the same files into one chain.

### 6. Check the gate

The lead verifies the five conditions of the [readiness gate](../PROTOCOL.md#readiness-gate) and asks the owner to accept the ADR and approve the spec. The owner runs:

```sh
xs adr 0012 accepted
xs spec S04 approved "the outcome, R1-R6, I1-I3"
```

The lead then runs `xs spec S04 ready`, which lists every condition that fails.

## The spec

`project/specs/S04-invoice-csv-export.md`:

```markdown
---
title: Accountants export invoices to CSV for a date range
owner: Ada
created: 2026-11-18
---

## Outcome

An accountant selects a date range on the invoice list and downloads a CSV of every invoice
and credit note in it. The file opens in Excel with correct accents and reconciles with the ledger.

## Boundaries

- No other formats (XLSX, PDF).
- No scheduled or recurring exports.
- No column customization.

## Requirements

- R1: The invoice list offers "Export CSV" for the current date range.
- R2: The CSV holds one row per invoice and per credit note; credit notes have negative amounts.
- R3: Columns, in order: number, date, customer, net, tax, total, currency, status.
- R4: Exports above 50,000 rows run as a background job; the user receives an email with a download link valid for 7 days.
- R5: The file name is `invoices-<from>-<to>.csv`, dates in ISO 8601.
- R6: The file is UTF-8 with BOM.

## Invariants

- I1: The sum of exported totals equals the sum of invoice totals for the same range.
  Why: the accountant reconciles the CSV against the ledger. Test: `S04 I1 export totals match ledger for a mixed month`.
- I2: Amounts are written from the stored decimal value, never through a float.
  Why: float conversion changed cents in a previous report. Test: `S04 I2 export preserves cents for 0.1 + 0.2`.
- I3: A user exports only invoices of their own organization.
  Why: invoices hold customer data. Test: `S04 I3 export excludes other organizations`.

## Decisions

- ADR 0012: CSV amounts use a dot decimal separator and no thousands separator.

## Open

- Column order for future fields: left to the tasks.
```

Its status and Log are in the ledger. `xs status S04` prints them:

```
S04: ready
  ...
Log (<repo>/.xs/ledger/logs/S04.md):
- 2026-11-18: spike: the job runner supports jobs up to 30 minutes; 50,000 rows take about 40 seconds.
- 2026-11-18: R5 assumption confirmed by Ada.
- 2026-11-18: approved by Ada: the outcome, R1-R6, I1-I3.
```

## The tasks

| Task | Title | `spec` | Chain | Priority |
|---|---|---|---|---|
| T41 | Tests: export totals match the ledger, cents preserved, organization scoped | S04 I1 I2 I3 | `export-core` | p1 |
| T42 | Export endpoint streams the CSV for a date range | S04 R2 R3 R5 R6 I1 I2 I3 | `export-core` | p2 |
| T43 | Background export above 50,000 rows with an email link | S04 R4 | `export-core` | p2 |
| T44 | "Export CSV" button on the invoice list | S04 R1 | `export-ui` | p2 |

T41 comes first: it writes the invariant tests every later task keeps green. T44 runs in its own chain because it touches only the UI.

`.xs/ledger/tasks/T42-export-endpoint-streams-csv.md`:

```markdown
---
title: Export endpoint streams the CSV for a date range
type: task
priority: p2
created: 2026-11-18
source: S04
spec: S04 R2 R3 R5 R6 I1 I2 I3
owner: Ada
---

## What

`GET /invoices/export.csv?from=&to=` streams the CSV defined by S04, for ranges up to 50,000 rows.

## Where

- `api/invoices/` for the route.
- `billing/totals.py` for the stored decimal amounts (researcher: line 40).

## Done when

- The tests `S04 I1`, `S04 I2` and `S04 I3` pass.
- A range with one credit note yields a negative row.
- The file opens in Excel with "Société Générale" intact.
```

## Change a spec

While the spec is not `done`, edit the spec, then amend or regenerate the tasks that cite the changed ids. Append `R7` to add a requirement. Mark a removed one `R3: dropped on <date>, <reason>`. Never renumber. Record each change as a Log line with `xs spec S04 noted "..."`.

After the spec is `done`, write a new spec. Example: `S09` adds XLSX export, cites S04 in its Outcome, and keeps the S04 invariant tests green.
