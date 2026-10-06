# "after" variant used by the probes: a scratch copy of HEAD 261e69ac with the pending guard removals applied
# by hand (one way to remove each; the real reflection may differ). Run with the quad-base/src path of the copy;
# the Property.luau edit (Q166) goes to the copy's quad-roblox/src/Handlers/Property.luau.
import sys
root = sys.argv[1]
def patch(path, old, new, count=1):
    s = open(path).read()
    assert s.count(old) == count, (path, old[:60], s.count(old))
    open(path, 'w').write(s.replace(old, new))
# Q176: Tag depth guard Quad0201
patch(root + '/Tag.luau', '\t\tif depth > 64 then\n\t\t\tErr.errorBeforeNearest("Quad0201', '\t\tif false then\n\t\t\tErr.errorBeforeNearest("Quad0201')
# Q170: Slot CRUD pre-scan (existing elements seeded as "held")
patch(root + '/Slot/init.luau', '''\t\tfor _, existing in ipairs(self._elements) do
\t\t\tlocal occ = occupantOf(existing)
\t\t\tif occ ~= nil then seen[occ] = "held" end
\t\tend''', '\t\t-- PROBE: pre-scan removed (Q170)')
# Q171: H-240 getOffsetAt restart + recompute checks 1 and 2
patch(root + '/Bookkeeping.luau', '\t\t\tif bk.offsetCacheValidUpTo < i then\n\t\t\t\t-- `H-240`: that', '\t\t\tif false then\n\t\t\t\t-- `H-240`: that')
patch(root + '/Bookkeeping.luau', '-- BEFORE the write below stomps the signal\n\t\t\t\tif bk.offsetSetUpTo < entryCursor then', '-- BEFORE the write below stomps the signal\n\t\t\t\tif false then')
patch(root + '/Bookkeeping.luau', "-- stale += above is discarded by the rewind's prefix restore.\n\t\t\tif bk.offsetSetUpTo < i then", "-- stale += above is discarded by the rewind's prefix restore.\n\t\t\tif false then")
# Q173 (debug-off half): chain walk Quad0070 never runs
patch(root + '/StoreBind.luau', 'function StoreBind.assertAcyclicChain(first: any, seed: any?, raise: (string, any) -> ())\n', 'function StoreBind.assertAcyclicChain(first: any, seed: any?, raise: (string, any) -> ())\n\tif true then return end\n')
# Q55 Time entry cache + Flush nil guard (Time read again at every openWindow), and H-570
p = root + '/Debounce.luau'
patch(p, 'local t = module.Backend.setTimeout(onWindowEnd, h._time)', 'local t = module.Backend.setTimeout(onWindowEnd, readTime(name, "Time", opts.Time))')
patch(p, '\t\t\th._time = readTime(name, "Time", opts.Time)\n', '\t\t\t-- PROBE: Q55 entry cache removed\n')
patch(p, '\t\t\t\tif h._time ~= nil then\n\t\t\t\t\topenWindow()\n\t\t\t\tend', '\t\t\t\topenWindow()')
patch(p, '\t\t\tif not b.Blocking then\n\t\t\t\treturn -- round11 `H-570`', '\t\t\tif false then\n\t\t\t\treturn -- round11 `H-570`')
# Q166 (H-877) — in quad-roblox/src/Handlers/Property.luau `announce`:
#   'or not quad.Backend.isClaimed(inst) then' removed from the new-value callback gate
print('ok')
