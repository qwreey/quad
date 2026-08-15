--!strict
--[[
	검증 대상: `Store<T>`가 레코드 타입 T의 각 필드를 Source로 감싼 타입을
	Luau `type function`으로 실제로 합성할 수 있는지 — 실제 실행이 아니라
	타입 체크(luau-analyze/luau-lsp) 대상.

	배경: .claude/base/bind-system-plan.md "`store.key` 레코드 필드 타이핑"
	절(2026-08-12 열일곱 번째 세션) — 사용자가 제시한 WrapStore/
	ProcessStoreType 스케치를 그대로 옮김. `research/pre-implementation-audit.md`
	1-10 해소 근거.

	[2026-08-15 audit/type-recursive-issue-with-typeof/REPORT.md 6-1절에서 복구]
	원래 실패 원인은 설계 문제가 아니라 **API 버전 드리프트**였음 —
	`types.newfunction`의 시그니처가 `(parameters: {head: {type}?, tail:
	type?}, returns: {head: {type}?, tail: type?}?, generics: {type}?): type`
	로, parameters/returns 둘 다 **레코드**(`{head=..., tail=...}`)를
	받는데 원본은 배열(`{ ty }`)을 그대로 넘기고 있었음. self 파라미터는
	`types.newtable()`이 돌려주는 **뮤터블 핸들 자기 자신**을 그대로
	참조하면 됨(나중에 `setproperty`로 채워도 핸들이라 소급 반영됨) —
	별도 self 타입을 새로 만들 필요 없음. 이 수정만으로 통과.
	재현: `luau-analyze 16-type-store-key-typefunction.luau` — 진단 0건.

	실측 환경: Luau 0.733(`mise ls luau`).
]]

export type Source<T> = {
	Get: (self: Source<T>) -> T,
	Set: (self: Source<T>, value: T) -> (),
}

type function WrapStore(ty: type): type
	-- Source<T> 형태를 그대로 조립. self는 이 함수가 만드는 result
	-- 테이블 핸들 자신 — 아직 setproperty로 다 채우기 전이어도 핸들
	-- 참조라 나중 변경이 소급 반영됨(types.newfunction이 캡처하는 건
	-- 핸들이지 스냅샷이 아님)
	local result = types.newtable()
	result:setproperty(types.singleton("Get"), types.newfunction({ head = { result } }, { head = { ty } }))
	result:setproperty(types.singleton("Set"), types.newfunction({ head = { result, ty } }, { head = {} }))
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

-- 음성 대조군 — 타입이 실제로 강제되는지(진단 0건이 곧 안전은 아니므로,
-- typing-limits.md §1의 교훈 그대로 이 스파이크에도 적용)
local _wrongTy: number = processed.ty:Get() -- 반드시 에러: string을 number로
processed.ty:Set(123) -- 반드시 에러: Source<string>에 number를 Set
processed.count:Set("nope") -- 반드시 에러: Source<number>에 string을 Set
processed.ty:NoSuchMethod() -- 반드시 에러: 존재하지 않는 메소드
