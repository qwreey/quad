import sys
root=sys.argv[1]
def patch(path, old, new, count=1):
    s=open(path).read()
    assert s.count(old)==count, (path, old[:60], s.count(old))
    s=s.replace(old,new)
    open(path,'w').write(s)
# A3: held branch of Observer._receive
patch(root+'/Observer.luau','''		else
			self._rerunRequired = true -- `H-159`''','''		else
			if self._running and not self._internal and fedBackDirectly(self.fn, module.Bookkeeping._recompute) then
				print("ZZDET-A3 Observer: install/held run fed its own upstream")
			end
			self._rerunRequired = true -- `H-159`''')
# Q166: process/drive on an unclaimed instance
patch(root+'/Dispatch/init.luau','''	local function process(inst: any, k: any, v: any, index: number)
		checkInst("process", inst)''','''	local function process(inst: any, k: any, v: any, index: number)
		if inst ~= nil and not module.Backend.isClaimed(inst) then
			print("ZZDET-877 Dispatch.process on an unclaimed instance key=" .. tostring(k))
		end
		checkInst("process", inst)''')
# H-570: Cancel/Flush while this gate's flush is on the stack
patch(root+'/Debounce.luau','''		function h.Cancel(_self: any)
			emit(false)''','''		function h.Cancel(_self: any)
			do
				local level, hit = 2, false
				while true do
					local f = debug.info(level, "f")
					if f == nil then break end
					if f == commitIdle or f == h.Flush then hit = true break end
					level += 1
				end
				if hit then print("ZZDET-570 handle:Cancel() inside this gate's own flush") end
			end
			emit(false)''')
print("patched", root)
