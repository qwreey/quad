#!/usr/bin/env bash
# Run `luau-lsp analyze` on probe files with a reconstructed user-environment flag set.
#   harness/run-cli.sh <mode> <file...>
# modes:
#   vsc   — the user's VSCode: extension-bundled luau-lsp 1.70.1 + extension-downloaded
#           globalTypes.PluginSecurity.d.luau + Roblox sync FFlags + workspace override (limit flags)
#   sync  — same binary/defs, Roblox sync FFlags only (no override; Studio's own limits)
#   pin   — repo pin: mise luau-lsp 1.69.0 + scripts/roblox-defs/globalTypes.d.luau + sync + override
#   pinsync — repo pin, sync only
# Always --no-flags-enabled (the extension's default) — NOT the CLI default "all FFlags on".
# Memory: choom 1000 (OOM victim first) + prlimit 3 GiB data (conventions.md budget).
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../../../.." && pwd)"
EXT=/code/.local/share/code-docker/code/extensions/johnnymorganz.luau-lsp-1.70.1-linux-x64/bin/server
EXTDEFS=/code/.local/share/code-docker/code/user-data/User/globalStorage/johnnymorganz.luau-lsp/globalTypes.PluginSecurity.d.luau
PINDEFS="$ROOT/scripts/roblox-defs/globalTypes.d.luau"
SNAP="$HERE/../flags/roblox-sync-2026-10-16.json"
mode="$1"; shift
case "$mode" in
  vsc) BIN="$EXT"; DEFS="$EXTDEFS"; OV=--override ;;
  sync) BIN="$EXT"; DEFS="$EXTDEFS"; OV= ;;
  pin) BIN="$(cd "$ROOT" && mise which luau-lsp)"; DEFS="$PINDEFS"; OV=--override ;;
  pinsync) BIN="$(cd "$ROOT" && mise which luau-lsp)"; DEFS="$PINDEFS"; OV= ;;
  *) echo "unknown mode $mode" >&2; exit 2 ;;
esac
mapfile -t FLAGS < <(python3 "$HERE/flags.py" args "$SNAP" $OV)
# "Unknown FFlag: X" lines (the binary does not know some synced flags — same as the extension) are dropped.
choom -n 1000 -- prlimit --data=3221225472 -- "$BIN" analyze --no-flags-enabled --platform=roblox \
  "--definitions=@roblox=$DEFS" "${FLAGS[@]}" "$@" 2>&1 | grep -v -e '^Unknown FFlag' -e '^\[INFO\]'
exit "${PIPESTATUS[0]}"
