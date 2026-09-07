--!strict
--[[
	quad-roblox public types — the single shared file the ROADMAP M5 banner
	requires ("공개 타입은 단일 파일에 몰아둘 것"; a later `quad-roblox-types`
	package split lifts this file wholesale). Roblox globals (TweenInfo, Enum,
	Instance) appear here, so this package is analyzed with the pinned
	`scripts/roblox-defs/globalTypes.d.luau` — quad-base stays defs-free.

	`Tween<T>` — the value-level wrapper `tween-plan.md`'s "확정: `Tween{...}`
	최종 모양" section pins down. M5 needed the TYPE first because the
	generated `D` prop unions include it (round14 `H-298` (a)); M11 unit ①
	(2026-09-06) put the value type into quad-types (engine-free — Roblox
	types as `any`) with this file re-exporting it AS-IS; **2026-09-07 (user
	decision, tween-plan "패키지 경계")** the whole value — type here, runtime
	`Tween.luau`, brand `Brand.luau` — is quad-roblox's, and the engine-typed
	fields are precise again (one definition, so the `H-326` invariance
	mismatch between an alias and its source cannot arise). The
	PropertyHandler consumption is unit ②.

	`NewChild` — the backend-agnostic core of the children-array element
	union. Since 2026-09-03 the generated `D.<Class>Param<E>` is instantiated
	with a per-class alias `<Class>Elem = NewChild | <Class>OnChange |
	State<<Class>OnChange> | { read __quadModifier: "<Class>" | … }` (src/D,
	`base/onchange-plan.md` "타이핑" 절; the last member is the class-tag
	marker of M7 unit ④ — `base/modifier-plan.md` 11절) —
	array-part descriptor kinds join THAT alias, not this union
	(claim-plan §7-12). M5-era union: what actually works through
	`drive` by the end of this milestone — a static child Instance
	(InstanceChildHandler, unit ③) or a reactive one (StoreBind → unwrap).
	Later milestones WIDEN this union as their handlers land (M10 did on
	2026-09-03 — Tag/Attribute, see the declaration comment; M6 Slot). M8
	Ref/PreRef/PostRef landed on 2026-09-04 NOT here but on the per-class
	alias — `<Class>RefMarker = { read __quadRefAccepts: (<Class>) -> () }`
	(+ `State<…>`) joins `<Class>Elem`, so a Frame slot admits `Ref<Frame?>`
	and ancestor boxes but rejects a sibling's Ref (`base/ref-plan.md`
	"children 자리의 타입" 절, round18 `H-321`; the round14 `H-298` (a) "Ref류"
	mention was that planned widening — kept out of NewChild for the same
	false-surface logic as `H-297` until the runtime existed).
	`None` joined every union once `H-300` (a) landed (2026-09-02 — the
	sentinel now carries a marker field, `QuadTypes.None`).
	Canonical prose: `bind-system-plan.md` 인스턴스 생성 절의 값 유니언 문단.
]]

local QuadTypes = require("../luau_packages/quad_types")

-- ── `Tween<T>` — 값-레벨 트윈 래퍼, **quad-roblox의 값 타입**(2026-09-07 사용자 결정 —
-- `base/tween-plan.md` "패키지 경계" 절: 옵션 어휘가 Roblox `TweenInfo`의 것이고 웹은
-- `Transition`으로 이름·모양이 다르며 `Animate`가 이미 여기 있다). 런타임은 `Tween.luau`
-- (install — `q.Tween`/`q.isTween`은 `RobloxExtension`으로 실린다), 소비는 `Handlers/Property.luau`.
-- 정본 모양은 tween-plan "확정: `Tween{...}` 최종 모양" 절. 엔진 타입 자리(`Info`/`Style`/
-- `Direction`)는 이제 **정밀**하다 — quad-types에 있던 시절엔 엔진 무관이라 `any`였고 round19
-- Q3 (a)의 정밀 별칭은 `State<X>` 불변성(`H-326`)에 막혔는데, 정의가 하나뿐이면 그 문제가 없다.
-- `Override`는 문자열 싱글톤 유니언(`H-343`, 사용자 결정 — 옵션 enum은 마커 값이 아니라 리터럴
-- 타입으로). `Mapped`는 재귀 제네릭(`Tween<U>` 반환)이라 데이터부/메소드부 쪼개기(typing-limits
-- §1②) — 파생 자리는 결과 타입을 명시 바인딩할 것(§1①).
export type TweenOverride = "Cancel" | "Finish"
-- 옵션 필드는 전부 `read` — 생성자는 읽기만 하고, 미리 만든 테이블 변수를 넘길 때
-- 가변 필드면 새 솔버가 `Time: number`를 `number?`에 불변으로 대조해 거부한다(실측).
export type TweenOptions<T> = {
	read Value: T,
	read Info: TweenInfo?, -- 있으면 편의 필드 무시
	read Time: number?,
	read Style: Enum.EasingStyle?,
	read Direction: Enum.EasingDirection?,
	read RepeatCount: number?,
	read Reverses: boolean?,
	read DelayTime: number?,
	read Override: TweenOverride?, -- 기본 "Cancel"
}
-- 유니언 멤버용 데이터부(`Mapped` 없음) — 재귀 메소드 테이블을 수백 유니언에 직접
-- 넣지 않는다(typing-limits 8.8). 실 Tween 값은 구조적으로 만족한다.
export type TweenData<T> = {
	read __quadTween: true,
	read Value: T,
	read Info: TweenInfo?,
	read Time: number?,
	read Style: Enum.EasingStyle?,
	read Direction: Enum.EasingDirection?,
	read RepeatCount: number?,
	read Reverses: boolean?,
	read DelayTime: number?,
	read Override: TweenOverride?,
}
-- `Mapped`는 typing-limits §1③(`typeof(named function)`) — 인라인 `<U>(…) -> Tween<U>`는
-- 반환이 `*error-type*`으로 새고 생성자 추론까지 오염된다(2026-09-06 실측, round19).
local function tweenMapped<T, U>(_self: TweenData<T>, _fn: (T) -> U): Tween<U>
	return nil :: any
end
export type Tween<T> = TweenData<T> & {
	Mapped: typeof(tweenMapped),
}
-- 순수 제네릭 함수(`H-343`): 문자열 `Override` 덕에 `Tween`엔 필드가 없어 콜러블 테이블이
-- 필요 없다 — 제네릭 `__call`의 `T` 오염(`H-324`, `luau-test/33` A 블록)이 함께 소멸.
export type TweenConstructor = <T>(opts: TweenOptions<T>) -> Tween<T>
-- Modifier 필드에 "저장된 그대로"의 값(`Peek` 반환·setter 변환 함수의 `old`) — quad-types의
-- `FieldOut<X> = X | State<X> | None`에 이 백엔드의 값 대수 `X = T | Tween<T>`를 넣은 것(전개형
-- `T | Tween<T> | State<T | Tween<T>> | None`, round3 Q23 (a)/Q24 후속). **여기서 별칭하고 생성 D는
-- `Types.FieldOut<T>`로 다시 별칭한다** — 같은 전개를 D 안에서 하면(인라인 유니언이든
-- `QuadTypes.FieldOut<T | Tween<T>>` 인스턴스화든) `export type D`가 솔버 제약 한도를 넘어
-- "too complex"(2026-09-07 실측, typing-limits 8.12).
export type FieldOut<T> = QuadTypes.FieldOut<T | Tween<T>>

-- `Animate(info)` options (M11 단위 ③, tween-plan "`Animate` 콤비네이터" 절): `Tween`
-- 옵션(`Value` 제외) + `CanAnimate`, 각 필드는 `T | State<T>`([2026-09-07 마커] State 자리는
-- 입력이라 `StateMarker<T>` — typing-limits 8.11; factory 안에서 `:Get()`
-- 한 번 풀어 plain으로 `Tween{...}`에 넘긴다). 반환 factory는 `:Apply` 전용이고
-- 타입은 **`(self: any) -> State<Tween<any>>`**(`H-334`, §4 확인 항목 — 실측 넷):
-- (1) 정직한 `State<T | Tween<T>>`(CanAnimate=false 분기가 plain)는 어느 슬롯
-- 유니언에 넣어도 "too complex"([2026-09-07 마커] 이 제약은 사라졌다 — 슬롯이 그 타입을
-- 받는다, `spec.shorthandtypes` `_markerUnion`; (2)~(4)는 그대로라 반환 타입은 유지); (2) `<T>(self: State<T>) -> …` 제네릭 factory는
-- `:Apply`의 `factory: (State<T>) -> U` 자리에 못 들어간다(제네릭 함수 값 불일치);
-- (3) `Animate` 자체를 `<T>`로 올리면 호출 자리에서 T를 못 잡는다; (4) `self:
-- State<any>`도 State 불변성으로 거부 — `self: any`만 통과(8.9절 `Apply`가 `any`인
-- 것과 같은 자리). 슬롯·setter 양성 전부 통과, 잃는 음성은 "Animate를 거친 교차-T
-- (number Source의 Animate를 UDim2 슬롯에)" 하나. 런타임 소비자는 어차피 plain/Tween
-- 둘 다 받고, `anim:Get()`을 직접 읽는 드문 자리만 `isTween`으로 갈라 볼 것.
export type AnimateInfo = {
	read Info: (TweenInfo | QuadTypes.StateMarker<TweenInfo>)?,
	read Time: (number | QuadTypes.StateMarker<number>)?,
	read Style: (Enum.EasingStyle | QuadTypes.StateMarker<Enum.EasingStyle>)?,
	read Direction: (Enum.EasingDirection | QuadTypes.StateMarker<Enum.EasingDirection>)?,
	read RepeatCount: (number | QuadTypes.StateMarker<number>)?,
	read Reverses: (boolean | QuadTypes.StateMarker<boolean>)?,
	read DelayTime: (number | QuadTypes.StateMarker<number>)?,
	read Override: (TweenOverride | QuadTypes.StateMarker<TweenOverride>)?, -- [round3 `H-433`] 형제 여덟과 같이 마커(첫 마커 커밋이 빠뜨림)
	read CanAnimate: (boolean | QuadTypes.StateMarker<boolean>)?,
	read Dedup: (boolean | QuadTypes.StateMarker<boolean>)?, -- Q12 (2026-09-07): 같은 목표·옵션이면 이전 Tween을 그대로(기본 true)
}
export type AnimateFn = (info: AnimateInfo) -> (self: any) -> QuadTypes.State<Tween<any>>

-- [2026-09-03 M10 widening] the quad-base array-part VALUES join here: `Tag(...)`
-- and `Attribute(...)` (the typed scalar sugar `StringAttribute(name, v)` etc.
-- returns an `Attribute`, so it rides the same member) + their State forms
-- (StoreBind unwraps array elements). OnChange descriptors are NOT here — they
-- are per-class (`<Class>Elem` in the generated D, `base/onchange-plan.md`).
export type NewChild =
	Instance
	-- ⭐ [2026-09-07 사용자 결정 — 공변/불변] State·Slot 팔은 **마커**(`StateMarker`/`SlotMarker`,
	-- quad-types 주석·typing-limits 8.11): 전체형 `State<Instance>`는 불변이라 `Source(frame)`
	-- (`State<Frame>`)·`State<Instance?>`·`State<Slot<…>>`를 전부 거부했고 팔마다 예산을 먹었다.
	-- 마커는 T에 공변이라 값 유니언 하나로 끝난다 — `State<Frame>`, `State<Instance?>`(NilHandler
	-- 팔 — `State<Slot|nil>`), `State<Slot<Frame>>`(Q1의 원래 팔, StoreBind 언랩 → SlotHandler),
	-- `State<Tag>`/`State<Attribute>`(M10 팔)가 이 한 줄에 든다. `State<Modifier>`는 7절이 error라
	-- 여기 없다. [round3 `H-431`] `State<Observer?>`/`State<EffectHandle?>`는 정본이 지시하는 leaf 종료
	-- 관용구(slot-plan "State<Observer?>를 사용하는게 적절" — nil emit으로 구독 해제, StoreBind 언랩 →
	-- leaf 핸들러/NilHandler)라 여기 든다 — 첫 마커 팔이 빠뜨렸던 것.
	| QuadTypes.SlotMarker<Instance>
	-- [2026-09-07 밤 사용자 제안 — 마커 전면화] Tag/Attribute/Observer/EffectHandle도 입력 자리는 마커
	-- (`research/source-layout-plan.md` 10-2): 메소드가 든 전체형이 유니언에 앉을 이유가 없고(8.8·8.9의
	-- 함수 필드 게이트가 그 때문), 타입 검사 예산도 준다(사용자: *"타입 체크 비용을 아끼기 위해 마커만
	-- 두는것도 괜찮아보임"*). 실제 값은 폭 서브타이핑으로 든다(8.11).
	| QuadTypes.StateMarker<(Instance | QuadTypes.SlotMarker<Instance> | QuadTypes.TagMarker | QuadTypes.AttributeMarker | QuadTypes.ObserverMarker | QuadTypes.EffectHandleMarker | QuadTypes.None)?>
	| QuadTypes.None
	| QuadTypes.TagMarker
	| QuadTypes.AttributeMarker
	-- [2026-09-07 post-implementation review Q2 (a), 사용자 확정 "권고대로 둘 다 넣는거 동의"]
	-- `state:Observer(fn)` / `Effect(fn)` handles in the children array — the leaf idiom
	-- `source-state-plan.md` "`state:Observer(fn)`" 절·`effect-plan.md` canonised (leaf
	-- handlers in `Observer.luau`/`Effect.luau`), missing from the M5 widening list (`H-355`).
	| QuadTypes.ObserverMarker
	| QuadTypes.EffectHandleMarker
	-- M7 단위 ③·④: Modifier는 MARKER로만 — 클래스별 `<Class>Modifier`를 유니언에
	-- 직접 넣으면 큰 클래스의 캐스트 자리에서 "too complex"(2026-09-04 실측,
	-- typing-limits 8.8절). 여기(`true`)는 무타입 base `Modifier()`의 명시 허용이고,
	-- 클래스 태그 마커 `{ read __quadModifier: "Frame" | "GuiObject" | … }`(자기 +
	-- 조상 체인)는 생성 `<Class>Elem`이 담는다 — 그래서 형제 클래스 Modifier는
	-- 거부된다(단위 ④, modifier-plan 11절). `State<Modifier>`는 7절이 error라 없다.
	| QuadTypes.ModifierMarker

-- `OnChange(name, fn)` descriptor (M10, `base/onchange-plan.md` — array-part
-- value since the 2026-09-03 reversal): frozen `{ Name, Callback }`,
-- Handlers/OnChange.luau. This is the RUNTIME shape; the checked factory
-- type (`OnChangeFn`, name → callback parameter via `index<PropTypesRead, K>` — 읽기 표면, Q19 2026-09-07)
-- and the per-class descriptor unions are generated (src/D).
export type OnChangeDescriptor = { read Name: string, read Callback: (any) -> () }

return {}
