#!/usr/bin/env bash
# test.sh on clean D1 (HEAD Effect) and D2+D3 (Observer stamp + Effect (a')), write diffs vs HEAD
SCR=/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/obs-eff-root
W=/code/Projects/quad/.claude/worktrees/agent-a44a4548414d6d6dd
cd $W
git show HEAD:quad-base/src/Observer.luau > $SCR/Observer.HEAD.luau
git show HEAD:quad-base/src/Effect.luau > $SCR/Effect.HEAD.luau
cp $SCR/Observer.D1.luau quad-base/src/Observer.luau; cp $SCR/Effect.HEAD.luau quad-base/src/Effect.luau
./scripts/test.sh > $SCR/testsh.D1.txt 2>&1; echo "D1 test.sh exit $?"
cp $SCR/Observer.D2.luau quad-base/src/Observer.luau; cp $SCR/Effect.P3Ea.luau quad-base/src/Effect.luau
./scripts/test.sh > $SCR/testsh.D1D2D3.txt 2>&1; echo "D1+D2+D3 test.sh exit $?"
cd $SCR
diff -u --label a/quad-base/src/Observer.luau --label b/quad-base/src/Observer.luau Observer.HEAD.luau Observer.D1.luau > D1-observer-install-loop.diff
diff -u --label a/quad-base/src/Observer.luau --label b/quad-base/src/Observer.luau Observer.D1.luau Observer.D2.luau > D2-observer-source-revision-stamp.on-D1.diff
diff -u --label a/quad-base/src/Effect.luau --label b/quad-base/src/Effect.luau Effect.HEAD.luau Effect.P3Ea.luau > D3-effect-catchup-sync-epoch-deps.diff
diff -u --label a/quad-base/src/Effect.luau --label b/quad-base/src/Effect.luau Effect.HEAD.luau Effect.P3E.luau > D3alt-effect-sync-epoch-deps-every-run.diff
wc -l D*.diff
grep -c '^[+-][^+-]' D1-observer-install-loop.diff D2-observer-source-revision-stamp.on-D1.diff D3-effect-catchup-sync-epoch-deps.diff
