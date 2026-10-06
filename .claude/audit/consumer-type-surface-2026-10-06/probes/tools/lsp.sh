#!/bin/bash
cd "$1"; shift
mise trust -q mise.toml >/dev/null 2>&1
mise exec -- luau-lsp analyze --flag:LuauSolverV2=true --flag:LuauTarjanChildLimit=160000 --flag:LuauSubtypingIterationLimit=100000 --flag:LuauTypeInferIterationLimit=1000000 --definitions=scripts/roblox-defs/globalTypes.d.luau --ignore "**/luau_packages/**" "$@" 2>&1 | grep -v '^\[INFO\]'
