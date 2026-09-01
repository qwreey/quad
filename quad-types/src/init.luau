--!strict
--[[
	`Quad` 공개 타입 계약 — 구현 없음. 런타임 값은 공유 **상수**뿐
	(`H-230` — 파일 끝의 반환 테이블, 로직은 여전히 0).
	`quad-base`가 이 타입을 구현하고, `quad-roblox`/향후 백엔드·플러그인
	패키지는 무거운 `quad-base` 전체 대신 이 패키지만 의존한다.

	**왜 별도 패키지인가**: `QuadRoblox(Quad): QuadRoblox`처럼 quad-base
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

-- `Ref<T>` 최소형(`.claude/base/ref-plan.md`, M2 `H-128`). 콜백은 `fn(value, ref)` —
-- 두 번째 인자가 Ref 자신(= `Epoch`). `:Wait`는 M8. **단일 타입 파라미터
-- `Ref<T>(T)`** — nil이 들어올 수 있는 자리는 호출자가 `Ref<<T?>>(nil)`로 넓힌다
-- (`ref-plan.md` "제네릭 시그니처").
export type RefCallback<T> = (value: T, ref: Ref<T>) -> ()
export type Ref<T> = {
	Value: T,
	Revision: number,
	Callbacks: { [RefCallback<T> | thread]: true }, -- 강한 해시맵 셋(+ M8 `:Wait` 대기자)
	WeakCallbacks: { [RefCallback<T>]: true }, -- weak-key 테이블
	Set: (self: Ref<T>, value: T) -> Ref<T>,
	Callback: (self: Ref<T>, fn: RefCallback<T>) -> Ref<T>,
	WeakCallback: (self: Ref<T>, fn: RefCallback<T>) -> Ref<T>,
	Uncallback: (self: Ref<T>, fn: RefCallback<T>) -> Ref<T>,
}

-- ── 반응형 코어(M2 단위 2) ────────────────────────────────────────────
-- 선언 스타일은 `.claude/base/typing-limits.md` §1②의 "데이터부/메소드부" 쪼개기 —
-- 콜백 파라미터 무주석 추론이 사는 유일한 스타일(`audit/handtrace-round10-reference-impl/
-- spikes/ty11_store_final.luau`가 최종형 실측). `Compute`의 `-> State<U>` 반환은 §1①의
-- 알려진 한계라 **파생 State를 만드는 자리는 결과 타입을 명시 주석**할 것.
-- `fn(self, previous?, ...deps)` — 전부 lazy 핸들, 값은 `:Get()`으로만
-- (`.claude/base/source-state-plan.md` "self 인자도 lazy 핸들로 통일").
export type StateData<T> = { Get: (self: StateData<T>) -> T }

-- 타입 별칭 이름 넷(`ObserverFn`/`EffectFn`/`GateEmit`/`GateSetup`)은 구현이 붙였고
-- `H-187` (a)로 사용자 승인(2026-08-31, "이름 그대로 사용해도 좋음").
-- `Observer` — 값을 안 실어주는 leaf 구독(`source-state-plan.md` "`state:Observer(fn)`").
-- `fn(targetState, self, emitFrom?)`: 3번째가 출처(`Epoch` | 집합), 설치·캐치업 발화는 `nil`.
-- 네 진입점은 `lifecycle-pattern.md` (2) — Weak가 프리미티브, `.Subscribed`는 강·약 공용.
export type Observer = {
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
-- `Handler` — 핸들러 계약 **필수 3종 + 선택 `name`**(`.claude/base/
-- dispatch-core-plan.md` "핸들러 계약"): `isHandlable`은 부작용 없는 순수
-- 판별(inst도 받음), `process`는 자기 자신을 무르는 1-인자 retractor를
-- 반환(생략 불가 — 정리할 게 없어도 `Void`). retractor 인자는 `nil`(단순
-- 철거)이거나 같은 핸들러가 처리할 새 값, 둘뿐. `name`은 진단 전용
-- (`H-214` (a) 사용자 확정, 2026-08-31) — 동률 경고·`listHandlers`·
-- `quad-debug` 체인 덤프가 있으면 쓰고 없으면 priority만 보인다,
-- 스캔·매치엔 아무 영향 없음.
export type Handler = {
	name: string?,
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
	setLength: (ownerKey: any, i: number, len: number | State<number>, anchor: any?, element: any?) -> (),
	setOffsetSource: (ownerKey: any, i: number, source: any) -> (), -- Source<number> | None
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

export type Quad = {
	Version: "0.0.0", -- quad-base/pesde.toml의 version과 항상 맞출 것
	debug: boolean,
	New: () -> Quad,
	RunInit: (self: Quad, initFn: (Quad) -> any) -> (),
	AddPlugin: <Self, P>(self: Self, pluginFn: (Self) -> P) -> Self & P,

	-- M2 공통 기반이 얹는 탑레벨 값(`ROADMAP.md` M2 `H-80`). `Source`/`Store`/
	-- `Effect`/`Blocker`는 각 단위에서 추가된다.
	Relate: () -> Relate,
	Void: (...any) -> (),
	Ref: <T>(default: T) -> Ref<T>,
	-- 단위 2. `State`는 런타임 생성자가 없다(파생 전용) — 타입만 위에서 export.
	Source: <T>(v: T) -> Source<T>,
	Store: <T>(defaults: T?) -> Store<T>,
	-- 단위 3. deps는 State/Source/Ref(`H-70`), `fn`엔 안 넘어간다.
	Effect: (fn: EffectFn, ...any) -> EffectHandle,
	-- 단위 4.
	Blocker: () -> Blocker,

	-- 디스패치 엔진(M3 단위 1, `H-25` — 마일스톤마다 서브시스템 필드를 여기
	-- 같이 갱신하는 규칙의 M3 몫). 닫힌 레코드라 이 필드가 없으면
	-- `quad.Dispatch` 접근이 런타임엔 되는데 `luau-analyze`에선 타입에러다.
	Dispatch: Dispatch,

	-- 공유 에러 네임스페이스(`H-231`) — quad-base의 모든 표면·백엔드가 같은
	-- 태그 맵을 써야 워커가 경계를 본다. 백엔드는 자기 quad-error 사본의
	-- 네임스페이스를 만들지 말고 이걸 받을 것.
	errorNamespace: ErrorNamespace,

	-- `None` 센티널(M3 단위 2에서 값이 생김 — 정의는 `Dispatch/None.luau`,
	-- 여기선 재export. `isNone`은 `v == None` 신원 비교).
	None: any,

	-- 생명주기 4종 — quad-base는 인터페이스(에러 스텁)만, 백엔드가 주입
	-- (`.claude/base/lifecycle-pattern.md`). `canBound(v) == not canExecute(v)`.
	bindLifetime: (inst: any, value: any) -> (),
	unbindLifetime: (value: any) -> (),
	canBound: (value: any) -> boolean,
	canExecute: (value: any) -> boolean,
	-- 주입 엔진 op(`architecture.md` EngineOps) — `Effect._bindDestroying`이 부른다. 미주입이면 에러 스텁.
	onDestroying: (inst: any, fn: () -> ()) -> { Connected: boolean, Disconnect: (self: any) -> () },

	-- 브랜드 술어(`.claude/base/brand-plan.md`). 나머지(`isTag`/`isAttribute*`/
	-- `isTween`/`isSlot`)는 그 타입의 마일스톤에서.
	isEpoch: (x: any) -> boolean,
	isSource: (x: any) -> boolean,
	isState: (x: any) -> boolean,
	isStore: (x: any) -> boolean,
	isObserver: (x: any) -> boolean,
	isEffect: (x: any) -> boolean,
	isBlocker: (x: any) -> boolean,
	isModifier: (x: any) -> boolean,
	isRef: (x: any) -> boolean,
	isPreRef: (x: any) -> boolean,
	isPostRef: (x: any) -> boolean,
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

-- ── 공유 상수(`H-230` (a) 사용자 확정, 2026-08-31) ──────────────────────
-- 타입 계약과 같은 이유로 여기 산다 — 백엔드가 무거운 quad-base 없이 닿아야
-- 하는 값들. `HANDLER_PRIORITY_*`는 밴드 상수(이름·순서·± 오프셋 공간이
-- 계약, 리터럴은 `H-213` — quad-base `Dispatch`가 재노출). `ERROR_LEVEL_SURFACE`는
-- quad-error 태그 레이어(`H-231` — 우선 "공개 표면" 하나만, 필요해지면 늘림):
-- 모든 공개 표면 함수와 `addHandler`가 수령하는 핸들러 함수가 이 레이어로
-- 태그되고, 사용자 입력·제공자 계약 위반 에러가 이 레이어를 겨냥한다.
return {
	HANDLER_PRIORITY_HIGH = 1000,
	HANDLER_PRIORITY_NORMAL = 0,
	HANDLER_PRIORITY_LOW = -1000,
	HANDLER_PRIORITY_FALLBACK = -1000000,
	ERROR_LEVEL_SURFACE = 1,
}
