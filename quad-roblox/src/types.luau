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
	(2026-09-06) moved the value type into quad-types (engine-free — Roblox
	types as `any`) and this file re-exports it AS-IS — the planned `read`
	refinement of the engine-typed fields was dropped (`H-326`: `State<X>` is
	invariant, so the generated slot member `State<Tween<T>>` must name the
	exact type `Animate`/`:Compute` return). The runtime (quad-base
	`Tween.luau`, sentinels) is M11 unit ①; the PropertyHandler consumption
	is unit ②.

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

-- M11 단위 ①(2026-09-06, round19 Q3): 값 타입의 정본은 quad-types(엔진 무관 —
-- Roblox 타입 자리는 `any`)이고 여기서는 **그대로 별칭**한다. Q3 (a)가 예정한
-- `read Info: TweenInfo?` 정밀화는 실측에서 포기했다(`H-326`): `State<X>`는 불변이라
-- [2026-09-07 마커] 슬롯의 State 팔이 공변 `StateMarker<T | Tween<T>>`가 되면서 이 논거는
-- 약해졌다(정밀판 `Tween`이 `Tween<T>`의 서브타입이면 든다) — 재검토 가능, 아직 안 함.
-- 생성 D 슬롯의 `State<Tween<T>>` 멤버는 `Animate`/`:Compute`가 돌려주는
-- `State<QuadTypes.Tween<T>>`와 X가 글자 그대로 같아야 한다 — 정밀판 별칭이든
-- 데이터부든 다른 타입이면 거부된다. 엔진 타입 오용(`Style = 3`)은 `Enum` 자체가
-- 대부분 잡고, 나머지는 엔진 원시 에러(Q5 (a)).
export type Tween<T> = QuadTypes.Tween<T>
-- 유니언 멤버용 데이터부(`Mapped` 없음) — 재귀 메소드 테이블을 수백 유니언에 직접
-- 넣지 않는다(typing-limits 8.8). 실 Tween 값은 구조적으로 만족한다.
export type TweenData<T> = QuadTypes.TweenData<T>

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
	read Override: (QuadTypes.TweenOverride | QuadTypes.StateMarker<QuadTypes.TweenOverride>)?, -- [round3 `H-433`] 형제 여덟과 같이 마커(첫 마커 커밋이 빠뜨림)
	read CanAnimate: (boolean | QuadTypes.StateMarker<boolean>)?,
	read Dedup: (boolean | QuadTypes.StateMarker<boolean>)?, -- Q12 (2026-09-07): 같은 목표·옵션이면 이전 Tween을 그대로(기본 true)
}
export type AnimateFn = (info: AnimateInfo) -> (self: any) -> QuadTypes.State<QuadTypes.Tween<any>>

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
	| QuadTypes.StateMarker<(Instance | QuadTypes.SlotMarker<Instance> | QuadTypes.Tag | QuadTypes.Attribute | QuadTypes.Observer | QuadTypes.EffectHandle | QuadTypes.None)?>
	| QuadTypes.None
	| QuadTypes.Tag
	| QuadTypes.Attribute
	-- [2026-09-07 post-implementation review Q2 (a), 사용자 확정 "권고대로 둘 다 넣는거 동의"]
	-- `state:Observer(fn)` / `Effect(fn)` handles in the children array — the leaf idiom
	-- `source-state-plan.md` "`state:Observer(fn)`" 절·`effect-plan.md` canonised (leaf
	-- handlers in `Observer.luau`/`Effect.luau`), missing from the M5 widening list (`H-355`).
	| QuadTypes.Observer
	| QuadTypes.EffectHandle
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
-- type (`OnChangeFn`, name → callback parameter via `index<PropTypes, K>`)
-- and the per-class descriptor unions are generated (src/D).
export type OnChangeDescriptor = { read Name: string, read Callback: (any) -> () }

return {}
