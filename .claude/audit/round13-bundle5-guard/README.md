# bundle5 guard — Q93 (a) + Q98 (a″) before/after

Worktree: `/code/Projects/quad/.claude/worktrees/agent-a54c27f3275bd7cf8` (HEAD ea41a076, only
`quad-base/src/State.luau` modified = `State.guards.diff`). Baseline copy: `State.before.luau`.

## Trees
`tree.before/` and `tree.after/` = copies of the worktree's relinked `quad-base quad-roblox quad-types
quad-error type-version-check` (after `./scripts/test.sh`), with State.luau swapped in BOTH places
(`quad-base/src/` and `quad-roblox/luau_packages/.pesde/qwreey+quad_base/3.2.0/quad_base/src/`).

## Runs (scripts/ — the sandbox only let them run from inside the worktree; copy there to rerun)
- test.sh: `testsh.before.txt` / `testsh.after.txt` (exit 0 / 0; outputs identical except the relink count line).
- per-file spec/smoke output: `scripts/specout.sh <dir>` → `spec.before/` vs `spec.after/` — 62 files, byte identical.
- existing probes (copied from `.claude/audit/round13-q9{3,8}-proto/`, `round13-e3-probe.luau`):
  `scripts/runprobe.sh <probe> quad-base/test [args]` → `out/<name>.{before,after}.txt`.
  q98-probe.after == prototype `q98probe.q93q98b.txt`; q98-yield-fuzz 20000 = prototype numbers.
- new: `b5-probe.luau` (quad-base, scenarios N1–N10), `b5-roblox.luau` (quad-roblox Animate path):
  `scripts/runprobe.sh b5-probe.luau quad-base/test`, `scripts/runprobe.sh b5-roblox.luau quad-roblox/test`.
- new: `b5-trace-fuzz.luau` — defined-path differential fuzzer (canonicalised per step, see header):
  `scripts/runtwice.sh b5-trace-fuzz.luau quad-base/test tfd50000 50000 defined` (noise check = before twice)
  and `... tfu5000 5000 ub` (positive control). Summaries: `out/tfd50000.summary.txt`, `out/tfu5000.summary.txt`.
  The only differing defined seed (3381) is subscriber-order noise: `out/seed3381-rep.txt` shows the same two
  hashes in both trees (Debounce timers with equal due time; tie-break = emit order).
