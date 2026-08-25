--!strict
-- (A) base/state-epoch-plan.md §2: "Source가 이 인터페이스를 구조적으로 만족한다"
--     "Revision은 공개 필드다. 비공개면 구조적 만족이 타입 레벨에서 성립하지 않는다"
export type Epoch = { Revision: number }
export type EpochSet = { [Epoch]: true }

export type StateData<T> = { Get: (self: StateData<T>) -> T }
export type State<T> = StateData<T> & {
    Compute: <U>(self: StateData<T>, fn: (self: StateData<T>) -> U) -> State<U>,
}
export type SourceData<T> = { Get: (self: SourceData<T>) -> T, Revision: number }
export type Source<T> = SourceData<T> & {
    Set: (self: SourceData<T>, v: T) -> SourceData<T>,
    Emit: (self: SourceData<T>) -> (),
    Compute: <U>(self: SourceData<T>, fn: (self: SourceData<T>) -> U) -> State<U>,
}

local src: Source<number> = nil :: any
local st:  State<number>  = nil :: any

local function takesEpoch(e: Epoch): number return e.Revision end
local r1 = takesEpoch(src)              -- 성립해야 함
-- local r2 = takesEpoch(st)            -- 음성 대조군(주석 해제하면 걸려야 정상)

-- EpochMap 표면 (§3)
export type EpochMap = {
    Update: (self: EpochMap, from: Epoch | EpochSet) -> boolean,
    Refresh: (self: EpochMap) -> boolean,
    Sync: (self: EpochMap, from: Epoch | EpochSet) -> (),
    TrackFrom: (self: EpochMap, other: EpochMap) -> (),
}
local m: EpochMap = nil :: any
local u1 = m:Update(src)                 -- Epoch 하나
local set: EpochSet = { [src :: Epoch] = true }
local u2 = m:Update(set)                 -- EpochSet
-- 게이트가 실제로 만드는 모양: {[Source<number>]: true}를 EpochSet 자리에
local rawSet: { [Source<number>]: true } = { [src] = true }
local u3 = m:Update(rawSet)

-- (B) base/effect-plan.md: fn 시그니처는 fn(self: EffectHandle) -> (() -> ())?
export type EffectHandle = { Rerun: (self: EffectHandle) -> () }
local function Effect(fn: (self: EffectHandle) -> (() -> ())?): EffectHandle return nil :: any end

local e1 = Effect(function(self) return function() end end)  -- cleanup 있음
local e2 = Effect(function(self) return nil end)             -- 명시적 nil
local e3 = Effect(function(self) end)                        -- 아무것도 안 돌려줌 (가장 흔한 모양)
