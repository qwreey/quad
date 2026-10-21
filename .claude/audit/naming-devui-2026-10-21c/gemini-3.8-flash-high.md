# devui 다이얼로그 API 네이밍 검토 보고서

> **안내**: 본 보고서의 선정안은 개발팀의 판단을 돕기 위한 **제안**이며, 최종 결정은 사용자가 수행합니다.
> 각 항목의 근거는 코드 및 테스트 검증을 바탕으로 **실측**(직접 실행 및 코드 확인)과 **추정**(UI/API 관례 및 사용자 인지 기반 추론)으로 구분하여 명시하였습니다.

---

## 1. 다이얼로그 열기 함수 (`Devui.<Name>`)

즉시 열리고(NOW), 대상 윈도우(또는 화면) 중앙에 배치되며, `OpenMenu`와 유사한 핸들(`{ IsOpen: State<boolean>, Close: (self) -> () }`)을 반환하는 명령형 함수.

- **선정 (제안)**: `OpenDialog`
- **순위 (Ranked Shortlist)**:
  1. `OpenDialog`
  2. `ShowDialog`
  3. `Dialog`
  4. `OpenModal`
  5. `Modal`
- **이유**:
  1. **기존 API와의 일관성**: devui의 팝업 API에는 즉시 열리고 핸들을 반환하는 `Devui.OpenMenu`([`quad-roblox-devui/src/init.luau:235`](file:///code/Projects/quad-agy/naming-1021c/quad-roblox-devui/src/init.luau#L235), [`quad-roblox-devui/src/Menu.luau:9-11`](file:///code/Projects/quad-agy/naming-1021c/quad-roblox-devui/src/Menu.luau#L9-L11))가 이미 확립되어 있습니다. `OpenDialog`는 `Open*` 접두사를 공유하여 사용자가 "즉시 열리고 핸들을 반환하는 명령형 함수"임을 자연스럽게 인지할 수 있습니다. (실측)
  2. **선언형 위젯과의 명확한 분리**: `Devui.Window`나 `Devui.PopupPanel`처럼 quad 인스턴스 트리의 `Children` 슬롯에 마운트하는 선언형 위젯([`quad-roblox-devui/src/init.luau:49-52`](file:///code/Projects/quad-agy/naming-1021c/quad-roblox-devui/src/init.luau#L49-L52))과 구별됩니다. (실측 및 추정)
- **오해를 유발하는 이름 (Flag)**:
  - `Modal` / `OpenModal`: 본 다이얼로그 모델은 입력 차단이 전혀 없는 비모달(`Modal = "None"`) 모드도 지원합니다. 함수명이 `Modal` 계열이면 `Devui.OpenModal({ Modal = "None" })`처럼 자기 모순적인 호출 코드가 되어 사용자에게 개념적 혼란을 줍니다. (추정)
  - `Dialog`: `Devui.Window`처럼 quad 선언형 트리 내부에서 반환값을 꽂아 넣는 위젯으로 오인하기 쉽습니다. (추정)

---

## 2. 다이얼로그 차단 범위 Prop 및 값 (`<BlockProp> = <Values>`)

다이얼로그가 열려 있는 동안 차단하는 범위(아무것도 차단 안 함 / 연 윈도우만 차단 및 딤 / 전체 화면 차단 및 딤)를 지정하는 prop. 기본값은 `"Window"`.

- **선정 (제안)**:
  - Prop: `Modal`
  - Values: `"None" | "Window" | "Global"` (기본값 `"Window"`)
- **순위 (Ranked Shortlist)**:
  - Prop: `Modal` > `Modality` > `Blocks` > `Block` > `Dim` > `Scope`
  - Values: `"None" | "Window" | "Global"` > `"None" | "Window" | "All"` > `"None" | "Window" | "Screen"` > `"None" | "Parent" | "App"`
- **이유**:
  1. **확립된 UI 표준 용어**: Qt, 웹 HTML `<dialog>`, 데스크톱 UI 툴킷 전반에서 대화 상자의 차단 범위를 나타내는 표준 용어는 모달리티(Modality / Modal)입니다. `Modal = "Window"`나 `Modal = "None"`은 읽기 쉽고 간결합니다. (추정)
  2. **Prop과 1:1 대응 및 대비**: 다이얼로그를 특정 윈도우에 종속시킬 때 `Window = win` prop을 넘기므로, 차단 대상 값으로 `"Window"`를 사용하는 것이 가장 직관적입니다. 또한 전체 차단을 나타내는 `"Global"`은 특정 윈도우 단위와 전역 단위를 가장 오해 없이 대비시킵니다. (실측 및 추정)
- **오해를 유발하는 이름 (Flag)**:
  - `Block` / `Blocks`: Lua/Luau 비동기 환경에서 코루틴이나 메인 스레드가 동기적으로 차단(synchronous execution block)되는 것으로 오해할 위험이 있습니다. 또한 이벤트 전파 차단(`stopPropagation`)과도 혼동될 수 있습니다. (추정)
  - `Dim`: 배경을 어둡게 하는 '시각 효과'에만 초점이 맞춰져 있어, 입력 차단(input blocking)이라는 핵심 동작 계약이 가려집니다. (추정)
  - `Scope`: 메뉴 시스템에서 이미 서브메뉴 체인을 묶는 `MenuScope` 및 `Scope` prop([`quad-roblox-devui/src/Menu.luau:26-30`](file:///code/Projects/quad-agy/naming-1021c/quad-roblox-devui/src/Menu.luau#L26-L30))으로 사용되고 있어 심각한 혼선을 초래합니다. (실측)
  - `"Parent"` (값): Roblox 개발자에게 `Instance.Parent` 계층을 연상시키지만, 다이얼로그는 실제 DataModel 상에서 윈도우 자식이 아니라 최상위 오버레이 레이어에 배치되므로 혼란스럽습니다. (실측 및 추정)
  - `"App"` (값): Roblox 개발 환경(플러그인, 인게임 도구)에서 도구를 "App"으로 지칭하는 관례는 낯섭니다. (추정)

---

## 3. 원콜 확인창 헬퍼 (`Devui.<Name>`)

"Delete this? [Delete] [Cancel]" 확인 다이얼로그를 한 번의 호출로 띄우는 편의 헬퍼. Escape 키는 취소로 작동하며 Cancel 버튼에 기본 포커스가 부여됨.

- **선정 (제안)**:
  - 함수명: `OpenConfirm`
  - 버튼 레이블 Prop: `ConfirmText` / `CancelText`
  - 콜백 Prop: `OnConfirm` + `OnCancel` (또는 단일 결과 콜백 필요 시 `OnResult`)
- **순위 (Ranked Shortlist)**:
  - 함수명: `OpenConfirm` > `ConfirmDialog` > `Confirm` > `AskConfirm`
  - 레이블: `ConfirmText` / `CancelText` > `ConfirmLabel` / `CancelLabel` > `OkText` / `CancelText`
  - 콜백: `OnConfirm` + `OnCancel` (2개 콜백) > `OnResult` > `OnAnswer`
- **이유**:
  1. **함수명 (`OpenConfirm`)**: 1번의 `OpenDialog` 및 기존 `OpenMenu`와 완벽히 짝을 이루며, 비차단(non-blocking) 명령형 헬퍼임을 분명히 나타냅니다. (실측 및 추정)
  2. **레이블 (`ConfirmText` / `CancelText`)**: devui의 모든 텍스트 표기 위젯 및 버튼은 `Label`이 아닌 `Text` prop을 사용합니다([`quad-roblox-devui/src/init.luau:43-44`](file:///code/Projects/quad-agy/naming-1021c/quad-roblox-devui/src/init.luau#L43-L44), [`quad-roblox-devui/src/Button.luau:43`](file:///code/Projects/quad-agy/naming-1021c/quad-roblox-devui/src/Button.luau#L43)). 또한 확인 대상 액션이 "Delete", "Overwrite" 등 파괴적 동작일 때 `OkText = "Delete"`는 의미적으로 어색하지만 `ConfirmText = "Delete"`는 자연스럽습니다. (실측 및 추정)
  3. **콜백 (`OnConfirm` + `OnCancel`)**: 도구 UI의 확인창은 대부분(약 90%) 취소 시 아무 동작도 하지 않습니다. 분리된 콜백을 사용하면 `OnResult = function(ok) if not ok then return end ... end` 같은 조건문 보일러플레이트 없이 `OnConfirm = doAction`만 넘길 수 있어 매우 간결합니다. 취소 시 처리가 필요할 때만 `OnCancel`을 선택적으로 넘길 수 있습니다. (추정)
- **오해를 유발하는 이름 (Flag)**:
  - `Confirm` (함수명): 브라우저의 `window.confirm()`처럼 호출 결과로 boolean을 동기 반환(`local ok = Devui.Confirm(...)`)하는 함수로 오해될 위험이 매우 큽니다. (추정)
  - `OkText`: 삭제/변경 등 비승인성 확인 대화 상자에서 `OkText = "Delete"`처럼 쓰일 때 단어 간 의미 충돌이 발생합니다. (추정)
  - `ConfirmLabel` / `CancelLabel`: devui의 핵심 명명 규칙(`Text`)을 깨뜨려 API 파편화를 유발합니다. (실측)
  - `OnAnswer`: 퀴즈나 설문형 텍스트 응답을 연상시켜 확인/취소 액션 핸들러의 의도와 맞지 않습니다. (추정)

---

## 4. 종합 요약표

| 항목 | 선정 (제안) | 추천 순위 요약 | 피해야 할 이름 (Flag) |
|---|---|---|---|
| **1. 다이얼로그 열기** | `OpenDialog` | `OpenDialog` > `ShowDialog` > `Dialog` > `OpenModal` > `Modal` | `Modal` (비모달과 모순), `Dialog` (선언형 위젯으로 오인) |
| **2. 차단 범위 Prop** | `Modal` | `Modal` > `Modality` > `Blocks` > `Block` > `Dim` > `Scope` | `Block` (스레드 동기 차단 오인), `Dim` (시각 효과에 치중), `Scope` (`MenuScope`와 충돌) |
| **2-1. 차단 범위 값** | `"None" \| "Window" \| "Global"` | `"None" \| "Window" \| "Global"` > `... \| "All"` > `... \| "Screen"` > `... \| "Parent" \| "App"` | `"Parent"` (`Instance.Parent` 오인), `"App"` (Roblox 환경에 부적합) |
| **3. 확인창 헬퍼 함수** | `OpenConfirm` | `OpenConfirm` > `ConfirmDialog` > `Confirm` > `AskConfirm` | `Confirm` (동기 boolean 반환으로 오인) |
| **3-1. 확인/취소 버튼 텍스트** | `ConfirmText` / `CancelText` | `ConfirmText`/`CancelText` > `ConfirmLabel`/`CancelLabel` > `OkText`/`CancelText` | `OkText` ("Delete" 등과 의미 충돌), `*Label` (`Text` 규약 위반) |
| **3-2. 확인 콜백** | `OnConfirm` + `OnCancel` | `OnConfirm` + `OnCancel` > `OnResult` > `OnAnswer` | `OnAnswer` (설문지 답변 오인) |

---

## 5. 실행 및 검증 내역 (실측)

- **전체 테스트 스위트 실행**:
  - 명령: `( ulimit -v 4000000; timeout 600 ./scripts/test.sh )`
  - 결과: exit code 0 통과 (doc-coverage 212/212, error-codes 272 ids, quad-base/roblox spec 전체 PASS).
- **devui 전용 테스트 스위트 실행**:
  - 명령: `( ulimit -v 4000000; timeout 600 ./quad-roblox-devui/test/run.sh )`
  - 결과: exit code 0 통과 (21개 테스트 스펙 및 181개 이상의 세부 단위 테스트 ALL PASS).
