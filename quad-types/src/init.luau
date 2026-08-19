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

export type Quad = {
	Version: "0.0.0", -- quad-base/pesde.toml의 version과 항상 맞출 것
	debug: boolean,
	New: () -> Quad,
	RunInit: (self: Quad, initFn: (Quad) -> any) -> (),
	AddPlugin: <Self, P>(self: Self, pluginFn: (Self) -> P) -> Self & P,
}

--[[
	`CheckVersion<T>` — 주입된 값의 실제 타입 `T`가 이 패키지가 아는
	`Quad.Version`과 일치하는지 컴파일 타임에 확인.

	**⚠️ 반드시 "가상 필드"로만 쓸 것 — `T`를 직접 패스스루하지 말 것.**
	처음엔 `return t`(단순 패스스루)로 짜서 단독으로는 잘 됐는데,
	**`AddPlugin<Self,P>`처럼 제네릭 self 파라미터를 쓰는 메소드와
	체이닝하면 조용히 깨짐**을 실측으로 확인함(2026-08-19) — 값의 정적
	타입이 한 번이라도 `type function`을 거치면, 그 뒤 제네릭 self 추론이
	"Expected this to be exactly 'P & Self', but got 'P & Self'"류의
	앞뒤가 같은 의미 없는 진단을 내며 깨진다(재구성이 아니라 **패스스루도
	똑같이** 깨짐 — 재구성 비용 문제가 아니라 "그 타입이 type function을
	거쳤다는 이력 자체"가 문제였음). 그래서 검증 결과를 **원본 타입과
	절대 안 섞이는 별도 필드**로 격리해야 한다 — `CheckVersion<T>` 자체는
	`T`를 절대 참조/반환하지 않고, 성공 시 트리비얼한 `true` 하나만 반환.

	**사용법(필수 — 이 필드를 실제로 참조해야 체크가 평가된다)**:
	```lua
	type Checked<T> = T & { __versionCheck: CheckVersion<T> }

	local function CheckQuad<T>(quad: T): Checked<T>
		return quad :: any
	end

	local checked = CheckQuad(injectedQuad)
	local _ = checked.__versionCheck -- ⚠️ 이 줄이 없으면 체크가 조용히 스킵됨(lazy 평가)
	-- 이후 checked는 injectedQuad와 완전히 같은 타입(원본 그대로) —
	-- AddPlugin 체이닝 등 뒤이은 제네릭 연산이 전부 안전하게 동작함
	```

	**에러 표시 방식(실측 확인)**: 불일치 시 `error()`가 아니라
	`print("메시지")` + `return types.never`를 쓸 것 — `error()`는 "type
	function 자체가 실패함"으로 판정돼 버려서 못 쓰고, `print`+`never`
	조합만 호출부에 정확히 "TypeError: <메시지>"로 뜬다.
]]
-- selene: allow(undefined_variable) — `types`는 `type function` 블록 안에서만
-- 주입되는 특수 전역이라 selene의 luau std가 아직 이걸 모델링 못 함(실측
-- 확인, 2026-08-19) — 실제 미정의 변수가 아니라 selene 쪽 오탐.
type function CheckVersion(t: type): type
	local versionProp = t:readproperty(types.singleton("Version"))
	if versionProp == nil then
		print("quad-base injection is missing a Version field")
		return types.never
	end
	local literal = versionProp:value()
	if literal ~= "0.0.0" then
		print(`quad-base version mismatch: this package expects "0.0.0", got "{tostring(literal)}"`)
		return types.never
	end
	return types.singleton(true)
end

export type CheckedQuad<T> = T & { __versionCheck: CheckVersion<T> }

return {}
