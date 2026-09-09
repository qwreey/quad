--!strict
--[[
	`Quad` 공개 타입 계약 — 구현 없음. 런타임 값은 공유 **상수**(`H-230` —
	파일 끝의 반환 테이블)와 **[2026-09-07 사용자 결정]** 브랜드 팩토리 `Brand()`
	하나(enum처럼 "타이핑을 돕는 특수 런타임 객체" — 사용자: *"노미널타이핑을 돕는다
	이외의 동작이 없어서 enum 과 비슷하게 특수 런타임 객체로 types 안에 실어두는게
	좋아보여. 실제로 20줄도 되지 않거든"*). 브랜드 **인스턴스**는 각 패키지가
	자기 `Brand.luau`에 만든다(quad-base·quad-roblox·장래 quad-spring의 `SpringBrand`) —
	팩토리가 여기 있어야 quad-base 없이도 브랜드를 만들 수 있다.
	`quad-base`가 이 타입을 구현하고, `quad-roblox`/향후 백엔드·플러그인
	패키지는 무거운 `quad-base` 전체 대신 이 패키지만 의존한다.

	**왜 별도 패키지인가**: `quad:UseProvider(QuadRoblox)`처럼 quad-base
	인스턴스를 **런타임에 주입받는** 패키지는, quad-base를 pesde
	`[dependencies]`로 선언할 필요가 없다 — 실제 값은 호출자가 넘겨준다.
	그런데 `dev_dependencies`로만 선언하면, quad-roblox가 게시된 뒤 다른
	사람이 그 패키지를 설치할 땐 dev dependency가 전파되지 않아 그
	require(타입만 쓰려는 목적이어도 런타임에 실행됨, 실측 확인됨)가 그
	자리에서 못 찾고 크래시한다. 그래서 "항상 안전하게 실 의존성으로 둘 수
	있을 만큼 작은 것"이 따로 필요하고, 그게 이 패키지다.
	(`.claude/base/project-setup-plan.md`/`session/2026-08-19-07-*.md` 참고)
]]

local TypeVersionCheck = require("./luau_packages/type_version_check")
local QuadError = require("./luau_packages/quad_error")

-- ── 마커·센티널 타입 ────────────────────────────────────────────────
-- [2026-09-07 밤 사용자 결정 — 파일 재배치] 위쪽에 마커·센티널, 가운데 값·핸들 타입, 맨 아래 `Quad`
-- 표면·`CheckedQuad`·런타임 값(`Brand` 팩토리·상수). 사용자: *"모든 마커 타입을 위쪽에 올려서 표현하고,
-- 중간엔 구현타입만 넣고, 맨 아래 실제 Quad 익스포팅 타입을 넣는 구조로 단일 파일로 유지 … 단일 파일로
-- 두는게 배포 상 ModuleScript 가 덜 들고, lsp 가 덜 힘들어 하기 때문"*. 마커는 "입력 자리"의 타입
-- (typing-limits 8.11 — 값은 폭 서브타이핑으로 들어가고 T가 있으면 공변), 센티널은 신원 값의 조언층
-- (`H-300` — 판정은 언제나 신원·브랜드). 각 마커의 런타임 대응(`Impl.__quadX = true`)은 그 타입 모듈이 진다.
-- 순수 재배치(2026-09-07) — 아래 블록과 주석은 옮겨졌을 뿐 내용은 그대로다.

-- 선언 스타일은 `.claude/base/typing-limits.md` §1②의 "데이터부/메소드부" 쪼개기 —
-- 콜백 파라미터 무주석 추론이 사는 유일한 스타일(`audit/handtrace-round10-reference-impl/
-- spikes/ty11_store_final.luau`가 최종형 실측). `Compute`의 `-> State<U>` 반환은 §1①의
-- 알려진 한계라 **파생 State를 만드는 자리는 결과 타입을 명시 주석**할 것.
-- `fn(self, previous?, ...deps)` — 전부 lazy 핸들, 값은 `:Get()`으로만
-- (`.claude/base/source-state-plan.md` "self 인자도 lazy 핸들로 통일").
-- ⭐ [2026-09-07 사용자 결정 — 공변/불변 문제] **마커 타입** `StateMarker<T>`: '입력받는
-- 자리'(children 유니언, 생성 D 슬롯 `PVn`, Modifier setter `Field<T>`, Slot 요소 자리 등)는
-- 전체형 `State<T>` 대신 이 마커를 요구한다. 전체형은 `Set(T)`/`Get(): T`가 양쪽 위치라
-- **불변**이어서 `State<number>`가 `State<number | UDim>` 자리에 못 들어갔고(`H-326`/`H-327`/
-- `H-353` — 멤버별 팔 나열로 우회), 읽기 전용 팬텀 필드만 든 마커는 **T에 공변**이라 한 팔로
-- 끝난다(`typing-limits.md` 8.11, `luau-test/done/34`·`35`). 실제 State 값은 폭 서브타이핑으로
-- 들어가고 다른 T는 여전히 거부된다. 사용자 원문: *"'입력받는 곳'에 대해서는 마커 필드와 내부
-- 구조 T하나만 보존하는 마커 타입을 써도 되지 않나 … 진짜 State<T>의 method 같은건 유저가 쓰는
-- 부분에 있어서 들어갈 뿐"*. 메소드가 필요한 자리(출력·`self`·`Peek` 반환·변환 함수의 `old`)는
-- 전체형 그대로. 런타임: `__quadState`는 `Impl.__quadState = true`(H-300 "타입이 약속하면
-- 값에도"), `__quadStateValue`는 **순수 팬텀**(런타임엔 없다 — T 값을 들고 있을 수 없어서;
-- `__quadRefAccepts`의 `Void`와 같은 층의 조언 필드, 읽는 코드가 없어야 한다). 사용자 확정(2026-09-07):
-- 순수 팬텀 허용, 값을 둘 수 있고 싸면 두는 것도 좋다.
export type StateMarker<T> = { read __quadState: true, read __quadStateValue: T }

export type SlotMarker<T> = { read __quadSlot: true, read __quadSlotValue: T }

-- 값 모양은 `base/tag-plan.md` "값 모양" / `base/attribute-plan.md` "채택안"
-- 절이 정본. 생성자들은 콜러블 네임스페이스(호출 = 생성, 필드 = 합성)라
-- `setmetatable<A, B>` 표기로 선언한다(`H10-3`/`H10-4` (d) — 교집합은
-- 무거주라 값 캐스트·제네릭 흐름이 깨진다, typing-limits 8.6절). `AttrKey`는
-- [2026-09-03 사용자 확정] 제네릭 자체가 폐기된 무타입 프리미티브다(값 타입은
-- 배열부 슈가 `AttrSugar<T>`가 진다 — attribute-plan 머리 배너); 옛 "제네릭
-- 파라미터 값 좁힘 미실측" 항목은 닫혔다(typing-limits §3).
-- [2026-09-07 사용자 결정 — `research/source-layout-plan.md` 3절 (b)] 이름 자리는 어디서나
-- `TagNames` = 문자열 | 다른 Tag(마커 — 입력 자리, 8.11) | 그것들의 plain 리스트(중첩 허용).
-- 리스트 인덱서가 `read`인 이유: 가변 `{T}`는 T에 불변이라 `{ tag, "x" }` 리터럴(`{Tag | string}`)을
-- 거부한다(스파이크 2026-09-07). 해시 테이블은 인덱서 타입을 통과하므로(인덱서 없는 테이블은
-- 인덱서 타입의 서브타입) 런타임 `flattenInto`가 잡는다. `H-389`의 `...string` 생성자를 되돌림.
export type TagMarker = { read __quadTag: true }
export type TagNames = string | { read [number]: TagNames } | TagMarker

export type AttrMarker = { read __quadAttr: true }

export type ObserverMarker = { read __quadObserver: true }

export type EffectHandleMarker = { read __quadEffect: true }

-- children 유니언용 마커 타입 — 무타입 base Modifier의 것(`true`). 클래스 태그
-- 마커 `{ read __quadModifier: "Frame" | "GuiObject" | … }`는 생성기가 클래스별
-- `<Class>Elem`에 찍는다(조상 체인 — 상위 클래스 Modifier가 하위 자식 자리에 감)
export type ModifierMarker = { read __quadModifier: true }

-- 센티널 둘 — `None`과 같은 신원 값(재export). 판정은 `v == Detach` 신원
-- 비교이고 마커 필드는 타입 좁힘용 조언층일 뿐(`H6-16` (a), 2026-09-03 사용자
-- 확정 — `None`의 `__quadNone`과 같은 모양, `H-300`). 신원 비교로는 좁혀지지
-- 않는다(truthiness 좁힘만) — 사용자 `Item` 쪽엔 캐스트가 남을 수 있음.
export type Detach = { read __quadDetach: true }
export type KeyGone = { read __quadKeyGone: true }

-- `None` 센티널의 구조 타입(`H-300` (a), 2026-09-02 사용자 확정) — 실값은
-- quad-base `Dispatch/None.luau`의 frozen 테이블이고 판정은 언제나 신원
-- (`v == None`)이다. 이 타입은 조언층: 마커 필드 하나로 빈-테이블
-- 타입이 모든 테이블에 매치되는 문제를 피해, 생성된 `D` 유니언(스칼라·
-- 이벤트·children)이 None을 실을 수 있게 한다.
export type None = { read __quadNone: true }

-- `Claim`의 매퍼 디스크립터/루트 센티널(M5 단위 ④, `claim-plan.md` §2·§7-1).
-- None과 같은 이중 구조 — 타입은 마커 필드(조언층), 런타임 판별은 브랜드
-- (`isMapperDescriptor`)·신원(`MapperRoot`).
export type MapperDescriptor = { read _mapper: true }
export type MapperRoot = { read __quadMapperRoot: true }

-- 에러 네임스페이스(`H-231` — quad-error는 상태 없는 생성자, 태그 맵은
-- quad-base가 만든 단일 네임스페이스에 산다. 사본 분리 문제의 해법 — 사용자
-- 설계 "quad-base에 errorNamespace 같은 무언가가 있어야 하고 error util이
-- 그걸 받는 구조").
export type ErrorNamespace = QuadError.Namespace

-- `Epoch` — 최소 인터페이스(`.claude/base/state-epoch-plan.md` §2). 판정은
-- identity + "직전과 다른 Revision"뿐, 순서 비교 없음. 런타임 판별은 `isEpoch`.
export type Epoch = { Revision: number }
export type EpochSet = { [Epoch]: true } -- 집합이지 배열이 아니다(게이트 배치가 그대로 넘어온다)

-- `Relate` — inst를 weak 키로 하는 릴레이션(`.claude/base/relate-plan.md` "API").
-- `inst`는 항상 weak, `Weak`/`Strong`은 value의 보관 방식만 가리킨다.
export type Relate = {
	SetStrong: (self: Relate, inst: any, key: any, value: any) -> (),
	GetStrong: (self: Relate, inst: any, key: any) -> any?,
	SetWeak: (self: Relate, inst: any, key: any, value: any) -> (),
	GetWeak: (self: Relate, inst: any, key: any) -> any?,
}

-- `StripNil<T>` — `T`에서 `nil`만 벗긴다(`Ref:Unwrap()`의 반환 타입, 2026-09-08 스파이크: 구·신 솔버 모두
-- `number?` → `number`, `(number | string)?` → `number | string`, nil 없는 T는 그대로). 타입 함수라 신 솔버 전용
-- 문법이지만 quad-types는 이미 `CheckReservedKeys`로 같은 계약 위에 있다.
export type function StripNil(t: type): type
	if t:is("union") then
		local comps: { type } = {}
		for _, c in t:components() do
			if not c:is("nil") then
				table.insert(comps, c)
			end
		end
		if #comps == 1 then
			return comps[1]
		end
		return types.unionof(table.unpack(comps))
	end
	return t
end

-- `Ref<T>` 최소형(`.claude/base/ref-plan.md`, M2 `H-128`). 콜백은 `fn(value, ref)` —
-- 두 번째 인자가 Ref 자신(= `Epoch`). `:Wait`는 M8. **단일 타입 파라미터
-- `Ref<T>(T)`** — nil이 들어올 수 있는 자리는 호출자가 `Ref<<T?>>(nil)`로 넓힌다
-- (`ref-plan.md` "제네릭 시그니처").
export type RefCallback<T> = (value: T, ref: Ref<T>) -> ()
export type Ref<T> = {
	-- 반공변 팬텀 필드(M8 단위 ③, round18 `H-321` — 사용자 확정): children 자리의
	-- 클래스 검사용. 생성 `<Class>Elem`이 `{ read __quadRefAccepts: (<Class>) -> () }`
	-- 만 담으면 `Ref<Frame?>`·상위 박스 `Ref<GuiObject?>`는 들어가고 형제
	-- `Ref<TextLabel?>`·무타입 `Ref<nil>`은 거부된다. `Set`의 파라미터가 같은 정보를
	-- 갖지만 새 솔버가 제네릭 메소드의 반공변을 안 보고(8.9절) 유니언 멤버
	-- `State.Set`과 이름이 충돌해 `Set`으론 검사가 안 선다 — 그래서 유니언 어디와도
	-- 안 겹치는 비제네릭 이름에 T를 굽는다. 런타임 값은 `Void`(호출되지 않음, H-300
	-- "타입이 약속하면 값에도"). 사용자 표현: "non-lazy type으로 T 비교자를 넣어 굽는다"
	read __quadRefAccepts: (T) -> (),
	Value: T,
	Revision: number,
	Callbacks: { [RefCallback<T> | thread]: true }, -- 강한 해시맵 셋(+ M8 `:Wait` 대기자)
	WeakCallbacks: { [RefCallback<T>]: true }, -- weak-key 테이블
	-- self 반환 메소드는 `<Self>` 제네릭(M8 단위 ① 리뷰 반영, round18 `H-317`):
	-- 반환을 `Ref<T>`로 고정하면 `PreRef(x):Callback(fn)` 체이닝에서 마커
	-- (`PreRef<T>` 교집합)가 사라져 nominal 타입이 첫 호출에 증발한다. 소형
	-- 실측: 체이닝·마커 보존·오타 T 거부·plain Ref → PreRef 거부 전부 성립
	Set: <Self>(self: Self, value: T) -> Self,
	Callback: <Self>(self: Self, fn: RefCallback<T>) -> Self,
	WeakCallback: <Self>(self: Self, fn: RefCallback<T>) -> Self,
	Uncallback: <Self>(self: Self, fn: RefCallback<T>) -> Self,
	-- M8 단위 ①: 항상 다음 `:Set`까지 기다린다(brief §0 Q5 (a)); thread를 주면
	-- 등록만 하고 즉시 self. 대기자는 `.Callbacks`의 thread 키(`:Set`이 소진·resume)
	Wait: <Self>(self: Self, thread: thread?) -> Self,
	-- 2026-09-08 (`ref-plan.md` "`:Unwrap()`" 절): 비어 있으면 호출 줄에서 에러, 아니면 값 — 타입은 nil을 벗긴다
	-- (`PreRef<Frame?>`를 이벤트 콜백 안에서 `ref:Unwrap():CaptureFocus()`처럼; 런타임 보장이 있는 자리 전용).
	Unwrap: (self: Ref<T>) -> StripNil<T>,
}
-- M8 단위 ①: `PreRef`/`PostRef` — 런타임은 `Ref` 그대로, 마커 필드로 nominal
-- (H-300 관례 — 런타임 값에도 실제 필드). fire 시점만 다르다(`ref-plan.md`
-- "`phase` 옵션 폐기 → 위치로 표현, `PreRef` 신설" 절 / "`PostRef`" 절).
-- children 배열 리터럴 전용 — Modifier 필드·Source·Store 값으로는 타입 차단.
export type PreRef<T> = Ref<T> & { read __quadPreRef: true }
export type PostRef<T> = Ref<T> & { read __quadPostRef: true }

-- ── 반응형 코어(M2 단위 2) ────────────────────────────────────────────
export type StateData<T> = { read __quadState: true, read __quadStateValue: T, Get: (self: StateData<T>) -> T }

-- 타입 별칭 이름 넷(`ObserverFn`/`EffectFn`/`GateEmit`/`GateSetup`)은 구현이 붙였고
-- `H-187` (a)로 사용자 승인(2026-08-31, "이름 그대로 사용해도 좋음").
-- `Observer` — 값을 안 실어주는 leaf 구독(`source-state-plan.md` "`state:Observer(fn)`").
-- `fn(targetState, self, emitFrom?)`: 3번째가 출처(`Epoch` | 집합), 설치·캐치업 발화는 `nil`.
-- 네 진입점은 `lifecycle-pattern.md` (2) — Weak가 프리미티브, `.Subscribed`는 강·약 공용.
export type Observer = {
	read __quadObserver: true, -- 런타임 `Impl.__quadObserver = true`(H-300; 입력 자리는 `ObserverMarker`)
	Subscribed: boolean,
	Subscribe: (self: Observer) -> Observer,
	WeakSubscribe: (self: Observer) -> Observer,
	Unsubscribe: (self: Observer) -> Observer,
	WeakUnsubscribe: (self: Observer) -> Observer,
}
export type ObserverFn<T> = (targetState: StateData<T>, self: Observer, emitFrom: (Epoch | EpochSet)?) -> ()

-- `EffectHandle` — `Effect(fn, ...deps)`의 핸들(`effect-plan.md`). `fn(self) -> ...cleanup`.
-- 네 진입점은 Observer와 같은 이름·같은 게이트이되 **본문은 자기 것**(`H-144`).
export type EffectHandle = {
	read __quadEffect: true, -- 런타임 `Impl.__quadEffect = true`(H-300; 입력 자리는 `EffectHandleMarker`)
	Subscribed: boolean,
	Rerun: (self: EffectHandle) -> EffectHandle,
	Subscribe: (self: EffectHandle) -> EffectHandle,
	WeakSubscribe: (self: EffectHandle) -> EffectHandle,
	Unsubscribe: (self: EffectHandle) -> EffectHandle,
	WeakUnsubscribe: (self: EffectHandle) -> EffectHandle,
}
-- ⚠️ 팩 표기는 "반환 안 해도 됨"을 위한 것(`H-95`) — 런타임이 소진하는 cleanup은
-- **첫 반환 하나뿐**이다(`H-185` 확정: 여러 정리는 `function() a() b() end`로 묶을 것).
export type EffectFn = (self: EffectHandle) -> ...(() -> ())

-- `state:Gate(setup)`의 정책 계약(`gate-plan.md` 2번): 바깥은 생성 시 1회, 반환 클로저는 상류
-- emit마다. `emit()`/`emit(true)` = 흡수 집합 flush, `emit(false)` = 버리기, 반환 = 쌓인 게 있었나.
export type GateEmit = (commit: boolean?) -> boolean
export type GateSetup = (emit: GateEmit) -> () -> ()

-- `Blocker` — `GateNode` 위의 정책(`blocker-plan.md`). `state:Apply(blocker)`가 `__apply`로 배선.
export type Blocker = {
	IsBlocked: boolean,
	IsOn: (self: Blocker) -> boolean,
	On: (self: Blocker) -> Blocker,
	Off: (self: Blocker) -> Blocker,
	OffWithoutEmit: (self: Blocker) -> Blocker,
	Policy: (self: Blocker, emit: GateEmit) -> () -> (),
	-- `state:Apply(b)`는 gated `State<T>`(같은 T)를 돌려준다 — 호출부가 결과 타입을 명시
	-- (`State<T>.Apply`의 객체 오버로드 주석 참고).
	__apply: (self: any, state: any) -> any,
}

-- ── 시간 op + `Debounce`/`Throttle` (2026-09-08, `base/debounce-throttle-plan.md`) ────
-- `setTimeout(func, delay) -> Timeout` / `clearTimeout(timeout)` — 백엔드가 심는 주입 op(6절, 사용자 지정
-- 시그니처: 함수가 먼저, Roblox `task.delay`는 반대). 닫힌 루프라 `any`가 아니라 마커로 사실상 nominal
-- (6절 "`Timeout` 핸들의 타입"; 마커 이름만 코퍼스 관례 `__quad*`(H-300)로 — 옛 표기 `__type_timeout`).
-- `_native`는 백엔드 페이로드 — base는 읽지도 쓰지도 않는다.
export type Timeout = { read __quadTimeout: true, _native: any }
-- 제어 핸들(5-4절): `Handle = Ref<<GateHandle?>>(nil)`로 받는다. 메소드형(`h.Value:Flush()`).
export type GateHandle = {
	Flush: (self: GateHandle) -> (), -- 보류분이 있으면 지금 통과(+창 재개방), 없으면 no-op
	Cancel: (self: GateHandle) -> (), -- 보류분을 버리고 idle로(전파 없음)
}
export type DebounceOptions = {
	Time: number | State<number>, -- 창 길이(초) — 신호마다 리셋. State면 스케줄 시점에만 `:Get()`(구독 없음)
	Leading: boolean?, -- 기본 false
	Trailing: boolean?, -- 기본 true
	MaxTime: (number | State<number>)?, -- 신호가 안 끊겨도 최대 이 간격마다 통과(Debounce 전용)
	Handle: Ref<GateHandle?>?,
}
export type ThrottleOptions = {
	Time: number | State<number>, -- 창 길이(초) — 신호가 리셋하지 못함
	Leading: boolean?, -- 기본 true
	Trailing: boolean?, -- 기본 true
	Handle: Ref<GateHandle?>?,
}
-- `Debounce{...}`/`Throttle{...}`가 돌려주는 애플리커티브 팩토리(`__apply` 메소드형, `H-158`) — 자기가 만든
-- 게이트 전부에 `:Flush()`/`:Cancel()` 브로드캐스트(weak 레지스트리, 5-4절). 결과 State는 호출부가 명시
-- (`local g: State<T> = s:Apply(Debounce{ Time = 0.3 })`, `Blocker`와 같다).
export type TimedGate = {
	Flush: (self: TimedGate) -> (),
	Cancel: (self: TimedGate) -> (),
	__apply: (self: any, state: any) -> any,
}

-- ── Context / Provider (2026-09-08, `base/context-plan.md`) ─────────────────────
-- 명시적 값 컨테이너 — 트리 탐색이 아니라 props로 건네는 타입드 다중 Store 가방(암묵 Context는 `archive/context-rejected.md`).
-- `Provider<T>`는 테이블 신원 키; `T`는 팬텀(`__quadProviderValue`)이라 `ctx:Get(p)`가 `T`로 추론된다.
export type Provider<T> = { read __quadProvider: true, read __quadProviderValue: T, read Name: string? }
export type Context = {
	read __quadContext: true,
	Set: <T>(self: Context, provider: Provider<T>, value: T) -> Context, -- 이 가방을 변경, self 반환
	Get: <T>(self: Context, provider: Provider<T>) -> T, -- 없으면 에러(사용자 결정)
	Peek: <T>(self: Context, provider: Provider<T>) -> T?, -- 없으면 nil — 있는지 확인용
}
export type ContextConstructor = setmetatable<{ Provider: <T>(name: string?) -> Provider<T> }, { __call: (self: any) -> Context }>

-- ── Operator (2026-09-08, `research/operator-sugar-plan.md` — 범위는 사용자 확정) ────────
-- 전부 `factory(self) -> State<U>` 모양, `state:Apply`로 붙인다. 숫자 인자는 plain이거나 State<number>.
export type NumArg = number | StateData<number>
export type NumOp = (self: StateData<number>) -> State<number>
export type Operator = {
	Not: (self: any) -> State<boolean>, -- 비제네릭·`self: any`: 제네릭 함수 값도 `StateData<any>`도 `Apply`의 함수 오버로드 자리에 안 들어간다(실측)
	Sum: (...NumArg) -> NumOp,
	Product: (...NumArg) -> NumOp,
	Min: (...NumArg) -> NumOp,
	Max: (...NumArg) -> NumOp,
	Band: (...NumArg) -> NumOp,
	Bor: (...NumArg) -> NumOp,
	Bxor: (...NumArg) -> NumOp,
	Bnot: NumOp,
	Shl: (n: NumArg) -> NumOp,
	Shr: (n: NumArg) -> NumOp,
	Clamp: (lo: NumArg, hi: NumArg) -> NumOp,
	Alternative: <T>(default: T | StateData<T>) -> (self: StateData<T?>) -> State<T>,
	-- 결과 타입을 호출자가 직접 준다: `theme:Apply(Operator.Index<<string>>("Primary"))`(사용자 결정 2026-09-08 —
	-- 키에서 추론하는 타입드 형태는 지금 솔버로 불가, `typing-limits.md` 8.15; 무주석 추론이 되면 그때 옮긴다)
	Index: <V>(key: any) -> (self: any) -> State<V>,
}

-- ── Tag / Attr (M10, round16 spike) ─────────────────────────────
export type Tag = {
	read __quadTag: true, -- 런타임 `TagImpl.__quadTag = true`(H-300)
	Added: (self: Tag, names: TagNames) -> Tag,
	Removed: (self: Tag, names: TagNames) -> Tag,
	Contains: (self: Tag, ...string) -> boolean, -- all present; vararg (`H-468`)
	Names: (self: Tag) -> () -> string?,
	Apply: <U>(self: Tag, factory: (Tag) -> U) -> U,
}
-- `H10-3`/`H10-4` (d): 교집합(함수∩테이블 — 무거주라 값 캐스트 붕괴 +
-- 제네릭 오염)이 아니라 솔버의 콜러블-테이블 표기로 선언한다. 실측
-- A/B·잔여 구멍은 typing-limits 8.6절. `Merged`는 Tag만 받는 엄격형(`Tag(a, b)`와 결과 같음).
export type TagConstructor = setmetatable<{ Merged: (...TagMarker) -> Tag }, { __call: (self: any, ...TagNames) -> Tag }>

-- `Tween<T>`는 **[2026-09-07 사용자 결정] quad-roblox `types.luau`로 이동**했다 — 옵션
-- 어휘(`Time`/`Style`/`Direction`/`RepeatCount`/`Reverses`/`DelayTime`)가 Roblox `TweenInfo`의
-- 것이고 웹 백엔드는 다른 이름·모양(`Transition`)을 가질 것이라 공개 표면을 공유할 이득이
-- 없다(`base/tween-plan.md` "패키지 경계" 절). quad-types엔 Tween이라는 이름이 없다.

export type Attr = {
	read __quadAttr: true, -- 런타임 `AttrImpl.__quadAttr = true`(H-300; 입력 자리는 `AttrMarker`)
	NameMap: (self: Attr) -> { [string]: any },
}
export type AttrConstructor = setmetatable<{
	Merged: (...Attr) -> Attr,
	Overridden: (...Attr) -> Attr,
}, { __call: (self: any, ...any) -> Attr }>

export type AttrKeyObject = { Name: string }
-- [2026-09-03 사용자 확정] AttrKey는 무타입 프리미티브(값 타입을 모른다 —
-- 패밀리가 못 덮는 엔진 고유 타입은 이걸로, 검증은 백엔드 setAttr 몫)
export type AttrKeyConstructor = (name: string) -> AttrKeyObject
-- 타입드 스칼라 슈가 — 배열부 값(단일 항목 그룹 `Attr({ [name] = value })`).
-- 값은 T | State<T> | None(삭제); nil은 거부(런타임 검증). State 자리는 마커(입력 자리 규칙, `StateMarker`)
export type AttrSugar<T> = (name: string, value: T | StateMarker<T> | None) -> Attr

-- ── Modifier (M7 단위 ①·④) — `base/modifier-plan.md` ───────────────────
-- 런타임 표면만(예약 메소드 넷). 클래스별 필드 setter 타입(`<Class>Modifier`)은
-- 생성기(M7 단위 ③)가 찍고, `Overridden`은 스파이크 `09`대로 `any`.
export type Modifier = {
	-- 마커(H-300 관례): `true` = 무타입(base `Modifier()`), 클래스 태그 값은
	-- 클래스명 문자열 — 그 리터럴은 생성/사용자 정의 `<Class>Modifier` 타입이
	-- 각자 선언한다(단위 ④, 11절). 런타임 값에도 실제로 있다(Dispatch/Modifier/init.luau)
	read __quadModifier: true,
	-- 정본 9절 `:Peek<<T>>(key)` — `store:Of<<T>>`와 같은 명시 인스턴스화 관례.
	-- [2026-09-07 회신 4차 Q24 후속] 반환은 `FieldOut<T>?` — 변환 함수의 `old`와 같은 "저장된 그대로"
	-- 값. `T`는 그 필드의 값 대수 전부(백엔드 값 어휘 포함 — quad-roblox라면 `X | Tween<X>`); 생성
	-- `<Class>Modifier`의 `Peek`가 그 별칭으로 덮는다
	Peek: <T>(self: Modifier, key: string) -> FieldOut<T>?,
	-- ⚠️ self·factory 둘 다 `any`(typing-limits 8.9절): 자기 타입을 참조하는
	-- 함수 필드가 유니언 멤버(`Tag`/`State`)의 같은 이름 메소드와 만나면 새
	-- 솔버의 유니언 검사가 조용히 통과한다 — children 자리의 클래스 소속
	-- 검사를 살리려고 재귀를 포기(사용자 확정 2026-09-04). 주석 붙인 팩토리는
	-- 그대로 타입드, 무주석 팩토리는 `any`.
	Apply: <U>(self: any, factory: (any) -> U) -> U,
	Overridden: (self: Modifier, ...any) -> any,
	-- 무검사 캐스트(11절): 인자 없으면 self 그대로(타입만), 이름을 주면 존재
	-- 검사 후 태그 교체. 검사형 `As<Class>()`는 클래스별 타입이 메소드로 찍는다
	As: <T>(self: Modifier, name: string?) -> T,
}
-- `H-310`(사용자 확정 2026-09-04): 인자는 Modifier 또는 `{ field = value }` 테이블,
-- 뒤가 필드 단위로 덮어씀(Overridden 규칙) — `Modifier()` == `Modifier({})`.
-- 단위 ④(사용자 확정 — 함수 하나에 일 하나): `TypedFactory<<T>>(name)`은 클래스
-- 이름을 알리고 그 태그를 심는 생성자를 돌려준다(T는 호출자가 쓴 그 클래스의
-- Modifier 타입 — 생성 `<Class>Modifier`나 사용자 정의), `DefineSubtype(parent,
-- subtype)`은 관계 간선 하나만 등록한다(부모 여럿 허용 — 인터페이스). 둘 다
-- 공개 API(프로바이더는 첫 사용자일 뿐, 컴포넌트도 같은 길), 둘 다 dedup.
export type ModifierConstructor = setmetatable<{
	Overridden: (...any) -> any,
	TypedFactory: <T>(name: string) -> (...(Modifier | { [string]: any })) -> T,
	DefineSubtype: (parent: string, subtype: string) -> (),
}, { __call: (self: any, ...(Modifier | { [string]: any })) -> Modifier }>
-- Modifier 필드에 "저장된 그대로"의 값 — `Peek` 반환과 setter 변환 함수의 `old`(생성 D의 `Field<T>`)가
-- 공유하는 출력 타입: 리터럴 | State 핸들 자체(값이 아니라 — 반응성 유지) | None(명시 해제).
-- State 팔 하나(저장된 것의 상한, round3 Q23 (a)). 입력 팔은 마커(8.11). quad-base는 필드에 무엇이
-- 저장되는지(엔진 값 어휘)를 모른다 — 백엔드가 `T` 자리에 자기 값 대수를 넣어 별칭한다: quad-roblox
-- `types.luau`의 `FieldOut<T> = QuadTypes.FieldOut<T | Tween<T>>`(= `T | Tween<T> | State<T | Tween<T>> | None`,
-- 2026-09-07 Tween 이동 전과 같은 전개형; 생성 D는 그걸 재별칭 — D 안 전개는 typing-limits 8.12).
-- ⚠️ 프로바이더 아래에서도 base `Modifier()`의 `Peek`는 이 정의를 쓰므로 `Peek<<UDim2>>`는 Tween 팔이 없다 —
-- 그 필드가 Tween을 품을 수 있으면 `Peek<<UDim2 | Tween<UDim2>>>`로 부를 것(T = 값 대수 전부, `H-459`).
export type FieldOut<T> = T | State<T> | None

export type State<T> = StateData<T> & {
	-- deps는 `...any`다 — 타입팩 `D...`로 위치 인자를 좁히는 형태는 strict에서 콜백 dep
	-- 추론이 `{read Get: ...}`로 뒤틀려 정상 호출까지 막힌다(M2 단위 2 실측, 스파이크 15가
	-- "미검증"으로 남겨둔 자리). 콜백 안에서 dep 파라미터에 주석을 달 것.
	Compute: <U>(self: StateData<T>, fn: (self: StateData<T>, previous: U?, ...any) -> U, ...any) -> State<U>,
	With: (self: StateData<T>, ...any) -> State<T>,
	-- 애플리커티브 팩토리는 함수이거나 메소드형 `__apply`를 가진 객체(`H-94`/`H-158`).
	-- **교집합 오버로드**로 선언한다(M2 단위 4 실측, `luau-test/done/26-*`): 유니온 하나로
	-- 두면 `Blocker`처럼 필드가 더 있는 객체가 제네릭 `U` 자리에서 너비 서브타이핑을 못
	-- 받아 `state:Apply(blocker)`가 strict에서 막힌다. 객체 쪽은 `any`를 돌려주므로 결과는
	-- `local g: State<number> = s:Apply(b)`로 명시(§1①의 파생 State 명시 주석 관례와 같다).
	Apply: (<U>(self: StateData<T>, factory: (State<T>) -> U) -> U) & ((self: StateData<T>, factory: { __apply: (self: any, state: any) -> any }) -> any),
	-- 등록 즉시 1회 실행. 무인자면 "항상 관측" 유틸.
	Observer: (self: StateData<T>, fn: ObserverFn<T>?) -> Observer,
	-- 전파 경로에 GateNode 하나(값은 안 가린다, 통지만 유보). 같은 T.
	Gate: (self: StateData<T>, setup: GateSetup) -> State<T>,
}
-- `Source`는 `State`를 구조적으로 만족하고 동시에 `Epoch`다(다중 태깅).
export type Source<T> = State<T> & {
	Revision: number,
	Set: (self: Source<T>, v: T) -> Source<T>,
	Emit: (self: Source<T>) -> Source<T>,
}

-- ── 디스패치 엔진(M3 단위 1) ──────────────────────────────────────────
-- `Handler` — 핸들러 계약 **필수 3종 + 선택 `name`·`keyType`**(`.claude/base/
-- dispatch-core-plan.md` "핸들러 계약"): `isHandlable`은 부작용 없는 순수
-- 판별(inst도 받음), `process`는 자기 자신을 무르는 retractor를
-- 반환(생략 불가 — 정리할 게 없어도 `Void`). 1번째 인자는 `nil`(단순
-- 철거)이거나 같은 핸들러가 처리할 새 값, 2번째는 `retracting`(`H-258` —
-- 아래 필드 주석). `name`은 진단 전용
-- (`H-214` (a) 사용자 확정, 2026-08-31) — 동률 경고·`listHandlers`·
-- `quad-debug` 체인 덤프가 있으면 쓰고 없으면 priority만 보인다,
-- 스캔·매치엔 아무 영향 없음.
-- `keyType`(round7 Q37 (a), 사용자 확정 2026-09-08 — `H-484`)은 선택 선언:
-- "이 핸들러는 이 타입의 키에서만 매치할 수 있다". `getHandler`가 키 타입별
-- 버킷(number / string / 그 밖)만 스캔하도록 하는 힌트이고, 없으면 모든
-- 버킷에 든다(서드파티·키 무관 핸들러는 지금처럼 전수 스캔 대상).
-- `isHandlable`은 그대로 최종 판별자 — 선언은 그 술어가 이미 거부하는 키를
-- 아예 안 묻게 할 뿐이다. 어긋나게 선언하면 그 핸들러는 그 버킷에서 조용히
-- 빠지고 더 낮은 priority의 미선언 핸들러가 대신 매치할 수 있다 — 선언은
-- `isHandlable`의 `type(k)` 가드와 같은 값이어야 한다.
export type Handler = {
	name: string?,
	keyType: ("number" | "string")?,
	isHandlable: (inst: any, key: any, value: any) -> boolean,
	priority: number,
	-- retractor 계약(`H-258`, 사용자 설계): 두 번째 인자 `retracting`이 참이면
	-- 단순 철거(retractFrom 경유 — 이 자리는 다시 처리되지 않는다), 거짓이면
	-- 같은 핸들러의 재처리가 곧 따라온다((A) 분기). nil을 값으로 받는
	-- 핸들러가 "철거의 nil"과 "값인 nil"을 이 플래그로 구별한다.
	process: (inst: any, key: any, value: any, index: number) -> (nextValue: any?, retracting: boolean) -> (),
}

-- `Dispatch` — 스캔/실행 엔진(`dispatch-core-plan.md` "Dispatch 체인" /
-- "우선순위 동률/매치 실패 처리"). 프리미티브가 아니라 모듈 인스턴스별
-- 네임스페이스(`InitDispatch(module)`가 설치, 멤버는 lowercase 네임스페이스
-- 규칙 — `architecture.md` "코드 스타일"). `HANDLER_PRIORITY_*`는 열린 숫자
-- 공간 위의 밴드 상수(`+ 1` 미세 조정 가능).
export type Dispatch = {
	getHandler: (inst: any, key: any, value: any) -> Handler?,
	process: (inst: any, key: any, value: any, index: number) -> (),
	retractFrom: (inst: any, key: any, index: number) -> (),
	addHandler: (handler: Handler) -> (),
	listHandlers: () -> { Handler },
	drive: (inst: any, flattened: { [any]: any }) -> (),
	-- Length/Offset 부기(M3 단위 2, `dispatch-core-plan.md` "Length/Offset" 절).
	-- 말단 핸들러 작성자만 지키는 계약 — 배열 자리마다 둘 다 필수(생략 UB),
	-- 해제는 setOffsetSource(None) → setLength(0) 순서.
	setLength: (ownerKey: any, i: number, len: number | StateMarker<number>, anchor: any?, element: any?) -> (),
	setOffsetSource: (ownerKey: any, i: number, source: any) -> (), -- Source<number> | None
	-- 그 해제 쌍을 한 본문으로(setOffsetSource(None) → setLength(0, anchor)) — 말단
	-- nop/leaf 핸들러의 "빈 자리 등록"(post-implementation review Q3 ③, 2026-09-07)
	setEmpty: (ownerKey: any, i: number, anchor: any?) -> (),
	getOffsetAt: (ownerKey: any, at: number) -> number,
	getBlocker: (ownerKey: any) -> Blocker,
	getBookkeeping: (ownerKey: any) -> any,
	HANDLER_PRIORITY_HIGH: number,
	HANDLER_PRIORITY_NORMAL: number,
	HANDLER_PRIORITY_LOW: number,
	HANDLER_PRIORITY_FALLBACK: number,
}

-- 예약 키 진단 — `keyof<T>`(키 싱글톤 유니온)만 받는다(`H-112`). `error()`는 못 쓴다
-- (타입 함수 자체가 실패로 판정) — `print` + `types.never`. 목록은 quad-base
-- `Store.luau`의 `RESERVED` 테이블의 사본이라 이름을 바꿀 땐 둘을 같이.
-- `.claude/base/typing-limits.md` §0: 타입 함수는 **진단까지만**.
export type function CheckReservedKeys(keys: type)
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
-- `Store<T>` — `T`는 `{hp: Source<number>, …}` 그대로(평범한 레코드, 타입 함수 없음).
-- `__reservedCheck`는 팬텀(런타임 nil, 읽지 말 것, `Names()`에 안 들어감).
export type Store<T> = T & {
	Of: <U>(self: any, name: string) -> Source<U>,
	Names: (self: any) -> { string },
	__reservedCheck: CheckReservedKeys<keyof<T>>,
}

-- ── Slot (M6, `H-25`의 "마일스톤마다 갱신" 몫 — 2026-09-03 잔여 마감) ────
-- 계약 정본은 `base/slot-plan.md` "CRUD API 확정" 표와 "`Slot:List(...)`" 절.
-- 요소 자리는 `T | State<T> | Slot<T>`(반응형 raw 요소는 내부 `:Single` 래퍼로,
-- 중첩은 Slot-in-Slot) — 같은 인자의 자기 참조라 `Ref<T>`처럼 안전하다
-- (`typing-limits.md` §1 "정확한 경계" 표: 한계는 **다른** 인자로 자기를
-- 돌려줄 때다).
-- 조회(`Get`/`IndexOf`/`Extract`류 반환)는 언래핑된 원래 값이 온다.
-- [2026-09-07 마커] 입력 자리(`Add`/`Replace`/`Extract`의 새 요소/`Splice`/`IndexOf`/생성자
-- `initial`)는 마커 — `Slot<Frame>`·`State<Frame>`이 `Slot<Instance>` 요소 자리에 공변으로
-- 들어간다. 출력(`Get`/`Extract`/`ExtractAll`/`Splice` 반환, `updateFn`의 `prev`)은 "언래핑된
-- 원래 값"이라 전체형 `SlotItem<T>` — 같은 값의 두 역할이라 별칭이 둘이다.
export type SlotElement<T> = T | StateMarker<T> | SlotMarker<T>
export type SlotItem<T> = T | State<T> | Slot<T>
export type SlotListOpts = { Owned: boolean? }
-- `updateFn(item, index, offset, prev, userdata) -> (result, userdata)`: `result`는
-- 요소 | nil/None(파괴) | Detach(홀드). `item`엔 `KeyGone` 센티널도 온다.
-- (별도 alias로 빼지 않는다 — `Slot<T>`↔`SlotElement<T>` 재귀 그룹 안에서
-- 메소드 제네릭 `<Item, UD>`를 인자로 받는 alias는 "다른 파라미터의 재귀"로
-- 거부된다 — 2026-09-03 실측, typing-limits §1①과 같은 제약.)
export type Slot<T> = {
	read __quadSlot: true, -- 런타임 `Slot_mt.__quadSlot = true`
	read __quadSlotValue: T, -- 순수 팬텀(StateMarker와 같은 층)
	Length: Source<number>,
	Offset: Source<number>,
	Add: (self: Slot<T>, element: SlotElement<T>, index: number?) -> number,
	Remove: (self: Slot<T>, index: number) -> (),
	Replace: (self: Slot<T>, index: number, newElement: SlotElement<T>) -> (),
	Extract: (self: Slot<T>, index: number, newElement: SlotElement<T>?) -> SlotItem<T>,
	ExtractAll: (self: Slot<T>) -> { SlotItem<T> },
	Splice: (self: Slot<T>, index: number, removeCount: number, ...SlotElement<T>) -> { SlotItem<T> },
	Clear: (self: Slot<T>) -> (),
	Move: (self: Slot<T>, oldIndex: number, newIndex: number) -> (),
	Swap: (self: Slot<T>, indexA: number, indexB: number) -> (),
	Get: (self: Slot<T>, index: number) -> SlotItem<T>?,
	IndexOf: (self: Slot<T>, element: SlotElement<T>) -> number?,
	List: <Item, UD>(
		self: Slot<T>,
		data: { Item } | StateMarker<{ Item }>,
		updateFn: (item: Item | KeyGone, index: number, offset: Source<number>, prev: SlotItem<T>?, userdata: UD?) -> (any, UD?),
		keyFn: ((item: Item, index: number) -> any)?,
		opts: SlotListOpts?
	) -> Slot<T>,
	Single: <UD>(
		self: Slot<T>,
		state: T? | StateMarker<T?>,
		updateFn: ((item: T | KeyGone, offset: Source<number>, prev: SlotItem<T>?, userdata: UD?) -> (any, UD?))?,
		opts: SlotListOpts?
	) -> Slot<T>,
}

-- ── 공개 표면 — `Quad`(quad-base가 구현), `CheckedQuad`, 런타임 값(`Brand` 팩토리·상수) ───────

export type Quad = {
	Version: "0.0.0", -- quad-base/pesde.toml의 version과 항상 맞출 것
	debug: boolean,
	New: () -> Quad,
	RunInit: (self: Quad, initFn: (Quad) -> any) -> (),
	AddPlugin: <Self, P>(self: Self, pluginFn: (Self) -> P) -> Self & P,
	-- 백엔드(프로바이더) 설치 전용(`H-305` (d′), 2026-09-02 사용자 확정) —
	-- AddPlugin과 타입 모양은 같지만 계약이 다르다: 모듈당 1슬롯 fn
	-- identity 락(같은 fn 재호출 no-op / 다른 identity — 다른 프로바이더든
	-- 같은 백엔드의 다른 사본·버전이든 — error). 백엔드 표면(`D` 등)은
	-- 이 반환 교집합 `Self & P`로 타입이 실린다 — quad-types엔 안 실림.
	UseProvider: <Self, P>(self: Self, providerFn: (Self) -> P) -> Self & P,

	-- M2 공통 기반이 얹는 탑레벨 값(`ROADMAP.md` M2 `H-80`). `Source`/`Store`/
	-- `Effect`/`Blocker`는 각 단위에서 추가된다.
	Relate: () -> Relate,
	Void: (...any) -> (),
	Ref: <T>(default: T) -> Ref<T>,
	PreRef: <T>(default: T) -> PreRef<T>, -- M8 단위 ①
	PostRef: <T>(default: T) -> PostRef<T>,
	-- 단위 2. `State`는 런타임 생성자가 없다(파생 전용) — 타입만 위에서 export.
	Source: <T>(v: T) -> Source<T>,
	-- `H-508` (2026-09-08 round8 Q43, 스파이크): overload intersection — the single generic
	-- `<T>(defaults: T?)` left `T` as `unknown` on the no-arg call, and `keyof<unknown>` in
	-- `__reservedCheck` raised at the first use (strict). The no-arg arm pins `Store<{}>`;
	-- the runtime is unchanged (`Store.luau` `or {}`, `H-83`).
	Store: (() -> Store<{}>) & (<T>(defaults: T) -> Store<T>),
	-- 단위 3. deps는 State/Source/Ref(`H-70`), `fn`엔 안 넘어간다.
	Effect: (fn: EffectFn, ...any) -> EffectHandle,
	-- 단위 4.
	Blocker: () -> Blocker,
	-- 시간 게이트 슈거(`base/debounce-throttle-plan.md`) — `Blocker`+`state:Gate`+아래 시간 op 위의 순수 슈거.
	Debounce: (opts: DebounceOptions) -> TimedGate,
	Throttle: (opts: ThrottleOptions) -> TimedGate,
	-- 생명주기 훅 슈거(`base/lifecycle-hooks-plan.md`) — `PreRef`/`PostRef`/`Effect` 인스턴스를 돌려주는 순수
	-- 팩토리. nil 가드 래퍼(`H-120`) 때문에 `fn`은 non-nil `inst`를 받는다. quad-base는 백엔드 요소 타입을
	-- 모르므로 제네릭 자리(`I`). **[2026-09-09 실측 정정]** `I`는 명시적 타입 인자로만 채워진다 —
	-- `q.OnCreated<<Frame>>(function(inst) … end)`. 콜백 파라미터에 주석을 다는 형태(`function(inst: Frame)`)는
	-- 신 솔버에서 `Type functions do not currently support types of the form '*error-type*'`로 죽는다
	-- (docs-ignoreme 재작성 중 발견, `typing-limits.md` 8.16).
	OnCreated: <I>(fn: (inst: I, ref: PreRef<I?>) -> ()) -> PreRef<I?>,
	OnRendered: <I>(fn: (inst: I, ref: PostRef<I?>) -> ()) -> PostRef<I?>,
	OnDestroyed: (fn: () -> ()) -> EffectHandle,
	-- 컴포넌트 에러 격리 슈거(`base/fallback-plan.md`) — `pcall`/`xpcall`+`debug.traceback` 위의 순수 함수.
	-- `err`는 `any`(문자열 가정 금지 — 그 문서 "`err: any`임을 반드시 문서화" 절).
	Fallback: <Ok, Err, A...>(base: (A...) -> Ok, onError: (err: any) -> Err) -> (A...) -> Ok | Err,
	Traceback: <Ok, Err, A...>(base: (A...) -> Ok, onError: (err: any, trace: string) -> Err) -> (A...) -> Ok | Err,
	-- 명시적 값 컨테이너(`base/context-plan.md`)와 연산자 콤비네이터(`research/operator-sugar-plan.md`), 2026-09-08
	Context: ContextConstructor,
	Operator: Operator,

	-- 디스패치 엔진(M3 단위 1, `H-25` — 마일스톤마다 서브시스템 필드를 여기
	-- 같이 갱신하는 규칙의 M3 몫). 닫힌 레코드라 이 필드가 없으면
	-- `quad.Dispatch` 접근이 런타임엔 되는데 `luau-analyze`에선 타입에러다.
	Dispatch: Dispatch,

	-- 공유 에러 네임스페이스(`H-231`) — quad-base의 모든 표면·백엔드가 같은
	-- 태그 맵을 써야 워커가 경계를 본다. 백엔드는 자기 quad-error 사본의
	-- 네임스페이스를 만들지 말고 이걸 받을 것.
	errorNamespace: ErrorNamespace,

	-- `None` 센티널(M3 단위 2에서 값이 생김 — 정의는 `Dispatch/None.luau`,
	-- 여기선 재export. `isNone`은 `v == None` 신원 비교 — 이 구조 타입은
	-- 조언층일 뿐 판정이 아니다, 최상위 `export type None` 참고(`H-300`).
	-- [2026-09-02] `H-300` 마커 필드가 생기며 `any`일 이유가 소멸해 좁힘
	-- (사용자 지적 — 옛 `any`는 마커 이전 "신원이라 표현 불가" 시절의 잔재).
	None: None,

	-- 생명주기 4종 — quad-base는 인터페이스(에러 스텁)만, 백엔드가 주입
	-- (`.claude/base/lifecycle-pattern.md`). `canBound(v) == not canExecute(v)`.
	bindLifetime: (inst: any, value: any) -> (),
	unbindLifetime: (value: any) -> (),
	canBound: (value: any) -> boolean,
	canExecute: (value: any) -> boolean,
	-- 주입 엔진 op(`architecture.md` EngineOps) — `Effect._bindDestroying`이 부른다. 미주입이면 에러 스텁.
	onDestroying: (inst: any, fn: () -> ()) -> { Connected: boolean, Disconnect: (self: any) -> () },
	-- 시간 op 둘(`architecture.md` EngineOps 줄, `debounce-throttle-plan.md` 6절) — 미주입이면 에러 스텁.
	setTimeout: (func: () -> (), delay: number) -> Timeout,
	clearTimeout: (timeout: Timeout) -> (),

	-- Slot 표면(M6 — `H-25` 몫, 2026-09-03). `Slot(initial?)`은 `:Add` 반복 sugar.
	-- `dispose`는 quad 관리 값을 지우는 유일한 안전 경로(마운트 중이면 error).
	Slot: <T>(initial: { SlotElement<T> }?) -> Slot<T>,
	Detach: Detach,
	KeyGone: KeyGone,
	dispose: (value: any) -> (),
	isSlot: (x: any) -> boolean,

	-- 브랜드 술어(`.claude/base/brand-plan.md`). `isTag`/`isAttr*`는
	-- M10 편입(2026-09-03)으로 아래 합류, `isSlot`은 위 Slot 표면과 함께 — quad-base
	-- 브랜드 전원 등재. `isTween`은 **[2026-09-07]** Tween과 함께 quad-roblox로(프로바이더
	-- 확장 `RobloxExtension`이 싣는다 — 백엔드 브랜드는 백엔드 표면).
	isEpoch: (x: any) -> boolean,
	isSource: (x: any) -> boolean,
	isState: (x: any) -> boolean,
	isStore: (x: any) -> boolean,
	isObserver: (x: any) -> boolean,
	isEffect: (x: any) -> boolean,
	isBlocker: (x: any) -> boolean,
	isContext: (x: any) -> boolean, -- 2026-09-08
	isProvider: (x: any) -> boolean,
	isModifier: (x: any) -> boolean,
	isRef: (x: any) -> boolean,
	isPreRef: (x: any) -> boolean,
	isPostRef: (x: any) -> boolean,
	isMapperDescriptor: (x: any) -> boolean, -- M5 단위 ④(Claim)
	-- `Claim(inst, desc) -> inst` — 이미 있는 트리를 quad 소유로(claim-plan §2;
	-- 타입 인자 없음·반환은 넣은 inst 그대로가 사용자 확정)
	Claim: <T>(inst: T, desc: MapperDescriptor) -> T,
	-- `Claim`의 매퍼 부속(M5 단위 ④, `H-25` 단위 ⑤ 확인분) — 루트 키
	-- 센티널 값(재노출은 `D.Mapper.Root`)과 제네릭 디스크립터 팩토리
	-- (백엔드 `D.Mapper.<Class>` 별칭의 원천, claim-plan §7-1).
	MapperRoot: MapperRoot,
	newMapperClass: (className: string) -> (key: any) -> (props: any) -> MapperDescriptor,

	-- 주입 물리 op(`architecture.md` EngineOps, M5 몫 — `H-25` 단위 ⑤
	-- 확인분). quad-base엔 값이 없고(스텁도 없음 — 미설치 접근은 nil 호출
	-- 크래시) 백엔드 팩토리가 설치한다. 시그니처 정본은
	-- `base/slot-plan.md`의 "물리 조작은 주입 op다" 절.
	nativeInsert: (target: any, offset: number, elements: { any }) -> (),
	nativeExtract: (target: any, offset: number, elements: { any }, newElements: { any }?) -> (),
	nativeRemove: (target: any, offset: number, elements: { any }, newElements: { any }?) -> (),
	nativeMove: (target: any, fromOffset: number, elements: { any }, toOffset: number) -> (),
	nativeSwap: (target: any, offsetA: number, elementsA: { any }, offsetB: number, elementsB: { any }) -> (),
	nativeDispose: (element: any) -> (),
	-- 요소 타입 화이트리스트 술어(`H-40` 주입 술어) — 백엔드가 자기 실물
	-- 판정으로 설치, 테스트는 mock 판정으로 교체.
	isInst: (value: any) -> boolean,
	-- gcconn/gchold 셋업 op(claim-plan §7-9 — `New` ②단계와 `Claim`이 같은
	-- op를 부른다. 이중 claim은 셋업 유무로 error).
	nativeClaim: (inst: any) -> (),
	-- 매퍼 키 해석 op(claim-plan — 조회라 조합 폴백 예외, 미주입이면 error).
	nativeFindChild: (inst: any, key: any) -> any,
	-- base 소유 핸들러(Tag/Attr)가 부르는 주입 op(`dispatch-core-plan.md`
	-- "base가 소유하는 핸들러와 주입되는 엔진 op"). quad-base는 안내 스텁을
	-- 두고 프로바이더가 덮어쓴다 — **[2026-09-03 M10 엔진 축]** quad-roblox
	-- `EngineOps`가 CollectionService/`SetAttribute`로 채움.
	addTag: (inst: any, names: { string }) -> (),
	removeTag: (inst: any, names: { string }) -> (),
	setAttr: (inst: any, name: string, v: any) -> (),

	-- M10 (round16 spike) — Tag/Attr 표면(`H-25`의 "마일스톤마다 갱신" 몫)
	isTag: (x: any) -> boolean,
	isAttr: (x: any) -> boolean,
	isAttrKey: (x: any) -> boolean,
	-- 콜러블 네임스페이스 둘은 `setmetatable<A,B>` 표기(`H10-3`/`H10-4`
	-- (d), 2026-09-02 사용자 확정 — fork의 잠정 `any`는 교집합 표기가
	-- 제네릭 추론을 오염시키던 시절의 것. 실측·잔여 구멍(__call 인자
	-- 무검사)은 typing-limits 8.6절이 소스)
	Tag: TagConstructor,
	Modifier: ModifierConstructor, -- M7 단위 ①
	Attr: AttrConstructor,
	AttrKey: AttrKeyConstructor,
	StringAttr: AttrSugar<string>,
	NumberAttr: AttrSugar<number>,
	BooleanAttr: AttrSugar<boolean>,
}

--[[
	`CheckedQuad<T, Pattern>` — 주입된 값의 실제 타입 `T`가 `Pattern`
	(글롭/캐럿 문자열, `type-version-check` 패키지 참고 — `"*"`/`"N^"`/정확값)에
	맞는 `Version`을 갖는지 컴파일 타임에 확인. quad-base/quad-roblox
	자신은 항상 같은 모노레포에서 같이 개발되므로 지금은 정확히 일치하는
	`"0.0.0"` 패턴으로만 쓰지만(아래 사용법), quad-spring-roblox류
	**독립적으로 게시되는 백엔드 플러그인**은 `"0.*.*"`처럼 느슨한 패턴을
	직접 골라 쓸 수 있다 — 그래서 패턴을 이 타입의 파라미터로 열어둠.

	**⚠️ 반드시 "가상 필드"로만 쓸 것 — `T`를 직접 패스스루하지 말 것.**
	`TypeVersionCheck.CheckVersion<Actual, Pattern>` 자체가 이미 이 규칙을
	지키게 설계돼 있다(트리비얼한 `true`만 반환, `T`를 절대 참조/재구성
	안 함) — `type function`을 거친 값은 패스스루라도 이후 `AddPlugin`
	같은 제네릭 self 메소드 체이닝이 조용히 깨진다는 게 실측 확인됐기
	때문(`typing-limits.md` §6, `type-version-check/src/init.luau`
	참고).

	**사용법(필수 — 이 필드를 실제로 참조해야 체크가 평가된다)**:
	```lua
	local checked: QuadTypes.CheckedQuad<typeof(injectedQuad), "0.0.0"> = injectedQuad :: any
	local _ = checked.__versionCheck -- ⚠️ 이 줄이 없으면 체크가 조용히 스킵됨(lazy 평가)
	-- 이후 checked는 injectedQuad와 완전히 같은 타입(원본 그대로) —
	-- AddPlugin 체이닝 등 뒤이은 제네릭 연산이 전부 안전하게 동작함
	```
]]
export type CheckedQuad<T, Pattern> = T & { __versionCheck: TypeVersionCheck.CheckVersion<index<T, "Version">, Pattern> }



-- ── `Brand` — 인스턴스 브랜드 팩토리(`base/brand-plan.md` "구현 — 인스턴스 브랜드" 절, as-is) ──
-- [2026-09-07 사용자 결정] quad-base `Brand.luau`에서 여기로 — 팩토리만이다. 브랜드 인스턴스와
-- `isX` 술어는 각 패키지의 자기 `Brand.luau`가 만든다(quad-base: State/Slot/Tag/…, quad-roblox:
-- Tween, 장래 quad-spring: Spring). `Brand()`는 weak-key 집합 하나를 쥔 객체 하나를 만들고, 값은
-- 자기가 속한 브랜드(들)에 스스로 등록한다(다중 태깅이 설계의 존재 이유 — `Source`는
-- `SourceBrand`이자 `EpochBrand`). 역조회는 없다(`archive/brand-shared-registry-reversed.md`).
-- 메소드 이름이 소문자인 건 공개 quad 표면이 아니라 패키지 내부 유틸이기 때문(brand-plan).
-- 아무것에도 의존하지 않는다(특히 `None` 분기 없음 — `isNone`은 `v == None`).
export type Brand = {
	register: (self: Brand, x: any) -> (),
	is: (self: Brand, x: any) -> boolean,
}

local function Brand(): Brand
	local members = setmetatable({}, { __mode = "k" }) :: { [any]: true }
	return {
		register = function(_self: Brand, x: any)
			members[x] = true
		end,
		is = function(_self: Brand, x: any): boolean
			return members[x] == true
		end,
	}
end

-- ── 공유 상수(`H-230` (a) 사용자 확정, 2026-08-31) ──────────────────────
-- 타입 계약과 같은 이유로 여기 산다 — 백엔드가 무거운 quad-base 없이 닿아야
-- 하는 값들. `HANDLER_PRIORITY_*`는 밴드 상수(이름·순서·± 오프셋 공간이
-- 계약, 리터럴은 `H-213` — quad-base `Dispatch`가 재노출). `ERROR_LEVEL_SURFACE`는
-- quad-error 태그 레이어(`H-231` — 우선 "공개 표면" 하나만, 필요해지면 늘림):
-- 모든 공개 표면 함수와 `addHandler`가 수령하는 핸들러 함수가 이 레이어로
-- 태그되고, 사용자 입력·제공자 계약 위반 에러가 이 레이어를 겨냥한다.
return {
	Brand = Brand,
	HANDLER_PRIORITY_HIGH = 1000,
	HANDLER_PRIORITY_NORMAL = 0,
	HANDLER_PRIORITY_LOW = -1000,
	HANDLER_PRIORITY_FALLBACK = -1000000,
	ERROR_LEVEL_SURFACE = 1,
}
