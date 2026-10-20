# Spread 입력 명칭 검토 보고서 (Naming Review — Spread Input Names in quad)

본 보고서는 Luau로 UI를 작성하는 Roblox 개발자(라이브러리 사용자)의 관점에서 quad의 신규 `Spread` 관련 퍼블릭 API 명칭을 검토한 결과입니다.
프로젝트의 모든 최종 결정 권한은 사용자에게 있으며, 본 문서에 제시된 수정안 및 대안은 사용자의 판단을 돕기 위한 **제안**입니다.

---

## 1. `SpreadInto<C>`
- **verdict**: keep
- **best name**: `SpreadInto<C>`
  - 제안 이유: quad의 기존 입력 위치 마커 타입 규약(`ModifierInto<C>`)과 완벽한 구조적 대칭을 이루어 "클래스 C에 들어갈 수 있는 Spread"라는 입력 제약(공변 서브타이핑 마커)을 직관적으로 전달함 [실측: `.claude/research/declaration-naming-table.md:46`, `.claude/research/declaration-surface-plan.md:105-115`].
- **alternatives**:
  - `SpreadMarker<C>`: `StateMarker<T>`(`quad-types/src/init.luau:55`)의 명명 패턴을 따라 메서드가 거세된 순수 입력 마커임을 강조하나, 특정 대상 클래스 C로 향한다는 진입(target placement) 관계(`Into`)가 축약됨 [추정].
  - `SpreadIn<C>`: 전치사를 줄여 더 간결하나, 이미 확정된 `ModifierInto<C>`와의 대칭성이 깨져 사용자에게 불필요한 어휘 분기를 유발함 [추정].
- **confusion risk**: **Low**
  - **Roblox / Luau**: Luau 언어 및 Roblox 엔진 전역에 `Into` 관련 예약어나 타입이 없어 충돌 위험이 전무함 [실측].
  - **JS**: JS에는 타입 레벨 marker 개념이 없으므로 충돌하지 않음 [추정].
  - **라이브러리 자체**: `State`/`StateMarker`, `Modifier`/`ModifierInto`에 이어 "메서드가 필요한 자리는 전체형(`Spread<C>`), 입력받는 자리는 마커(`SpreadInto<C>`)"라는 quad 타입 표면 규약에 정확히 들어맞음 [실측: `quad-types/src/init.luau:42-55`].

---

## 2. `FieldSpread` / `TrackSpread`
- **verdict**: keep
- **best name**: `FieldSpread` / `TrackSpread` (패턴: `<Part>Spread`)
  - 제안 이유: 킷의 기존 내부 요소 스타일링 prop인 `FieldModifier` / `TrackModifier`(`quad-roblox-devui/README.md:175`, `quad-roblox-devui/src/Inputs/InputText.luau:60`, `quad-roblox-devui/src/Inputs/SliderNum.luau:46`) 옆에 나란히 배치되어 발견성(discoverability)이 뛰어나고, Ref나 OnEvent 등 동적 요소를 주입하기 위한 확장 prop임을 즉시 유추할 수 있음 [실측/추정].
- **alternatives**:
  - `Field` / `Track`: 가장 간결하나, 슬롯(자식 컴포넌트/인스턴스 자체)을 넘기는 prop으로 오해될 위험이 매우 큼 [추정].
  - `FieldProps` / `TrackProps`: React/Roblox 관례에 친숙하나, 일반 프로퍼티 테이블이 아닌 Ref/이벤트/Modifier를 포괄하는 일회성 가방(`SpreadInto<TextBox>`)을 받는다는 본질을 왜곡함 [추정].
- **confusion risk**: **Medium**
  - **Roblox / Luau**: Roblox 엔진 프로퍼티와 충돌하지 않음 [추정].
  - **JS**: JS에서 `spread`는 문법 연산자(`...`)이지 prop 명칭(명사)이 아니므로, `FieldSpread = ...` 형태가 처음에는 다소 낯설게 느껴질 수 있음 [추정].
  - **라이브러리 자체**: 내부 요소를 커스터마이징하는 경로가 `FieldModifier`(정적 재사용 기본값)와 `FieldSpread`(일회성 바인딩/확장) 2개로 공존하여 사용자가 "어느 것을 써야 하는가"에 대한 선택 피로를 겪으며, 둘을 함께 넘겼을 때의 우선순위(Spread가 Modifier를 덮어씀)를 학습해야 하는 부담이 존재함 [추정].

---

## 3. `:Add`
- **verdict**: change
- **best name**: `Append`
  - 제안 이유: quad의 "먼저 놓인 것이 이김(first-in-place wins)" 규칙 아래에서 새 Spread가 우선순위 큐의 맨 뒤(가장 낮은 우선순위/기본값 자리)에 덧붙여진다는 위치적 순서를 명확히 드러내며, 배열 값(Ref, OnEvent, 자식)이 뒤에 이어붙는(concatenate) 실제 런타임 동작과 정확히 일치함 [제안].
- **alternatives**:
  - `Add`: 빌더/누적기 관점에서는 가장 짧고 직관적이나, 딕셔너리/프로퍼티 관점에서 "새로 추가한(Add) 프로퍼티가 기존 프로퍼티를 덮어쓰거나 최소한 반영될 것"이라는 강력한 오독을 낳음 [추정].
  - `Extend`: 파이썬/러스트 컬렉션의 확장 개념으로 순서 보존 합성을 잘 나타내나, 딕셔너리 `update`나 클래스 상속/확장(`extends`)과 혼동되어 여전히 덮어쓰기 오해를 유발할 수 있음 [추정].
- **confusion risk**: **High** (기존 `:Add` 유지 시) / **Low** (`Append` 채택 시)
  - **JS**: Spread의 어원이 된 JS Spread(`{ ...s, ...other }`)는 뒤에 오는 `other`가 기존 키를 덮어씀(later wins). 따라서 `s:Add(other)`를 보았을 때 JS 경험자는 `other`의 프로퍼티가 적용될 것으로 기대함 [추정].
  - **Roblox / Luau**: 일반적인 맵 병합 함수나 빌더 패턴에서 `Add(x)`를 호출했는데 `x` 안에 든 프로퍼티가 이미 존재한다는 이유로 "에러도 없이 조용히 무시(drop)"되는 것은 개발자 관점에서 매우 당혹스러우며 침묵하는 버그(silent bug)를 유발함 [추정].
  - **sanity check 질의에 대한 판단**: `:Add`는 "추가된 것이 덮어쓴다" 또는 "추가된 프로퍼티가 적용된다"는 인상을 강하게 주므로 **부적합함**. 덮어쓰지 않고 뒤에 덧붙여 빈자리만 채우는 동작은 **`Append`**로 표현해야 우선순위 큐의 꼬리에 붙는다는 멘탈 모델이 성립함 [제안].

---

## 세트 전체의 일관성 및 설계 누수 검토 (종합 3줄 평가)
1. **Modifier(뒤가 이김)와 Spread(앞이 이김)의 우선순위 정반대 충돌**: 동일한 요소 배열부(`Frame { s1, m1, s2, m2 }`)에 놓이는 두 객체가 정반대의 키 우선순위 규칙(`m1, m2`는 m2 승리, `s1, s2`는 s1 승리)을 가져 사용자에게 극심한 인지 부조화를 유발함 [실측: `quad-base/src/Dispatch/Modifier/init.luau:546-557` (역순 순회 실측) / 추정].
2. **JS Spread(뒤가 이김)와의 어휘적 배반**: 이름은 JS 객체 전개(`{ ...t }`)에서 따왔으면서 평가 우선순위는 JS와 정반대인 "앞이 이김"을 채택하여, JS 전개 구문에 익숙한 사용자에게 침묵하는 값 누락 버그를 유도함 [추정].
3. **내부 컴포넌트 커스터마이징의 이중 통로 분열**: 재사용 기본값(`Modifier`)과 일회성 바인딩(`Spread`)이라는 라이브러리 내부 메커니즘 분기가 컴포넌트 API 표면(`FieldModifier` vs `FieldSpread`)에 그대로 노출되어 사용자에게 불필요한 개념 구분과 선택 비용을 전가함 [추정].
