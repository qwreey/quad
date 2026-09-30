p='/code/Projects/quad/.claude/worktrees/agent-a44a4548414d6d6dd/quad-base/src/Observer.luau'
s=open(p).read()
a=s.index('\tfunction Impl._receive(self: any, from: any)')
b=s.index('\t-- Catch-up: bind/subscribe replays')
new='''\tfunction Impl._receive(self: any, from: any)
\t\tif self._running then
\t\t\tself._pending = true -- PROTOTYPE P2: every delivery during a run is deferred (Effect's rawRerun)
\t\telseif module.Backend.canExecute(self) then
\t\t\trunLoop(self, from, false)
\t\telse
\t\t\tself._rerunRequired = true
\t\tend
\tend

'''
s=s[:a]+new+s[b:]
open(p,'w').write(s)
