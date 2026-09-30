#!/usr/bin/env bash
# usage: setv.sh <HEAD|D123|U|Unest> — installs that Observer/Effect pair into the worktree (stays installed)
W=/code/Projects/quad/.claude/worktrees/agent-a57474fa822e253a8
SCR=/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/obs-eff-unify
A=/code/Projects/quad/.claude/audit/round13-obs-eff-root
case $1 in
  HEAD) cp $SCR/Observer.HEAD.luau $W/quad-base/src/Observer.luau; cp $SCR/Effect.HEAD.luau $W/quad-base/src/Effect.luau;;
  D123) cp $A/Observer.D2.luau $W/quad-base/src/Observer.luau; cp $A/Effect.P3Ea.luau $W/quad-base/src/Effect.luau;;
  *) cp $SCR/Observer.$1.luau $W/quad-base/src/Observer.luau; cp $SCR/Effect.$1.luau $W/quad-base/src/Effect.luau;;
esac
echo "installed $1"
