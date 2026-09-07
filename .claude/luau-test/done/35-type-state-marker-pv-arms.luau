--!strict
--[[
	검증 대상: 스파이크 `34`의 마커를 **생성 D의 슬롯 유니언 모양**에 넣었을 때(사용자 결정
	2026-09-07 "공변성/불변성 문제를 해결하기 위한 작업"). 지금 `PVn`은 `T | State<T> | TweenData<T> |
	State<Tween<T>> | None` + 유니언 T면 멤버별 팔(`H-353`/`H-362`, 11팔)이다. 마커면
	`T | TweenData<T> | StateMarker<T | Tween<T>> | None` **한 벌**로 (a) `State<m>`(멤버) (b)
	`State<Tween<m>>` (c) 정직한 `State<T | Tween<T>>`(`H-334`가 "too complex"로 포기한 팔)까지
	받는지, (d) `Tween<T>`(교집합) 값이 호출 인자 자리에서 `TweenData<T>` 팔에 들어가는지
	(gen-d 주석의 2026-09-06 관측 — setter는 전체형 Tween을 썼다), (e) setter의 변환 함수
	`(old) -> FieldV?`가 유니언 T에서 멤버 값을 돌려줘도 되는지(`H-362`의 `SHF` 분리 사유),
	(f) 음성 — 다른 T·`State<T?>`는 거부되는지.
	실행: `luau-analyze --fflags=LuauSolverV2=true 35-*.luau` 및 플래그 없이.
	기대(새 솔버): N1~N4 에러, 나머지 전부 통과.
	(quad-types 없이 자립 — `number | string`이 `number | UDim` 자리의 모양.)
]]

type StateMarker<T> = { read __quadState: true, read __quadStateValue: T }
type TweenData<T> = { read __quadTween: true, read Value: T, read Time: number? }
local function mapped<T, U>(_self: TweenData<T>, _fn: (T) -> U): Tween<U>
	return nil :: any
end
type Tween<T> = TweenData<T> & { Mapped: typeof(mapped) }
type StateReal<T> = {
	read __quadState: true,
	read __quadStateValue: T,
	Get: (self: StateReal<T>) -> T,
	Set: (self: StateReal<T>, v: T) -> (),
	Compute: <U>(self: StateReal<T>, fn: (T) -> U) -> StateReal<U>,
}
type None = { read __quadNone: true }

-- 생성 D 슬롯(PV)과 setter(FieldV/Field) — 유니언 T = number | string
type PV<T> = T | TweenData<T> | StateMarker<T | Tween<T>> | None
type FieldV<T> = T | Tween<T> | StateMarker<T | Tween<T>> | None
type FieldOut<T> = T | Tween<T> | StateReal<T> | StateReal<Tween<T>> | None -- 변환 함수의 old(출력)
type Field<T> = FieldV<T> | ((old: FieldOut<T>?) -> FieldV<T>?)
type Param = { read Radius: PV<number | string>?, read Size: PV<number>? }
type Modifier = { Radius: (self: Modifier, value: Field<number | string>) -> Modifier }

local function make<T>(v: T): StateReal<T>
	return nil :: any
end
local function tween<T>(v: T): Tween<T>
	return nil :: any
end
local mod = (nil :: any) :: Modifier

-- (a)(b)(c) Param 슬롯
local p1: Param = { Radius = 8 }
local p2: Param = { Radius = "x" }
local p3: Param = { Radius = make(8) } -- State<number> (멤버)
local p4: Param = { Radius = make("x") } -- State<string> (멤버)
local p5: Param = { Radius = make(tween(8)) } -- State<Tween<number>>
local p6: Param = { Radius = make(8 :: number | Tween<number>) } -- 정직한 State<T | Tween<T>>
local p7: Param = { Radius = tween(8) } -- Tween 값(교집합)이 TweenData 팔에
local p8: Param = { Radius = make(8 :: number | string) } -- State<number | string>
local p9: Param = { Size = make(1), Radius = (nil :: any) :: None }
-- (d) 호출 인자 자리 — setter
local m1 = mod:Radius(8):Radius("x"):Radius(make(8)):Radius(make("x")):Radius(make(tween("x"))):Radius(tween(8))
-- (e) 변환 함수 — 유니언 T에서 멤버 값을 돌려줌 / old를 State로 읽음
local m2 = mod:Radius(function(old)
	if type(old) == "number" then
		return old + 1
	end
	return "y"
end)
local m3 = mod:Radius(function(old)
	return make(8)
end)
-- (f) 음성
local n1: Param = { Radius = make(true) } -- N1: State<boolean>
local n2: Param = { Radius = make(nil :: number?) } -- N2: State<number?>
local n3: Param = { Size = make("x") } -- N3: 다른 멤버
local n4 = mod:Radius(make(tween(true))) -- N4: State<Tween<boolean>>

print(p1, p2, p3, p4, p5, p6, p7, p8, p9, m1, m2, m3, n1, n2, n3, n4)
