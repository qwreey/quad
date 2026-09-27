function Impl.Get(self: any): any
    while true do
        if self._cacheCurrCount ~= self._cacheTargetCount then
            self:_recompute()
        elseif self._valueEpochMap:Refresh() then
            self:_invalidate()
            self:_recompute()
        else
            return self._cache
        end
    end
end
