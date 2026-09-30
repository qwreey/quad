#!/usr/bin/env bash
# usage: obsv.sh <label> <Observer.luau source|HEAD>  — installs that Observer.luau into the worktree (stays installed)
W=/code/Projects/quad/.claude/worktrees/agent-a44a4548414d6d6dd
if [ "$2" = "HEAD" ]; then git -C "$W" show HEAD:quad-base/src/Observer.luau > "$W/quad-base/src/Observer.luau"
else cp "$2" "$W/quad-base/src/Observer.luau"; fi
echo "installed $2 as $1"
