# `quad` v2 사후 구현 종합 코드 리뷰 보고서 (Gemini Review)

> **[2026-09-07 메인 판정]** G-01/G-06/G-07 실존 → `H-417`~`H-419`로 반영(원장 `post-implementation-review-round1.md` §13), G-02/G-04/G-05/G-08·S-01~S-06 확인 기록, G-03/G-09는 기존 Q18/Q3 ⑨에 논거 추가. 이 파일은 외부 리뷰 원문으로 보존.

> **문서 상태**: 2차 순회(Round 2) 완료  
> **검토 시점**: 2026-09-07 (마일스톤 M0~M11 구현 완료, 핸드오버 전체 코드 리뷰 0~6순회 `H-344`~`H-416` 및 사용자 문항 Q1~Q20 수립 이후)  
> **검토 대상 코퍼스**: `quad-base`, `quad-roblox`, `quad-types`, `quad-error`, `scripts/`  
> **작성 기준 및 원칙**:
> 1. 엔트리 문서 `CLAUDE.md`, `.claude/conventions.md`, `.claude/project-context.md`, `.claude/todos.md` 및 세부 설계 문서를 준수한다.
> 2. 선행 리뷰 원장(`.claude/qa-request/post-implementation-review-round1.md`)에서 이미 보고되었거나, 의도적으로 기각/확인/UB로 확정된 사항은 **새로운 결함으로 중복 보고하지 않는다**.
> 3. 프레임워크의 기존 설계 철학("하나의 무언가가 두 일을 하지 않는다", "드문 오용에 복잡한 구조를 쓰지 않는다", "핫패스에 불필요한 비용을 얹지 않는다")을 존중하며 실질적 런타임/계약 결함에 집중한다.
> 4. 의혹이 제기될 수 있으나 코드 분석 결과 건전성(Soundness)이 입증된 핵심 불변식은 **False Positive 반증**으로 명확히 기록하여 향후 불필요한 재의혹을 방지한다.

---

## 1. 검토 개요 및 감사 범위

본 검토는 Roblox 엔진을 위한 DOMless 반응형 UI 렌더러 `quad` v2의 전체 마일스톤 구현 및 6차에 걸친 핸드오버 코드 리뷰 이후, 서로 다른 시각과 심층 분석 앵글을 통해 2회(Round 1 & Round 2)에 걸쳐 수행되었습니다.

### 검토 대상 영역
1. **반응형 코어 (`quad-base/src/`)**:
   - `State.luau`, `Source.luau`, `EpochMap.luau`, `Observer.luau`, `Effect.luau`, `Blocker.luau`
   - 반응형 파동 전파, 에포크 기반 동등성 판정, lazy `Get` 루프 최신성, 생명주기 바인딩
2. **슬롯 및 부기 (`quad-base/src/Slot.luau`, `Bookkeeping.luau`)**:
   - 동적 자식 리스트 CRUD (`Add`, `Remove`, `Replace`, `Extract`, `Splice`, `Move`, `Swap`)
   - 접두사 합(Prefix sum) 오프셋 캐시, 커서 되감기(rewind) 및 무효화, 배치 블로커, 소유권 관리
3. **디스패치 엔진 (`quad-base/src/Dispatch/`)**:
   - `init.luau`, `StoreBind.luau`, `None.luau`, `Modifier.luau`, `Ref.luau`, `Slot.luau`
   - 하강 diff 재디스패치(descending-diff), 우선순위 밴드 스캔, 체인 관리, retractor 수명주기
4. **값 객체 및 프리미티브**:
   - `Store.luau`, `Tag.luau`, `Attribute.luau`, `AttributeKey.luau`, `Ref.luau`, `Modifier.luau`, `Tween.luau`, `Claim.luau`
5. **Roblox 백엔드 (`quad-roblox/src/`)**:
   - `RobloxFactory.luau`, `EngineOps.luau`, `LifetimeHandle.luau`, `Animate.luau`, `D/init.luau`
   - `Handlers/` (`Property.luau`, `Event.luau`, `OnChange.luau`, `InstanceChild.luau`, `InstanceShorthand.luau`)
6. **인프라 및 진단 (`quad-error/`, `scripts/`)**:
   - `quad-error/src/init.luau`: 레이어 태그 기반 콜스택 워커 (`errorBefore`, `errorBeforeNearest`)
   - `scripts/gen-d.py`, `scripts/test.sh`: 타입 생성 파이프라인 및 테스트 게이트

---

## 2. 선행 리뷰 필터링 확인 (기보고/기각 항목 제외 내역)

사용자 지침에 따라 선행 리뷰 원장(`post-implementation-review-round1.md`) 및 기존 세션 로그에서 이미 확정된 아래 항목들은 본 보고서의 신규 결함 목록에서 제외했습니다:

| 항목 | 기존 식별 번호 / 위치 | 기각 / 확정 사유 |
|---|---|---|
| `Ref:Wait(thread)`에 죽은 코루틴 전달 | `H-170`, `H-339`, `H-411` | 기결정 UB (사용자 책임, `H-411`에서 `running`만 가드) |
| `Tween` 자연 완료 후에도 슬롯 유지 | §5 R3, `H-352` | 기각 (의도된 계약 — Completed 이벤트 미구독 확정) |
| `Effect` `fn`의 비함수 cleanup 반환 | §2 구A1, `H-185` | 기각 (문서화된 계약 — no-pcall 원칙, 런타임 가드 미설치) |
| `InstanceShorthand`의 `numberOnly` 필드 | `H-402`, §4 Q17 | 기보고 사용자 질의 대기 항목 |
| `Animate` Compute의 nil/None 팔 누락 | `H-379`, §4 Q8 | 기보고 사용자 질의 대기 항목 |
| `Bookkeeping.setLength` mutate-then-throw | `H-413`, §4 Q18 | 기보고 사용자 질의 대기 항목 |
| `native*` 조합 폴백의 부재 | `H-376`, §4 Q6 | 기보고 사용자 질의 대기 항목 |
| `Slot:Clear` / `ExtractAll` 루프 효율 | `H-356` ①, §4 Q3 ⑨ | 기보고 사용자 판단 대기 항목 (관측된 병목 아님) |
| `OnChange` 쓰기 전용 타입 제외로 인한 제한 | `H-414`, §4 Q19 | 기보고 사용자 질의 대기 항목 |
| `Destroy` 후 Lua 참조 유지 시 `bindLifetime` | `H-415`, §4 Q20 | 기보고 사용자 질의 대기 항목 |

---

## 3. 1차 순회 발견 사항 (Round 1 Findings)

### [G-01] `Tag.luau` 빈 문자열 `""` 입력 시 디스패치 깊이의 mutate-then-throw 위험

- **위치**: `quad-base/src/Tag.luau:48-84` (`flattenInto`), `quad-roblox/src/EngineOps.luau:101-106` (`addTag`)
- **심각도**: Low / Edge-case
- **현상**:
  - `Tag("")`, `tag:Added("")`, 또는 `Tag({"valid", ""})`와 같이 빈 문자열 `""`이 포함된 태그 값이 생성/전달될 때, `flattenInto`는 `type(nameOrList) == "string"`만 검사하므로 이를 유효한 태그로 통과시킵니다.
  - 이 태그가 인스턴스에 마운트되어 디스패치(`TagFallbackHandler.process`)를 거치면:
    1. `NoneModule.registerEmptySlot`이 호출되어 부기 상 `offsetSource`와 `length = 0`이 먼저 커밋됩니다.
    2. `tagNameMap`에 `holders[k] = true`가 기록됩니다.
    3. `module.addTag(inst, added)`가 실행됩니다.
    4. Roblox 엔진의 `CollectionService:AddTag(inst, "")`은 빈 문자열에 대해 엔진 예외(ArgumentException: tag name cannot be empty)를 던집니다.
  - 결과적으로 `h.process` 중간에서 예외가 발생하여 `H-103` 주의사항에 따라 `chains`에 등록 중이던 NOOP 마커가 영구히 남고 retractor가 반환되지 못합니다.
- **원인 분석**:
  - `Tag.luau`의 `flattenInto`가 타입은 엄격하게 검증하지만(`isPlainBranded`, 메타테이블 여부, 해시 키, nil 구멍 등), 문자열의 도메인(비어있지 않은 문자열 `name ~= ""`)을 검증하지 않습니다.
- **권고안**:
  - `Tag.luau`의 `flattenInto`에서 빈 문자열 검사를 추가하는 방안:
    ```lua
    -- flattenInto 내 문자열 분기:
    elseif type(nameOrList) == "string" then
        if nameOrList == "" then
            Err.errorBeforeNearest("Tag: tag name cannot be an empty string", SURFACE)
        end
        target[nameOrList] = true
    ```
  - 생성 시점(`Tag(...)`/`:Added(...)`)에서 한 줄 비교로 조기 차단할 수 있으므로 surface 레벨 방어가 비용 대비 효과적입니다.

---

### [G-02] `Slot.luau` `prepareElements`와 `occupantOf`의 검증 경계 분석

- **위치**: `quad-base/src/Slot.luau:740-768` (`occupantOf`, `prepareElements`)
- **심각도**: Informational / Architecture Analysis
- **현상 및 분석**:
  - `occupantOf(element)`는 오직 State 래퍼 슬롯(`element._wrapped ~= nil`)에 대해서만 내부의 현재 값(`element._wrapped:Get()`)을 꺼내어 검사하고, 일반 사용자 생성 Slot(`isSlot(element)`이고 `_wrapped == nil`)에 대해서는 Slot 객체 자신(`element`)만을 occupant로 반환합니다.
  - **분석 결과 (정상 작동 확인 및 경계 조건)**:
    1. Slot에 요소가 추가되는 모든 경로(`rawAdd`)는 즉시 `claimOwner(element, self)`를 호출합니다.
    2. 따라서 중첩 Slot A에 `inst1`이 이미 들어있다면, 그 순간 `elementOwner:SetWeak(inst1, OWNER, A)`가 설정되어 있습니다.
    3. 이후 부모 Slot이나 다른 Slot에 `inst1`을 추가하려 하면, `prepareElements` 761행의 `elementOwner:GetWeak(occupant, OWNER) ~= nil` 검사에 즉시 걸려 `"this element is already mounted"`로 조기 차단됩니다.
    4. 반면 `State<Instance>` 래퍼는 마운트 시점까지 `claimOwner`가 불리지 않으므로 `occupantOf`가 `element._wrapped:Get()`을 통해 unmaterialized 상태의 동일 점유자 충돌을 방어하는 것입니다.
  - **결론**: `occupantOf`의 현재 구현은 의도된 것이며, 일반 중첩 Slot과 State 래퍼 Slot 간의 소유권 등록 타이밍 차이를 정확히 반영하고 있습니다. (False Positive 반증)

---

### [G-03] `Bookkeeping.luau` `setLength` State 분기 예외 안전성 메커니즘 (Q18 심층 분석)

- **위치**: `quad-base/src/Bookkeeping.luau:280-311` (`setLength`)
- **심각도**: Medium (선행 리뷰 Q18의 정밀 검증)
- **상세 분석**:
  - `setLength`는 다음 순서로 실행됩니다:
    1. 이전 옵저버 해제: `bk.observers[i] = nil` 및 `unbindLifetime(oldObserver)`
    2. 상태 쓰기: `bk.lengthList[i] = len`, `bk.N`, `bk.indexOfElement`, 커서 무효화
    3. `Brand.isState(len)` 분기:
       - `local observer = len:Observer(...)` 생성 (이때 registration fire 발생!)
       - `module.bindLifetime(anchor, observer)` 호출
       - `bk.observers[i] = observer` 저장
  - **위험 시나리오**:
    - `len:Observer(cb)` 생성 시 즉시 실행되는 콜백 내부에서 사용자 코드가 에러를 발생시키거나,
    - 전달된 `anchor`가 claim되지 않은 Instance여서 `bindLifetime`이 throw하는 경우(`H-290`),
    - 부기는 이미 새 State `len`으로 덮어써졌으나 `observers[i]`는 저장되지 못한 채 영구히 `nil`로 남습니다.
    - 이후 해당 State `len`이 값을 변경(`:Set`)하더라도 옵저버가 연결되어 있지 않으므로 오프셋 재계산(`gatedRecompute`)이 트리거되지 않아 부기 불일치가 고착됩니다.
  - **처방 (Q18 연계 권고)**:
    - 선행 리뷰 Q18의 (a)안(사전 검증: `canBound` 및 `anchor` 유효성 확인 후 옵저버 설치)을 적용하면 `bindLifetime` 단계의 실패를 원천 차단할 수 있습니다.

---

### [G-04] `Property.luau`의 `Override = "Finish"`와 트윈 재시작 타이밍

- **위치**: `quad-roblox/src/Handlers/Property.luau:135-156`
- **심각도**: Low / Engine-dependent Behavior
- **현상 및 분석**:
  - 6순회 `H-406`을 통해 `prev.Tween:Cancel()` 이전에 `TweenService:Create`를 먼저 호출하도록 변경되었습니다.
  - `TweenService:Create`가 호출되는 시점에는 아직 `inst[k] = prev.Value` 스냅이 실행되지 않은 상태이지만, Roblox 엔진의 `TweenBase:Play()`는 **`Play()`가 호출되는 순간의 `inst[k]` 현재 값**을 트윈 보간의 시작점으로 사용하므로 정상적으로 `prev.Value`에서 `v.Value`로 트윈이 시작됩니다.
  - CLI Mock 환경에서는 완벽히 동작하며, 엔진의 미세한 버전에 따라 `Create` 시점 프로퍼티 값을 캐시하는지 Studio 실측 항목으로 유지하는 것이 유익합니다.

---

### [G-05] `D.New(className)` 팩토리 파이프라인에서 `drive` 실패 시 미마운트 Instance 거동

- **위치**: `quad-roblox/src/D/init.luau` (생성된 `New` 함수, `scripts/gen-d.py:584-592`)
- **심각도**: Low / Normal GC Path
- **현상 분석**:
  - `New(className)(props)`에서 `drive` 도중 throw가 발생하면, 생성된 `inst`는 반환되지 않고 `Parent`에도 붙지 않은 고아 상태가 됩니다.
  - `nativeClaim`으로 걸려있던 `gcconn`은 `inst`에 대한 강참조가 사라지면 Roblox GC에 의해 정상 수거되므로 메모리 누수 없이 안전함을 확인했습니다.

---

## 4. 2차 순회 신규 발견 및 심층 분석 (Round 2 Findings)

### [G-06] `Claim.luau`: 최상위 `Claim(inst, desc)`의 `inst` 검증 부재로 인한 내부 줄 blame 노출

- **위치**: `quad-base/src/Claim.luau:98-104` (`Claim`), `quad-roblox/src/LifetimeHandle.luau:49-72` (`nativeClaim`)
- **심각도**: Medium / Error-blame contract violation
- **현상**:
  - `Claim(inst, desc)`는 둘째 인자 `desc`에 대해서는 `Brand.isMapperDescriptor(desc)`로 철저히 검증하지만, 첫째 인자 `inst`에 대해서는 `nil` 또는 타입 검증을 전혀 수행하지 않습니다:
    ```lua
    local function Claim(inst: any, desc: any): any
        if not Brand.isMapperDescriptor(desc) then
            Err.errorBefore("Claim: second argument must be a D.Mapper descriptor", SURFACE)
        end
        resolve(inst, desc)
        return inst
    end
    ```
  - 만약 사용자가 `Claim(nil, desc)` 또는 비-인스턴스 값을 넘긴 경우, `resolve` 내부의 80행 `module.nativeClaim(inst)`로 흘러갑니다.
  - 실 백엔드 `LifetimeHandle.luau`의 66행은 `inst:GetPropertyChangedSignal("ClassName"):Connect(...)`를 호출합니다.
  - 이로 인해 `attempt to index nil with 'GetPropertyChangedSignal'`이라는 원시 Luau VM 런타임 에러가 발생합니다.
  - **계약 위반**: 이 에러는 `errorBefore`를 거치지 않은 C/VM 에러이므로, `quad-error`의 스택 워커가 동작하지 않고 **quad 내부 파일(`quad-roblox/src/LifetimeHandle.luau:66`)이 그대로 blame에 노출**됩니다.
- **원인 분석**:
  - `Slot.luau`의 `wrapElement`는 `if not isInst(v) then raise(...) end`로 주입된 판정 술어를 통해 검증하는 반면, `Claim.luau`는 `inst` 인자에 대한 기본 검증을 생략했습니다.
- **권고안**:
  - `Claim.luau`의 `Claim` 함수 머리에 첫째 인자 검증을 추가:
    ```lua
    local function Claim(inst: any, desc: any): any
        if inst == nil or (module.isInst and not module.isInst(inst)) then
            Err.errorBefore("Claim: first argument must be a valid Instance", SURFACE)
        end
        if not Brand.isMapperDescriptor(desc) then
            Err.errorBefore("Claim: second argument must be a D.Mapper descriptor", SURFACE)
        end
        resolve(inst, desc)
        return inst
    end
    ```

---

### [G-07] `Dispatch.drive(inst, props)` 및 `D.New(className)(props)`에서 `props` 비테이블 입력 시의 blame 위치

- **위치**: `quad-base/src/Dispatch/init.luau:306-319` (`drive`), `quad-base/src/Modifier.luau:408` (`flatten`)
- **심각도**: Low / Blame hygiene
- **현상**:
  - `D.New(className)(props)` 또는 `Dispatch.drive(inst, props)`에 잘못된 타입(예: `nil`이나 문자열)이 전달될 때:
  - `drive` 진입부의 319행 `flatten(flattened)`가 즉시 호출되고, `Modifier.luau` 408행의 `local n = #input`에서 `attempt to get length of a nil value` (VM 런타임 에러)가 발생합니다.
  - 대조군인 `Store(defaults)`, `Tween(opts)`, `Animate(info)` 등은 모두 생성자 첫머리에서 `type(x) ~= "table"`을 `Err.errorBeforeNearest`로 검증하여 사용자 코드 줄을 명확히 지목합니다.
- **분석 및 권고**:
  - strict Luau에서는 정적 타입이 `Props` 테이블을 강제하므로 타입 체커가 1차 방어합니다.
  - 그러나 동적/무타입 환경에서의 완전한 에러 blame 격리를 위해, `drive` 또는 `flatten` 첫머리에 `type(flattened) ~= "table"`에 대한 `errorBefore` 검증을 1줄 추가하면 일관성이 향상됩니다.

---

### [G-08] `Bookkeeping.luau` `setOffsetSource`의 동기 `:Set` 호출 시 상태 관측 창 (Observation Window)

- **위치**: `quad-base/src/Bookkeeping.luau:330-335`
- **심각도**: Low / Reentrancy observation
- **현상 및 분석**:
  - `setOffsetSource`는 `bk.sourceList[i] = source`를 먼저 쓴 후 `source:Set(offset)`을 동기 호출합니다:
    ```lua
    local offset = getOffsetAt(ownerKey, i)
    local current = source:Get()
    bk.sourceList[i] = source
    if current ~= offset then
        source:Set(offset) -- ← 하류 Observer 동기 발화 가능
    end
    ```
  - `source:Set`은 `Source.luau`의 `emitDown`을 트리거하므로, 이 `source`에 연결된 사용자 옵저버/컴퓨트가 동기적으로 실행됩니다.
  - 이때 만약 상위 호출자가 배치 등록 도중이거나(Blocker가 켜진 상태), 아직 다른 슬롯들의 등록이 완료되지 않은 상태라면, 사용자 콜백은 부분적으로만 갱신된 부기 상태를 읽을 수 있습니다.
  - **평가**: 다행히 `H-392`를 통해 `sourceList[i]` 쓰기 순서가 교정되어 부기 동결 버그는 차단되었으며, 배치 도중의 동기 발화는 quad의 standing rule인 "재진입 family는 최신 상태를 보장하지 않는다(UB)" 범위에 부합합니다.

---

### [G-09] `Slot.luau` `Clear` 및 `ExtractAll`의 개별 언마운트와 중간 상태 관측 가능성

- **위치**: `quad-base/src/Slot.luau:854-869` (`Clear`, `ExtractAll`)
- **심각도**: Informational / Architecture note (Q3 ⑨ 연계)
- **현상 및 분석**:
  - `Slot_mt.Clear`는 `#self._elements`부터 1까지 역순으로 `rawRemove(self, i)`를 반복 호출합니다.
  - 각 `rawRemove` 호출마다 `unbindObserverAt` -> `releaseOwner` -> `nativeRemove` -> `vacate` -> `spliceArraysDown` -> `maybeRecompute`가 개별적으로 실행됩니다.
  - 선행 리뷰 `H-356` / Q3 ⑨에서 지적된 "성능(N회 recompute)" 문제 외에도, **상태 일관성 측면**에서 요소가 하나씩 지워질 때마다 `Slot.Length`와 `Slot.Offset`이 점진적으로 줄어드는 파동이 발생합니다.
  - 만약 슬롯의 길이나 오프셋을 구독하고 있는 사용자 옵저버가 있다면, `Clear`가 완전히 끝나기 전의 중간 크기(N-1, N-2, ...)를 매 단계 관측하게 됩니다.
  - **권고**: 단일 배치 블로커로 감싸서(`Blocker:On() ... Blocker:OffWithoutEmit()`) 1회의 recompute로 접는 최적화가 적용되면, 성능 개선뿐만 아니라 중간 상태 노출 방지(원자적 클리어) 측면에서도 이점을 얻을 수 있습니다.

---

## 5. 핵심 불변식의 건전성 증명 (Soundness Verification)

코드 분석 과정에서 잠재적 결함으로 의심되었으나, 면밀한 검증을 통해 **설계상 완전히 건전함(Sound)**이 입증된 핵심 불변식들을 기록합니다.

### [S-01] `AttributeKey` 약참조 캐시(`cache`)와 `nameClaims:SetStrong`의 생명주기 공존성 증명

- **의혹**:
  - `AttributeKey.luau`의 `cache`는 `{ __mode = "v" }` (약한 값 테이블)로 선언되어 있습니다.
  - 어떤 인스턴스 `inst`에 `AttributeKey("X")`로 속성을 바인딩한 후, 호출자의 Lua 로컬 변수에서 해당 키 객체 참조가 사라지면 GC에 의해 `cache["X"]`가 수거될 수 있는가?
  - 수거된 후 다시 `AttributeKey("X")`를 호출하면 새 객체 `k'`가 생성되어, `nameClaims`에 남아있는 이전 객체 `k`와 달라 충돌(`"already bound by another owner"`)을 일으키지 않는가?
- **건전성 증명**:
  1. `AttributeKey.luau` 121행에서 바인딩이 일어날 때 `nameClaims:SetStrong(inst, k.Name, k)`가 호출됩니다.
  2. `nameClaims`는 `Relate()` 인스턴스로, `buckets[inst].StrongMap[k.Name] = k`에 `k` 객체를 **강하게(Strong)** 보관합니다.
  3. 인스턴스 `inst`가 살아있고 속성이 바인딩되어 있는 동안, Lua VM 힙 내에는 `k`에 대한 확실한 강한 도달 경로(Strong reachability)가 존재합니다.
  4. Lua/Luau GC 규칙상, 어떤 객체에 대한 도달 가능한 강한 참조가 하나라도 존재하는 한, 그 객체는 약한 값 테이블(`cache`)에서도 수거되지 않고 보존됩니다.
  5. 따라서 `inst`에 속성이 바인딩되어 있는 동안에는 다른 어떤 코드에서 `AttributeKey("X")`를 호출하더라도 항상 동일한 `k` 객체가 캐시에서 반환됩니다.
  6. 반대로 속성이 완전히 retract되고 외부 참조도 모두 사라진 경우에만 `cache`에서 정상적으로 GC 수거되므로, 메모리 누수도 없고 허위 충돌도 발생하지 않습니다.

### [S-02] `Ref.luau` 동적 재바인딩 시 `old`와 `new`의 대칭적 수명주기 무결성

- **검증 내용**:
  - `RefLeafHandler.process`는 `relate:GetWeak(inst, k)`를 통해 이전 Ref를 추적합니다.
  - 반응형 소스(`State<Ref>`)에 의해 슬롯의 Ref가 교체될 때:
    1. `Dispatch.process` (A) 분기가 sitting retractor를 호출합니다.
    2. retractor는 클로저에 캡처된 `old`에 대해 `unbindLifetime(old)` -> `old:Set(nil)` -> `relate:SetWeak(inst, k, nil)`을 정확한 순서로 수행합니다.
    3. 직후 새 `process`가 호출되어 새 `v`에 대해 `bindLifetime(inst, v)` -> `relate:SetWeak(inst, k, v)` -> `v:Set(inst)`를 수행합니다.
  - 결과적으로 이전 Ref의 완벽한 해제와 새 Ref의 안전한 설치가 단일 디스패치 파동 내에서 대칭적으로 완결됩니다.

### [S-03] `Modifier.luau` `flatten`의 해시/배열 분리 순회 알고리즘

- **검증 내용**:
  - `flatten`은 `n = #input`을 기준으로 해시부와 배열부를 명확히 분리합니다:
    - 1단계: `next(input, if n > 0 then n else nil)`을 통해 순수 해시부(및 희소 인덱스)만 순회하여, 해시 키에 잘못 배치된 Modifier를 O(1)~O(k)로 조기 거부합니다.
    - 2단계: `for i = n, 1, -1 do` 역순 순회를 통해 배열부의 Modifier들을 소비하고, `ProcessedModifier` 센티널로 대체하여 배열의 구멍(hole) 발생을 방지합니다.
  - 이 2단계 분리 구조는 배열부를 불필요하게 두 번 순회하지 않으면서도 해시부 오용을 완벽히 차단합니다.

### [S-04] `State.luau` 정적 의존성 그래프와 Lazy `Get` 루프의 최신성 보장

- **검증 내용**:
  - `State`의 의존성은 동적 런타임 추적이 아닌 노드 생성 시점의 정적 `_hold` 배열로 고정됩니다.
  - `Get()` 호출 시 `while true do` 루프를 돌며, `_cacheCurrCount ~= _cacheTargetCount` 확인 및 `_valueEpochMap:Refresh()`를 통해 상류 에포크 변경을 감지하고 수렴할 때까지 재계산합니다.
  - 이는 중간 계산 도중 reentrant `:Set`이 발생하거나 닫힌 게이트 뒤에서 보류되었던 변경이 유입되더라도 항상 최종 일관성(Eventual Consistency)과 최신 읽기를 보장합니다.

### [S-05] `Claim.luau` DFS 매퍼 해석과 Bottom-up 치환의 무결성

- **검증 내용**:
  - `Claim.luau`의 `resolve` 함수는 자식 매퍼 디스크립터들을 재귀 탐색할 때, 해석된 실제 자식 Instance를 `props[i] = child`로 그 자리에 제자리 치환(In-place mutation)합니다.
  - 이 치환 덕분에 하류의 `Dispatch.drive(inst, props)`가 호출될 때 `InstanceChildHandler`는 매퍼 디스크립터를 전혀 알 필요 없이 완전히 일반적인 정적 Instance 자식으로 인식합니다.
  - `New` 파이프라인의 인스턴스 조립과 `Claim`의 기존 트리 해석이 완벽히 동일한 핸들러 계층을 공유할 수 있도록 만든 매우 우아한 어댑터 패턴임을 검증했습니다.

### [S-06] `Blocker.luau`의 `_handles` 약참조 셋과 Upvalue 수명 일치

- **검증 내용**:
  - `Blocker.Policy(emit)`가 반환하는 `onUpstreamEmit` 클로저는 내부의 `handle` 함수를 upvalue로 강하게 참조합니다.
  - `Blocker`는 `self._handles[handle] = true`로 약키 테이블에 핸들을 보관하므로, `GateNode`가 살아있는 동안에는 강참조가 유지되어 약키 셋에서 수거되지 않고, `GateNode`가 GC되면 `Blocker` 측에서도 자동으로 정리됩니다.
  - 블로커가 등록된 게이트 노드들을 영구히 붙들지 않으면서도 수명 주기 동안 안전하게 콜백을 유지하는 메모리 누수 방지 불변식이 성립함을 확인했습니다.

---

## 6. 종합 평가 및 아키텍처 제언

### 전체 품질 평가
- `quad` v2 코드베이스는 철저한 마일스톤 계획과 6차례의 고강도 선행 리뷰를 거치며 최고 수준의 정밀도와 완성도를 달성했습니다.
- 특히 다음 영역의 설계는 매우 돋보입니다:
  - **부기 불변식 및 자가 치유 (`Bookkeeping.luau`)**: 사용자 코드 실행 중 캐시 무효화가 발생하더라도 스스로 인지하고 이전 캐시 베이스로부터 되감아 재시작하는 자가 치유(Self-healing) 구조.
  - **프레임워크 에러 진단 계층 (`quad-error`)**: 레이어 태그 기반 스택 워커를 통해 내부 래퍼 프레임에 구애받지 않고 항상 정확한 사용자 호출 위치를 blame하는 결정론적 진단 체계.
  - **엄격한 타입 생성 파이프라인 (`gen-d.py`)**: Roblox API Dump로부터 Luau 신규 솔버의 복잡도 한계를 회피하면서도 타입 안전성을 극대화하는 정교한 마커/유니언 설계.

### 향후 유지보수를 위한 핵심 권고사항
1. **공개 진입점의 인자 검증 완성도 제고**:
   - `Claim(inst, desc)`의 `inst` 검증([G-06]) 및 `Tag`의 빈 문자열 검증([G-01])처럼, 공개 API 진입부에서 사용자 입력을 엄격히 조기 차단하면 quad 내부 파일 라인이 에러 메시지에 노출되는 것을 완벽히 방지할 수 있습니다.
2. **선행 리뷰 질의(Q1~Q20)의 순차적 확정**:
   - 현재 원장에 정리된 사용자 질의(Q1~Q20) 중 Q8(`Animate` None/nil 통과 팔)과 Q18(`setLength` 사전 검증) 등은 실제 사용성 및 예외 안전성에 직결되므로 우선적으로 결정을 확정하고 반영하는 것이 권장됩니다.
