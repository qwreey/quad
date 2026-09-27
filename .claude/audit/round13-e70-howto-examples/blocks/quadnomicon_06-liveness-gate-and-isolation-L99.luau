-- quad-base: bindLifetime
if not canBound(value) then error(...) end             -- 거부 메시지 세 팔은 여기
if value._assertBindable then value:_assertBindable() end -- 커밋 전 훅
Backend.holdLifetime(inst, value)                      -- 커밋
if isObserver(value) then value:_catchUp() end
if isEffect(value) then value:_bindDestroying(inst) end
