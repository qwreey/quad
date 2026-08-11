# `OnChange` 특수 키 — `GetPropertyChangedSignal` 바인딩

**상태**: base — 2026-08-10 세션에서 확정. quad-roblox 전용(값 타입/API
레이어 없음, `Attribute`와 같은 패키지 배치). **[2026-08-11 아홉 번째
세션 후속]** `AttributeKey`와 동일한 이름별 weak 캐시로
`OnChange(a) == OnChange(a)` 동등성도 확정 — 아래 "확정" 절 참고.

## 문제

이벤트 바인딩은 이미 평범한 문자열 키 + reflection(`GetEventsOfClass`)으로
확정돼 있음(`bind-system-plan.md`의 "인스턴스 생성 / 이벤트 네이밍 인체공학"
절) — `inst[key]`가 이미 `RBXScriptSignal`이라 그냥 `Connect`하면 됨.
`GetPropertyChangedSignal(name)`은 이 패턴이 그대로 안 통함: 프로퍼티 이름을
인자로 받아 **별도 메소드 호출**로 시그널을 얻어야 하고, 그 프로퍼티 이름은
이미 "값 세팅" 키 네임스페이스(`Frame.Position = x`)와 겹침 — 값 타입만으론
"세팅"과 "변경 리스닝"을 구분할 방법이 없어서 별도 마커가 필요함.

## 확정

- **`OnChange(propertyName): OnChangeKey`** — 프로퍼티 이름을 감싸는 DI 키
  팩토리, `AttributeKey(name)`/`Tag(...)`와 같은 패턴(`AttributeKey`는 구
  `Attribute` — 2026-08-11 아홉 번째 세션에 여러 Store를 묶는 그룹
  `Attribute(...)` 프리미티브가 신설되며 이름 충돌 방지로 리네임됨,
  `base/attribute-plan.md` 참고). 사용 예:
  `Frame { [OnChange "Position"] = function(v: UDim2) ... end }`.
- **제네릭 타입 파라미터 없음 — `OnChange<<T>>` 같은 타입 파라미터화는 안
  함.** 콜백 파라미터 타입은 호출부가 인라인으로 직접 명시
  (`function(v: UDim2) ... end`) — Luau가 그 타입이 실제 프로퍼티 타입과
  일치하는지 검증해주지 않음. 이미 확정된 "이벤트 바인딩은 콜백 시그니처를
  Luau가 검증 못 하는 대가를 받아들인다"는 결정(`bind-system-plan.md` "이벤트
  바인딩 — `On.EventName` 도트액세스 안 씀" 절, "타입 안전성을 어느 정도
  포기하는 대가")과 같은 급의 트레이드오프라 새로 정당화할 것 없음 — 오히려
  `AttributeKey<<T>>`처럼 제네릭으로 정확히 맞추려는 시도는 이벤트 키보다 더
  엄격한 걸 요구하는 셈이라 일관성이 깨짐.
- **기각안 — 프로퍼티별 정적 `OnChange.PropertyName` 전량 코드 생성**:
  `archive/onchange-per-property-codegen-rejected.md` 참고. Attribute의
  "제네릭 + 자주 쓰는 것만 정적 지름길" 절충과 겉보기엔 비슷해 보이지만
  규모가 다른 문제라 기각.
- **패키지 경계: 전부 quad-roblox** — `Handlers/OnChange.luau`에 `OnChange(name)`
  키 팩토리와 Handler를 같이 둠(단일 키 `AttributeKey.luau`와 같은 배치,
  base 쪽 값 타입 파일 없음 — 그룹 `Attribute.luau`는 값 타입 자체가
  quad-base 소속이라 다름, `base/attribute-plan.md` 참고).
  `GetPropertyChangedSignal` 자체가 Roblox 엔진 API라 base에
  둘 이유가 없음 — Tag처럼 백엔드 무관한 값/API 레이어가 따로 있는 경우와
  다름.
- **`process(inst,k,v)`**: `inst:GetPropertyChangedSignal(name):Connect(function()
  v(inst[name]) end)`. **`retract(inst,k,v)`**: 그 Connection을
  `:Disconnect()`. 일반 `Handlers/Event.luau`와 같은 결(Connection
  관리뿐, 새 메커니즘 없음).
- **`State<function>` 지원 — 새 메커니즘 없음.** 이미 확정된 "이벤트도
  store-bind 가능 — `false`로 disconnect" 메커니즘(`bind-system-plan.md`)이
  `OnChange` 키에도 그대로 적용됨 — `OnChangeHandler`는 `process`/`retract`만
  구현하면 되고, `v`가 State/Source면 범용 `Dispatch/StoreBind.luau`가 알아서
  언랩+재귀 재-dispatch해서 `process`를 다시 호출해줌. `OnChange` 전용 분기
  불필요.
- **`OnChange(name)`도 `AttributeKey`와 같은 이름별 weak 캐시 적용
  (2026-08-11 아홉 번째 세션 후속)** — `AttributeKey<<T>>(name)`이
  이름만으로 캐시되는 것과 정확히 같은 모양(이름 → 키, 다른 가변 정보
  없음)이라 같은 기법 그대로 재사용(`base/attribute-plan.md` "동등성"
  절). `State<function>`이 되더라도 문제 없이 작동하고(캐시는 키
  객체 자체의 identity만 다루지, 그 키에 바인딩된 값/콜백과는 무관),
  `OnChange "a" == OnChange "a"`가 외부에서 관찰 가능해지는 것도
  의도적으로 허용해도 되는 동작 — 문제 없음(사용자 확인). `Handlers/OnChange.luau`
  안 `OnChange(name)` 팩토리에 `AttributeKey`와 동일한 캐시 구현.

## 다른 특수 DI 키와의 대조

| | 소스 | 값 타입 | 패키지 경계 |
|---|---|---|---|
| 이벤트(`MouseButton1Click = fn`) | `inst[key]`가 이미 Signal | 콜백, 타입 미검증 | quad-roblox(`Handlers/Event.luau`) |
| `AttributeKey(name)` | `SetAttribute`/`GetAttribute` | 값(제네릭 또는 정적 타입 패밀리로 타입 파라미터화) | quad-roblox(`Handlers/AttributeKey.luau`) |
| `OnChange(name)` | `GetPropertyChangedSignal(name)` | 콜백, 타입 미검증(제네릭 없음) | quad-roblox(`Handlers/OnChange.luau`) |

`OnChange`가 Attribute처럼 제네릭화되지 않은 이유는 "콜백을 받는다"는
성질이 Attribute(값을 직접 받음)보다 이벤트에 더 가깝기 때문 — 카테고리가
헷갈리지 않도록 표로 명확히 구분해둠.
