# P3 = P1b + Observer stamp of its OWN state's revision when that state is a Source (an Epoch).
p='/code/Projects/quad/.claude/worktrees/agent-a44a4548414d6d6dd/quad-base/src/Observer.luau'
s=open(p).read()
# stamp at every fn start: runLoop body and the inline receive
s=s.replace('''\t\t\tself._pending = false
\t\t\tself.fn(self._state, self, from)
\t\t\tfrom = nil''','''\t\t\tself._pending = false
\t\t\tself._seenRevision = self._state.Revision -- PROTOTYPE P3 (nil for a derived State)
\t\t\tself.fn(self._state, self, from)
\t\t\tfrom = nil''')
s=s.replace('''\t\tif module.Backend.canExecute(self) then -- read at fire time (`H-174`)''','''\t\t-- PROTOTYPE P3: a direct Source delivery whose revision this handle already ran on (a catch-up or a
\t\t-- nested run in the same wave read it) is not a new change — skip. Only `from == _state` (a Source):
\t\t-- a derived State dedups stale/nested deliveries itself (emit map), and a gate batch is never skipped.
\t\tif from == self._state and self._seenRevision == from.Revision then
\t\t\treturn
\t\tend
\t\tif module.Backend.canExecute(self) then -- read at fire time (`H-174`)''')
s=s.replace('''\t\t\tlocal outer = self._running
\t\t\tself._running = true
\t\t\tself.fn(self._state, self, from)
\t\t\tself._running = outer
\t\t\tif self._pending and not outer''','''\t\t\tlocal outer = self._running
\t\t\tself._running = true
\t\t\tself._seenRevision = self._state.Revision -- PROTOTYPE P3
\t\t\tself.fn(self._state, self, from)
\t\t\tself._running = outer
\t\t\tif self._pending and not outer''')
s=s.replace('''\t\t\t_pending = false, -- PROTOTYPE P1''','''\t\t\t_seenRevision = false, -- PROTOTYPE P3: the state's Revision at this handle's last fn start (Source only)
\t\t\t_pending = false, -- PROTOTYPE P1''')
open(p,'w').write(s)
print(s.count('PROTOTYPE P3'))
