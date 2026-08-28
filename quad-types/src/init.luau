--!strict
--[[
	`Quad` 공개 타입 계약 — 구현 없음, 런타임 값은 없다시피 함(빈 테이블).
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

-- `Epoch` — 최소 인터페이스(`.claude/base/state-epoch-plan.md` §2). 판정은
-- identity + "직전과 다른 Revision"뿐, 순서 비교 없음. 런타임 판별은 `isEpoch`.
export type Epoch = { Revision: number }

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

	-- 생명주기 4종 — quad-base는 인터페이스(에러 스텁)만, 백엔드가 주입
	-- (`.claude/base/lifecycle-pattern.md`). `canBound(v) == not canExecute(v)`.
	bindLifetime: (inst: any, value: any) -> (),
	unbindLifetime: (value: any) -> (),
	canBound: (value: any) -> boolean,
	canExecute: (value: any) -> boolean,

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

return {}
