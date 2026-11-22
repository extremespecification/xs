---
title: The invariants of the product, true after every change
owner: <name>
created: <date>
---

## Outcome

The rules that hold for the whole product, whatever spec is being built. Each is an invariant like any other: its test is named `S00 I<n> ...`, a change that touches it needs the owner's approval, and the reviewer and the mutation check treat it as they treat a spec's. A rule that belongs to one feature goes in that feature's spec.

## Invariants

<!-- - I1: no request returns another organization's data. Why: one leak ends the product. Test: `S00 I1 requests see only their organization`. -->
