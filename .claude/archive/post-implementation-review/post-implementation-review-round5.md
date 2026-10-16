# 사후 구현 감사 원장 (Round 5) — 2026-09-07

> **[2026-09-07 밤 메인 판정 — round3 §10]** 전제 정정: `G-15`/`G-18`/`G-19`/`G-20`/`G-21`이 전제한 "nil 키 *읽기* VM 에러"는 틀렸다(Luau는 읽기는 nil, *쓰기*만 에러 — 실측; §6 `S-16`이 같은 결론). 그래서 `G-15`/`G-18`/`G-19`는 이미 표면 에러(확인), `G-20`/`G-21`은 크래시가 아니라 조용한 nil/false 반환이었으나 사용자 회신 Q32에 따라 가드 반영(`H-468`·`H-469`, `Contains`는 가변인자). `G-16`은 실존 → Q30대로 `H-467`. `G-17`은 디스패치 계약 밖 오용(UB). §6 후행 배치(Gemini가 나중에 덧붙임): `G-22` → `H-473`, 6.4(Q31 — `unbindLifetime(nil)`도 에러) → `H-474`, 6.3의 `G-17`/`G-18` 재권고는 판정 유지(round3 §10 확인 행). Q30~Q32는 이 파일 §4의 사용자 회신을 결정으로 읽었다. 이 파일은 외부 리뷰 원문으로 보존.

- **검토 일시**: 2026-09-07
- **HEAD 커밋**: `2156b01d5b448552489bd84e4f96a0b6cdb0a028` (`fix: Q28·Q29 회신 반영...`)
- **검토 범위**: `quad-base`, `quad-roblox`, `quad-types`, `quad-error`, `scripts/` 및 `.claude/base/` 정본 계획 문서 전체
- **진입 및 규약**: `.claude/qa-request/external-review-entry.md` 절차 준수, 번호 체계(`G-15`~, `S-11`~, `Q30`~) 승계

---

## 1. 기보고 확인 표

`.claude/qa-request/external-review-entry.md` 3절의 중복 보고 제외 규칙에 따라, 기존 원장의 `H-440`~`H-462`, `G-10`~`G-14`, `S-07`~`S-10`, `Q25`~`Q29` 전수 대조를 수행하여 중복 여부를 검증했습니다.

| 검토 후보 항목 | 대조 대상 (기보고/정본) | 중복 여부 및 판정 근거 |
|---|---|---|
| `dispose(nil)` 및 `unbindLifetime(nil)` 처리 일관성 | G-12 (`drive(nil)`), G-14 (`unbindLifetime(nil)`) | **신규 (G-15)**: `unbindLifetime(nil)`의 침묵 no-op과 `dispose(nil)`의 `cannot dispose this value` 간 불일치. `nil` 인자 전달을 엄격히 거부하는 표면 가드 요구. |
| `Slot:Single`에서 `quad.None` 처리 누락 | `slot-plan.md`, H-379, Q8 (a) | **신규 (G-16)**: `Single`의 `Compute` 및 plain 분기가 `g == nil`만 검사하여 `None` 수신 시 `{ None }` 배열이 방출되고 `KeyGone`이 발화되지 않아 `(item: T | KeyGone)` 계약 파괴 (`H-467` 반영 완료). |
| `isPropertyOf`/`isEventOf`의 `inst.ClassName` 널 접근 | G-01, G-10 (`""` 빈 문자열 가드) | **신규 (G-17)**: `inst`가 mock 객체이거나 `ClassName`이 없을 때 `memberSet`의 `sets[className]`에서 Luau VM 원시 에러 `table index is nil`로 디스패치 루프가 중단되는 결함 (실측 확인). |
| `Bookkeeping` 공개 함수들의 `ownerKey == nil` | H-434 (`checkPosition`), G-12 | **신규 (G-18)**: `setEmpty(nil, 1)`, `getBlocker(nil)` 등 호출 시 `ownerKey` 널 가드가 없어 `Relate.luau:30` `table index is nil` VM 에러 노출 (실측 확인). |
| `Tag:Contains(nil)` 및 `Slot:Get(nil)` 원시 에러 | H-344 (`Tag:Added`/`Removed`), H-410 (`Slot:Get`) | **신규 (G-20)**: `Added`/`Removed`나 `Slot:Add`/`Remove`와 달리 질의 API 머리에 널 가드가 없어 `self._names[nil]`, `self._elements[nil]` VM 크래시 누출 (`H-468` 반영 완료). |
| `Modifier:Peek(nil)` 호출 시 VM 에러 | Q24 후속 (`FieldOut<T>?`), H-410 | **신규 (G-21)**: `methods.Peek`가 `return self[FieldsKey][key]` 한 줄로 작성되어 `mod:Peek(nil)` 시 `table index is nil` 크래시 발생 (`H-469` 반영 완료). |
| `Ref:Callback`/`Uncallback`의 `fn` 타입 검사 누락 | H-199 (`State:With`), H-202 (`State:Compute`) | **신규 (G-22)**: `Ref:Callback(fn)`, `Ref:WeakCallback(fn)`, `Ref:Uncallback(fn)`에 함수 타입 가드가 없어 `nil` 전달 시 `table index is nil`, 비함수 전달 시 `attempt to call` VM 크래시 발생 (실측 확인). |
| `flatten`의 희소 배열 key 검증 | H-312 | **건전 (S-11)**: `flatten`의 `next(input, k)` 루프가 희소 배열 키(`[10] = mod`)를 해시 키로 정상 판별하여 명확한 표면 에러를 발생시킴을 확인. |
| `RefLeafHandler`의 바인딩 및 콜백 순서 | round18 Q4, H-71 | **건전 (S-12)**: `v:Set(inst)` 직전 `relate:SetWeak`를 선행하여 콜백 재진입 시 이중 바인딩을 방지하는 불변식 확인. |
| `Claim`의 `nativeFindChild` nil 반환 동작 | claim-plan.md §3 | **건전 (S-13)**: 자식 매핑 실패 시의 재귀 크래시는 정본상 의도된 UB(디버그 도구의 몫)로 규정되어 있음을 확인. |
| `Relate.luau`의 `inst == nil` 취약점 중앙 가드 | H-444, H-447 | **건전 (S-14)**: 읽기(`Get`)와 달리 쓰기(`Set`)는 nil 인스턴스를 허용할 수 없으므로, API 표면별로 도메인 에러를 발생시키는 설계 기조가 타당함을 확인. |
| `Ref`의 `inst:Destroy()` 무반응 및 값 보존 | ref-plan.md 37~45행 | **건전 (S-15)**: `Ref`는 Destroy와 무관하게 동작하며, 관례를 벗어난 use-after-destroy는 정본 명세상 의도된 UB임을 확인. |
| `ModifierMT.__index`의 `methods[nil]` 읽기 동작 | H-448, Q11 (a) | **건전 (S-16)**: Luau 테이블 읽기 시 `t[nil]`은 에러를 던지지 않고 `nil`을 반환하므로, 245행 `methods[key]`가 정상 통과되어 255행의 `type(key) ~= "string"` 도메인 가드가 안전하게 발화됨을 실측 확인. |

---

## 2. 신규 발견 사항 (`G-15` ~ `G-22`)

### [G-15] `dispose(nil)` 및 `unbindLifetime(nil)`의 `nil` 인자 허용/모호한 에러 및 수명주기 불일치
- **위치**: `quad-base/src/Slot/init.luau:352-362`, `quad-roblox/src/LifetimeHandle.luau:155-158`
- **심각도**: Medium
- **설명**: 
  `dispose(value)`는 슬롯에 결속된 수명주기(`elementOwner` 등)를 명시적으로 정리하는 공개 진입점이고, `unbindLifetime(value)`는 바인딩된 핸들을 조기 해제하는 수명주기 프리미티브입니다. 현재 `unbindLifetime(nil)`은 `post-implementation-review-round3.md` `H-444`에 의해 `if value == nil then return end`로 조용히 성공(no-op) 처리되는 반면, `dispose(nil)`은 `elementOwner:GetWeak(nil, OWNER)`가 `nil`을 반환한 뒤 `else` 분기로 빠져 `dispose: this backend cannot dispose this value`라는 모호한 에러를 발생시킵니다. 그러나 사용자 회신(Q31)에서 확정되었듯이, 초기화되지 않은 변수나 우발적으로 `nil`이 된 요소가 수명주기 함수로 넘어가 조용히 성공하거나 부정확한 에러를 내는 것은 라이브러리 경계에서 반드시 차단되어야 합니다. 따라서 `dispose`와 `unbindLifetime` 모두 진입 머리에서 `if value == nil then Err.errorBeforeNearest("<함수명>: value must not be nil", SURFACE) end` 가드를 두어 `nil` 인자를 표면 레벨에서 즉시 엄격하게 거부하도록 일관성을 맞추는 방안을 제안합니다.
- **코드 인용**:
```luau
-- quad-base/src/Slot/init.luau:352-362
local function dispose(value: any)
	if elementOwner:GetWeak(value, OWNER) ~= nil then
		Err.errorBeforeNearest("dispose: this value is still held by a Slot or a mounted position..." .. ZOMBIE_NOTE, SURFACE)
	end
	if isSlot(value) then S.destroySlotTree(value)
	elseif module.isInst(value) then module.nativeDispose(value)
	else Err.errorBeforeNearest("dispose: this backend cannot dispose this value", SURFACE) end -- ← nil 전달 시 이 모호한 에러 발생
end
```
```luau
-- quad-roblox/src/LifetimeHandle.luau:155-158
local function unbindLifetime(value: any)
	if value == nil then
		return -- header contract: no-op if unbound (round3 H-444) ← nil 전달 시 조용한 성공(침묵)
	end
```

---

### [G-16] `Slot:Single`의 `None` 값 누락으로 인한 `updateFn` 계약 파괴 및 `KeyGone` 미발화 *(메인 세션 `H-467` 반영 완료)*
- **위치**: `quad-base/src/Slot/List.luau:218-223`
- **심각도**: High
- **설명**:
  `Slot:Single(state, updateFn, opts)`는 단일 값 상태를 내부적으로 1원소 또는 빈 배열 형태의 `Slot:List` 데이터 소스로 변환하는 편의 API입니다. `quad` 프레임워크는 `nil`을 표현하는 1급 센티널로 `quad.None`(`S.None`)을 표준 지원하고 있으나, 기존 `Single`의 변환 구현은 오직 `if g == nil then {} else { g }` 및 `if state == nil then {} else { state }`만 검사했습니다. 상태에 `quad.None`이 전달되면 `g == nil`이 `false`로 평가되어 빈 배열 `{}`이 아니라 `{ None }` 단일 원소 배열이 방출되었습니다. 이로 인해 리스트 reconcile 엔진은 항목이 제거되었다고 인지하지 못하여 `KeyGone` 제거 신호를 발화하지 않고, 대신 `updateFn`의 `item` 자리에 `None` 테이블 센티널을 그대로 전달하여 `(item: T | KeyGone)` 계약을 파괴했습니다. 메인 세션에서 사용자 회신(Q30)을 반영하여 `g == nil or g == None` 및 `state == nil or state == None`일 때 빈 배열 `{}`을 반환하도록 `H-467` 커밋으로 수정 완료되었습니다.
- **코드 인용 (수정 반영본)**:
```luau
-- quad-base/src/Slot/List.luau:218-223 (H-467 반영 완료)
local None = S.None
local data = if S.isState(state)
	then state:Compute(function(v: any) local g = v:Get(); return (if g == nil or g == None then {} else { g }) end)
	else (if state == nil or state == None then {} else { state })
```

---

### [G-17] `Property`/`Event` 핸들러의 `isHandlable`이 `inst.ClassName` 부재 시 `Reflection.luau:29` VM 크래시를 유발하는 결함
- **위치**: `quad-roblox/src/Handlers/Property.luau:112-114`, `quad-roblox/src/Handlers/Event.luau:55-58`, `quad-roblox/src/Reflection.luau:20-32`
- **심각도**: Medium
- **설명**:
  `Property`와 `Event` 핸들러의 `isHandlable(inst, k, v)`는 주어진 키가 해당 인스턴스의 프로퍼티나 이벤트인지 판별하기 위해 `Reflection.isPropertyOf(inst.ClassName, k)` 및 `Reflection.isEventOf(inst.ClassName, k)`를 호출합니다. 만약 `inst`가 Roblox native Instance가 아닌 일반 모의 객체(mock table, test double)이거나 `ClassName` 필드가 누락된 테이블인 경우(`inst.ClassName == nil`), `Reflection.luau`의 `memberSet` 클로저는 인자에 대한 널 가드 없이 29행에서 `sets[className] = set`(`sets[nil] = set`) 대입을 수행하여 Luau VM 원시 에러인 `table index is nil`을 던지며 디스패치 루프 전체를 크래시시킵니다 (실측 재현 확인). 핸들러의 `isHandlable`은 "이 핸들러가 처리할 수 있는가"를 검사하는 순수 불리언 술어(`(inst: any, k: any, v: any) -> boolean`) 계약이어야 하므로, `Reflection.luau` 머리에 `if className == nil then return false end` 가드를 추가하거나 `isHandlable`에서 `inst.ClassName ~= nil`을 선행 체크하여 안전하게 `false`를 반환하도록 보강하는 방안을 제안합니다.
- **코드 인용**:
```luau
-- quad-roblox/src/Handlers/Property.luau:112-114
local function isHandlable(inst: any, k: any, v: any): boolean
	return type(k) == "string" and k ~= "Parent" and isPropertyOf(inst.ClassName, k)
end
```
```luau
-- quad-roblox/src/Reflection.luau:20-32
return function(className: string, key: string): boolean
	local set = sets[className]
	if set == nil then
		set = {}
		for _, d in fetch(className) do
			if acceptFn(d) then
				set[d.Name] = true
			end
		end
		sets[className] = set -- ← className == nil일 때 여기서 Luau VM 'table index is nil' 크래시!
	end
	return set[key] == true
end
```

---

### [G-18] `Bookkeeping` 공개 함수 `getBlocker(nil)` 호출 시 `Relate.luau:30` VM 크래시
- **위치**: `quad-base/src/Bookkeeping.luau:61-68`
- **심각도**: Low
- **설명**:
  `quad-base/src/Bookkeeping.luau`의 `getBlocker(ownerKey)`는 디스패치 및 슬롯 레이어에서 배치 차단기를 얻기 위해 호출되는 함수입니다. 현재 `checkPosition` 같은 위치 검증 로직은 갖추어져 있으나 `ownerKey`에 대한 널 가드가 없어 `getBlocker(nil)` 호출 시 65행에서 `blockers:SetStrong(ownerKey, "blocker", blocker)`를 호출하고, `Relate.luau:30`의 `self.buckets[inst] = bucket`(`self.buckets[nil] = bucket`)에서 `table index is nil` VM 원시 에러가 발생합니다 (실측 재현 확인). 반면 `getBookkeeping(nil)`이나 `setEmpty(nil, 1)` 등은 `module.bindLifetime(nil, bk)`를 거치며 `bindLifetime: inst must not be nil` 표면 에러를 정상 발화하므로, `getBlocker` 머리에도 `if ownerKey == nil then Err.errorBeforeNearest("quad.Dispatch.getBlocker: ownerKey must not be nil", SURFACE) end` 가드를 추가하여 일관된 표면 에러를 보장할 것을 제안합니다.
- **코드 인용**:
```luau
-- quad-base/src/Bookkeeping.luau:61-68
local function getBlocker(ownerKey: any): any
	local blocker = blockers:GetStrong(ownerKey, "blocker")
	if blocker == nil then
		blocker = Blocker()
		blockers:SetStrong(ownerKey, "blocker", blocker) -- ← ownerKey == nil일 때 Relate.luau:30에서 VM 크래시!
	end
	return blocker
end
```

---

### [G-20] `Tag:Contains(nil)` 및 `Slot:Get(nil)` 호출 시 질의 API 가드 부재 *(메인 세션 `H-468` 반영 완료)*
- **위치**: `quad-base/src/Tag.luau:136-151`, `quad-base/src/Slot/init.luau:271-278`
- **심각도**: Low
- **설명**:
  `Tag:Contains(name)`와 `Slot:Get(index)`는 각각 태그 포함 여부와 슬롯 요소를 조회하는 공개 읽기 API입니다. `Tag.Added`/`Tag.Removed`나 `Slot:Add`/`Slot:Remove` 등 모든 변경 API는 인자를 엄격히 검증하는 반면, 기존 `Tag:Contains`와 `Slot:Get`은 널 가드 없이 `self._names[name] == true` 및 `unwrapElement(self._elements[index])`를 실행했습니다. 사용자 지침(Q32)에 따라 `Tag:Contains`는 가변인자(`...string`)를 받아 0개 인자(동적 unpack)는 허용하되 `nil` 및 비문자열은 에러를 던지도록 확장되었고, `Slot:Get`은 `type(index) ~= "number"` 검사를 통해 `nil`을 엄격히 거부하는 `H-468` 커밋으로 수정 완료되었습니다.
- **코드 인용 (수정 반영본)**:
```luau
-- quad-base/src/Slot/init.luau:271-278 (H-468 반영 완료)
function Slot_mt.Get(self: any, index: number): any
	if type(index) ~= "number" then
		Err.errorBeforeNearest(`Slot:Get: index must be a number (got {typeof(index)})`, SURFACE)
	end
	return S.unwrapElement(self._elements[index])
end
```
```luau
-- quad-base/src/Tag.luau:136-151 (H-468 반영 완료)
function TagImpl.Contains(self: any, ...: string): boolean
	local n = select("#", ...)
	for i = 1, n do
		local name = select(i, ...)
		if type(name) ~= "string" then
			Err.errorBeforeNearest(`Tag:Contains: names must be strings (got {typeof(name)} at argument {i})`, SURFACE)
		end
		if self._names[name] ~= true then
			return false
		end
	end
	return true
end
```

---

### [G-21] `Modifier:Peek(nil)` 호출 시 비문자열/nil 가드 부재 *(메인 세션 `H-469` 반영 완료)*
- **위치**: `quad-base/src/Dispatch/Modifier/init.luau:163-169`
- **심각도**: Low
- **설명**:
  `mod:Peek(key)`는 모디파이어 내부의 필드 값을 반응성 언래핑 없이 그대로 조회하는 공개 조회 API입니다. 기존 구현은 `return self[FieldsKey][key]` 한 줄로 작성되어 있어, `key`가 빈 문자열이거나 `nil`일 때도 도메인 검증 없이 통과하여 `nil`을 반환했습니다. 사용자 지침(Q32: "Modifier:Peek도 키가 존재하는 것, 빈 문자열조차 안 되도록 막았는데 nil을 허용할 이유 없음")에 따라, 메인 세션에서 `if type(key) ~= "string" or key == "" then Err.errorBeforeNearest(...) end` 가드를 추가한 `H-469` 커밋으로 수정 완료되었습니다.
- **코드 인용 (수정 반영본)**:
```luau
-- quad-base/src/Dispatch/Modifier/init.luau:163-169 (H-469 반영 완료)
function methods.Peek(self: any, key: any): any
	if type(key) ~= "string" or key == "" then
		Err.errorBeforeNearest(`Modifier:Peek: key must be a non-empty string (got {if key == "" then '""' else typeof(key)})`, SURFACE)
	end
	return self[FieldsKey][key]
end
```

---

### [G-22] `Ref:Callback`/`WeakCallback`/`Uncallback`의 `fn` 타입 가드 부재로 인한 VM 크래시 (`table index is nil`, `attempt to call`)
- **위치**: `quad-base/src/Ref/init.luau:111-121, 156-160`
- **심각도**: Low
- **설명**:
  `Ref:Callback(fn)`, `Ref:WeakCallback(fn)`, `Ref:Uncallback(fn)`은 리프 값 상자 `Ref`에 변경 리스너를 등록하고 해제하는 공개 API입니다 (`quad-types` 명세 `RefCallback<T> = (value: T, ref: Ref<T>) -> ()`). 그러나 `fn` 인자에 대한 함수 타입 검사(`type(fn) == "function"`)가 누락되어 있어, 사용자가 실수로 `ref:Callback(nil)` 또는 `ref:Uncallback(nil)`을 호출할 경우 `self.Callbacks[nil] = true` 및 `self.Callbacks[nil] = nil`에서 Luau VM 원시 에러 `table index is nil`이 발생하고(`Ref/init.luau:118, 157`), 숫자 등 비함수를 넘기면(`ref:Callback(123)`) `fn(self.Value, self)` 실행 시 `attempt to call a number value` 원시 크래시가 발생합니다 (실측 재현 확인). 동일 모듈의 `Ref:Wait(thread)`가 `if thread ~= nil and type(thread) ~= "thread" then Err.errorBeforeNearest(...)`로 방어하고 있고 형제 프리미티브(`State:Compute`, `State:Observer`, `Effect`, `OnChange`)들도 모두 `fn`의 함수 여부를 엄격히 검사하여 도메인 에러를 발생시키는 것과 대조적입니다. `Callback`, `WeakCallback`, `Uncallback`의 진입 머리에 `if type(fn) ~= "function" then Err.errorBeforeNearest("Ref: callback must be a function", SURFACE) end` 가드를 추가하여 비함수 인자를 도메인 표면 에러로 조기 차단할 것을 제안합니다.
- **코드 인용**:
```luau
-- quad-base/src/Ref/init.luau:111-121
function RefImpl.WeakCallback<T>(self: Ref<T>, fn: Callback<T>): Ref<T>
	self.WeakCallbacks[fn] = true -- ← fn == nil일 때 VM 'table index is nil' 크래시!
	fn(self.Value, self)          -- ← fn이 비함수일 때 VM 'attempt to call' 크래시!
	return self
end

function RefImpl.Callback<T>(self: Ref<T>, fn: Callback<T>): Ref<T>
	self.Callbacks[fn] = true     -- ← fn == nil일 때 VM 'table index is nil' 크래시!
	fn(self.Value, self)
	return self
end
```
```luau
-- quad-base/src/Ref/init.luau:156-160
function RefImpl.Uncallback<T>(self: Ref<T>, fn: Callback<T>): Ref<T>
	self.Callbacks[fn] = nil      -- ← fn == nil일 때 VM 'table index is nil' 크래시!
	self.WeakCallbacks[fn] = nil
	return self
end
```

---

## 3. 건전성 확인 목록 (`S-11` ~ `S-16`)

- **[S-11] `Dispatch/Modifier/init.luau`의 `flatten`에서 sparse array key 가드 동작의 건전성**:
  `flatten` 함수([`quad-base/src/Dispatch/Modifier/init.luau:39-72`](file:///code/Projects/quad/quad-base/src/Dispatch/Modifier/init.luau#L39-L72))는 배열 인덱스를 `1`부터 `rawlen(input)`까지 순회한 뒤, `next(input, k)` 루프를 통해 비배열 키가 섞여 있는지(`mixed hash key`) 검사합니다. 이때 `[10] = mod`처럼 배열 길이가 0인 희소 배열(sparse array)이 들어오면 `next` 루프에 의해 해시 키(`H-312`)로 정상 포착되어 표면 에러 `modifier array must not contain non-array keys`를 정확히 발생시킴을 확인했습니다. VM 크래시나 무한 루프 없이 엄격한 유효성 검사가 건전하게 동작합니다.

- **[S-12] `RefLeafHandler`의 `v:Set(inst)` 전 `relate:SetWeak` 선행 순서의 건전성**:
  [`quad-base/src/Ref/init.luau:210-213`](file:///code/Projects/quad/quad-base/src/Ref/init.luau#L210-L213)에서 `v:Set(inst)`를 호출하기 직전에 `relate:SetWeak(inst, k, v)`를 먼저 수행합니다. 이는 `v:Set(inst)` 실행 중 리스너에 의해 동일한 `inst`/`k`에 대한 재진입이나 수명주기 해제가 트리거되더라도, 이미 약참조 북키핑이 완료되어 있어 이중 바인딩이나 고아 핸들이 발생하지 않도록 보장하는 안전하고 건전한 순서임을 확인했습니다.

- **[S-13] `Claim`의 `nativeFindChild` nil 반환 시 재귀 생성 분기의 건전성**:
  [`quad-base/src/Claim.luau:93-100`](file:///code/Projects/quad/quad-base/src/Claim.luau#L93-L100)의 `resolve`는 자식 디스크립터 매핑 시 이름 부재/중복을 의도적으로 UB(디버그 툴링의 몫)로 규정하고 있으며, `nativeFindChild`가 nil을 반환할 경우 후속 재귀가 자연 크래시하도록 둔 설계가 `base/claim-plan.md` §3 명세에 완벽히 부합함을 확인했습니다.

- **[S-14] `Relate.luau`의 `inst == nil` 취약점과 `Relate:getBucket` 레벨에서의 중앙 가드 가능성 분석**:
  `Relate:GetWeak`, `Relate:GetStrong` 등에서 `inst == nil`일 때 VM 에러가 발생하는 패턴에 대해, `Relate:getBucket`에서 `self.buckets[nil]`은 Luau 테이블 읽기 규칙에 따라 크래시 없이 단순히 `nil`을 반환합니다. 반면 `Relate:getOrCreateBucket`의 쓰기(`SetStrong`/`SetWeak`)는 `self.buckets[nil] = bucket`에서 크래시가 발생합니다. 읽기와 쓰기의 동작이 비대칭적이므로, 내부 자료구조(`Relate.luau`)에서 일괄 무음 처리하기보다는 각 공개 호출 표면(API 진입점)에서 의미 있는 도메인 에러를 던지는 현재의 설계 기조가 구조적으로 타당함을 확인했습니다.

- **[S-15] `Ref`의 `inst:Destroy()` 무반응 및 `.Value` 유지 동작의 건전성**:
  `base/ref-plan.md` 37~45행에 명시된 대로 "Ref는 Destroy와 완전히 무관하게 동작하며, 관례를 벗어난 장기 보관에 따른 use-after-destroy는 quad가 런타임 안전망을 두지 않는 의도된 UB"임이 확정되어 있습니다. 따라서 `RefLeafHandler`가 `onDestroying`을 연결하지 않고 디스패치 언마운트(retractor)에서만 `v:Set(nil)`을 호출하는 구조는 정본에 완벽히 부합하는 정상 설계임을 확인했습니다.

- **[S-16] `ModifierMT.__index`의 `methods[nil]` 읽기 동작 및 도메인 가드 건전성 실측 증명**:
  `ModifierMT.__index` 245행의 `local method = methods[key]`가 255행의 `type(key) ~= "string"` 검사보다 선행하고 있어 `mod[nil]` 시 245행에서 VM 크래시가 발생할 것으로 의심(구 G-19)되었으나, 실제 Luau 환경에서 스크래치 테스트(`quad-base/test/tmp.*.luau`)로 실측한 결과: Luau의 평범한 테이블 읽기 `t[nil]`은 에러를 던지지 않고 안전하게 `nil`을 반환합니다. 따라서 245행은 조용히 `method = nil`로 통과되고, 255행의 `if type(key) ~= "string"` 가드로 직행하여 의도된 도메인 에러 `Modifier: setter keys must be strings (got nil)`가 호출자 위치를 정확히 가리키며 정상 발화함을 입증했습니다. 따라서 가드 순서 역전 의혹은 건전한 코드로 확인되었습니다.

---

## 4. 사용자 회신 및 열린 질문 (`Q30` ~ `Q32`)

### [Q30] `Slot:Single`에서 `None` 수신 시 라이프사이클 처리 규격 (G-16 관련)
- **질문**: `Slot:Single(state, updateFn)`에 `quad.None`이 전달되었을 때, `None`을 일반 값으로 취급하여 `updateFn(None)`을 호출하는 것이 의도된 동작인가, 아니면 `nil`과 동등하게 간주하여 빈 배열 `{}`로 변환함으로써 `updateFn(KeyGone)`을 발화하고 슬롯을 비우는 것이 의도된 동작인가?
- **사용자 회신 (확정)**: **의미론적으로 `None == nil`이 맞다.** quad 내부에서 `None`은 핸들러 처리를 거쳐 어떻게든 `nil`로 수렴한다. 이 프로젝트는 컴포넌트가 Slot이나 Instance를 반환할 수 있고, 결과가 무엇이든 유저가 Slot 안이든 직접 마운트든 무관하게 쓸 수 있는 구조로 계획되었으므로, `None`도 `nil`로 특수 처리되어 빈 배열 `{}`을 방출하고 정상적인 `KeyGone` 언마운트 수명주기를 타도록 수정하는 것이 맞다.
- **조치 상태**: 메인 세션에서 `quad-base/src/Slot/List.luau`에 `H-467` 커밋으로 반영 완료.

### [Q31] `dispose(nil)` 및 북키핑 공개 API의 `nil` 수신 시 no-op 허용 여부 (G-15, G-18 관련)
- **질문**: `Slot.unbindLifetime(nil)`은 no-op으로 조용히 반환하는 반면, `dispose(nil)`이나 `Dispatch.setEmpty(nil, 1)` 등은 원시 VM 에러가 발생한다. `dispose(nil)`을 호출했을 때 엄격하게 표면 에러를 던질지, 아니면 `unbindLifetime`처럼 no-op으로 조용히 반환할 것인가?
- **사용자 회신 (실측 및 분석 지침)**: `unbindLifetime`에 `nil` 처리를 넣었던 이유가 있었는지 실측하고, 특별한 이유가 없다면 에러를 내는 것이 낫다. 처음부터 요소나 인자가 `nil`로 들어가 조용히 성공하는 케이스가 발생하는 것은 방지되어야 한다.
- **실측 결과 분석**: `post-implementation-review-round3.md` `H-444`에서 `unbindLifetime(nil)`은 헤더 계약인 *"no-op if unbound"*에 근거하여 nil 조기 반환이 들어갔으나, `H-447`에서 `bindLifetime(inst, nil)`은 즉시 에러(`bindLifetime: value must not be nil`)로 분리되었습니다. 코퍼스 전체에서 내부 호출자 중 `unbindLifetime(nil)`의 no-op 성공에 의존하는 곳은 존재하지 않으며(모두 유효 객체만 전달), 요소가 잘못 `nil`로 평가되어 들어갔을 때 침묵하는 성공은 결함을 은폐합니다. 따라서 `dispose(nil)`과 `unbindLifetime(nil)` 모두 `nil` 인자를 허용하지 않고 `value must not be nil` 표면 에러를 던지도록 가드를 일치시키는 것이 확정 방향입니다.

### [Q32] 질의형 API(`Slot:Get`, `Tag:Contains`, `Modifier:Peek`)의 `nil` 인자 수용 방침 (G-20, G-21 관련)
- **질문**: `Get`, `Contains`, `Peek` 같은 단순 조회/질의 API에 `nil`이 들어왔을 때, `nil`/`false`를 조용히 반환하는 관용적 정책을 취할지, 아니면 `errorBeforeNearest`로 즉시 실패하는 엄격한 정책을 취할 것인가?
- **사용자 회신 (확정)**: **`nil` 허용 불가 (에러 발생).** Slot의 인덱스 키는 확실히 존재하는 요소이고, `Modifier:Peek`도 키가 존재하는 것이므로 빈 문자열(`""`)조차 안 되도록 막은 마당에 `nil`을 허용할 이유가 없다. 단, `Tag:Contains(...)`는 단순 확장의 관점에서 가변인자(`string...`)를 받아 전부 존재하는지 검사할 수 있으며, 동적 unpack 등으로 인해 인자 개수가 0개인 경우는 허용될 수 있으나 `nil`은 여전히 허용되지 않고 에러를 발생시켜야 한다.
- **조치 상태**: 메인 세션에서 `Tag.luau`, `Slot/init.luau`, `Modifier/init.luau`에 각각 `H-468`, `H-469` 커밋으로 반영 완료.

---

## 5. 종합 요약 및 핸드오버 표

| ID | 분류 | 위치 | 심각도 | 처리 상태 및 권고 조치 요약 |
|---|---|---|---|---|
| **G-15** | 결함 | `Slot/init.luau:352`, `LifetimeHandle.luau:155` | Medium | **잔여 결함**: `dispose(nil)`의 모호한 에러 및 `unbindLifetime(nil)`의 조용한 침묵 해소 → `value must not be nil` 표면 에러 가드 추가 (Q31). |
| **G-16** | 결함 | `Slot/List.luau:218` | High | **반영 완료 (`H-467`)**: `Slot:Single`에서 `None`을 `nil`과 동등하게 처리하여 빈 배열 `{}` 방출 및 `KeyGone` 정상 발화 (Q30). |
| **G-17** | 결함 | `Reflection.luau:29` | Medium | **잔여 결함**: mock/비Instance 디스패치 시 `sets[nil] = set` Luau VM 크래시 → `Reflection.memberSet` 머리에 `className == nil` 시 `return false` 가드 추가. |
| **G-18** | 결함 | `Bookkeeping.luau:65` | Low | **잔여 결함**: `getBlocker(nil)` 시 `Relate.luau:30` `table index is nil` VM 크래시 → `ownerKey == nil` 표면 에러 가드 추가. |
| **G-20** | 결함 | `Tag.luau:136`, `Slot/init.luau:271` | Low | **반영 완료 (`H-468`)**: `Slot:Get(nil)` number 타입 가드 및 `Tag:Contains(...names)` 가변인자 비문자열/nil 표면 에러 가드 추가 (Q32). |
| **G-21** | 결함 | `Modifier/init.luau:163` | Low | **반영 완료 (`H-469`)**: `Modifier:Peek(nil)` 비문자열 및 빈 문자열 표면 에러 가드 추가 (Q32). |
| **G-22** | 결함 | `Ref/init.luau:111, 156` | Low | **잔여 결함**: `Ref:Callback`/`Uncallback`의 `type(fn) ~= "function"` 가드 부재로 VM 크래시 → 진입 머리 함수 타입 표면 에러 가드 추가. |
| **S-11** | 건전 | `Modifier/init.luau:39` | — | `flatten`의 희소 배열 키(`[10] = mod`)에 대한 `H-312` 가드 정상 동작 확인. |
| **S-12** | 건전 | `Ref/init.luau:210` | — | `RefLeafHandler`의 `relate:SetWeak` 선행 순서로 재진입 이중 바인딩 방지 불변식 확인. |
| **S-13** | 건전 | `Claim.luau:93` | — | `Claim`의 매핑 실패 시 재귀 크래시가 정본(`claim-plan.md` §3)상 의도된 UB임을 확인. |
| **S-14** | 건전 | `Relate.luau:22` | — | `Relate` 중앙 가드 대신 호출 표면별 도메인 에러 가드가 타당함을 확인. |
| **S-15** | 건전 | `Ref/init.luau:214` | — | `Ref`의 `inst:Destroy()` 무반응 및 값 보존이 정본(`ref-plan.md`)상 의도된 UB임을 확인. |
| **S-16** | 건전 | `Modifier/init.luau:245` | — | Luau 테이블 읽기 `methods[nil]`은 VM 에러를 내지 않고 `nil`을 반환하여 255행 도메인 가드가 정상 발화됨을 실측 확인 (구 G-19 건전성 전환). |

---

## 6. 후행 심층 조사 및 실측 검증 상세 (Followup Batch Investigation)

> **맥락 분리 안내**: 본 절은 메인 에이전트의 1차 검토 및 판정(`post-implementation-review-round3.md` §10 `H-463`~`H-472`) 이후, 사용자 요청에 따라 진행된 **후행 배치 조사 및 실측 테스트 결과**를 별도로 분리하여 기록한 영역입니다. 메인 에이전트는 이 절을 참고하여 잔여 항목들을 일괄 인계받을 수 있습니다.

### 6.1 신규 미해결 결함 상세: [G-22] `Ref:Callback` 계열의 함수 타입 가드 누락

- **위치**: `quad-base/src/Ref/init.luau:111-121, 156-160`
- **심각도**: Low / VM Crash Prevention
- **실측 재현 증상**:
  - `ref:Callback(nil)` 또는 `ref:Uncallback(nil)` 호출 시, `self.Callbacks[nil] = true` 및 `self.Callbacks[nil] = nil`이 실행되어 `quad-base/src/Ref/init.luau:118` 및 `157`에서 Luau VM 원시 에러인 `table index is nil` 발생.
  - `ref:Callback(123)` 등 비함수 전달 시, `fn(self.Value, self)` 실행 중 `attempt to call a number value` VM 원시 에러 발생 (`Ref/init.luau:119`).
- **권고 조치**:
  - `RefImpl.Callback`, `RefImpl.WeakCallback`, `RefImpl.Uncallback` 진입 머리에 `if type(fn) ~= "function" then Err.errorBeforeNearest("Ref: callback must be a function", SURFACE) end` 가드 추가.

### 6.2 실측 검증에 따른 건전성 확인: [S-16] `ModifierMT.__index` 가드 순서 (구 G-19 정정)

- **위치**: `quad-base/src/Dispatch/Modifier/init.luau:244-261`
- **실측 결과**:
  - 245행 `local method = methods[key]`에서 `key == nil`일 때 Luau의 일반 테이블 읽기 규칙(`t[nil]`)은 크래시 없이 단순히 `nil`을 반환합니다.
  - 따라서 245행을 무사히 통과한 뒤 255행의 `if type(key) ~= "string"` 검사에 정상 도달하여 의도된 도메인 에러 `Modifier: setter keys must be strings (got nil)`를 발화하며, 사용자 호출 위치를 정확하게 blame합니다.
  - 따라서 순서 역전 크래시 의혹은 기각되며 코드는 건전함(Sound)으로 판정합니다.

### 6.3 실측 재현 확인: [G-17] `Reflection.memberSet` 및 [G-18] `Bookkeeping.getBlocker(nil)`

1. **[G-17] `Reflection.memberSet`**:
   - `ClassName` 필드가 없는 모의 테이블(`{}`)을 인스턴스로 전달하여 디스패치할 때, `sets[className] = set`(`sets[nil] = set`) 대입이 실행되어 `quad-roblox/src/Reflection.luau:29`에서 `table index is nil` VM 크래시 발생 확인.
   - 조치: `Reflection.memberSet` 머리에 `if className == nil then return false end` 가드 필요.
2. **[G-18] `Bookkeeping.getBlocker(nil)`**:
   - `getBlocker(nil)` 호출 시 65행 `blockers:SetStrong(nil, ...)`에서 `Relate.luau:30`의 `self.buckets[inst] = bucket`(`self.buckets[nil] = bucket`) 대입으로 인해 `table index is nil` VM 크래시 발생 확인.
   - 조치: `getBlocker` 머리에 `if ownerKey == nil then Err.errorBeforeNearest("quad.Dispatch.getBlocker: ownerKey must not be nil", SURFACE) end` 가드 필요.

### 6.4 Q31 심층 분석: `unbindLifetime(nil)`과 `dispose(nil)`의 일관된 거부 정책

- **현상**: `unbindLifetime(nil)`은 `H-444`에 의해 조용히 no-op 성공 처리되고 있으나, `dispose(nil)`은 `cannot dispose this value` 에러를 냅니다.
- **분석 및 확정**: 사용자 회신 Q31("처음부터 elem 이나 무언가 nil로 들어가 조용히 성공하는 케이스가 나오게 된다는건데, 가능해선 안되는 부분")에 따라, 수명주기 API에 우발적인 `nil`이 전달되어 침묵 성공하는 것은 결함을 숨기므로 위험합니다.
- **권고 조치**: `dispose(nil)`과 `unbindLifetime(nil)` 모두 `if value == nil then Err.errorBeforeNearest("<함수명>: value must not be nil", SURFACE) end`로 명확한 표면 에러를 던지도록 정렬합니다.

### 6.5 메인 에이전트 핸드오버 잔여 태스크 요약

| 항목 ID | 심각도 | 대상 파일 | 요약 및 권고 조치 |
|---|---|---|---|
| **G-22** | Low | `quad-base/src/Ref/init.luau` | `Ref:Callback`/`WeakCallback`/`Uncallback` 머리에 `type(fn) ~= "function"` 표면 에러 가드 추가 |
| **G-15** | Medium | `quad-base/src/Slot/init.luau`, `quad-roblox/src/LifetimeHandle.luau` | `dispose(nil)` 및 `unbindLifetime(nil)` 머리에 `value == nil` 표면 에러 가드 추가 (Q31) |
| **G-17** | Medium | `quad-roblox/src/Reflection.luau` | `memberSet` 반환 함수 머리에 `if className == nil then return false end` 가드 추가 |
| **G-18** | Low | `quad-base/src/Bookkeeping.luau` | `getBlocker(ownerKey)` 머리에 `ownerKey == nil` 표면 에러 가드 추가 |
