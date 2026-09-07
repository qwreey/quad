# `quad` v2 사후 구현 심층 정적 분석 보고서 (Gemini Review Round 4)

> **[2026-09-07 메인 판정]** G-10~G-14 **전부 실존** → `H-440`~`H-444`로 반영(원장 `post-implementation-review-round3.md` §5), S-07~S-10 건전 판정은 정본과 일치. 이 파일은 외부 리뷰 원문으로 보존(옛 이름 post-implementation-gemini-review-round4-ignoreme.md — 사용자 허락으로 개명).

> **문서 상태**: 4차 순회(Round 4) 진행 중 기록 (다른 에이전트 작업 완료 후 인계용)  
> **검토 시점**: 2026-09-07 (마일스톤 M0~M11 구현 완료, 7순회 `H-420`~`H-430` 및 사용자 질의 회신 1차 반영 이후)  
> **검토 대상 코퍼스**: `quad-base`, `quad-roblox`, `quad-types`, `quad-error`, `scripts/`  
> **작성 원칙**:
> 1. 엔트리 문서 `CLAUDE.md`, `.claude/conventions.md`, `.claude/project-context.md`, `.claude/todos.md` 및 세부 설계 문서를 준수한다.
> 2. 선행 리뷰 원장(`post-implementation-review-round1.md` `H-344`~`H-430`, `Q1`~`Q21`, `post-implementation-review-round2.md` `G-01`~`G-09`, `S-01`~`S-06`)에서 이미 확정/기각된 사항은 중복 보고하지 않는다.
> 3. 무분별한 에러 가드 확장을 지양하고, 프레임워크의 기존 철학("하나의 무언가가 두 일을 하지 않는다", "내부 라인 blame 누출 방지")에 부합하는 실질적 계약 결함에 집중한다.
> 4. 의혹이 제기되었으나 정본 대조 결과 건전성(Soundness)이 입증된 항목은 False Positive 방지용으로 함께 기록한다.

---

## 1. 선행 리뷰 필터링 확인 (기보고/기각/확정 항목 제외 내역)

| 항목 | 기존 식별 번호 / 위치 | 기각 / 확정 사유 |
|---|---|---|
| `Tag("")` 빈 문자열 가드 누락 | `G-01`, `H-417` | 기반영 (`flattenInto` 및 `AttributeKey`에 빈 문자열 가드 추가) |
| `Claim(inst, desc)`의 `inst` 미검증 | `G-06`, `H-418` | 기반영 (`Claim` 머리에 `isInst` 게이트 추가) |
| `Dispatch.drive(inst, props)`의 `props` 비테이블 | `G-07`, `H-419` | 기반영 (`drive` 머리에 `type(props) ~= "table"` 게이트 추가) |
| `ContentId` 덤프 타입 매핑 오류 | `H-420` | 기반영 (`gen-d.py` 정규화 및 재생성) |
| `AttributeKey` 빈 문자열 및 스칼라 슈거 | `H-421` | 기반영 (`Attribute/init.luau` 사설 키 생성부 가드 추가) |
| `scripts/test.sh` 게이트 누락 | `H-422`, `H-423` | 기반영 (모듈 스코프 function 정규식 검사 및 `gen-d check` 추가) |
| `gen-d.py` 자유변수 `parent_of` 스코프 | `H-424` | 기반영 (`ancestors` 상위로 이동) |
| `Claim.luau` props 게이트 선행 | `H-425` | 기반영 (`_fired`/`nativeClaim` 이전 검증으로 이동) |
| `Ref/init.luau` `:Set` "normal" 코루틴 가드 | `H-426` | 기반영 (`running` 외에 `normal` 상태 nearest 처리) |
| `Bookkeeping.luau` 범위 절 허위 진단 | `H-427` | 기반영 (`at > N+1` 조건부 범위 절 및 C-6 불변식 추가) |
| `Animate` Compute의 nil/None 팔 누락 | `H-379`, §4 Q8 | 기보고 사용자 질의 대기 항목 |
| `Bookkeeping.setLength` mutate-then-throw | `H-413`, §4 Q18 | 기보고 사용자 질의 대기 항목 |

---

## 2. 신규 발견 결함 사항 (Round 4 Findings)

### [G-10] `OnChange("", fn)` 빈 문자열 프로퍼티 이름 가드 누락 및 엔진 에러 노출

- **위치**: `quad-roblox/src/Handlers/OnChange.luau:62-68` (`OnChange`), `quad-roblox/src/Handlers/OnChange.luau:89-95` (`process`)
- **심각도**: High / Peer to `H-417`, `H-421`
- **현상**:
  - `OnChange(name, fn)` 생성자는 `type(name) ~= "string"`만 검사하고, 빈 문자열(`name == ""`)에 대한 검증을 수행하지 않습니다:
    ```lua
    local function OnChange(name: string, fn: (any) -> ()): OnChangeDescriptor
        if type(name) ~= "string" then
            errNS.errorBeforeNearest("OnChange: property name must be a string", SURFACE)
        end
        if type(fn) ~= "function" then
            errNS.errorBeforeNearest(`OnChange("{name}"): callback must be a function`, SURFACE)
        end
        local d = table.freeze({ Name = name, Callback = fn })
        descriptors[d] = true
        return (d :: any) :: OnChangeDescriptor
    end
    ```
  - 만약 사용자가 `OnChange("", callback)`을 작성하여 `drive(inst, { OnChange("", callback) })`로 전달하면:
    1. [`OnChange.luau:89`](file:///code/Projects/quad/quad-roblox/src/Handlers/OnChange.luau#L89)에서 `dispatch.setEmpty(inst, k, inst)`가 먼저 실행되어 부기(Bookkeeping) 상에 빈 슬롯이 등록됩니다.
    2. 직후 93행의 `inst:GetPropertyChangedSignal(name):Connect(...)`가 호출될 때 Roblox 엔진이 `ArgumentException: The property name cannot be empty` 원시 엔진 예외를 던집니다.
    3. 이 예외는 `quad-error`의 스택 워커를 거치지 않으므로 **quad 내부 파일 라인(`quad-roblox/src/Handlers/OnChange.luau:93`)이 그대로 에러 blame에 노출**됩니다.
    4. 또한 `h.process` 중간에서 throw가 발생함에 따라 부기 슬롯과 NOOP 마커 정리가 비정상적인 상태로 남게 됩니다.
- **원인 분석 및 연관성**:
  - 7순회 `H-417`(`Tag("")`) 및 `H-421`(`AttributeKey("")`, `Attribute({ [""] = 5 })`)과 **완벽히 동일한 구조의 구멍**입니다.
  - Tag와 Attribute는 엔진 op 도달 전 빈 문자열 가드가 추가되었으나, 동일하게 `GetPropertyChangedSignal` 엔진 op에 도달하는 `OnChange`는 누락되었습니다.
- **권고안**:
  - `OnChange` 생성자 머리에 빈 문자열 차단 가드 추가:
    ```lua
    local function OnChange(name: string, fn: (any) -> ()): OnChangeDescriptor
        if type(name) ~= "string" or name == "" then
            errNS.errorBeforeNearest("OnChange: property name must be a non-empty string", SURFACE)
        end
        if type(fn) ~= "function" then
            errNS.errorBeforeNearest(`OnChange("{name}"): callback must be a function`, SURFACE)
        end
        ...
    ```

---

### [G-11] `Slot:List` / `reconcile` 비-테이블 및 `nil` 입력 시 Luau VM 런타임 크래시 (`#items`)

- **위치**: `quad-base/src/Slot/List.luau:949-966` (`reconcile`), `quad-base/src/Slot/List.luau:1041-1054` (`Slot_mt.List`)
- **심각도**: Medium / Blame hygiene & Defensive robustness
- **현상**:
  - `Slot:List(data, updateFn, keyFn?, opts?)`에서 `updateFn`의 함수 타입 검증(`type(updateFn) ~= "function"`)이 없습니다.
  - 또한 `reconcile(items)`의 950행:
    ```lua
    local function reconcile(items: any)
        local keys, seen = table.create(#items), {}
        for i, item in ipairs(items) do
    ```
    에서 `items`가 `nil`이거나 테이블이 아닌 경우(예: 반응형 `State`의 초기값이 `nil`이거나 `:Set(nil)`로 방출된 경우, 또는 무타입 환경에서 `Slot():List(nil, fn)` 호출 시), Luau VM이 `attempt to get length of a nil value` 원시 런타임 에러를 직접 발생시킵니다.
  - **계약 불일치**:
    - `keyFn`이 `nil`을 반환하거나 중복 키를 반환하는 경우는 959행에서 `Err.errorBefore("Slot:List — keyFn returned nil...")`로 안전하게 프레임워크 에러로 감싸서 사용자 줄을 blame합니다.
    - 반면 `items` 자체에 대한 타입 가드가 없어 `#items`의 VM 런타임 에러가 발생하고, 내부 파일 `quad-base/src/Slot/init.luau:950`이 사용자에게 노출됩니다.
- **권고안**:
  - `Slot_mt.List` 머리에서 진입점 인자 검증(`type(updateFn) ~= "function"`) 추가.
  - `reconcile(items)` 머리에서 `type(items) ~= "table"`인 경우 `Err.errorBefore`를 던지거나, `items == nil`인 경우 빈 테이블 `{}`로 간주하여 기존 마운트된 요소들을 정상적으로 소멸/언마운트(`settle`)하도록 처리.

---

### [G-12] `Dispatch.drive(inst, props)`의 `inst == nil` 검증 부재 및 `Relate.luau` VM 에러 노출

- **위치**: `quad-base/src/Dispatch/init.luau:306-312` (`drive`), `quad-base/src/Relate.luau:22-33` (`getBucket`)
- **심각도**: Low / Blame hygiene
- **현상**:
  - 선행 `H-419`에서는 `props`의 비테이블 입력(`type(flattened) ~= "table"`)을 가드하였고, `H-418`에서는 `Claim(inst, desc)`의 `inst` 검증을 추가하였습니다.
  - 그러나 공개 디스패치 진입점인 `Dispatch.drive(inst, props)`는 첫째 인자 `inst`가 `nil`인지 검증하지 않습니다.
  - `Dispatch.drive(nil, props)`가 호출되면(배열 파트가 있는 경우):
    1. 327행: `bookkeeping.getBlocker(inst)` 호출
    2. `Bookkeeping.luau:107`: `bookkeeping:GetWeak(inst, "bk")` 호출
    3. `Relate.luau:23`: `self.buckets[inst]` 실행
    4. Luau에서 `t[nil]` 인덱싱은 원시 VM 에러인 `table index is nil`을 발생시킵니다.
    5. 결과적으로 사용자 호출 위치가 아닌 `quad-base/src/Relate.luau:23` 내부 줄이 blame에 노출됩니다.
- **권고안**:
  - `Dispatch.drive` 머리에 `if inst == nil then Err.errorBefore("Dispatch.drive: inst must not be nil", SURFACE) end` 가드 추가.

---

### [G-13] `Store` 빈 문자열 키 `""` 허용 및 `Attribute(store)`를 통한 `H-421` 우회 엔진 크래시

- **위치**: 
  - `quad-base/src/Store.luau:50-59` (`checkKey`)
  - `quad-base/src/Attribute/init.luau:76-82` (`flattenArg` - `isStore` 분기)
- **심각도**: High / `H-421` (`AttributeKey("")`)의 자매 결함
- **현상**:
  1. `Store.luau:50`의 `checkKey(name, what)`는 `type(name) ~= "string"` 및 `RESERVED[name]`만 검사하고, **빈 문자열(`name == ""`) 검증이 누락**되어 있습니다:
     ```lua
     local function checkKey(name: any, what: string)
         if type(name) ~= "string" then
             Err.errorBeforeNearest(`Store: {what} must be a string (got {typeof(name)})`, SURFACE)
         end
         if RESERVED[name] then
             Err.errorBeforeNearest(`Store: "{name}" is a reserved store key`, SURFACE)
         end
     end
     ```
     이에 따라 `Store({ [""] = Source(1) })` 및 `store:Of("")`가 검증을 통과하여 생성됩니다.
  2. `Attribute/init.luau:104`에서는 7순회 `H-421`을 반영하여 일반 테이블 키에 대해 `rawName == ""`를 명시적으로 차단하였습니다:
     ```lua
     if type(rawName) ~= "string" or rawName == "" then -- `H-421`: `""` reached setAttribute at dispatch depth
         Err.errorBeforeNearest(`{ctx}: plain-table keys must be non-empty strings`, SURFACE)
     end
     ```
  3. **그러나 바로 위의 `if isStore(arg) then` 분기(`Attribute/init.luau:76`)에는 `name == ""` 검사가 없습니다**:
     ```lua
     if isStore(arg) then
         for _, name in ipairs(arg:Names()) do
             if not overwrite and map[name] ~= nil then
                 Err.errorBeforeNearest(`{ctx}: attribute name "{name}" appears more than once`, SURFACE)
             end
             map[name] = arg[name]
         end
     ```
  4. 사용자가 `Attribute(store)`를 인스턴스에 마운트(`drive(inst, { Attribute(store) })`)하면:
     - `AttributeGroupFallbackHandler`가 `groupKey(v, "")` -> `newUncachedKey("")`를 생성합니다.
     - `AttributeKeyFallbackHandler.process`에서 `nameClaims:SetStrong(inst, "", k)`를 커밋한 직후, `EngineOps.luau:116`의 `inst:SetAttribute("", realv)`를 호출합니다.
     - Roblox 엔진이 `ArgumentException: attribute name cannot be empty` 원시 예외를 발생시키며 **디스패치 심도에서 즉시 크래시**합니다.
     - 그 결과 `h.process` 중간 예외로 인해 `Dispatch`의 `NOOP` 마커가 영구 고착되고 `nameClaims`에 빈 문자열 키 점유가 해제되지 않은 채 누수됩니다.
- **원인 분석 및 연관성**:
  - `Attribute/init.luau`에서 `H-421`을 처리할 때 일반 테이블 리터럴만 방어하고 `Store` 언랩 경로를 간과한 비대칭입니다.
  - 또한 `Store` 자체에서도 빈 문자열 식별자를 허용할 이유가 없으므로 두 계층 모두에 방어가 필요합니다.
- **권고안**:
  1. `Store.luau:50`의 `checkKey`에 `name == ""` 차단 추가:
     ```lua
     if type(name) ~= "string" or name == "" then
         Err.errorBeforeNearest(`Store: {what} must be a non-empty string (got {typeof(name)})`, SURFACE)
     end
     ```
  2. `Attribute/init.luau:77`의 `isStore` 순회 내에 방어 가드 추가:
     ```lua
     for _, name in ipairs(arg:Names()) do
         if name == "" then
             Err.errorBeforeNearest(`{ctx}: attribute name cannot be empty`, SURFACE)
         end
         ...
     ```

---

### [G-14] `LifetimeHandle`의 `unbindLifetime(nil)` / `canExecute(nil)` 등 호출 시 `Relate.luau:23` VM 크래시 및 계약 불일치

- **위치**:
  - `quad-roblox/src/LifetimeHandle.luau:75-86` (`isBoundAlive`), `143-155` (`unbindLifetime`), `96-104` (`bindLifetime`)
  - `quad-base/test/mock.luau:538-549`, `559-570`, `604-617`
- **심각도**: Medium / Blame hygiene & 계약 불일치
- **현상**:
  1. `LifetimeHandle.luau:11` 헤더 계약에는 명확히 다음과 같이 규정되어 있습니다:
     > `unbindLifetime(value) -- early release of one value; no-op if unbound`
  2. 하지만 `unbindLifetime(nil)`을 호출하면:
     ```lua
     local gchold = BindData:GetWeak(value, "gchold")
     ```
     에서 `Relate.luau:23`의 `self.buckets[inst]` (`inst == nil`)을 직접 평가하여 **Luau VM 원시 에러 `table index is nil`**이 터집니다.
  3. 동일하게:
     - `canExecute(nil)` 및 `canBound(nil)` 호출 시 내부 `isBoundAlive(nil)`가 `BindData:GetWeak(nil, "gcconn")`을 호출하여 `Relate.luau:23 table index is nil` 크래시를 냅니다.
     - `bindLifetime(nil, v)` 호출 시, 98행의 의도된 프레임워크 에러(`bindLifetime: Instance is not claimed by quad...`)에 도달하기 전인 97행 `InstData:GetWeak(nil, "gchold")`에서 `table index is nil`로 죽어버려 깔끔한 에러 메시지가 무색해집니다.
- **권고안**:
  1. `quad-roblox/src/LifetimeHandle.luau` 및 `quad-base/test/mock.luau`:
     - `isBoundAlive(value)` 머리에 `if value == nil then return false end` 추가 (`canExecute(nil)`은 `false`, `canBound(nil)`은 `true` 반환 보장).
     - `unbindLifetime(value)` 머리에 `if value == nil then return end` 추가 (헤더의 "no-op if unbound" 계약 충족).
     - `bindLifetime(inst, value)` 머리에 `if inst == nil then Err.errorBefore("bindLifetime: Instance is not claimed by quad (create it via quad, or Claim it first)", SURFACE) end` 게이트 배치.
  2. (권장 방어책) `quad-base/src/Relate.luau:22`의 `getBucket(self, inst)`에 `if inst == nil then return nil end`를 추가하여, 임의의 `GetWeak(nil, ...)` / `GetStrong(nil, ...)` 조회가 안전하게 `nil`을 반환하도록 보호.

---

## 3. 핵심 불변식의 건전성 증명 (Soundness Verification)

코드 분석 과정에서 잠재적 결함 또는 비대칭으로 의심되었으나, 정본(`.claude/base/*-plan.md`) 및 아키텍처 대조를 통해 **의도된 설계이며 완전히 건전함(Sound)**이 확인된 항목들입니다:

### [S-07] `Slot/Tree.luau`의 `destroySlotTree`에서 `Owned = false` 슬롯의 `_destroyed = true` 미설정과 생존 불변식
- **의혹**: `slot._owned == false`인 Slot에 대해 `destroySlotTree`가 호출될 때, `unmountSlotTree(slot)` 후 조기 리턴하여 `slot._destroyed = true`가 설정되지 않는다. 이것이 누락된 버그인가?
- **건전성 증명**:
  1. 설계 정본 `.claude/base/slot-plan.md` 560-564행에 명확히 규정되어 있습니다:
     > *"Owned = false인 Slot은 _destroyed가 서지 않는다 — destroySlotTree가 그 분기에서 unmountSlotTree로 빠져 꼬리에 안 닿는다. 그 Slot은 요소를 만든 적이 없으니 좀비가 없고 재사용도 그대로 가능하다 — 사용자 확정 ('owned = false 은 state<Frame> -> slot(single) 형태가 구현되는 것이라 맞아'). '파괴 대신 언마운트만'이라는 그 분기의 뜻 그대로."*
  2. 또한 `spec.slot.luau:297`의 테스트에서도 부모 슬롯에서 제거된 `Owned = false` 자식 슬롯이 파괴되지 않고 살아남아 다른 슬롯에 정상적으로 재마운트되는 동작을 핵심 계약으로 검증하고 있습니다.
  3. 따라서 `_destroyed = true`가 세워지지 않는 것은 결함이 아니라, 해당 슬롯의 생존 및 재사용을 보장하기 위한 의도된 설계입니다.

### [S-08] `Modifier.Overridden()` 0인자 호출 에러 vs `Attribute.Overridden()` 빈 컨테이너 반환 비대칭
- **의혹**: `Attribute.Overridden()`은 0인자 호출 시 빈 `Attribute({})`를 반환하는 반면, `Modifier.Overridden()`은 0인자 호출 시 `"expects at least one Modifier"` 에러를 던집니다.
- **건전성 증명**:
  1. 설계 정본 `.claude/base/modifier-plan.md` 265-266행:
     > *"단 0인자 Modifier()는 빈 값이고 Overridden()은 error라 동치는 인자가 하나 이상일 때만."*
  2. `Modifier()` 생성자는 빈 Modifier를 생성하는 진입점 역할을 담당하지만, `Overridden`은 둘 이상의 이미 존재하는 인스턴스를 병합하는 특수 연산이므로 0인자 호출을 금지하는 것이 원래 확정된 스펙입니다.

### [S-09] 일반 중첩 Slot(`isSlot`)의 `occupantOf`와 `prepareElements`의 중복 마운트 방어 무결성
- **의혹**: `occupantOf`가 일반 Slot에 대해서는 내부 요소를 재귀 검사하지 않고 Slot 객체 자신만 반환하는데, 중첩 슬롯 내 자식 요소들의 중복 마운트가 완전히 방어되는가?
- **건전성 증명**:
  1. 일반 중첩 Slot `s`에 요소 `e`가 추가되는 모든 경로(`rawAdd`)는 즉시 `claimOwner(e, s)`를 동기적으로 실행합니다.
  2. 부모 슬롯이 아직 마운트(materialize)되지 않은 상태이더라도 `claimOwner`는 즉시 커밋되어 `elementOwner`에 등록됩니다.
  3. 따라서 다른 슬롯에 동일한 요소 `e`를 추가하려 할 때 `prepareElements`의 `elementOwner:GetWeak(occupant, OWNER) ~= nil`에서 즉시 포착되어 `"already mounted"`로 차단됩니다.
  4. `occupantOf`가 `element._wrapped:Get()`을 별도로 수행하는 유일한 이유는 `State<Instance>` 래퍼의 경우 마운트 시점까지 `claimOwner`가 유예되기 때문이며, 일반 슬롯과의 차이가 완전히 건전하게 격리되어 있음을 확인했습니다.

### [S-10] `InstanceShorthand`의 `UIPadding`과 `UIPaddingOffset`의 `_quad_padding` 자식 공유 및 소멸 동작의 건전성

- **위치**: `quad-roblox/src/Handlers/InstanceShorthand.luau:63-64, 88-101`
- **의혹**:
  - `UIPadding`과 `UIPaddingOffset`이 동일한 자식 이름 `_quad_padding`을 공유합니다. 만약 두 속성을 함께 사용하다가 한쪽에 `None`(= `nil`)을 넣으면 `destroyManagedChild`가 호출되어 자식 인스턴스를 파괴하므로, 다른 한쪽의 설정까지 날아가는 부작용이 발생하는 것은 아닌가?
- **건전성 증명**:
  1. 설계 정본 `.claude/base/ui-shorthand-plan.md:64-66` 및 `H-335`에 이미 명확히 의도된 제약으로 문서화되어 있습니다:
     > *"UIPadding and UIPaddingOffset SHARE the managed _quad_padding child (v1 did too — class.lua PaddingAll/PaddingAllOffset): both delegate to the same four (child, PaddingX) chains at index 1, so the last written key wins per property, and nil on either key destroys the shared child (H-335)."*
  2. v1 시절부터 이어져 온 단일 `UIPadding` 컴포넌트 공유 모델이며, 두 숏핸드는 상호 보완적이 아니라 어느 한쪽 방식을 선택해 쓰는 편의 키이므로 공유 자식 소멸 동작은 확정된 스펙이자 건전한 구현입니다.

---

## 4. 메인 에이전트 인계 종합 권고사항 (Handover Summary)

| 항목 번호 | 심각도 | 핵심 내용 | 권고 조치 파일 |
|---|---|---|---|
| **[G-10]** | High | `OnChange("", fn)` 빈 문자열 프로퍼티 인자 가드 누락 및 엔진 `ArgumentException` 누출 | `quad-roblox/src/Handlers/OnChange.luau` |
| **[G-11]** | Medium | `Slot:List` / `reconcile`의 `nil`/비테이블 `#items` VM 크래시 | `quad-base/src/Slot/List.luau` |
| **[G-12]** | Low | `Dispatch.drive(nil, props)`의 `Relate.luau:23` `self.buckets[nil]` VM 크래시 | `quad-base/src/Dispatch/init.luau` |
| **[G-13]** | High | `Store` 빈 문자열 키 `""` 허용 및 `Attribute(store)`의 `H-421` 우회 엔진 크래시 | `quad-base/src/Store.luau`, `quad-base/src/Attribute/init.luau` |
| **[G-14]** | Medium | `LifetimeHandle`의 `unbindLifetime(nil)` / `canExecute(nil)` 등 호출 시 `table index is nil` 크래시 | `quad-roblox/src/LifetimeHandle.luau`, `quad-base/test/mock.luau`, `quad-base/src/Relate.luau` |
| **[S-07]~[S-10]** | Sound | `Owned=false` 슬롯 수명, `Overridden` 0인자 비대칭, 중첩 Slot 소유권, `UIPadding` 숏핸드 공유 자식 동작의 정본 부합성 확인 (False Positive 방지) | 수정 불요 (현행 유지) |
