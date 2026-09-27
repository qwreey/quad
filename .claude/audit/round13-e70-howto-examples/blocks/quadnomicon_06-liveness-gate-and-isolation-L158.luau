function Impl._receive(self: any, from: any)
    if module.Backend.canExecute(self) then -- read at fire time
        ...
        self.fn(self._state, self, from)
        ...
    else
        self._rerunRequired = true -- 바인딩 전 변경은 붙들었다가 묶일 때 한 번 따라잡는다
    end
end
