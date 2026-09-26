#!/bin/bash
# run_copy.sh <variant> <files...>   (run inside copy)
SC=/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/q87
v=$1; shift
cd $SC/qr_$v && /code/.local/share/mise/installs/github-johnny-morganz-luau-lsp/1.69.0/luau-lsp analyze --flag:LuauSolverV2=true \
	--flag:LuauTarjanChildLimit=160000 --flag:LuauSubtypingIterationLimit=100000 --flag:LuauTypeInferIterationLimit=1000000 \
	--definitions=/code/Projects/quad/scripts/roblox-defs/globalTypes.d.luau --ignore "**/luau_packages/**" "$@" 2>&1 | grep -v '^\[INFO'
