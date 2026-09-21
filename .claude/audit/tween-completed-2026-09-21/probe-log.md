# TweenBase.Completed probe — raw logs (2026-09-21)

Studio: Place1.rbxl, id 178322bc-3cc4-411c-8461-bd639a4a5e2a, Edit mode.
Scratch root: workspace.QuadTweenProbe (created+destroyed per test unless noted).

## Test 1 — natural finish

```
Play-called @ 430599.3600 | Completed(Enum.PlaybackState.Completed) @ 430599.5432 | PlaybackState-after=Enum.PlaybackState.Completed @ 430599.8762
```

Confirmed: exactly one Completed(Completed) fires (~0.18s after Play, matches 0.2s tween). tween.PlaybackState after wait = Completed.

## Test 2 — Cancel after it already completed

```
Completed(Enum.PlaybackState.Completed) @ 430614.9756 | finished, PlaybackState=Enum.PlaybackState.Completed Position={1, 0}, {0, 0} @ 430615.3081 | Cancel-returned @ 430615.3081 | Completed(Enum.PlaybackState.Cancelled) @ 430615.3082 | after-wait, PlaybackState=Enum.PlaybackState.Cancelled Position={1, 0}, {0, 0} @ 430615.6090
```

Findings: `:Cancel()` on an ALREADY-FINISHED tween DOES fire `Completed` again, with `Enum.PlaybackState.Cancelled` (even though the tween had already fired `Completed(Completed)` once). It appears in the log after "Cancel-returned" but before "after-wait" — i.e. it surfaces at the next yield point (the `task.wait(0.3)` immediately following), not before `Cancel()` returns. `tween.PlaybackState` becomes `Cancelled` after. The property VALUE does not change/reset — `frame.Position` stays at the tween's target `{1,0},{0,0}` both right after natural completion and after the later Cancel.

## Test 3 — Cancel while running (sync vs deferred)

```
after-cancel-returned @ 430640.0908 | Completed(Enum.PlaybackState.Cancelled) @ 430640.0908 | final-check PlaybackState=Enum.PlaybackState.Cancelled @ 430640.3077
```

Findings: `Completed(Cancelled)` DOES fire when cancelling a running tween. Log order is "after-cancel-returned" THEN "Completed(Cancelled)" — the log entry for "after-cancel-returned" was appended synchronously right after `:Cancel()` returned (same clock tick), and only the following `task.wait(0.2)` yield let the Completed signal actually run. So the Completed(Cancelled) signal is DEFERRED, not fired synchronously inside the `:Cancel()` call — it queues and fires at the next resumption point (matches "events in this place are Deferred").

## Test 4 — ordering across replace (A cancelled, B started)

Run 1 (no yield between `A:Cancel()` and `B:Play()`):
```
B-started-marker @ 430660.5736 | A-Completed(Enum.PlaybackState.Cancelled) @ 430660.5736 | B-Completed(Enum.PlaybackState.Completed) @ 430660.8567 | run1-done @ 430661.3902
```
Order: `B-started-marker` → `A Completed(Cancelled)` → `B Completed(Completed)`. `B:Play()` (called synchronously right after the marker) does not itself yield, so both A's deferred Cancelled-completion and B's later natural completion only surface at the following `task.wait(0.8)`.

Run 2 (a bare `task.wait()` inserted between `A2:Cancel()` and `B2:Play()`):
```
B2-started-marker-before-wait @ 430661.6067 | A2-Completed(Enum.PlaybackState.Cancelled) @ 430661.6067 | B2-started-marker-after-wait @ 430661.6229 | B2-Completed(Enum.PlaybackState.Completed) @ 430661.9237 | run2-done @ 430662.4237
```
Order: `B2-started-marker-before-wait` → `A2 Completed(Cancelled)` → `B2-started-marker-after-wait` → `B2 Completed(Completed)`.

**Does the order change?** Yes. In run 1, A's `Completed(Cancelled)` surfaces only at the wait AFTER `B:Play()` was already called (so relative to the B-Play call, A's cancellation notice arrives "late"/interleaved with B's own lifecycle). In run 2, inserting a yield between `Cancel()` and `Play()` makes A's deferred `Completed(Cancelled)` fire and drain BEFORE `B2:Play()` is ever called. So whether the old tween's Cancelled-completion notice is observed before or after the new tween starts depends entirely on whether a yield point exists between the `Cancel()` call and the next `Play()` call — the signal itself is always deferred (never synchronous inside `Cancel()`), so a purely synchronous call sequence (no `task.wait` in between) does not guarantee the old one's Completed fires before the new one is played; it just guarantees it fires before the new one's own eventual Completed.

## Test 5 — Instance destroyed mid-tween

```
frame-destroyed @ 430688.9558 | Completed(Enum.PlaybackState.Completed) @ 430689.7391 | after-wait PlaybackState=Enum.PlaybackState.Completed conn.Connected=true tween.Instance-is-frame=true frame.Parent=nil @ 430690.1719
```

Findings: `:Destroy()` on the tween's target Instance does NOT cancel/stop the running engine tween. The tween kept running on the now-parentless (destroyed) Frame and fired `Completed(Enum.PlaybackState.Completed)` (NOT Cancelled) at its natural ~1s mark (~0.78s after the destroy, consistent with the 1s TweenInfo minus the 0.2s already elapsed) — this matches the header comment in `Property.luau` ("Before: the engine tween ran on into the destroyed child"). `tween.PlaybackState` afterward = `Completed`. The `Completed` connection's `.Connected` is still `true` (destroying the target does not disconnect it). `tween.Instance` still returns the (destroyed) frame (`== frame` is true) — the tween object keeps a live reference to the destroyed Instance. `frame.Parent` is `nil` as expected.

## Test 6 — Parent removed (not destroyed) vs destroyed

```
parent-removed @ 430709.6384 | Completed(Enum.PlaybackState.Completed) @ 430710.4218 | after-wait PlaybackState=Enum.PlaybackState.Completed Position={1, 0}, {0, 0} frame.Parent=nil @ 430710.8544
```

Findings: setting `frame.Parent = nil` behaves the same as `:Destroy()` for tween purposes — the tween keeps running to natural completion (`Completed(Completed)`, not Cancelled) even though the Frame is unparented, and the property (`Position`) is actually updated to the tween's target value on the orphaned instance. No difference from test 5 was observed other than the Instance object remaining otherwise usable (not destroyed) — the engine tween is entirely independent of the target's place in the DataModel tree; only explicit `:Cancel()` or `:Pause()` stop it.

## Test 7 — weak-key table + value closure capturing the key (ephemeron question)

Technique: same GC-observation idiom as `round11-studio-2026-09-21/REPORT.md` item 5 (per-epoch `table.create(5000)`×20 allocation pressure + `task.wait(0.05)`, cap 150 epochs, check when the table entry disappears via `next(wk) == nil`).

Main experiment (ephemeron case vs. non-capturing control), run together:
```
lastEpoch=8 controlEmptyAt=8 ephemeronEmptyAt=8
```
Sanity check (key kept strongly alive elsewhere — must NEVER be collected, validates the technique isn't a false-positive):
```
pinnedKey-still-alive=true wkPinned-ever-empty=false
```

Findings: with `wk = setmetatable({}, {__mode="k"})`, `key = Instance.new("Frame")` (unparented), `wk[key] = function() return key end`, then dropping the local `key` — the entry WAS collected (`next(wk) == nil` became true), at the same epoch (8) as the control case where the value does NOT capture the key. The sanity control (key held strongly elsewhere) never became empty across 40 epochs, confirming the observation technique correctly distinguishes "collectible" from "pinned". **Conclusion: Luau's weak-key tables implement true ephemeron semantics** — a value that closes over its own key does not artificially keep that key alive; the key's weak-table entry is collected purely based on the key's own external reachability, exactly like a value that doesn't reference the key at all. **This CONTRADICTS the doc comment in `Property.luau` ("Luau has no ephemerons") — see the final note below.**

Repeat run (with epoch-by-epoch trace for the first 15 epochs) confirms reproducibility and shows no lag between the two cases:
```
controlEmptyAt=5 ephemeronEmptyAt=5 trace=[e1:c=false,e=false e2:c=false,e=false e3:c=false,e=false e4:c=false,e=false e5:c=true,e=true]
```
Both tables stay populated in lockstep and flip to empty in the exact same epoch, both runs (epoch 8 first run, epoch 5 second run — epoch count itself varies run to run, but the two cases never diverge within a run). This rules out both "never collected" (classic pre-ephemeron Lua 5.1 resurrection bug) and "collected later than the control" (a fixpoint-but-slower algorithm) — the two cases are indistinguishable in timing.

## Test 8 — Completed connection does not pin the frame after finish

```
frame-collected-at-epoch=14 (nil = not collected within 150 epochs)
```

Findings: Frame tweened (0.2s), `Completed` connected with a closure capturing `frame`, tween allowed to finish, then `frame:Destroy()` and all local references dropped (connection left live/`.Connected == true`, never disconnected) — only a `weak-key` table entry (`wk[frame] = true`) remains reachable. The frame WAS collected (epoch 14). Confirms an `RBXScriptConnection`'s callback closure does not keep its captured Instance alive once the closure itself becomes unreachable (i.e. once nothing outside references the tween/connection anymore) — a live-but-dangling connection is not by itself a GC root pinning its capture.

## Engine facts relevant to quad's `Property.luau` (read lines 1-229, not modified)

Read `quad-roblox/src/Handlers/Property.luau` — quad's `tweenSlots`/`tweenRetractors` (`quad.Relate()`, weak-keyed by `inst`) currently cancels the previous engine tween synchronously inside its own `process`/retractor logic (`prev.Tween:Cancel()` called directly, not by waiting on the `Completed` signal) before playing/writing the new value. Facts above that matter if `OnCancelled`/`OnCompleted`/`OnStarted` are added:

- **Synchronous `:Cancel()` call site vs. engine `Completed` signal are NOT the same moment.** Tests 2/3/4 show the engine's own `Completed(Cancelled)` notification is always DEFERRED — it never fires synchronously inside `:Cancel()`, only at the next yield point. So if `OnCancelled` is implemented by listening to the tween's own `Completed` event, it will fire measurably later (and out of order relative to quad's own subsequent synchronous work — see test 4) than the point where quad's dispatch logic decided to cancel. **If `OnCancelled` needs to be synchronous with quad's own `:Cancel()` call (matching quad's usual synchronous dispatch semantics elsewhere in the codebase), it must be invoked directly at the call site — not via `tween.Completed:Connect`.** Relying on the engine signal would make `OnCancelled` observably async/deferred relative to everything else quad does synchronously in `process`/the retractor.
- **A finished tween can still receive `Completed(Cancelled)` again if `:Cancel()` is called on it after it already finished** (test 2). Property.luau's retractor already calls `prev.Tween:Cancel()` unconditionally on teardown even when `prev.Tween`'s state may already be `Completed` (nothing in the code checks `PlaybackState` first) — so a naive `Completed`-signal-based `OnCancelled`/`OnCompleted` pairing could see a SECOND `Completed` firing (with `Cancelled`) for a tween whose `OnCompleted` already fired naturally. Callback authors would need to be told (or quad would need to suppress) this double-fire if wiring straight to the engine signal.
- **Ordering across a replace (test 4) is only deterministic relative to the NEW tween's own natural completion, not relative to when the new tween's `Play()` was called** — the old tween's deferred `Completed(Cancelled)` can land either before or after the new `:Play()` call depending on whether a yield happens in between. Since `Property.luau`'s `process` runs fully synchronously (cancel old → build/write new → `Play()`, no yields), any engine-signal-based `OnCancelled` for the old tween is guaranteed to be observed strictly AFTER `process` has already started/is playing the new tween — i.e. by the time an engine-signal `OnCancelled` for A fires, `OnStarted` for B may already have been called (if `OnStarted` is synchronous at the `Play()` call site). This is a real ordering hazard for anyone assuming "cancelled" always precedes "started" for the replacement.
- **Destroying/unparenting the target Instance does not stop the engine tween or fire `Cancelled`** (tests 5/6) — it runs to natural completion and fires ordinary `Completed(Completed)`, even on a destroyed/orphaned Instance, and the property write still lands on the dead Instance. `Property.luau`'s retractor path is only reached through quad's own teardown (which calls `:Cancel()` explicitly), so this only matters if some caller destroys the Instance through a path that bypasses quad's dispatch/retraction (documented UB elsewhere in this repo, e.g. Q9 "zombie Slot" — the same class of gap: an engine tween on a quad-orphaned Instance is not something `Completed`-signal-based hooks would ever see fire as Cancelled).
- **Weak-key GC behavior (tests 7/8) is favorable, and the `Property.luau` header comment "Luau has no ephemerons" (used to justify making `tweenRetractors`'s bucket VALUE weak, to avoid the retractor closure — which captures `inst` — pinning its own weak key) appears to be based on an incorrect assumption.** Measured here: Luau's weak-key (`__mode="k"`) tables DO behave as true ephemerons — a value closure capturing its own key does not pin that key any differently than a non-capturing value (tests 7, two independent runs, epoch-by-epoch trace showing zero lag between the two cases). This does not mean the current design (weak value, closure captures `inst`) is wrong — it is still correct and safe — but the STATED REASON in the comment ("Luau has no ephemerons") does not hold up under this measurement, and a strong-value bucket (closure as value, capturing its own key) might actually have been fine too. This is a documentation-accuracy finding, not a functional bug — flagging for whoever revisits that comment.

## Unfinished items

None — all 8 measurements plus the `Property.luau` read completed.

