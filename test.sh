#!/usr/bin/env bash
# test.sh: the one check for the XS scripts. Runs the guard and digest self-tests, then where, land, xs and the
# integrator on throwaway repos.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
python3 "$here/adapters/claude-code/guard" --selftest
python3 "$here/adapters/claude-code/lifecycle" --selftest
python3 "$here/skills/retro/scripts/digest.py" --selftest
python3 "$here/scripts/flow" --selftest
xs="$here/scripts/xs"

t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
fail() { echo "FAIL: $*"; exit 1; }
repo() { cd "$t" && git init -q -b main "$1" && cd "$1" && git config user.name test && git config user.email test@example.com &&
  git config commit.gpgsign false && echo '.xs/' > .gitignore && git add .gitignore && git commit -q -m init; }

# land: refuses what is not committed and red checks; lands, cleans up, and where agrees
repo repo
git worktree add -q .xs/worktrees/feat -b feat
cd .xs/worktrees/feat
echo x > a.txt && git add a.txt && git commit -q -m "feat: a"
out=$("$here/scripts/where"); grep -q '1 commit(s) not on main' <<<"$out" || fail "where missed the unlanded branch"
echo y > a.txt
CHECK=true "$here/scripts/land" >/dev/null 2>&1 && fail "land landed with uncommitted changes"
git checkout -q a.txt
echo new > b.txt
CHECK=true "$here/scripts/land" >/dev/null 2>&1 && fail "land landed with an untracked file the checks could see"
rm b.txt
CHECK=false "$here/scripts/land" >/dev/null 2>&1 && fail "land landed on red checks"
before=$(git rev-parse main)
out=$(CHECK=true "$here/scripts/land" --dry-run 2>&1) || fail "land --dry-run refused: $out"
grep -q 'would queue feat' <<<"$out" || fail "land --dry-run did not say what it would queue"
[ "$(git rev-parse main)" = "$before" ] || fail "land --dry-run moved main"
ls "$(git rev-parse --path-format=absolute --git-common-dir)/xs-queue" 2>/dev/null | grep -q '^[0-9]' && fail "land --dry-run queued the branch"
out=$(CHECK=true "$here/scripts/land"); grep -q 'removed' <<<"$out" || fail "land did not land and clean up"
cd "$t/repo"
[ "$(git log -1 --format=%s main)" = "feat: a" ] || fail "main did not move, or moved by more than the work"
out=$("$here/scripts/where"); grep -q 'not on main' <<<"$out" && fail "where still reports unlanded work"
CHECK=true "$here/scripts/land" >/dev/null 2>&1 && fail "land ran on main"

# land with a forge: push, open the request, queue it in the forge's merge train; main does not move here
git init -q --bare -b main "$t/forge-origin.git" && git remote add origin "$t/forge-origin.git" && git push -q origin main
mkdir -p "$t/bin" && for f in gh glab; do printf '#!/bin/sh\n[ "$2" = view ] && exit 1\necho "%s $*" >> "%s"\n' "$f" "$t/forge.log" > "$t/bin/$f"; chmod +x "$t/bin/$f"; done
for forge in github gitlab; do
  git worktree add -q ".xs/worktrees/f-$forge" -b "f-$forge" && (cd ".xs/worktrees/f-$forge" && echo "$forge" > f.txt && git add f.txt && git commit -q -m "f: $forge" &&
    PATH="$t/bin:$PATH" LAND_FORGE=$forge CHECK_CHANGE=true "$here/scripts/land" >/dev/null) || fail "land with $forge failed"
  git -C "$t/forge-origin.git" rev-parse -q --verify "f-$forge" >/dev/null || fail "land with $forge did not push the branch"
done
grep -q '^gh pr create .*--head f-github' "$t/forge.log" && grep -q '^gh pr merge f-github --auto' "$t/forge.log" || fail "land did not queue the pull request in GitHub's merge queue"
grep -q '^glab mr create .*--source-branch f-gitlab' "$t/forge.log" && grep -q '^glab mr merge f-gitlab --auto-merge' "$t/forge.log" || fail "land did not queue the merge request in GitLab's merge train"
[ "$(git log -1 --format=%s main)" = "feat: a" ] || fail "land with a forge moved main locally"
git worktree remove -f .xs/worktrees/f-github && git worktree remove -f .xs/worktrees/f-gitlab && git remote remove origin

# next-id: specs and ADRs are seen on other branches, in other worktrees and on the remote
mkdir -p project/adr project/specs && touch project/adr/0001-a.md && git add project && git commit -q -m adr
git worktree add -q .xs/worktrees/b -b b && (cd .xs/worktrees/b && mkdir -p project/specs && touch project/specs/S05-b.md && git add project && git commit -q -m b)
git worktree add -q .xs/worktrees/c -b c && mkdir -p .xs/worktrees/c/project/specs && touch .xs/worktrees/c/project/specs/S07-c.md
[ "$("$here/scripts/next-id" S)" = S08 ] || fail "next-id missed another branch or worktree"
[ "$("$here/scripts/next-id" ADR)" = 0002 ] || fail "next-id ADR"
git clone -q --bare . "$t/origin.git" && git clone -q "$t/origin.git" "$t/mate" 2>/dev/null
(cd "$t/mate" && git config user.name mate && git config user.email mate@example.com && git config commit.gpgsign false &&
  git checkout -q -b mate && mkdir -p project/specs && touch project/specs/S20-mate.md && git add project && git commit -q -m mate && git push -q origin mate)
git remote add origin "$t/origin.git"
[ "$("$here/scripts/next-id" S)" = S21 ] || fail "next-id missed a branch that is only on the remote"
out=$("$here/scripts/where"); grep -q 'origin/mate' <<<"$out" || fail "where missed a branch that is only on the remote"

# import-git dates what git holds, births and exits, into the ledger: a lowercase "accepted" counts; a removed ADR is
# retired; a dropped task leaves the backlog
mkdir -p project/tasks && printf -- '---\nstatus: done\n---\n' > project/tasks/T01-a.md
printf -- '---\nstatus: todo\n---\n' > project/tasks/T30-x.md && printf 'Proposed on 2026-11-18, accepted by the owner on 2026-11-19.\n' > project/adr/0007-b.md
printf 'Proposed on 2026-11-18.\n\nThe accepted trade: a body line, not an acceptance.\n' > project/adr/0008-c.md
git add project && git commit -q -m "T01, T30, ADR 0007, 0008" -- project
git rm -q project/adr/0008-c.md && printf 'Rejected on 2026-11-19: a new name and a new body,\ntoo different for git to see a rename.\n' > project/adr/0008-rejected.md
git add project && git commit -q -m "rename ADR 0008" -- project
sed 's/^status: todo/status: dropped/' project/tasks/T30-x.md > x && mv x project/tasks/T30-x.md && git rm -q project/adr/0001-a.md
git commit -q -m "drop T30, retire ADR 0001" -- project
dry=$("$xs" import-git --dry-run)
grep -q src=git .xs/ledger/EVENTS.log && fail "import-git --dry-run wrote the log"
grep -q ' T30 task.dropped status=dropped src=git' <<<"$dry" || fail "import-git missed a dropped task"
grep -q ' ADR-0007 adr.accepted src=git' <<<"$dry" || fail "import-git missed a lowercase accepted"
grep -q ' ADR-0008 adr.accepted' <<<"$dry" && fail "import-git took a body line for an acceptance"
grep -q ' ADR-0008 adr.retired' <<<"$dry" && fail "import-git took a rename for a removal"
grep -q ' ADR-0001 adr.retired reason=removed src=git' <<<"$dry" || fail "import-git left a removed ADR waiting"
"$xs" import-git >/dev/null
L=.xs/ledger/EVENTS.log
grep -qE '^[0-9TZ:-]+ project/repo T01 task\.filed status=todo src=git$' $L || fail "import-git missed T01 filed"
grep -q ' T01 task.closed status=done src=git' $L || fail "import-git missed T01 closed"
grep -q ' T01 landed on=main src=git' $L || fail "import-git missed T01 landed"
"$xs" import-git >/dev/null 2>&1 && fail "import-git ran twice"
at=$(sed -n 's/^\([^ ]*\) [^ ]* T01 task.closed .*/\1/p' $L)
"$xs" void T01 task.closed "$at" "squashed: wrong second" >/dev/null || fail "xs void refused an event in the log"
grep -q " T01 event.voided of_kind=task.closed of_at=$at reason=squashed:_wrong_second" $L || fail "xs void wrote no event"
"$xs" void T01 task.closed 2000-01-01T00:00:00Z "x" >/dev/null 2>&1 && fail "xs void cancelled an event that does not exist"

# xs: the coordinator files and starts, the worker closes, the integrator lands; main receives only the work
repo xsr
echo 'WIP limit: 1' > AGENTS.md && git add AGENTS.md && git commit -q -m rules
main0=$(git rev-parse main)
[ "$("$xs" file --priority p1 "First task" | cut -d' ' -f1)" = T01 ] || fail "xs file did not number T01"
grep -q ' T01 task.filed status=todo type=task priority=p1 by=test$' $L || fail "xs file wrote no event"
grep -q '^status:' .xs/ledger/tasks/T01-first-task.md && fail "xs file wrote a status line in the task"
[ "$(git -C .xs/ledger branch --show-current)" = xs-ledger ] || fail "the ledger is not checked out on xs-ledger"
[ -z "$(git -C .xs/ledger merge-base xs-ledger main 2>/dev/null)" ] || fail "the ledger shares history with main"
"$xs" file "Second task" >/dev/null
[ "$(git rev-parse main)" = "$main0" ] && [ -z "$(git status --porcelain)" ] || fail "xs file touched main"
[ -z "$(git -C .xs/ledger status --porcelain)" ] || fail "xs file left the ledger uncommitted"
"$xs" next | head -n 1 | grep -q '^T01 p1 task First task$' || fail "xs next did not put the p1 first"
"$xs" start T01 --branch t01 >/dev/null || fail "xs start refused a ready task"
[ "$(git rev-parse main)" = "$main0" ] || fail "xs start committed on main"
grep -q ' T01 task.started status=doing branch=t01 by=test$' $L || fail "xs start wrote no event"
[ -d .xs/worktrees/t01 ] || fail "xs start created no worktree"
"$xs" start T01 --branch t01 >/dev/null || fail "xs start is not idempotent"
[ "$(grep -c ' T01 task.started' $L)" = 1 ] || fail "xs start ran twice wrote two events"
"$xs" start T01 --branch other >/dev/null 2>&1 && fail "xs start took a task held on another branch"
"$xs" start T02 --branch t02 >/dev/null 2>&1 && fail "xs start went past the WIP limit"
"$xs" status | grep -q '^T01 doing on t01 p1 First task$' || fail "xs status did not show T01 doing"
task="$t/xsr/.xs/ledger/tasks/T01-first-task.md"
cd .xs/worktrees/t01
"$xs" close T01 >/dev/null 2>&1 && fail "xs close closed a task without a Done section"
printf '\n## Done\n\n- Proof: `true`.\n' >> "$task" && echo x > a.txt
echo "2026-11-21T00:00:00Z project/xsr T01 task.closed status=done by=forger" >> "$t/xsr/$L"
"$xs" close T01 >/dev/null 2>&1 && fail "xs committed a log edited by hand"
git -C "$t/xsr/.xs/ledger" checkout -q EVENTS.log
sed -i.bak 's/^priority: p1/priority: p9/' "$task" && rm "$task.bak"
"$xs" close T01 >/dev/null 2>&1 && fail "xs close took a priority outside the vocabulary"
sed -i.bak 's/^priority: p9/priority: p1\nstatus: done/' "$task" && rm "$task.bak"
"$xs" close T01 >/dev/null 2>&1 && fail "xs close took a status line written by hand"
sed -i.bak '/^status: done$/d' "$task" && rm "$task.bak"
git add a.txt && git commit -q -m "T01 done" -- a.txt
"$xs" close T01 >/dev/null || fail "xs close refused a task with its proof"
"$xs" status T01 | grep -q '^T01: closed, branch t01' || fail "a closed task is not closed"
CHECK=true "$here/scripts/land" >/dev/null || fail "land refused T01"
cd "$t/xsr"
[ "$(git log -1 --format=%s main)" = "T01 done" ] && [ "$(git rev-list --count "$main0..main")" = 1 ] || fail "main received more than the work"
grep -qE ' T01 landed status=done on=main commit=[0-9a-f]+ branch=t01 by=land$' $L || fail "the integrator wrote no landed event"
"$xs" status T01 | grep -q '^T01: done' || fail "a landed task is not done"
"$xs" start T02 --branch t02 >/dev/null || fail "xs start refused once the WIP was free"
# the lead records each review round and its verdict: the tool counts the rounds (S12 R3, R4)
"$xs" review T01 >/dev/null 2>&1 && fail "xs review opened a review of a done task"
"$xs" reviewed T02 approve >/dev/null 2>&1 && fail "xs reviewed recorded a verdict without an open review"
"$xs" review T02 >/dev/null || fail "xs review refused a doing task"
grep -qE ' T02 review\.started round=1 by=test$' $L || fail "xs review wrote no round 1"
"$xs" reviewed T02 approve --must-fix 1 >/dev/null 2>&1 && fail "xs reviewed approved with a must-fix open"
"$xs" reviewed T02 maybe >/dev/null 2>&1 && fail "xs reviewed took a verdict other than approve or changes"
"$xs" reviewed T02 changes --must-fix one >/dev/null 2>&1 && fail "xs reviewed took a must-fix that is not a number"
"$xs" reviewed T02 changes --must-fix 1 >/dev/null || fail "xs reviewed refused a verdict on the open round"
grep -qE ' T02 review\.verdict verdict=changes round=1 must_fix=1 by=test$' $L || fail "xs reviewed wrote no verdict"
"$xs" reviewed T02 approve >/dev/null 2>&1 && fail "xs reviewed recorded a second verdict for round 1"
"$xs" review T02 >/dev/null && "$xs" reviewed T02 approve >/dev/null || fail "xs review did not open round 2"
grep -qE ' T02 review\.verdict verdict=approve round=2 must_fix=0 by=test$' $L || fail "xs reviewed wrote no approval"
"$xs" review T02 >/dev/null
"$xs" reviewed T02 changes --must-fix 2 2>&1 >/dev/null | grep -q 'stop after three review rounds' || fail "xs reviewed did not warn on round 3"
"$xs" status T02 | grep -q '^T02: doing' || fail "a review changed the task's state"
"$here/scripts/flow" >/dev/null || fail "flow failed on the review events"
echo 'WIP limit: 2' > AGENTS.md && git commit -q -m wip -- AGENTS.md
"$xs" file "Third task" >/dev/null && sed -i.bak 's/^priority:/after: T02\npriority:/' .xs/ledger/tasks/T03-third-task.md && rm .xs/ledger/tasks/T03-third-task.md.bak
"$xs" start T03 --branch t03 >/dev/null 2>&1 && fail "xs start took a task whose after task is doing on another branch"
"$xs" start T03 --branch t02 >/dev/null || fail "xs start refused the next task of a chain"
grep -q '^after: T02$' "$(git -C .xs/ledger show --name-only --format= HEAD | sed 's|^|.xs/ledger/|' | grep T03)" || fail "xs start did not commit the task's text"

# the readiness gate: xs spec ready refuses a spec that fails one of its conditions, and names it
mkdir -p project/specs project/adr && printf '# ADR 0009: a\n\n## Decision\n\nWe do a.\n' > project/adr/0009-a.md
spec='---\nowner: test\n---\n\n## Outcome\n\nTotals match.\n\n## Requirements\n\n- R1: the export holds one row per order.\n\n## Invariants\n\n- I1: totals match. Why: money. Test: `S01 I1 totals match`.\n\n## Decisions\n\n- ADR 0009: a.\n\n## Open\n\n- pagination: task.\n'
gate() { printf -- "$spec" | sed "$1" > project/specs/S01-a.md; out=$("$xs" spec S01 ready 2>&1) && fail "xs spec ready took a spec where $2"; grep -q "$3" <<<"$out" || fail "xs spec ready refused a spec where $2 for another reason: $out"; }
gate 's/^Totals match.$//' "the outcome is empty" "Outcome"
gate 's/^- R1: the export/- the export/' "a requirement has no id" "requirement has no id"
gate 's/one row per order/a fast export/' "a requirement says fast" "R1 .*fast"
gate 's/ Test: `S01 I1 totals match`//' "an invariant names no test" "I1 names no test"
gate 's/Test: `S01 I1/Test: `S02 I1/' "an invariant's test is named for another spec" "I1 names no test"
gate 's/one row per order/one row per order [ASSUMPTION]/' "an assumption is unconfirmed" "R1 .*ASSUMPTION"
gate 's/^- pagination: task.$/- pagination./' "an open item has no route" "open item"
gate 's/^- ADR 0009: a.$/- use JSON./' "a decision has no ADR" "decision has no ADR"
gate 's/^- ADR 0009: a.$/- ADR 0008: b./' "a decision names a missing ADR" "ADR 0008"
gate 's/^owner: test$/owner: someone/' "the owner has not approved" "someone has not approved"
echo '- Spec approval: none' >> AGENTS.md
printf -- "$spec" | sed 's/^owner: test$/owner: someone/' > project/specs/S01-a.md
out=$("$xs" spec S01 ready 2>&1) || true
grep -q "has not approved" <<<"$out" && fail "xs spec ready asked for an approval AGENTS.md waives"
git checkout -q AGENTS.md
printf -- "$spec" > project/specs/S01-a.md && "$xs" adr 0009 proposed >/dev/null
"$xs" spec S01 approved "the outcome and R1-R3" >/dev/null
out=$("$xs" spec S01 ready 2>&1) && fail "xs spec ready took a spec whose ADR is only proposed"
grep -q "ADR 0009 is not accepted" <<<"$out" || fail "xs spec ready refused a proposed ADR for another reason: $out"
"$xs" status S01 | grep -q '^S01: draft' || fail "a refused xs spec ready changed the status"
"$xs" adr 0009 accepted >/dev/null
out=$("$xs" spec S01 ready 2>&1) && fail "xs spec ready took a spec whose missing invariant test no task writes"
grep -q "no task writes the test of I1" <<<"$out" || fail "xs spec ready refused the missing test task for another reason: $out"
sed -i.bak 's/^priority:/spec: S01 I1\npriority:/' .xs/ledger/tasks/T03-third-task.md && rm .xs/ledger/tasks/T03-third-task.md.bak
"$xs" spec S01 ready >/dev/null || fail "xs spec ready refused a spec that passes the gate: $("$xs" spec S01 ready 2>&1)"
grep -q '^- [0-9-]*: approved by test: the outcome and R1-R3$' .xs/ledger/logs/S01.md || fail "xs spec approved wrote no Log line"
grep -q ' S01 spec.ready status=ready by=test$' $L || fail "xs spec ready wrote no event"
cp "$here/template/project/specs/S00-product.md" project/specs/
"$xs" spec S00 done >/dev/null 2>&1 && fail "xs spec S00 done closed the standing spec"
"$xs" status S00 | grep -q '^S00: ready' || fail "S00 is not ready"
out=$("$here/scripts/flow" --explain)
grep -q '^2 lead time, filed to main: .*(over 1 of 1 landed)$' <<<"$out" || fail "flow did not read the lead time from the ledger"
grep -q '^cycle time, started to main: .*(over 1 of 1 landed' <<<"$out" || fail "flow did not read the cycle time from xs start"
# a spec closes only when main holds each invariant test it names, in any case, with spaces or underscores
printf -- '---\nowner: test\n---\n\n## Invariants\n\n- I1: rule. Test: `S02 I1 totals match`.\n' > project/specs/S02-b.md
git add project && git commit -q -m "S01 S02 ADR 0009" -- project
out=$("$xs" spec S02 done 2>&1) && fail "xs spec done closed a spec whose invariant test is not on main"
grep -q 'S02 I1 totals match' <<<"$out" || fail "xs spec done did not name the missing test: $out"
echo 'def test_s02_i1_totals_match(): pass' > a_test.py && git add a_test.py && git commit -q -m "S02 I1 test"
"$xs" spec S02 done >/dev/null || fail "xs spec done refused a test named in snake case"
printf -- '---\nowner: test\n---\n\nNo invariants.\n' > project/specs/S03-c.md && git add project && git commit -q -m S03 -- project
"$xs" spec S03 done >/dev/null || fail "xs spec done refused a spec that names no test"
# a branch that closes no task lands too: one landed event with no task
(cd .xs/worktrees/t02 && echo notes > notes.txt && git add notes.txt && git commit -q -m "T02 notes" && CHECK=true "$here/scripts/land" --keep >/dev/null) ||
  fail "land failed on a branch that closes no task"
grep -qE ' - landed on=main commit=[0-9a-f]+ branch=t02 by=land$' $L || fail "land wrote no landed event for a branch that closes no task"

# memory: an agent proposes, the owner promotes; landing marks stale what the change touched; reads are recalls
export XS_HOME="$t/home" XS_SESSION=s1
printf '1. Rule one.\nWIP limit: 9\n' > AGENTS.md && git commit -q -m rules -- AGENTS.md
"$xs" propose --kind preference --anchor a.txt --evidence q "answer in Italian" >/dev/null 2>&1 && fail "xs propose took a preference"
"$xs" propose --kind rule --evidence q "no anchor" >/dev/null 2>&1 && fail "xs propose took an entry without an anchor"
[ "$("$xs" propose --kind rule --anchor a.txt --evidence "the owner, twice" "Measure fixes on fixed recordings" | cut -d' ' -f1)" = L01 ] || fail "xs propose did not number L01"
"$xs" queue | grep -q '^L01 proposed rule to AGENTS.md' || fail "xs queue missed the proposal"
"$xs" promote L01 >/dev/null
grep -q '^2\. Measure fixes on fixed recordings (L01)$' AGENTS.md || fail "xs promote did not write the next numbered rule"
grep -q ' L01 learning.promoted status=promoted' $L || fail "xs promote wrote no event"
git commit -q -m "L01" -- AGENTS.md
"$xs" load >/dev/null && "$xs" search "fixed recordings" | grep -q 'learnings/L01-.*\[promoted\]' || fail "xs search missed L01"
[ "$(grep -c ' L01 learning.recalled via=' "$XS_HOME/events.log")" = 2 ] || fail "load and search recorded no recall"
grep -q 'learning.recalled' $L && fail "a recall reached the ledger"
"$xs" file "Change a" >/dev/null && "$xs" start T04 --branch t04 >/dev/null
cd .xs/worktrees/t04 && echo changed > a.txt
printf '\n## Done\n\n- Proof: `true`.\n' >> "$t/xsr/.xs/ledger/tasks/T04-change-a.md" && "$xs" close T04 >/dev/null
git add a.txt && git commit -q -m "T04" -- a.txt
CHECK=true "$here/scripts/land" >/dev/null || fail "land refused T04"
cd "$t/xsr"
grep -q '^2\. Measure fixes on fixed recordings (L01, stale: a.txt changed)$' AGENTS.md || fail "landing did not mark L01 stale on main"
grep -q ' L01 learning.stale status=stale anchor=a.txt by=land$' $L || fail "landing wrote no stale event"
"$xs" queue | grep -q '^L01 stale' || fail "xs queue missed the stale entry"
# the curator: a recommendation on a stale entry, and an amended text that replaces it
"$xs" recommend L01 holds "T04 changed only the text of a.txt" >/dev/null
"$xs" queue | grep -q '^L01 stale .*\[recommended: holds, T04 changed only the text of a.txt\]' || fail "xs queue did not show the recommendation"
"$xs" propose --kind rule --anchor a.txt --evidence "T04" --replaces L01 "Measure fixes on fixed recordings, twice" | grep -q '^L02 ' || fail "xs propose --replaces failed"
"$xs" queue | grep -q '^L02 proposed rule to AGENTS.md (replaces L01)' || fail "xs queue did not show what L02 replaces"
"$xs" promote L01 >/dev/null && grep -q '(L01)$' AGENTS.md || fail "xs promote did not confirm the stale entry"
"$xs" recommend L01 retire "x" >/dev/null 2>&1 && fail "xs recommend took an entry that is not stale"
"$xs" propose --kind rule --anchor a.txt --evidence x --replaces L01 "y" >/dev/null 2>&1 && fail "xs propose --replaces took an entry that is not stale"
"$xs" promote L02 >/dev/null
! grep -q '(L01' AGENTS.md && grep -q 'twice (L02)$' AGENTS.md && grep -q ' L01 learning.retired status=retired .*replaced_by=L02' $L || fail "promoting a replacement did not retire the entry it replaces"
"$xs" repeated L02 "measure on the recordings, again" >/dev/null
grep -q ' L02 correction.repeated' $L || fail "xs repeated wrote no event"
"$xs" checked L02 "lint: no-new-factory-run" >/dev/null
grep -q 'L02' AGENTS.md && fail "xs checked left the entry in AGENTS.md"
git commit -q -m "L02 checked" -- AGENTS.md
"$xs" idea "a chart of the core numbers" >/dev/null && grep -q '^- [0-9-]* a chart of the core numbers (owner)$' .xs/ledger/IDEAS.md || fail "xs idea wrote no line"
# chain order: a task with after: waits until each task it names is done or dropped
"$xs" file "Fifth task" >/dev/null && sed -i.bak 's/^priority:/after: T04, T02\npriority:/' .xs/ledger/tasks/T05-fifth-task.md && rm .xs/ledger/tasks/T05-fifth-task.md.bak
"$xs" next | grep -q '^T05 ' && fail "xs next listed a task whose after task is not done"
out=$("$xs" start T05 --branch t05 2>&1) && fail "xs start started a task whose after task is not done"
grep -q 'after T02, which is doing' <<<"$out" || fail "xs start did not name the open after task: $out"
echo "diff" > .xs/ledger/tasks/T02-second-task.patch
"$xs" drop T02 "folded into T05" >/dev/null
git -C .xs/ledger ls-files --error-unmatch tasks/T02-second-task.patch >/dev/null 2>&1 || fail "xs did not commit the task's saved patch"
grep -q '^Dropped: folded into T05$' .xs/ledger/tasks/T02-second-task.md || fail "xs drop wrote no reason in the task"
"$xs" next | grep -q '^T05 ' || fail "xs next left out a task whose after tasks are done or dropped"
"$xs" start T05 --branch t05 >/dev/null || fail "xs start refused a task whose after tasks are done or dropped"
# ADRs: the file is the decision and is never edited; its status, Built and Amended by are events
printf '# We do x\n\n## Decision\n\nAccepted practice: x.\n' > project/adr/0001-we-do-x.md && sum=$(cksum < project/adr/0001-we-do-x.md)
"$xs" adr 0001 proposed >/dev/null && "$xs" adr 0001 accepted "answering T05" >/dev/null
"$xs" adr 0001 built "partly (T05)" >/dev/null && "$xs" adr 0001 built "yes (T05)" >/dev/null && "$xs" adr 0001 amended "ADR 0002 (y)" >/dev/null
[ "$(cksum < project/adr/0001-we-do-x.md)" = "$sum" ] || fail "xs adr edited the ADR file"
grep -q ' ADR-0001 adr.accepted status=accepted note=answering_T05 by=test$' $L || fail "xs adr accepted wrote no event"
grep -q ' ADR-0001 adr.built status=accepted built=yes_(T05) by=test$' $L || fail "xs adr built wrote no event"
"$xs" status ADR-0001 | grep -q '^ADR-0001: accepted, built yes_(T05), amended ADR_0002_(y)' || fail "xs status did not show the ADR's state"
"$xs" adr 0099 accepted >/dev/null 2>&1 && fail "xs adr took an unknown ADR"
"$xs" adr 0001 built "maybe" >/dev/null 2>&1 && fail "xs adr took a Built: outside no|partly|yes"
# releases, rollbacks and incidents are events only; flow reads the time to restore
"$xs" release v1 --commit abc123 >/dev/null && grep -q ' v1 released commit=abc123 by=test$' $L || fail "xs release wrote no event"
"$xs" rollback v1 "bad deploy" >/dev/null && grep -q ' v1 rolled-back reason=bad_deploy by=test$' $L || fail "xs rollback wrote no event"
"$xs" incident resolve db >/dev/null 2>&1 && fail "xs incident resolved an incident never opened"
"$xs" incident open db "the database is down" --sev 5 >/dev/null 2>&1 && fail "xs incident accepted a severity outside 1-4"
"$xs" incident open db "the database is down" --sev 1 >/dev/null && grep -q ' db incident.opened what=the_database_is_down sev=1 by=test$' $L || fail "xs incident open wrote no event"
"$xs" incident open db "again" >/dev/null 2>&1 && fail "xs incident opened an incident already open"
"$xs" incident resolve db >/dev/null && grep -q ' db incident.resolved by=test$' $L || fail "xs incident resolve wrote no event"
"$xs" incident resolve db >/dev/null 2>&1 && fail "xs incident resolved an incident twice"
"$here/scripts/flow" --explain | grep -q '^time to restore: p50 0.0 h, max 0.0 h (1 of 1 resolved)$' || fail "flow did not read the time to restore"
"$here/scripts/flow" --explain | grep -q 'change failure rate 100%' || fail "flow did not read the release and its rollback"
# xs start --run launches the agent AGENTS.md declares, in the worktree, with the brief on its input
printf 'WIP limit: 9\n- Agent copy: `cat > brief.txt`\n' > AGENTS.md && "$xs" file "Run task" >/dev/null && git commit -q -m "agent copy" -- AGENTS.md
"$xs" start T06 --branch t06 --run nobody >/dev/null 2>&1 && fail "xs start ran an agent AGENTS.md does not declare"
"$xs" status T06 | grep -q '^T06: todo' || fail "xs start claimed a task for an undeclared agent"
"$xs" start T06 --branch t06 --run copy >/dev/null || fail "xs start --run failed"
for _ in $(seq 50); do [ -s .xs/worktrees/t06/brief.txt ] && break; sleep 0.1; done
grep -q '^title: Run task' .xs/worktrees/t06/brief.txt || fail "the agent did not receive the task as its brief"
grep -q ' T06 task.started .* agent=copy$' $L || fail "task.started does not record the agent"
for _ in $(seq 50); do grep -q ' T06 agent.finished' $L && break; sleep 0.1; done
run=$(grep -o ' T06 agent.started run=copy-[0-9]* role=copy$' $L | grep -o 'copy-[0-9]*') || fail "xs start --run recorded no agent.started"
grep -q " T06 agent.finished run=$run exit=0 outcome=doing$" $L || fail "the agent's exit was not recorded as agent.finished of the same run"

# the agents' events: one status for every tool; a stop says why and until when; OpenTelemetry gets a span per run
"$xs" agent T06 stopped run=r1 reason=tired >/dev/null 2>&1 && fail "xs agent took a reason outside the vocabulary"
"$xs" agent T06 started run=r1 colour=red >/dev/null 2>&1 && fail "xs agent took an unknown field"
"$xs" agent T06 started run=r1 "model=a b" >/dev/null 2>&1 && fail "xs agent took a value with a space"
"$xs" agent T06 started run=r1 tool=claude-code model=sonnet effort=medium role=implementer session=s-1 >/dev/null || fail "xs agent started failed"
"$xs" status | grep -q '^  agent r1 running since .*, implementer, claude-code, sonnet, medium$' || fail "xs status did not show the running agent"
"$xs" agent --branch nowhere finished run=x | grep -q 'nothing recorded' || fail "xs agent --branch failed outside the factory"
"$xs" file "Never started" >/dev/null && "$xs" agent T07 started run=x | grep -q 'never started: nothing recorded' || fail "xs agent recorded on a task never started"
port=$t/otlp.port; body=$t/otlp.json
python3 -c '
import http.server, sys
class H(http.server.BaseHTTPRequestHandler):
    def do_POST(s):
        open(sys.argv[2], "w").write(s.path + "\n" + s.headers.get("Authorization", "") + "\n" + s.rfile.read(int(s.headers["Content-Length"])).decode())
        s.send_response(200); s.end_headers()
    def log_message(*a): pass
srv = http.server.HTTPServer(("127.0.0.1", 0), H); srv.timeout = 10; open(sys.argv[1], "w").write(str(srv.server_port)); srv.handle_request()' "$port" "$body" &
for _ in $(seq 50); do [ -s "$port" ] && break; sleep 0.1; done
OTEL_EXPORTER_OTLP_ENDPOINT="http://127.0.0.1:$(cat "$port")" OTEL_EXPORTER_OTLP_HEADERS="Authorization=Bearer%20k" \
  "$xs" agent --branch t06 stopped run=r1 reason=limit resume_at=2026-11-24T03:00:00Z >/dev/null || fail "xs agent --branch stopped failed"
wait
grep -q ' T06 agent.stopped run=r1 reason=limit resume_at=2026-11-24T03:00:00Z$' $L || fail "xs agent --branch did not record on the task doing there"
"$xs" status | grep -q '^  agent r1 stopped at .*: limit, resumes at 2026-11-24T03:00:00Z, no resume scheduled$' || fail "xs status did not show the stop and the missing job"
python3 - "$body" <<'PY' || fail "the OTLP span is wrong"
import json, sys
path, auth, body = open(sys.argv[1]).read().split("\n", 2)
assert path == "/v1/traces" and auth == "Bearer k", (path, auth)
s = json.loads(body)["resourceSpans"][0]["scopeSpans"][0]["spans"][0]
a = {x["key"]: x["value"]["stringValue"] for x in s["attributes"]}
assert s["name"] == "invoke_agent implementer" and a["gen_ai.request.model"] == "sonnet" and a["gen_ai.provider.name"] == "claude-code", s
assert a["gen_ai.conversation.id"] == "s-1" and a["xs.reason"] == "limit" and a["xs.task"] == "T06", a
assert int(s["endTimeUnixNano"]) >= int(s["startTimeUnixNano"]) > 0 and len(s["traceId"]) == 32 and len(s["spanId"]) == 16, s
PY
"$xs" status T06 | grep -q '^T06: doing, branch t06' || fail "an agent event changed the task's state"
"$xs" status --since 2000-01-01 | grep -q '^[0-9TZ:-]* T06 agent.stopped run=r1' || fail "xs status --since did not list the events"
[ -z "$("$xs" status --since 2999-01-01)" ] || fail "xs status --since listed old events"

# handoff and takeover: the state of a task in git, the uncommitted work as a patch, a brief any tool can follow
"$xs" handoff T06 >/dev/null 2>&1 && fail "xs handoff ran without a next step"
out=$("$xs" handoff T07 --next x 2>&1) && fail "xs handoff took a task never started"
grep -q 'only a started task is handed off' <<<"$out" || fail "xs handoff did not say why it refused: $out"
w=.xs/worktrees/t06; echo half > $w/half.txt; before=$(git -C $w status --porcelain)
"$xs" handoff T06 --next "finish the export" --open "check the dark theme" >/dev/null || fail "xs handoff failed"
[ "$(git -C $w status --porcelain)" = "$before" ] || fail "xs handoff changed the worktree or its index"
md=$(ls .xs/ledger/handoffs/T06-*.md) && grep -q '^- check the dark theme$' "$md" && grep -q 'session s-1 (ACP `session/load`)' "$md" || fail "the handoff lacks the open request or the session"
git -C .xs/ledger show --name-only --format= HEAD | grep -q '^handoffs/T06-.*\.patch$' || fail "xs handoff did not commit the patch"
grep -q ' T06 task.handed_off file=handoffs/T06-.*\.md head=[0-9a-f]* by=test$' $L || fail "xs handoff wrote no event"
git -C $w clean -qfd && [ ! -e $w/half.txt ] || fail "setup: the other session's worktree"
out=$("$xs" takeover T06) || fail "xs takeover failed: $out"
[ "$(cat $w/half.txt)" = half ] && grep -q '^title: Run task' $w/brief.txt || fail "xs takeover did not restore the uncommitted work"
grep -q '^finish the export$' <<<"$out" && grep -q "^worktree: .*$w$" <<<"$out" || fail "xs takeover did not print the brief"
grep -q ' T06 task.taken_over ' $L || fail "xs takeover wrote no event"
"$xs" takeover T06 | grep -q 'already in the worktree' || fail "xs takeover applied the patch twice"
echo other > $w/half.txt && "$xs" takeover T06 >/dev/null 2>&1 && fail "xs takeover applied over other changes"
"$xs" status T06 | grep -q '^T06: doing, branch t06' || fail "a handoff changed the task's state"

out=$("$here/scripts/where")
grep -q 'ledger (xs-ledger), never lands' <<<"$out" || fail "where did not label the ledger's checkout"

# a team: the claim is pushed with the ledger; main stays untouched; a second clone is refused
repo team
"$xs" file "Shared task" >/dev/null && "$xs" file "Local task" >/dev/null
git clone -q --bare . "$t/team.git"
for c in ca cb; do git clone -q "$t/team.git" "$t/$c" && git -C "$t/$c" config user.name "$c" && git -C "$t/$c" config user.email "$c@example.com" && git -C "$t/$c" config commit.gpgsign false; done
remote_main=$(git -C "$t/team.git" rev-parse main)
(cd "$t/ca" && "$xs" start T01 --branch a >/dev/null) || fail "xs start refused in the first clone"
[ "$(git -C "$t/team.git" rev-parse xs-ledger)" = "$(git -C "$t/ca" rev-parse xs-ledger)" ] || fail "xs start did not push the ledger"
[ "$(git -C "$t/team.git" rev-parse main)" = "$remote_main" ] || fail "xs start moved the remote main"
out=$(cd "$t/cb" && "$xs" start T01 --branch b 2>&1) && fail "the second clone claimed a task claimed elsewhere"
grep -q 'claimed elsewhere' <<<"$out" || fail "xs start did not say the task is claimed elsewhere: $out"
[ ! -d "$t/cb/.xs/worktrees/b" ] || fail "xs start created a worktree for a refused claim"
remote=$(git -C "$t/team.git" rev-parse xs-ledger)
(cd "$t/cb" && XS_NO_PUSH=1 "$xs" start T02 --branch c >/dev/null) || fail "xs start refused with XS_NO_PUSH"
[ "$(git -C "$t/team.git" rev-parse xs-ledger)" = "$remote" ] || fail "xs start pushed with XS_NO_PUSH=1"
(cd "$t/ca" && "$xs" file "From ca" >/dev/null) && (cd "$t/cb" && "$xs" file "From cb" >/dev/null) || fail "a second writer was refused"
git -C "$t/team.git" show xs-ledger:EVENTS.log | grep -q ' T02 task.started .*branch=c' || fail "cb's local event did not reach the remote with its next command"
[ "$(git -C "$t/team.git" ls-tree --name-only xs-ledger tasks/ | grep -c '^tasks/T0[34]-from-c[ab]\.md$')" = 2 ] || fail "two clones filed the same number"
for h in pre-commit commit-msg pre-push; do printf '#!/bin/sh\nexit 1\n' > "$t/ca/.git/hooks/$h" && chmod +x "$t/ca/.git/hooks/$h"; done
(cd "$t/ca" && "$xs" file "Hooked" >/dev/null) || fail "a project hook stopped the ledger"
rm "$t/ca/.git/hooks/"{pre-commit,commit-msg,pre-push}
printf '#!/bin/sh\n[ -e rejected ] && exit 0\ntouch rejected; exit 1\n' > "$t/team.git/hooks/pre-receive" && chmod +x "$t/team.git/hooks/pre-receive"
printf '\n## Done\n\n- Proof: kept.\n' >> "$t/ca/.xs/ledger/tasks/T01-shared-task.md"
(cd "$t/ca" && "$xs" close T01 >/dev/null) || fail "xs close did not retry a rejected push"
git -C "$t/team.git" show xs-ledger:tasks/T01-shared-task.md | grep -q 'Proof: kept' || fail "the retry lost the text it undid"
rm "$t/team.git/hooks/pre-receive"
git -C "$t/cb" config commit.gpgsign true && git -C "$t/cb" config gpg.program false
(cd "$t/cb" && XS_NO_PUSH=1 "$xs" file "Unpushed" >/dev/null) && (cd "$t/ca" && "$xs" file "Pushed" >/dev/null) &&
  (cd "$t/cb" && "$xs" file "After" >/dev/null) || fail "the pull of the ledger asked for a signature"
git -C "$t/cb" config commit.gpgsign false
git clone -q "$t/team.git" "$t/cc" && (cd "$t/cc" && git config user.name cc && git config commit.gpgsign false && XS_NO_PUSH=1 "$xs" file "From cc" >/dev/null)
[ -n "$(ls "$t/cc/.xs/ledger/tasks/" | grep -- '-from-cc\.md$' | grep -v '^T01-')" ] || fail "a clone with XS_NO_PUSH started a ledger of its own"

# the integrator: workers deliver with --queue and go on; one round per batch; a conflict and a red branch are ejected
repo q
echo one > shared.txt && git add shared.txt && git commit -q -m one
common=$(git rev-parse --path-format=absolute --git-common-dir)
mkdir "$common/xs-integrate.lock" && echo $$ > "$common/xs-integrate.lock/pid"   # hold the lock: no integrator starts
deliver() { git worktree add -q ".xs/worktrees/$1" -b "$1" && (cd ".xs/worktrees/$1" && eval "$2" && git add -A && git commit -q -m "$1" && "$here/scripts/land" --queue >/dev/null) || fail "land --queue refused $1"; }
deliver b1 'echo a > a1.txt'
deliver b2 'echo a > a2.txt'
deliver b3 'echo three > shared.txt'
deliver b4 'echo four > shared.txt'
deliver b5 'echo a > red.txt'
rm -rf "$common/xs-integrate.lock"
export CHECK_GATE="echo run >> $t/runs; ! test -f red.txt"
out=$("$xs" integrate 2>&1) || fail "xs integrate failed: $out"
grep -q 'ejected b4: conflict. rebase b4 on main and resolve: shared.txt' <<<"$out" || fail "the integrator did not eject the conflicting branch, naming the file: $out"
grep -q 'ejected b5: red' <<<"$out" || fail "the integrator did not eject the red branch"
[ -f a1.txt ] && [ -f a2.txt ] && [ "$(cat shared.txt)" = three ] && [ ! -f red.txt ] || fail "main does not hold exactly b1, b2 and b3"
git rev-parse -q --verify b4 >/dev/null && git rev-parse -q --verify b5 >/dev/null || fail "an ejected branch was removed"
grep -q ' - land.ejected branch=b4 reason=conflict by=land$' .xs/ledger/EVENTS.log || fail "the ejection is not in the ledger"
git log --format=%s main | grep -q '^land' && fail "the integrator committed bookkeeping on main"
# a task filed while the gate runs writes the ledger, not main: the round still lands at its first try
before=$(wc -l < "$t/runs")
mkdir "$common/xs-integrate.lock" && echo $$ > "$common/xs-integrate.lock/pid"
deliver b6 'echo a > a6.txt'; deliver b7 'echo a > a7.txt'; deliver b8 'echo a > a8.txt'
rm -rf "$common/xs-integrate.lock"
CHECK_GATE="echo run >> $t/runs; $xs file 'filed during the gate' >/dev/null" "$xs" integrate >/dev/null 2>&1 || fail "the integrator failed while a task was filed"
[ $(( $(wc -l < "$t/runs") - before )) = 1 ] || fail "a task filed during the gate made the round run the gate again"
[ -f a6.txt ] && [ -f a7.txt ] && [ -f a8.txt ] || fail "the integrator did not land the batch"
out=$("$xs" where) || fail "xs where failed"
grep -q '_integrate  *integrator' <<<"$out" || fail "where did not label the integrator's worktree"
deliver b9 'echo a > a9.txt'   # no lock held: land --queue starts an integrator in the background
for _ in $(seq 50); do [ -f a9.txt ] && break; sleep 0.2; done
[ -f a9.txt ] || fail "land --queue started no integrator, or it did not land the branch"
# the queue pins the tip land saw: a ref written after delivery (an agent's raw write of another branch) is ejected
for _ in $(seq 50); do [ -d "$common/xs-integrate.lock" ] || break; sleep 0.2; done   # b9's integrator lets go
mkdir "$common/xs-integrate.lock" && echo $$ > "$common/xs-integrate.lock/pid" || fail "b9's integrator kept the lock"
deliver m1 'echo a > m1.txt'; deliver m2 'echo a > m2.txt'; deliver m5 'echo a > m5.txt'
git worktree add -q .xs/worktrees/m3 -b m3 && (cd .xs/worktrees/m3 && echo a > m3.txt && git add m3.txt && git commit -q -m m3) &&
  printf 'm3\n%s\nnokeep\n' "$t/q/.xs/worktrees/m3" > "$common/xs-queue/$(date +%s)000000000-m3"   # the old format, with no tip line; its name sorts it first
unreviewed=$(git -C .xs/worktrees/m1 commit-tree -p m1 -m unreviewed "$(cd .xs/worktrees/m1 && echo b > evil.txt && git add evil.txt && git write-tree)")
git update-ref refs/heads/m1 "$unreviewed" && git update-ref -d refs/heads/m5
rm -rf "$common/xs-integrate.lock"
out=$("$xs" integrate 2>&1) || fail "xs integrate failed on a moved branch: $out"
grep -q "ejected m1: moved. m1 is at $unreviewed, not at [0-9a-f]\{40\} as delivered by land: reset it to what was delivered (git branch -f m1 " <<<"$out" || fail "the integrator did not eject a branch whose tip moved: $out"
grep -q ' - land.ejected branch=m1 reason=moved by=land$' .xs/ledger/EVENTS.log || fail "the moved ejection is not in the ledger"
[ ! -f m1.txt ] && [ ! -f evil.txt ] && ! git merge-base --is-ancestor "$unreviewed" main || fail "main took a branch whose tip moved after land"
[ "$(git rev-parse m1)" = "$unreviewed" ] || fail "the ejected moved branch was not left as it was"
[ -f m2.txt ] || fail "an unmoved branch queued beside a moved one did not land"
[ -f m3.txt ] || fail "an entry queued before the pin, with no tip, did not land"
grep -q "ejected m5: moved. m5 is at nothing" <<<"$out" && [ ! -f m5.txt ] || fail "a pinned branch deleted after land was not ejected as moved: $out"
# a ref written while the gate runs: the round lands the pinned commit, and keeps the branch that moved
mkdir "$common/xs-integrate.lock" && echo $$ > "$common/xs-integrate.lock/pid" || fail "the integrator kept the lock"
deliver m6 'echo a > m6.txt'
late=$(git -C .xs/worktrees/m6 commit-tree -p m6 -m late "$(cd .xs/worktrees/m6 && echo b > late.txt && git add late.txt && git write-tree)")
rm -rf "$common/xs-integrate.lock"
out=$(CHECK_GATE="git update-ref refs/heads/m6 $late" "$xs" integrate 2>&1) || fail "xs integrate failed on a ref moved during the gate: $out"
grep -q "m6 landed; kept m6 and its worktree: its ref moved to $late after land" <<<"$out" || fail "the integrator did not keep a branch moved during the round: $out"
[ -f m6.txt ] && [ ! -f late.txt ] && [ "$(git rev-parse m6)" = "$late" ] && [ -d .xs/worktrees/m6 ] || fail "a ref moved during the gate landed, or its branch was removed"
unset CHECK_GATE
# an ejected task stays closed, and where says why
"$xs" file "Red task" >/dev/null && "$xs" start T02 --branch r1 >/dev/null
(cd .xs/worktrees/r1 && printf '\n## Done\n\n- Proof: none.\n' >> "$t/q/.xs/ledger/tasks/T02-red-task.md" && echo a > red.txt && git add red.txt && git commit -q -m red &&
  "$xs" close T02 >/dev/null && CHECK_GATE='! test -f red.txt' "$here/scripts/land" >/dev/null 2>&1) && fail "a red branch landed"
out=$("$here/scripts/where"); grep -q "T02 closed on r1: ejected, red" <<<"$out" || fail "where did not show the ejected task: $out $(tail -5 .xs/ledger/EVENTS.log)"
git worktree add -q .xs/worktrees/u1 -b u1 && (cd .xs/worktrees/u1 && echo a > u1.txt && git add u1.txt && git commit -q -m u1 &&
  CHECK_GATE="echo x >> $t/q/.xs/ledger/EVENTS.log" "$here/scripts/land" >/dev/null 2>&1) || fail "a ledger that failed after main moved stopped land"
[ "$(git log -1 --format=%s main)" = u1 ] && ! grep -q 'branch=u1' .xs/ledger/EVENTS.log || fail "the failed ledger write is not as expected"
"$xs" file "Next" >/dev/null && grep -q ' - landed on=main .*branch=u1 by=land$' .xs/ledger/EVENTS.log || fail "the next command did not write the integrator's events"

"$xs" file --type prototype "Three layouts of the board" | grep -q -- '-three-layouts-of-the-board.md$' || fail "xs file refused a prototype"

# xs sync: with a forge's merge train the forge moves main; a closed task whose branch it merged becomes landed
repo forgesync
git init -q --bare -b main "$t/fs-origin.git" && git remote add origin "$t/fs-origin.git" && git push -q origin main
"$xs" file "Forge merged" >/dev/null && "$xs" file "Forge waiting" >/dev/null
for n in 1 2; do
  "$xs" start T0$n --branch fs$n >/dev/null && (cd .xs/worktrees/fs$n && echo $n > f$n.txt && git add f$n.txt && git commit -q -m "f$n") || fail "setup of xs sync"
  printf '\n## Done\n\n- Proof: `true`.\n' >> "$(ls .xs/ledger/tasks/T0$n-*.md)" && "$xs" close T0$n >/dev/null || fail "setup of xs sync: close"
done
git clone -q "$t/fs-origin.git" "$t/fs-clone" && (cd "$t/fs-clone" && git fetch -q "$t/forgesync" fs1 &&
  git -c user.name=forge -c user.email=forge@example.com -c commit.gpgsign=false cherry-pick FETCH_HEAD >/dev/null && git push -q origin main) || fail "setup of xs sync: the forge's rebase merge"
out=$("$xs" sync) || fail "xs sync failed: $out"
grep -q ' T01 landed status=done on=main commit=[0-9a-f]* branch=fs1 by=forge$' $L || fail "xs sync did not record the task the forge merged"
grep -q ' T02 landed' $L && fail "xs sync landed a task the forge did not merge"
[ "$("$xs" sync)" = "nothing new on origin/main" ] || fail "xs sync recorded a landing twice"
mkdir -p "$t/fakegh" && printf '#!/bin/sh\n[ "$3" = fs2 ] && echo %s && exit 0; exit 1\n' \
  "'{\"state\":\"OPEN\",\"statusCheckRollup\":[{\"conclusion\":\"FAILURE\"}]}'" > "$t/fakegh/gh" && chmod +x "$t/fakegh/gh"
out=$(LAND_FORGE=github PATH="$t/fakegh:$PATH" "$xs" sync) || fail "xs sync with a forge failed: $out"
grep -q ' T02 land.ejected branch=fs2 reason=red by=forge$' $L || fail "xs sync did not record the request the forge held back: $out"
[ "$(LAND_FORGE=github PATH="$t/fakegh:$PATH" "$xs" sync)" = "nothing new on origin/main" ] || fail "xs sync recorded an ejection twice"
"$xs" status --unlanded | grep -q '^T02 closed on fs2: ejected, red$' || fail "xs status --unlanded does not show the forge's ejection"

# p0, an incident, goes before everything
repo prio
"$xs" file --priority p1 "Slow export" >/dev/null && "$xs" file --type bug --priority p0 "Restore main: the gate is red" >/dev/null || fail "xs file refused a p0"
"$xs" next | head -n 1 | grep -q '^T02 p0 bug Restore main' || fail "xs next did not put the p0 first"

# xs install links the skills, the adapters and the hook once; xs init keeps every file a repo already has, and creates the ledger
mkdir -p "$t/home/.claude" "$t/home/.codex" && cd "$t" && h="$t/home"
HOME=$h "$xs" install >/dev/null && HOME=$h "$xs" install >/dev/null || fail "xs install failed"
[ -f "$h/.claude/skills/lead/SKILL.md" ] && [ -f "$h/.agents/skills/implementer/SKILL.md" ] && [ -f "$h/.claude/agents/reviewer.md" ] || fail "xs install did not link the skills and adapters"
[ "$(grep -c 'adapters/claude-code/guard' "$h/.claude/settings.json")" = 1 ] || fail "xs install did not register the hook once"
python3 -c "import json,sys; h=json.load(open(sys.argv[1]))['hooks']; assert [m['hooks'][0]['command'].rsplit('/',1)[1] for m in h['PreToolUse']] == ['guard', 'lifecycle'] and h['SubagentStop'][0]['hooks'][0]['command'].endswith('/lifecycle')" "$h/.claude/settings.json" || fail "xs install did not register the lifecycle hooks once"
python3 -c "import json,sys; p=sys.argv[1]; c=json.load(open(p)); c['hooks']['PreToolUse'][0]['matcher']='Bash'; json.dump(c,open(p,'w'))" "$h/.claude/settings.json"
HOME=$h "$xs" install >/dev/null && grep -q '"Bash|Agent|Task"' "$h/.claude/settings.json" || fail "xs install did not extend an older hook to spawns"
ln -s "$here/skills/distill" "$h/.claude/skills/distill" && ln -s /nowhere "$h/.claude/skills/theirs"
HOME=$h "$xs" install >/dev/null && [ ! -L "$h/.claude/skills/distill" ] && [ -L "$h/.claude/skills/theirs" ] || fail "xs install did not remove only its own dangling links"
git init -q -b main ri && cd ri && git config user.name test && git config user.email test@example.com && echo 'my rules' > AGENTS.md
HOME=$h "$xs" init >/dev/null || fail "xs init failed"
[ "$(cat AGENTS.md)" = 'my rules' ] || fail "xs init overwrote an AGENTS.md"
[ -f project/specs/README.md ] && [ -f CLAUDE.md ] && grep -qx '.xs/' .gitignore || fail "xs init did not copy the template"
[ -f .xs/ledger/tasks/README.md ] && [ ! -e project/tasks ] && git rev-parse -q --verify xs-ledger >/dev/null || fail "xs init did not create the ledger"

# xs answer with the answer: it is written in the decision's Done section, then the decision closes
repo xsa
"$xs" ask "Which relay?" >/dev/null && "$xs" file "A task" >/dev/null
"$xs" answer T02 "no" >/dev/null 2>&1 && fail "xs answer took a task that is no decision"
"$xs" answer T01 "" >/dev/null 2>&1 && fail "xs answer took an empty answer"
"$xs" answer T01 "The council's relay; see ADR 0002" >/dev/null || fail "xs answer refused an answer"
[ "$(tail -n 3 .xs/ledger/tasks/T01-*.md | tr '\n' '|')" = "## Done||The council's relay; see ADR 0002|" ] || fail "xs answer did not write the answer in Done"
"$xs" status T01 | grep -q '^T01: done' && grep -q ' T01 question.answered status=done by=test$' $L || fail "xs answer did not close the decision"
"$xs" answer T01 "again" >/dev/null 2>&1 && fail "xs answer answered a closed decision"
printf '\n## Done\n\n- Proof: by hand.\n' >> .xs/ledger/tasks/T02-a-task.md && "$xs" close T02 >/dev/null
"$xs" status T02 | grep -q '^T02: done' || fail "a task never started stays closed for ever"

# xs migrate moves a tracker kept on main to the ledger, once, with migrated events where a file disagreed with its events
repo mig
mkdir -p project/tasks project/specs project/adr
printf -- '---\ntitle: a\ntype: task\nstatus: done\npriority: p2\nclosed: 2026-11-19\n---\n\n## Done\n\nok\n' > project/tasks/T01-a.md
printf -- '---\ntitle: b\ntype: task\nstatus: doing\nbranch: x\npriority: p1\n---\n' > project/tasks/T02-b.md
printf 'T05-T09 x\n' > project/tasks/RESERVED
mkdir project/tasks/archive && printf -- '---\ntitle: old\n---\n' > project/tasks/archive/T00-old.md
printf -- '---\ntitle: c\ntype: task\nstatus: in-progress\npriority: p2\n---\n' > project/tasks/T03-c.md
printf '2026-11-18T10:00:00Z project/mig T01 task.filed status=todo by=test\n2026-11-19T10:00:00Z project/mig T01 task.closed status=done by=test\n' > project/EVENTS.log
printf -- '---\nowner: test\nstatus: ready\n---\n\n## Outcome\n\nx.\n\n## Log\n\n- 2026-11-19: approved by test: all\n- 2026-11-20: built in the run, approved by that direction.\n' > project/specs/S01-a.md
printf '# We do a\n\nAccepted on 2026-11-19 by test.\nBuilt: yes (T01)\n\n## Decision\n\nA.\n' > project/adr/0001-a.md
printf 'project/EVENTS.log merge=union\nx merge=binary\n' > .gitattributes
git add -A && git commit -q -m "the old layout"
"$xs" migrate >/dev/null || fail "xs migrate failed"
grep -q '^2026-11-19T10:00:00Z project/mig T01 task.closed status=done by=test$' $L || fail "xs migrate lost an event"
grep -q ' T02 task.migrated status=doing branch=x src=migrate$' $L || fail "xs migrate recorded no state for a task without events"
grep -q ' T01 task.migrated' $L && fail "xs migrate recorded a state the events already gave"
grep -q '^status:' .xs/ledger/tasks/T02-b.md && fail "xs migrate kept a status line"
[ -e .xs/ledger/tasks/RESERVED ] && fail "xs migrate kept RESERVED"
! grep -q 'by=that' $L && grep -q ' S01 spec.approved by=test src=migrate$' $L && grep -q ' S01 spec.migrated status=ready src=migrate$' $L || fail "xs migrate missed the spec's approval or status"
[ -f .xs/ledger/tasks/archive/T00-old.md ] || fail "xs migrate lost a folder of tasks"
grep -q ' T03 task.migrated status=todo was=in-progress src=migrate$' $L || fail "xs migrate erased a status outside the vocabulary"
grep -q 'approved by test: all' .xs/ledger/logs/S01.md && ! grep -q '^## Log\|^status:' project/specs/S01-a.md || fail "xs migrate did not move the spec's Log"
grep -q ' ADR-0001 adr.migrated status=accepted built=yes_(T01) src=migrate$' $L || fail "xs migrate missed the ADR's header"
! grep -q '^Accepted\|^Built' project/adr/0001-a.md && grep -q '^A\.$' project/adr/0001-a.md || fail "xs migrate did not strip the ADR's header, or touched its decision"
[ "$(git status --porcelain project/tasks project/EVENTS.log | grep -c '^D ')" = 6 ] || fail "xs migrate did not remove the old tracker from main"
[ "$(cat .gitattributes)" = 'x merge=binary' ] || fail "xs migrate did not clean .gitattributes"
"$xs" status S01 | grep -q '^S01: ready' && "$xs" status T02 | grep -q '^T02: doing, branch x' || fail "the migrated state is wrong"
"$xs" migrate >/dev/null 2>&1 && fail "xs migrate ran twice"
repo migs && mkdir -p project/specs && printf -- '---\nowner: test\nstatus: draft\n---\n\n## Outcome\n\nx.\n' > project/specs/S01-a.md
git add -A && git commit -q -m specs && "$xs" migrate >/dev/null && ! grep -q '^status:' project/specs/S01-a.md || fail "xs migrate refused a repo with only specs"
echo "test.sh: ok"
