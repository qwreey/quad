function Impl._receive(self: any, from: any)
    local valueChanged = self._valueEpochMap:Update(from)
    local emitChanged = self._emitEpochMap:Update(from)
    if valueChanged then
        self:_invalidate() -- rule 1: value is stale
    end
    if valueChanged or emitChanged then
        emitDown(self, from) -- rules 1/2: forward the SAME source; rule 3: swallow
    end
end
