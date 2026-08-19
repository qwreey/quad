--!strict
--[[
	검증 대상: `Store<{field: T}>`로 선언되지 않은 이름에 dot-access하면
	타입 시간에 실제로 거부되는지 — `.claude/base/store-plan.md` "Store =
	Source들의 이름 붙은 모음" 절의 "[확인 요구, 2026-08-18 구현 전 QA]"
	항목, 사용자 원문: *"Store<{ field: type }> 상 없는 네임에는 타입
	시간에 Source 가 없는것으로 나와 타입 에러만 나면 됩니다. 아마 지금
	설계가 그럴것이예요"* — "아마"라 M0에서 실측 확인하라고 명시됨.
	`todos.md` 00번 항목 / `ROADMAP.md` M0 목록.

	`16-type-store-key-typefunction.luau`가 이미 검증한 `ProcessStoreType`
	(type function 기반 `Store<T>` 합성)을 그대로 재사용 — 새로 검증하는
	건 그 결과 타입이 **인덱서 없는 순수 레코드**라 미선언 프로퍼티
	접근을 실제로 거부하는지 하나뿐.

	실행: `luau-analyze 21-type-store-undeclared-key-rejected.luau` — 양성
	경로(선언된 키 3개)는 클린, 미선언 키 접근 2건(읽기/메소드 호출)만
	TypeError로 걸려야 함.
]]

export type Source<T> = {
	Get: (self: Source<T>) -> T,
	Set: (self: Source<T>, value: T) -> (),
}

type function WrapStore(ty: type): type
	local result = types.newtable()
	result:setproperty(types.singleton("Get"), types.newfunction({ head = { result } }, { head = { ty } }))
	result:setproperty(types.singleton("Set"), types.newfunction({ head = { result, ty } }, { head = {} }))
	return result
end

type function ProcessStoreType(ty: type): type
	local props = ty:properties() :: { [type]: { read: type?, write: type? } }
	local result = types.newtable()
	for i, v in props do
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

-- 양성 경로 — 선언된 키는 정상 접근
local okTy: string = processed.ty:Get()
local okCount: number = processed.count:Get()
processed.ty:Set("hi")
print(okTy, okCount)

-- 검증 포인트 — 선언 안 된 키에 접근하면 타입 에러가 나야 함
print(processed.doesNotExist) -- 반드시 에러: 'doesNotExist'는 Processed에 없는 프로퍼티
processed.alsoMissing:Get() -- 반드시 에러: 'alsoMissing'도 없는 프로퍼티(체이닝된 :Get() 호출까지 안 감)
