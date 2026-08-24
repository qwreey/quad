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

- **`OnChange(propertyName): OnChangeKey`** — 프로퍼티 이름을 감싸는 특수 키
  팩토리, `AttributeKey(name)`/`Tag(...)`와 같은 패턴(`AttributeKey`는 구
  `Attribute` — 2026-08-11 아홉 번째 세션에 여러 Store를 묶는 그룹
  `Attribute(...)` 프리미티브가 신설되며 이름 충돌 방지로 리네임됨,
  `base/attribute-plan.md` 참고). 사용 예:
  `Frame { [OnChange "Position"] = function(v: UDim2) ... end }`.
- **제네릭 타입 파라미터 없음 — `OnChange<<T>>` 같은 타입 파라미터화는 안
  함.** 콜백 파라미터 타입은 호출부가 인라인으로 직접 명시
  (`function(v: UDim2) ... end`) — Luau가 그 타입이 실제 프로퍼티 타입과
  일치하는지 검증해주지 않음.
  **[근거 교체, 2026-08-18 구현 전 QA — 결론은 그대로]** 옛 근거는 *"이벤트
  바인딩은 콜백 시그니처를 Luau가 검증 못 하는 대가를 받아들인다는 결정과
  같은 급"* 이었는데, **그 전제가 거짓**이다(이벤트는 props 타입의 **필드**라
  `D` 생성기가 콜백 타입을 정확히 줄 수 있음 —
  `base/bind-system-plan.md`의 "인스턴스 생성 / 이벤트 네이밍 인체공학" 절).
  진짜 이유는 **`OnChange(name)`이 이름을 인자로 받는 팩토리라 그 경로가
  없다는 것** — 필드가 아니므로 생성기가 미리 타입을 찍어둘 자리가 없고,
  프로퍼티별로 전량 생성하는 안은 이미 기각돼 있다(아래 항목). 그래서
  `AttributeKey<<T>>`처럼 제네릭으로 맞추려는 시도만 남는데, 그건 호출부가
  매번 타입을 두 번 적게 만들 뿐이라 채택 안 함.
- **기각안 — 프로퍼티별 정적 `OnChange.PropertyName` 전량 코드 생성**:
  `archive/onchange-per-property-codegen-rejected.md` 참고. Attribute의
  "제네릭 + 자주 쓰는 것만 정적 지름길" 절충과 겉보기엔 비슷해 보이지만
  규모가 다른 문제라 기각.
- **패키지 경계: 전부 quad-roblox** — `Handlers/OnChange.luau`에 `OnChange(name)`
  키 팩토리와 Handler를 같이 둠. **[정정, 2026-08-13 열네 번째 세션]**
  예전엔 "단일 키 `AttributeKey.luau`와 같은 배치"라고 적었으나 그
  `AttributeKey`는 같은 세션에 **quad-base로 옮겨갔음**(부기가 엔진 지식을
  요구하지 않아서, `base/attribute-plan.md` "패키지 배치" 절) — `OnChange`가
  quad-roblox에 남는 이유는 그것과 달리 **`GetPropertyChangedSignal`
  자체가 로직**이라 "한 줄 op 주입"으로 줄어들지 않기 때문
  (`base/dispatch-core-plan.md` "base가 소유하는 핸들러와 주입되는 엔진
  op" 절의 분할 기준).
  `GetPropertyChangedSignal` 자체가 Roblox 엔진 API라 base에
  둘 이유가 없음 — Tag처럼 백엔드 무관한 값/API 레이어가 따로 있는 경우와
  다름.
- **`process(inst,k,v,index)`**: **먼저 `v == nil`이면 Connect를 건너뛰고
  no-op 클로저를 반환**하고, 아니면 `inst:GetPropertyChangedSignal(name):Connect(
  function() v(inst[name]) end)` 후 **그 Connection을 `:Disconnect()`하는
  클로저를 반환**. 일반 `Handlers/Event.luau`와 같은 결(Connection
  관리뿐, 새 메커니즘 없음).
  - **⭐ [정정, 2026-08-24 6라운드 손 트레이싱 `H-27`] 그 `v == nil` 얼리리턴이
    빠져 있었다.** 이 문서는 스스로 *"일반 `Handlers/Event.luau`와 같은 결"*이라
    결론냈는데, `base/event-plan.md`가 확정한 그 "같은 결"의 핵심이 정확히
    **`(k=이벤트키, v=nil)`을 받으면 기존 Connection 해제만 하고 새로 Connect하지
    않는다**이다. 없으면 `Frame { [OnChange "Position"] = someState }`에서
    `someState:Set(None)`으로 콜백을 끌 때, `NoneHandler` → `NilHandler`를
    거쳐 이 핸들러가 **`v == nil`로 다시 매치**되어(매치가 키 기반이라 `nil`도
    잡고, `NilHandler`는 `type(k) == "number"` 전용이라 여기 안 걸린다)
    `Connect(function() nil(inst.Position) end)`가 **실제로 심긴다.** 그 순간엔
    아무 일도 안 일어나고, 나중에 `inst.Position`이 실제로 바뀌면
    **`attempt to call a nil value`**로 터진다 — 즉 "콜백을 끈다"는 동작이
    실제로는 **"나중에 터질 Connection을 새로 심는"** 동작이 된다.
    `base/dispatch-core-plan.md`는 같은 종류의 방어를 `PropertyHandler`에는
    이미 명시적으로 요구하고 있다(*"`v == nil`이면 셋을 건너뛰는 방어"*) —
    `OnChange`만 빠져 있었다. **[정정, 2026-08-13 다섯 번째 세션]** 원래는
  별도 `retract(inst,k,v)` 필드가 Disconnect를 담당한다고 적혀 있었으나,
  Handler 계약이 `process` 1-메소드로 합쳐지며 그 로직이 반환 클로저로
  이동 — `connection`은 `process`의 로컬 변수를 클로저가 upvalue로 그대로
  캡처하므로 별도 `Relate` 저장/재조회가 필요 없음(`dispatch-core-plan.md`
  "핸들러 내부 상태 저장" 절).
- **`State<function>` 지원 — 새 메커니즘 없음.** 이미 확정된 "이벤트도
  store-bind 가능" 메커니즘(`base/event-plan.md`)이
  `OnChange` 키에도 그대로 적용됨 — `OnChangeHandler`는 `process`(와 그
  반환 클로저)만 구현하면 되고, `v`가 State/Source면 범용 `Dispatch/StoreBind.luau`가 알아서
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

## 다른 특수 키와의 대조

| | 소스 | 값 타입 | 패키지 경계 |
|---|---|---|---|
| 이벤트(`MouseButton1Click = fn`) | `inst[key]`가 이미 Signal | 콜백 — **[2026-08-18 정정] 타입 검증됨**(props 타입의 필드라 `D` 생성기가 콜백 시그니처를 찍어줌) | 판별은 quad-roblox(`Handlers/Event.luau`), 타입은 `D` 생성기 |
| `AttributeKey(name)` | 주입된 `setAttribute` op | 값(제네릭 또는 정적 타입 패밀리로 타입 파라미터화) | **quad-base**(키+Handler, 2026-08-13 열네 번째 세션 재배치) / 엔진 op만 백엔드 |
| `OnChange(name)` | `GetPropertyChangedSignal(name)` | 콜백, 타입 미검증(제네릭 없음) | quad-roblox(`Handlers/OnChange.luau`) |

`OnChange`가 Attribute처럼 제네릭화되지 않은 이유는 위 "확정" 절의 정정된
근거대로 **이름을 인자로 받는 팩토리라 타입을 미리 찍어둘 필드가 없기**
때문 — "콜백을 받는다"는 성질이 이벤트에 가깝다는 분류 자체는 그대로지만,
이벤트 쪽은 필드라서 타입이 나온다는 게 2026-08-18에 확인됐으므로 그
유사성이 근거가 되지는 못한다.
