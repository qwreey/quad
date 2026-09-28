#!/usr/bin/env bash
# usage: run.sh <worktree> <base|variant> [TEARDOWN_WINDOW_AS] [ARM_AT_STARTED] [spec]
# Installs Property.luau (HEAD baseline or the spike variant with switches), runs the probe; "spec" also runs test.sh.
W=$1; S=$(dirname "$0"); P=$W/quad-roblox/src/Handlers/Property.luau
if [ "$2" = base ]; then cp "$S/Property.base.luau" "$P"; else
	cp "$S/Property.variant.luau" "$P"
	sed -i -E "s/^local TEARDOWN_WINDOW_AS = .*/local TEARDOWN_WINDOW_AS = \"${3:-Completed}\"/; s/^local ARM_AT_STARTED = .*/local ARM_AT_STARTED = ${4:-false}/" "$P"
fi
echo "##### $2 TEARDOWN_WINDOW_AS=${3:-Completed} ARM_AT_STARTED=${4:-false}"
if [ "$5" = spec ]; then (cd "$W" && ./scripts/test.sh > "$S/test-$2-${3:-Completed}-${4:-false}.log" 2>&1; echo "test.sh exit $?"); fi
(cd "$W/quad-roblox" && luau test/probe.cbs.luau 2>&1)
