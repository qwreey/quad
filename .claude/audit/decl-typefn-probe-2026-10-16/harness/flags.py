#!/usr/bin/env python3
"""Reconstruct the FFlag set the VSCode luau-lsp extension (1.70.1) sends to its server.

Mirrors dist/extension.js of johnnymorganz.luau-lsp-1.70.1:
  - server started with --no-flags-enabled (fflags.enableByDefault = false)
  - fflags.sync: GET clientsettingscdn v1 PCStudioApp, keep keys starting with
    FFlagLuau / FIntLuau / DFFlagLuau / DFIntLuau, strip the FFlag/FInt/DFFlag/DFInt prefix
  - fflags.enableNewSolver -> LuauSolverV2 = "true"
  - fflags.override (workspace) applied last
Usage:
  flags.py fetch <out.json>          # snapshot the sync set (no overrides)
  flags.py args <snapshot.json> [--override]   # print --flag:K=V args for `luau-lsp analyze`
  flags.py init <snapshot.json> [--override]   # print JSON for LSP initializationOptions.fflags
"""
import json, sys, urllib.request

URL = "https://clientsettingscdn.roblox.com/v1/settings/application?applicationName=PCStudioApp"
PREFIXES = ("FFlag", "FInt", "DFFlag", "DFInt")
# repo .vscode/settings.json (and the user's code-server User settings) — identical override block
OVERRIDE = {
    "LuauTarjanChildLimit": "160000",
    "LuauSubtypingIterationLimit": "100000",
    "LuauTypeInferIterationLimit": "1000000",
}


def fetch():
    with urllib.request.urlopen(URL, timeout=20) as r:
        data = json.load(r)["applicationSettings"]
    out = {}
    for k, v in data.items():
        for p in PREFIXES:
            if k.startswith(p + "Luau"):
                out[k[len(p):]] = v
    return out


def build(snapshot, override):
    flags = dict(snapshot)
    flags["LuauSolverV2"] = "true"
    if override:
        flags.update(OVERRIDE)
    return flags


def main():
    cmd = sys.argv[1]
    if cmd == "fetch":
        snap = fetch()
        json.dump(dict(sorted(snap.items())), open(sys.argv[2], "w"), indent=1)
        print(f"{len(snap)} flags; LuauDoNotExportBrokenTypeFunction={snap.get('LuauDoNotExportBrokenTypeFunction')}")
    else:
        snap = json.load(open(sys.argv[2]))
        flags = build(snap, "--override" in sys.argv)
        if cmd == "args":
            print("\n".join(f"--flag:{k}={v}" for k, v in flags.items()))
        elif cmd == "init":
            print(json.dumps(flags))


if __name__ == "__main__":
    main()
