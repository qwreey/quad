--!strict
--[[
	검증 대상: `Store<T>`가 레코드 타입 T의 각 필드를 Source로 감싼 타입을
	Luau `type function`으로 실제로 합성할 수 있는지 — 실제 실행이 아니라
	타입 체크(luau-analyze/luau-lsp) 대상.

	배경: .claude/base/bind-system-plan.md "`store.key` 레코드 필드 타이핑"
	절(2026-08-12 열일곱 번째 세션) — 사용자가 제시한 WrapStore/
	ProcessStoreType 스케치를 그대로 옮김. `research/pre-implementation-audit.md`
	1-10 해소 근거.

	핵심 우려: (a) `type function` 문법 자체(`types.newtable`/`:setproperty`/
	`types.singleton`/`ty:properties()`/`types.newfunction`)가 실제 설치된
	Luau 버전에서 정확히 이 API 모양인지 — type function은 비교적 최근/
	계속 진화 중인 기능이라 버전에 따라 세부 이름이 다를 수 있음
	(https://luau.org/types/type-functions/ , https://luau.org/types-library/
	최신 문서 기준으로 맞춰볼 것 — 아래는 사용자가 손으로 쓴 스케치를 최대한
	그대로 옮긴 것이라 API 이름이 실제와 다를 수 있음, 그 자체가 이
	스파이크의 목적). (b) 결과 타입 `ProcessStoreType<{ty: string}>`이
	실제로 `{ty: Source<string>}`을 "만족"해서(이름이 아니라 구조로)
	`Source<string>` 필드가 필요한 자리에 그대로 대입 가능한지.

	실행: `luau-analyze 16-type-store-key-typefunction.luau` 또는
	`luau-lsp analyze` — 문법/API 에러가 나면 정확한 에러 메시지(어느 줄,
	어떤 API 호출)를 그대로 알려줄 것 — 그게 다음 시도에서 API 이름을
	고치는 데 바로 쓰임. 이 파일 자체가 한 번에 통과할 걸 기대하기보다,
	"type function으로 이 방향 자체가 막히는지 아닌지"를 확인하는 게 목적.

	기대 결과: 맨 아래 `checkTy`/`checkCount` 대입이 타입 에러 없이 통과
	(= `Processed.ty`가 구조적으로 `Source<string>`을 만족).
]]

export type Source<T> = {
	Get: (self: Source<T>) -> T,
	Set: (self: Source<T>, value: T) -> (),
}

type function WrapStore(ty: type): type
	-- Source<T> 형태를 그대로 조립 — 실사용에선 :Set/:Compute/:With 등도
	-- 같은 방식으로 추가해야 하지만, 이 스파이크는 "필드가 Source로 감싸
	-- 지는가"라는 구조적 만족 여부만 보면 되므로 :Get만 붙임
	local result = types.newtable()
	result:setproperty(types.singleton("Get"), types.newfunction({}, { ty }))
	return result
end

type function ProcessStoreType(ty: type): type
	local props = ty:properties() :: { [type]: { read: type?, write: type? } }
	local result = types.newtable()
	for i, v in props do
		-- i는 프로퍼티 이름을 담은 singleton 타입, i:value()로 실제 문자열
		local fieldType = v.read or v.write
		if fieldType then
			result:setproperty(i, WrapStore(fieldType))
		end
	end
	return result
end

type Input = { ty: string, count: number }
type Processed = ProcessStoreType<Input>

local processed: Processed = nil :: any

-- 검증 포인트: Processed의 각 필드가 실제로 Source<T> 구조를 만족하는지
local checkTy: string = processed.ty:Get()
local checkCount: number = processed.count:Get()
