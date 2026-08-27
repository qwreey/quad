--!strict
-- 레인 A/D: 최종형 Store — §1② 쪼개기 선언(재귀 `Compute -> State<U>` 포함)의 `Source<T>` 필드 +
-- `CheckReservedKeys<keyof<T>>` 팬텀 필드 + 빈 `{}` + `Of<<T>>` — luau-analyze로 한 번에.
-- 기대: (A)(B)(C)(E) 진단 0, (D)(F)(G) 정확히 걸림, (H) 예약 키 print 진단.
export type StateData<T> = { Get: (self: StateData<T>) -> T }
export type State<T> = StateData<T> & {
	Compute: <U>(self: StateData<T>, fn: (self: StateData<T>) -> U) -> State<U>,
}
export type Source<T> = State<T> & { Set: (self: Source<T>, v: T) -> Source<T>, Revision: number }

type function CheckReservedKeys(keys: type)
	local list = if keys:is("union") then keys:components() else { keys }
	for _, k in list do
		if k:is("singleton") then
			local v = k:value()
			if v == "Of" or v == "Names" or v == "__reservedCheck" then
				print(`quad.Store: "{v}" is a reserved key`)
				return types.never
			end
		end
	end
	return types.singleton(true)
end
type Store<T> = T & {
	Of: <U>(self: any, name: string) -> Source<U>,
	Names: (self: any) -> { string },
	__reservedCheck: CheckReservedKeys<keyof<T>>,
}
local function Store<T>(defaults: T?): Store<T> return (nil :: any) end
local function Source<T>(v: T): Source<T> return (nil :: any) end

-- (A) 키 있는 최종형
local s = Store({ hp = Source(100), name = Source("x") })
local a1: Source<number> = s.hp
local a2: number = s.hp:Get()
s.hp:Set(5)
-- (B) 무주석 콜백 파라미터 추론 생존
local b1 = s.hp:Compute(function(x) return x:Get() * 2 end)
-- (C) Of<<T>>
local c1: Source<boolean> = s:Of("dyn")
local c2: Source<number> = s:Of("dyn2")
local c3: Source<boolean> = s:Of<<boolean>>("z")
local c4: Source<number> = s:Of<<boolean>>("z2")   -- 음성: 명시 인스턴스화면 걸려야
-- (D) 음성: 틀린 타입
local d1: Source<string> = s.hp
local d2: string = s.hp:Get()
-- (E) 빈 Store
local empty = Store({} :: {})
local e1: { string } = empty:Names()
local e2: Source<number> = empty:Of("dyn")
-- (F) 선언 안 된 키
local f1 = s.nope
-- (G) Compute 반환 타입 명시 주석 구멍(§1) — 이 줄은 조용히 통과할 것(기대: 진단 없음 — 알려진 한계)
local g1: State<string> = s.hp:Compute(function(x) return x:Get() * 2 end)
-- (H) 예약 키 충돌 — 타입 함수 진단
local bad = Store({ Of = Source(1) })
local h1 = bad.Of
