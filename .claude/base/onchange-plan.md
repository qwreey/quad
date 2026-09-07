# `OnChange(name, fn)` — 배열부 디스크립터로 `GetPropertyChangedSignal` 바인딩

**상태**: base — 2026-08-10 세션 확정, **⭐ [2026-09-03 역전·재확정] 해시
파트 특수 키(`[OnChange "x"] = fn`)에서 배열부 값 `OnChange(name, fn)`으로
전면 재작성**(사용자 제안·동의 원문은
`archive/onchange-hash-key-reversed.md`와
`session/2026-09-03-05-onchange-array-reversal.md`). quad-roblox 전용
(`Handlers/OnChange.luau`), 구현·Studio 실측 완료(round16 `H10-14`,
`audit/m10-events-studio-2026-09-03.md` 3절). 옛 모양은 구현까지 됐다가 같은
날 뒤집혔다 — 이 문서에 옛 서술은 남기지 않는다(archive가 소스).

## 문제

이벤트 바인딩은 평범한 문자열 키 + reflection(`GetEventsOfClass`)으로
확정돼 있음(`bind-system-plan.md`의 "인스턴스 생성 / 이벤트 네이밍 인체공학"
절) — `inst[key]`가 이미 `RBXScriptSignal`이라 그냥 `Connect`하면 됨.
`GetPropertyChangedSignal(name)`은 이 패턴이 그대로 안 통함: 프로퍼티 이름을
인자로 받아 **별도 메소드 호출**로 시그널을 얻어야 하고, 그 프로퍼티 이름은
이미 "값 세팅" 키 네임스페이스(`Frame.Position = x`)와 겹침 — 별도 표면이
필요함.

## 확정

- **`OnChange(propertyName, fn): OnChangeDescriptor`** — 배열부에 두는 **값**
  (`Tag(...)`·생명주기 훅 `OnCreated`류와 같은 자리). 사용:

  ```luau
  Frame {
      Text = "a",
      OnChange("Text", function(v: string) ... end),
      OnChange("Text", function(v) ... end),     -- 같은 이름 둘 — 둘 다 붙는다
      someState,                                  -- State<디스크립터>도 같은 경로
  }
  ```

  디스크립터는 frozen `{ Name, Callback }`, 모듈 로컬 weak-key 브랜드. **캐시
  없음·동등성 계약 없음** — 매 호출이 새 값이라 같은 이름을 두 자리에 두면
  둘 다 바인딩된다(키 형태에선 테이블 리터럴이 뒤 것만 남기던 결함이 있었다).
- **⭐ 초기값 발화 계약** — 배열부는 해시부보다 먼저 돌므로(`F-4-1`, base가
  약속하는 유일한 순서) Connect가 **같은 props의 프로퍼티 대입보다 항상
  먼저** 산다. 따라서 `Frame { Text = "a", OnChange("Text", fn) }`에서 `fn`은
  초기값 `"a"`에도 발화한다(Deferred 시그널 환경에선 한 틱 뒤, 배달 시점의
  값을 읽어 — `audit/m10-events-studio-2026-09-03.md`). **사용자 확정**
  (2026-09-03): *"초기값 발화는 계약으로. … observer 와 유사한 동작이 난다는
  점도 의외로 흔한 디자인이 돼. 다만 설정 뒤에서 안 하면, emit 안 나긴 하고,
  AbsolutePosition 같은게 바로 계산되진 않겠지만, 그냥 프로퍼티 셋 이전에
  바운딩 해준다만 만족해도 해결돼."* 즉 계약은 **"프로퍼티 셋 이전에
  바운딩된다"** 하나이고, 그 따름정리가 초기값 발화다 — props에 그 프로퍼티가
  없으면 당연히 발화 없음, 파생 프로퍼티(`AbsolutePosition` 등)가 그 자리에서
  계산돼 있다는 보장도 없음, **[2026-09-07 7순회 `H-429` 셋째 헤지]** props의 값이
  엔진 기본값과 같으면(`Frame { Visible = true }`) 엔진이 동일값 대입에 시그널을 안
  쏘므로 발화 없음이 정상(mock은 무조건 쏘므로 CLI와 갈린다 — `HUMAN_TODO.md` 13번
  실측으로 확정할 것). 콜백이 초기값을 걸러야 하면 사용자가 `==`로
  거른다(사용자: *"== 비교가 엄청 싸서 그 안에서 dedup 하면 되는 부분"*) —
  quad가 초기값을 억제하지 않는다.
- **핸들러(`"OnChange"`, NORMAL)**: `type(k) == "number"` ∧ 디스크립터
  (`H-52` 키 가드). 말단이라 배열 위치를 등록한다(`H-39`) —
  `TagFallbackHandler`와 같은 `setOffsetSource(inst, k, None)` +
  `setLength(inst, k, 0)`(물리 요소 없음). `process`는
  `inst:GetPropertyChangedSignal(name):Connect(function() fn(inst[name]) end)`
  후 그 Connection을 `:Disconnect()`하는 클로저 반환(`connection`은 process
  로컬을 클로저가 캡처 — `dispatch-core-plan.md` "핸들러 내부 상태 저장" 절).
  **`v == nil` 분기 없음** — 배열 원소의 `None`/`nil`은 NoneHandler/NilHandler
  몫이라 이 핸들러에 닿지 않는다(옛 `H-27` 얼리리턴은 키 형태의 산물).
  같은-값 dedup 없음(`Connect`는 비멱등 — `Handlers/Event.luau`와 같은 근거,
  재발행 churn은 `event-plan.md`가 허용). 미지 프로퍼티 이름은 엔진 에러가
  `process` 안에서 난다(Studio 실측 `Bogus is not a valid property name`) —
  아래 타이핑이 정적으로 먼저 잡는 것이 방어다.
- **`State<디스크립터>` — 새 메커니즘 없음.** `Tag`와 같은 배열 원소
  StoreBind 경로(언랩 + 재디스패치, retractor가 Disconnect). `None`으로 끄면
  NilHandler(길이 0)로 넘어가 연결만 사라진다.
- **패키지 경계: 전부 quad-roblox** — `GetPropertyChangedSignal` 자체가
  로직이라 "한 줄 op 주입"으로 줄어들지 않기 때문(`dispatch-core-plan.md`
  "base가 소유하는 핸들러와 주입되는 엔진 op" 절의 분할 기준). 디스크립터
  브랜드는 quad-base `Brand`가 아니라 모듈 로컬 weak-key 집합(quad-roblox는
  quad-base를 require하지 않음 — round14 Q3 (a)).

## 타이핑 — 생성기가 검증·추론까지 준다 (2026-09-03 실측, `luau-test/done/30-*`)

옛 결정 "제네릭 없음, 콜백 타입은 인라인 명시·미검증"은 **키 형태의
한계**였다(이름을 인자로 받는 팩토리라 생성기가 타입을 찍어둘 필드가 없음).
값 형태에선 생성기가 세 조각을 찍는다(`scripts/gen-d.py` → `D/init.luau`):

1. **`PropTypes`** — D 스코프 전체의 프로퍼티 이름 → 타입(235개, 2026-09-03
   덤프 기준). 클래스 간 타입이 다른 이름(`Style`/`CanvasSize`/`Color`/
   `Offset`/`Transparency`/`Padding`)은 **`any`** — `index<>`가 유니언을 주면
   주석 콜백이 반공변으로 거부되기 때문(실측).
2. **`OnChangeFn = <K>(name: K & keyof<PropTypes>, fn: (index<PropTypes, K>) -> ()) -> OnChangeDescriptor<K>`**
   — `RobloxExtension.OnChange`가 이 타입(런타임 팩토리는 무타입). 이름
   오타(`keyof`)와 콜백 파라미터 타입 불일치(`index<>`)를 **호출 자리**에서
   잡고, **무주석 콜백의 파라미터를 추론**한다(`function(v) … end`의 `v`가
   `UDim2`) — `typing-limits.md`가 실측한 "제네릭 콜백 인자에 컨텍스트 타입이
   안 흐른다"의 예외로, `index<>`가 파라미터 타입을 직접 만들어 주기 때문.
   **[2026-09-07 7순회 `H-428` 정정]** 그 추론은 **검사·멤버 접근 방향에만** 흐른다 —
   무주석 `v`에 **연산자**를 쓰면(`v + 1`) `index<PropTypes, K>`가 줄어들기 전에 연산자
   제약이 풀려 `unknown`으로 실패한다(실측). 연산자를 쓰는 콜백은 파라미터에 주석을
   달 것(`typing-limits.md` 8.10).
3. **클래스별 `<Class>OnChange` 유니언**(`{ Name: "Position", Callback:
   (UDim2) -> () } | …`)이 `D.<Class>`/`D.Mapper.<Class>`의 `E`에 합류
   (클래스당 별칭 `<Class>Elem = NewChild | <Class>OnChange |
   StateMarker<<Class>OnChange> | { read __quadModifier: "<Class>" | … } |
   <Class>RefMarker | StateMarker<<Class>RefMarker>` — State 팔 둘은 **[2026-09-07 마커]**
   공변 `StateMarker`(옛 `State<…>` 전체형, `typing-limits.md` 8.11; 아래 캐비엇 (a)), 넷째 멤버는 **[2026-09-04 M7
   단위 ④]** 클래스 태그 마커(자기 + 조상 체인, `modifier-plan.md` 11절), 마지막
   둘은 **[2026-09-04 M8 단위 ③]** 반공변 팬텀 마커 `{ read __quadRefAccepts:
   (<Class>) -> () }`(`ref-plan.md` "children 자리의 타입" 절, round18 `H-321`),
   `<Class>MapperElem = <Class>Elem | MapperDescriptor` — 타입과 런타임 캐스트가 같은 별칭을 참조) — **클래스
   밖 이름**은 생성자 자리에서 거부된다(진단에 "too complex" 잡음이 함께 붙지만
   에러 자체는 난다).

캐비엇 둘: (a) **[2026-09-07 마커 — 사용자 결정]** **닫힘** — `<Class>Elem`의 State 팔이 공변 마커 `StateMarker<FrameOnChange>`가 돼(`typing-limits.md` 8.11) 캐스트 없이 든다; 아래는 옛 서술. `State<T>`는 `Set` 파라미터 때문에 **불변**이라
`q.Source(OnChange(...))`는 `State<FrameOnChange>`에 안 맞는다 — 클래스
유니언으로 캐스트해 만든다(`q.Source(OnChange(...) :: FrameOnChange)`;
반응형 자식 `q.Source(frame)` vs `State<Instance>`도 같은 규칙, 선행 한계).
(b) Color3/string처럼 멤버가 많은 타입의 콜백은 유니언 대조가 체커 기본
한도를 넘어 `scripts/test.sh`가 `LuauSubtypingIterationLimit=100000`을 싣는다
(`typing-limits.md` 8.7절 — 다른 형태·한도는 무효였다). 기각안 둘도 거기:
전 이름 싱글톤 유니언을 `K &`로 직접 교차(too complex), 이름·타입 쌍 오버로드
교집합(37개부터 too complex). 프로퍼티별 정적 `OnChange.PropertyName` 전량
생성 기각은 그대로(`archive/onchange-per-property-codegen-rejected.md`).

## 다른 특수 표면과의 대조

| | 소스 | 값 타입 | 자리 | 패키지 경계 |
|---|---|---|---|---|
| 이벤트(`MouseButton1Click = fn`) | `inst[key]`가 이미 Signal | 콜백 — 타입 검증됨(props 필드라 `D` 생성기가 시그니처를 찍음) | 해시부 | 판별은 quad-roblox(`Handlers/Event.luau`), 타입은 `D` 생성기 |
| `[AttributeKey(name)] = v` | 주입된 `setAttribute` op | 값(제네릭 또는 정적 타입 패밀리) | 해시부 키 | **quad-base**(키+Handler) / 엔진 op만 백엔드 |
| `Tag(...)` | 주입된 `addTag`/`removeTag` op | 값 객체 | 배열부 | quad-base / 엔진 op만 백엔드 |
| `OnChange(name, fn)` | `GetPropertyChangedSignal(name)` | 디스크립터 값 — 콜백 타입 검증·추론(생성 `OnChangeFn`) | 배열부 | quad-roblox(`Handlers/OnChange.luau`) |

`AttributeKey`만 해시부 키로 남는다(값 세팅이라 `key = value`가 자연스럽다) —
그 키의 strict 타이핑 사각은 **[2026-09-03 확정]** `H10-12`/`H10-15`로 닫혔다 — `AttributeKey(name)`는 무타입 프리미티브로 두고 타입은 배열부 슈가(`StringAttribute(name, value)`류)가 진다(`attribute-plan.md` 머리 배너).
