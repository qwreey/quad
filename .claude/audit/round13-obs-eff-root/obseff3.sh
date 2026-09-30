#!/usr/bin/env bash
# runs xprobe-obseff for base / P1b / P3 and leaves P3 installed
SCR=/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/obs-eff-root
W=/code/Projects/quad/.claude/worktrees/agent-a44a4548414d6d6dd
for v in base P1b P3; do
  if [ $v = base ]; then src=HEAD; else src=$SCR/Observer.$v.luau; fi
  bash $SCR/obsv.sh $v $src >/dev/null
  mkdir -p $SCR/out/$v
  cd $W && ./scripts/relink.sh >/dev/null 2>&1
  cd $W/quad-base/test && luau xprobe-obseff.luau > $SCR/out/$v/obseff.txt 2>&1
done
diff $SCR/out/base/obseff.txt $SCR/out/P1b/obseff.txt > $SCR/obseff.base-P1b.diff
diff $SCR/out/P1b/obseff.txt $SCR/out/P3/obseff.txt > $SCR/obseff.P1b-P3.diff
echo "== base -> P1b"; cat $SCR/obseff.base-P1b.diff
echo "== P1b -> P3"; cat $SCR/obseff.P1b-P3.diff
echo "== P3 tail"; tail -n 12 $SCR/out/P3/obseff.txt
