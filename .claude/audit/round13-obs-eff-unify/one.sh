#!/usr/bin/env bash
# usage: one.sh <probe.luau (abs path)> [args...] — copies into quad-base/test as xr_one.luau and runs it there
W=/code/Projects/quad/.claude/worktrees/agent-a57474fa822e253a8
P=$1; shift
cd $W && ./scripts/relink.sh >/dev/null 2>&1
cp "$P" $W/quad-base/test/xr_one.luau
cd $W/quad-base/test
timeout 300 luau xr_one.luau "$@" 2>&1
echo "exit $?"
rm -f xr_one.luau
