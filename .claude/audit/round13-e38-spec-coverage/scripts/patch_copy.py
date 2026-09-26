"""Patch a SCRATCH COPY of the repo (never the repo): line-number-preserving.
 - src modules (incl. luau_packages/.pesde copies): local `error` wrapper printing @@QERR (E28 idea), prepended on the
   first non-directive line (no new line → coverage/blame line numbers unchanged).
 - spec/smoke files: local `pcall`/`xpcall` shims printing @@PC for every failed spec-level pcall, prepended on line 1.
"""
import os, re, sys
root = sys.argv[1]
ERR = ('local __qraw_error = error; local function error(m: any, l: number?): never if type(m) == "string" and '
       'string.find(m, "Quad%d%d%d%d") then print("@@QERR\\t" .. (string.gsub(m, "\\n", "\\\\n"))) end '
       'if l == 0 then __qraw_error(m, 0) end __qraw_error(m, (l or 1) + 1) end; ')
PC = ('local __rawpcall, __rawxpcall = pcall, xpcall; local function __pcrep(ok, ...) if not ok then '
      'local e = ...; print("@@PC\\t" .. (string.gsub(tostring(e), "\\n", "\\\\n"))) end return ok, ... end; '
      'local function pcall(f, ...) return __pcrep(__rawpcall(f, ...)) end; '
      'local function xpcall(f, h, ...) return __pcrep(__rawxpcall(f, h, ...)) end; '
      'local string = setmetatable({}, { __index = string }); do local rf, rm = string.find, string.match; '
      'local function rep(s, p, a) if a ~= nil and type(s) == "string" then for id in (string.gmatch :: any)(s, "Quad%d%d%d%d") do '
      'print("@@FIND\t" .. id .. "\t" .. tostring(p)) end end end; '
      'string.find = function(s, p, ...) local r = table.pack(rf(s, p, ...)); rep(s, p, r[1]); return table.unpack(r, 1, r.n) end; '
      'string.match = function(s, p, ...) local r = table.pack(rm(s, p, ...)); rep(s, p, r[1]); return table.unpack(r, 1, r.n) end end; ')
ns = nt = 0
for dp, dn, fn in os.walk(root):
    for f in fn:
        if not f.endswith('.luau'): continue
        p = os.path.join(dp, f)
        t = open(p).read()
        lines = t.split('\n')
        is_test = '/test' in dp and '/src' not in dp
        if is_test and (f.startswith('spec.') or f.startswith('smoke.')):
            lines[0] = PC + lines[0]; nt += 1
        elif '/src' in dp and re.search(r'\berror\s*\(', t):
            i = 0
            while i < len(lines) and lines[i].startswith('--!'): i += 1
            lines[i] = ERR + lines[i]; ns += 1
        else:
            continue
        open(p, 'w').write('\n'.join(lines))
print('src', ns, 'tests', nt)
