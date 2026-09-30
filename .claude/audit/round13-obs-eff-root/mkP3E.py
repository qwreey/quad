# P3E: Effect — at every fn start, mark the live revision of each DIRECT Epoch dep (Source/Ref) as seen.
# Symmetric with Observer P3 (`_seenRevision` of its own Source). State deps untouched (gate-safe, H-151).
p='/code/Projects/quad/.claude/worktrees/agent-a44a4548414d6d6dd/quad-base/src/Effect.luau'
s=open(p).read()
old='''			self._pending = false
			self._rerunRequired = false -- the ONLY place the flag goes down: fn really runs'''
new='''			self._pending = false
			self._rerunRequired = false -- the ONLY place the flag goes down: fn really runs
			-- PROTOTYPE P3E: fn is about to read every dep live; a direct Epoch dep's (Source/Ref) live
			-- revision is exactly what its next delivery would carry, so mark it seen — a same-wave delivery
			-- arriving after this run (revival mid-wave, explicit Rerun) then fails `Update`. State deps are
			-- not touched: a Gate below them may be withholding (`H-151`).
			for d in self._deps do
				if isEpoch(d) then
					self._epochs:Sync(d)
				end
			end'''
assert old in s
s=s.replace(old,new)
open(p,'w').write(s)
