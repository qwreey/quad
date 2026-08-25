--!strict
export type EffectHandle = { Rerun: (self: EffectHandle) -> () }

-- (i) 확정된 시그니처
local function EffectA(fn: (self: EffectHandle) -> (() -> ())?) end
EffectA(function(self) end)                       -- 흔한 모양
EffectA(function(self) return nil end)            -- 명시적 nil
EffectA(function(self) return function() end end) -- cleanup

-- (ii) 조건 분기가 있는 경우 — 한쪽만 반환
EffectA(function(self)
    if math.random() > 0.5 then return function() end end
end)

-- (iii) 가변 반환 팩으로 열기
local function EffectB(fn: (self: EffectHandle) -> ...(() -> ())) end
EffectB(function(self) end)
EffectB(function(self) return function() end end)

-- (iv) 유니온 함수 타입
local function EffectC(fn: ((self: EffectHandle) -> ()) | ((self: EffectHandle) -> (() -> ()))) end
EffectC(function(self) end)
EffectC(function(self) return function() end end)
