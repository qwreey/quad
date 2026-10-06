> Gemini 원문 — 판정은 agy-triage.md

# quad round14 반영 diff (1cef4ef7..HEAD) 리뷰 보고서

## 1. 머리 요약

- **리뷰 대상**: `git diff 1cef4ef7..HEAD` (커밋 10개, P0~P4 단계적 반영분)
- **전체 판정**: **우수 (반영 완성도 높음)** — 전체 테스트 `./scripts/test.sh` 통과 (exit code 0, 63개 spec 통과, `error-codes` 258개 id / 254개 raise site 0 untagged, `doc-coverage` 206/206 100%).
- **핵심 원칙 준수 여부**:
  - **반응형 순수성 & UB 계약화 방지**: Compute 안 Set, 반응형 콜백 내 yield, Observer 상류 되먹임 등 UB에 대한 가드 철거 및 문서화("관측 — 계약 아님") 충실히 이행됨.
  - **검사의 층 & Lazy 보존**: 비싸거나 깊은 검사는 `q.debug` 층으로 이동되었으며, 특히 **"debug에서도 lazy를 깨지 않는다"**는 원칙에 따라 State 원소의 사전 `:Get()` 검사(`H-517`) 및 `wrapElement` 내 `assertAcyclicChain` 사전 검사가 정상 철거됨을 실측으로 확인.
  - **프로토콜 분리 (`q.Protocols.DispatchHint`)**: 코어 객체를 하드코딩하지 않고 모듈별 `__dispatchHint` 훅과 `Brand` 등록부 체계로 깔끔하게 전환됨.
  - **백엔드 2층 구조**: 20개 주입 op와 4개 합성 op 분리 및 `isClaimed` / `canExecute` 동작 정합성 확인.
- **발견 사항 요약**:
  - **HIGH (0건)**: 치명적인 논리 오류나 런타임 회귀 없음.
  - **MED (1건)**: P3/P3b에서 `H-517`이 되돌려져 State 원소의 사전 값 검사가 철거되었으나, `CHANGELOG.md:60` 및 `docs/site/src/content/docs/changelog.md:62`에 "(`State`에 담긴 원소도 그 현재값으로 미리 검사합니다)"라는 옛 동작 서술이 남아 같은 CHANGELOG 40행 및 실제 런타임 동작과 정면 충돌함 (실측).
  - **LOW (3건)**:
    - `spec.slot.luau:817-818` 주석에 P2 시절 동작("with q.debug on, the round14 Q173 value-chain walk in wrapElement still reads it")이 남아 현재 동작과 불일치 (실측).
    - `quad-roblox/src/Tween.luau:148, 217`에서 `quad.Protocols: { [string]: Brand? }` 프로토콜 규약(nil 확인으로 좁혀 쓰기)과 달리 `DispatchHint`에 대한 nil 가드 없이 직접 호출함 (추정).
    - `docs/getting-started/11-slot.md:269` HTML 주석 내 핸들러 옛 명칭(`StoreBind`) 잔여 (추정).

---

## 2. 발견 표

| 번호 | 심각도 | 파일:줄 | 한 문장 요약 | 실측/추정 |
| :---: | :---: | :--- | :--- | :---: |
| **1** | **MED** | `CHANGELOG.md:60`<br>`docs/site/src/content/docs/changelog.md:62` | Q170 최종(lazy 보존)으로 State 원소 사전 값 검사가 철거되었으나, CHANGELOG 60행에 "State에 담긴 원소도 그 현재값으로 미리 검사합니다"라는 모순된 설명이 남아 있음. | **실측** |
| **2** | **LOW** | `quad-base/test/spec.slot.luau:817-818` | Q173 P3 반영으로 `wrapElement`의 사전 순환 검사가 철거되었음에도, `spec.slot` 주석에 "with q.debug on, ... still reads it"라는 P2 시절 서술이 남아 있음. | **실측** |
| **3** | **LOW** | `quad-roblox/src/Tween.luau:148, 217` | `Protocols: { [string]: Brand? }` 규약 상 `Brand?`에 대해 nil 가드 후 좁혀 쓰도록 규정했으나, `Tween.luau`가 `quad.Protocols.DispatchHint`를 nil 가드 없이 호출함. | **추정** |
| **4** | **LOW** | `docs/getting-started/11-slot.md:269` | `StateHandler`로 개명된 내장 핸들러의 옛 이름(`StoreBind`)이 가이드 문서 HTML 주석에 남아 있음. | **추정** |

---

## 3. 발견별 근거 문단

### 발견 1 (MED, 실측): CHANGELOG 내 State 원소 사전 검사 서술 잔여 모순

- **해당 위치**:
  - `CHANGELOG.md:60`
  - `docs/site/src/content/docs/changelog.md:62`
- **원장/결정과의 대조**:
  - `.claude/qa-request/post-implementation-review-round14.md` Q170 닫힘(2026-10-06):
    > 사용자 회신: *"debug 일 때 lazy 가 사라지는건 안 돼. Get은 디버그에도 없는게 맞아보여. (3) 래퍼 마운트 때 보는 쪽으로 통일하자"*
  - 이에 따라 `H-517`(CRUD 라인에서 `raw:Get()`으로 State 원소의 현재값을 검사하던 것)이 완전히 철거되고, State 원소는 마운트 및 값 재조정 시점(`:List`/`:Single` 내부)에 `Quad0156` 등으로 검사하도록 통일되었습니다.
  - 실제로 `CHANGELOG.md:40`에는 다음과 같이 정확히 갱신되었습니다:
    > `Slot의 CRUD가 넣기 전에 미리 하는 검사는 이제 원소 종류 하나입니다 ... State로 넣은 원소는 넣을 때 값을 읽지 않고 :List/:Single 항목처럼 마운트·값 변경 때 검사합니다 — 마운트 전 Slot에 같은 Instance를 쥔 State 둘을 넣으면 넣는 줄 대신 마운트 줄에서 Quad0156이 나며 ...`
  - 그러나 20줄 뒤인 `CHANGELOG.md:60`에는 여전히 옛 P2 초안의 문장이 괄호 안에 남아 있습니다:
    > `이제 Add·생성자·Replace·Extract·Splice·List/Single이 Slot: this element is not claimed by quad …로 거부합니다(State에 담긴 원소도 그 현재값으로 미리 검사합니다).`
- **실측 검증**:
  - 프로브 코드를 통해 unmounted Slot에 claim되지 않은 외부 Instance를 쥔 State를 `Add` 했을 때 동작을 확인:
    ```luau
    local foreign = mock.Instance.foreign("Frame")
    local stForeign = q.Source(foreign)
    local s = q.Slot()
    local okAdd, errAdd = pcall(function() s:Add(stForeign) end)
    print("Add ok?", okAdd) -- 출력: true nil (Add 시점에는 검사하지 않고 통과!)
    local okDrive, errDrive = pcall(function() q.Dispatch.drive(mock.Instance.new("Folder"), { s }) end)
    print("Drive ok?", okDrive, errDrive) -- 출력: false, Quad0241 (마운트 시점에 비로소 거부됨!)
    ```
  - 따라서 CHANGELOG 60행의 `(State에 담긴 원소도 그 현재값으로 미리 검사합니다)`는 런타임 실제 동작과 정면 충돌하며, 같은 파일 40행의 설명과도 모순됩니다.
- **제안**:
  - `CHANGELOG.md:60` 및 `docs/site/src/content/docs/changelog.md:62`의 괄호 문구를 다음과 같이 수정 제안:
    - 수정 전: `(State에 담긴 원소도 그 현재값으로 미리 검사합니다)`
    - 수정 후: `(State에 담긴 원소는 넣을 때 값을 읽지 않고 마운트·값 변경 때 거부합니다)` (또는 괄호 삭제)

---

### 발견 2 (LOW, 실측): `spec.slot.luau` 817-818행 주석의 P2 동작 서술 잔여

- **해당 위치**:
  - `quad-base/test/spec.slot.luau:817-818`
- **원장/결정과의 대조**:
  - `spec.slot.luau:817-818` 주석:
    ```luau
    -- a lazy Compute element is not run by the CRUD line (the pre-pass reads no State value; with q.debug
    -- on, the round14 Q173 value-chain walk in wrapElement still reads it — not asserted here)
    ```
  - P2 반영 당시에는 Q173에 따라 `wrapElement` 내에서 `q.debug`일 때 `assertAcyclicChain`을 호출하여 순환 State를 잡으려 했으나, 이 경우 `raw:Get()`이 호출되어 lazy Compute가 unmounted Slot의 `Add` 줄에서 미리 실행되는 문제가 있었습니다.
  - 사용자의 "debug여도 lazy가 깨지면 안 된다"는 원칙 확립에 따라, P3에서 `Elements.luau:76-81`의 `assertAcyclicChain` 사전 검사는 완전히 철거되었고, 마운트 시점(`Slot/List.luau` `checkItemChains`)으로 옮겨졌습니다.
  - 실제로 같은 파일의 7절(`spec.slot.luau:1570-1584`)에서는 다음과 같이 단언하고 있습니다:
    ```luau
    -- (7) round14 P3 (2026-10-06 — Q170 (최종) user principle "debug 일 때 lazy 가 사라지는건 안 돼..."):
    -- with q.debug ON, a State element added to an UNMOUNTED Slot is not read — its Compute fn
    -- does not run at the Add line; the chain check runs when the Slot mounts
    sl7:Add(comp7)
    assert(runs == 0, "debug on: Add on an unmounted Slot does not run the Compute fn (ran " .. runs .. ")")
    ```
- **실측 검증**:
  - `q.debug = true`인 상태에서 `spec.slot.luau` 819~824행과 동일한 코드를 실행한 결과 `runs`는 0이었습니다.
  - 즉, `with q.debug on, the round14 Q173 value-chain walk in wrapElement still reads it`라는 주석 내용은 P2 시절의 임시 동작 서술이며, 현재 코드 동작과 완전히 다릅니다.
- **제안**:
  - `spec.slot.luau:817-818` 주석을 P3 현행 동작에 맞게 수정 제안 (예: `-- a lazy Compute element is not run by the CRUD line even with q.debug on (lazy model preserved; round14 P3 Q170/Q173)`).

---

### 발견 3 (LOW, 추정): `quad-roblox/src/Tween.luau` 내 `Protocols.DispatchHint` 무가드 호출

- **해당 위치**:
  - `quad-roblox/src/Tween.luau:148, 217`
- **원장/결정과의 대조**:
  - `.claude/qa-request/post-implementation-review-round14.md` Q161 반영 보강 (다):
    > 사용자 회신: *"타입을 더 붙일 수 있는 구조가 되려면 런타임과 똑같게 [string] -> Brand? 가 되어야할듯. … local a = quad.Protocols.DispatchHint; if not a then ... end 식으로 한번 걸러주면"*
  - `quad-types/src/init.luau:713-717`:
    ```luau
    -- [2026-10-06 round14 Q161 반영 보강 (다) — 사용자 결정] 능력(프로토콜) 브랜드의 공개 집합(q.Protocols.DispatchHint 등).
    -- 런타임과 같은 모양 — 키를 더해도 타입이 안 바뀌고, 쓰는 쪽은 `local hint = quad.Protocols.DispatchHint; if hint then … end`로
    -- 좁혀 씁니다; 훅 `__dispatchHint`는 타입에 싣지 않습니다.
    Protocols: { [string]: Brand? },
    ```
  - `docs/site/src/content/docs/reference/extend/02-dispatch-handler-contract.md:232`:
    > "값을 만들 때 `quad.Protocols.DispatchHint:Register(value)`(타입은 `Brand?`라 한 번 `nil` 확인으로 좁힙니다 — 아래 예제)"
- **코드 상태**:
  - `quad-roblox/src/Tween.luau:148`:
    ```luau
    local DispatchHint = quad.Protocols.DispatchHint -- members register at creation (newTween)
    ```
  - `quad-roblox/src/Tween.luau:217`:
    ```luau
    DispatchHint:Register(self)
    ```
  - `DispatchHint`가 `nil`일 가능성에 대한 가드가 없습니다.
  - 현재 quad 배포본에서는 `quad.Protocols.DispatchHint`가 항상 존재하므로 런타임 예외는 발생하지 않지만, 프로토콜 규약("프로토콜은 옵셔널 능력 브랜드이며 소비자는 `if hint then ... end`로 좁혀 쓴다") 측면에서는 가드가 생략되어 있습니다.
- **제안**:
  - `if DispatchHint ~= nil then DispatchHint:Register(self) end`로 가드 처리 제안.

---

### 발견 4 (LOW, 추정): `docs/getting-started/11-slot.md:269` 주석 내 `StoreBind` 옛 이름 잔여

- **해당 위치**:
  - `docs/getting-started/11-slot.md:269`
- **원장/결정과의 대조**:
  - CHANGELOG 및 레퍼런스에서 자리에 놓인 State를 한 단계 벗겨 넘기는 내장 핸들러가 `StoreBind`에서 `StateHandler`로 개명되었습니다.
  - `docs/getting-started/11-slot.md` 269행의 HTML 주석:
    ```html
    <!-- 근거: 2026-09-11 mock 실측 ... StoreBind가 ... -->
    ```
  - 독자에게 노출되는 본문 텍스트는 아니므로 심각도는 극히 낮으나, 내부 주석에 옛 핸들러 명칭이 남아 있습니다.
- **제안**:
  - HTML 주석 내 `StoreBind`를 `StateHandler`로 갱신 제안.

---

## 4. 묶음 (근본 원인)

이번 diff에서 발견된 사소한 불일치들은 다음과 같은 2가지 공통된 근본 원인(뿌리)에서 비롯되었습니다:

### 묶음 A: 탐사 가드 도입(`H-517`) 취소에 따른 "잔여 동기화 누락" (발견 1, 발견 2)
- **뿌리 메커니즘**:
  - round10~13 탐사 과정에서 "반쪽 상태 방지"를 위해 State 원소의 사전 검사(`H-517`)와 unmounted Slot의 순환 검사(`Q173`)가 선행 패스(`wrapElement`, `prepareElements`)에 추가되었습니다.
  - 그러나 round14 검토에서 **"debug일 때라도 lazy가 사라져선 안 된다"**는 대원칙(사용자 결정 Q170 최종, Q173)이 확립되면서, 사전 검사들이 대거 철거되고 마운트/재조정 층으로 이동되었습니다.
  - 이 과정에서 핵심 로직 코드(`Slot/init.luau`, `Elements.luau`, `List.luau`)와 CHANGELOG 40행, spec 7절 등 주요 지점은 올바르게 수정되었으나, **CHANGELOG의 다른 단락(60행) 및 이전 spec의 주석(817행)**에 이전 결정 시절의 서술이 미처 정리되지 않고 잔존했습니다.

### 묶음 B: 새 프로토콜 인터페이스 규약과 번들 내부 구현 간의 관성 (발견 3)
- **뿌리 메커니즘**:
  - Q161 반영 보강 (다)에서 `Protocols`를 `{ [string]: Brand? }`로 일반화하고 외부 프로바이더/소비자에게는 nil 가드를 통한 타입 좁히기를 공식 가이드라인으로 제시했습니다.
  - 하지만 `quad-roblox`는 사실상 `quad-base`와 단일 패키지 생태계로 결합되어 테스트되다 보니, `quad.Protocols.DispatchHint`가 항상 존재함을 전제하고 작성되어 프로토콜 규약(옵셔널 nil 체크)이 구현 코드에 엄격하게 적용되지 않았습니다.

---

## 5. 확인 못 한 것 (미완)

1. **Roblox 실제 런타임 환경 (클라이언트 / 스튜디오) 실측**:
   - `quad-roblox`의 Tween 및 시그널 바인딩은 Luau mock 환경(`test.sh`)에서 100% 통과했으나, Roblox 실기기의 **Deferred 시그널 큐 순서**, 실제 물리 인스턴스 소멸 타이밍, `task.delay`의 float32 반올림 및 프레임 스케줄링 환경에서의 실측은 이번 worktree 환경(Linux CLI)의 제약으로 직접 수행하지 못했습니다 (원장의 `HUMAN_TODO I` 영역).
2. **Luau 컴파일러 최적화(-O2) 인라인 방지 실측**:
   - Q174 보강 1 & 2에 따라 `_reentryFrames` 감지기에서 `fireCompleted`, `fireOnChange` 등의 프레임이 `-O2`에서 인라인되지 않도록 `debug.info` 스택 깊이를 맞추는 방어 코드가 삽입되었습니다. CLI 환경의 테스트 스위트에서는 정상 동작을 확인했으나, Roblox 엔진의 네이티브 Luau 런타임 최적화 빌드에서의 스택 프레임 보존 여부는 실기기 확인이 필요합니다.
