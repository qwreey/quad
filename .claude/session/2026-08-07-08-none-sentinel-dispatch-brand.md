<!-- quad-v2 세션 로그 원문 — CLAUDE.md에서 이전됨(2026-08-11 정리 세션). -->
<!-- 이 파일은 quadnomicon 개발로그 소재용 원자료로, 당시 시행착오(정정 전 서술 포함)를 그대로 보존함. -->
<!-- 현재 유효한 설계는 이 파일이 아니라 base//research//archive/가 최종 소스 — 이 파일 안의 판단이 이후 세션에서 뒤집혔을 수 있음. -->

## 2026-08-07 여덟 번째 세션 — `None` 센티널 확정(인라인 필드 지우기), `NoneHandler`가 Tween store-bind와 같은 재귀 재디스패치임을 확인

세 번째 세션에서 "미확정"으로 메모만 남겨뒀던 `None` 센티널
(`{ Override = nil, mod }`처럼 인라인 키로 modifier 값을 명시적으로
지우고 싶어도 Lua 테이블의 `키 = nil`이 "키 없음"과 구별 안 되는 문제)을
사용자가 "이거 결정할 게 진짜 있냐"고 다시 제기해 라이브로 짧게 논의,
확정까지 감. 전부 `base/modifier-plan.md`(2-1번)/`base/bind-system-plan.md`
(신규 절)/`base/ui-shorthand-plan.md`(신규 절)에 반영 완료:

- **merge/setter 쪽은 아무것도 안 바뀜** — `None`은 raw 저장 계층의 그냥
  평범한 실재값이라, 기존 merge 규칙("인라인 키 존재 시 무조건 우선",
  `Override`의 "뒤 인자가 필드 단위로 이김")이 손댈 것 없이 그대로 작동함.
  처음엔 "merge 시점에 키를 지운다"는 새 분기가 필요하다고 잘못 생각했다가,
  "값을 표현만 할 수 있으면 기존 규칙이 이미 다 해줌"이라는 걸로 정정.
  인라인 props 테이블 키(`{ TextColor3 = None, mod }`)와 Modifier setter
  인자(`mod:TextColor3(None)`) 둘 다 지원 — 메커니즘이 완전히 같아 구현
  비용 거의 0("어차피 무료로 얻어지는거 아님?" — 사용자), 후자 덕에
  "특정 필드만 지우는 재사용 가능한 modifier 조각" 패턴도 공짜로 됨.
  `:Peek()` 반환 타입도 `T | State<T> | None | nil`로 확장(raw 계층에서
  `None`을 있는 그대로 돌려줌 — Peek은 확정 안 하고 그대로 넘긴다는 기존
  9번 절 원칙 그대로).
- **실제 "지우기"는 디스패치 단계에서, 새 메커니즘 없이 풀림 — 핵심
  발견.** 처음엔 "우선순위 최상단에서 값을 그냥 nop 처리"로 생각했다가,
  사용자가 "그럼 process에 특수 로직이 들어간다"고 지적하며 더 나은 안을
  직접 제시: `NoneHandler`라는 평범한 pluggable 핸들러 하나를 추가 —
  `isHandlable`이 `v == None`을 잡고, `process`가 `v`를 진짜 `nil`로 바꿔
  **`process(inst, k, nil)`을 재귀 호출**. 이게 바로 이미 확정돼 있던 Tween
  store-bind 핸들러(`bind-system-plan.md` "확정된 디스패치 모델" 절,
  `v`가 Store면 `realv`를 계산해 `process(inst,k,realv)`로 재귀)와
  **완전히 같은 패턴**이라는 걸 확인 — 새 아키텍처 개념이 하나도 안 늘어남.
  base 드라이버 자체(`process(inst,k,v) -> getHandler(inst,k,v).process(...)`)는
  `None`을 전혀 모르는 순수 제네릭 그대로 유지, 개별 프로퍼티/이벤트/UI
  shorthand 핸들러 시그니처도 `None`이 안 나옴(원래 있어야 했던 "`v`가
  `nil`인 경우" 처리를 재사용할 뿐).
- **`None`의 의미는 "리셋"이 아니라 "이 조합 단계에서 이 필드를 세팅
  안 함"** — 실제로 `v=nil`을 받은 핸들러가 뭘 할지는 핸들러마다 다름(일반
  프로퍼티는 사실상 그대로 두는 것과 다름없고, UICorner 숏핸드처럼 실제
  Instance를 만들어 붙이는 핸들러는 그 자식을 지움). 구체 사례로
  `ui-shorthand-plan.md`에 UICorner 절 신설 — `process(inst,k,nil)`이
  만들어둔 `_quad_corner`류 자식을 직접 지움(이건 `retract`가 아니라
  `process` 자신의 로직 — `retract`는 "다른 핸들러가 키를 넘겨받는" 별개
  시나리오 전용, 이미 확정돼 있던 원칙 재확인), 값이 자주 `nil`↔숫자로
  토글되면 생성/제거 비용이 매번 든다는 캐비엇도 명시.
- **M2(디스패치 엔진) 착수 시 확인할 것 하나 새로 생김** — "이 키를 지금
  누가 담당 중인가" bookkeeping이 바깥 순회 루프가 아니라 `process` 호출
  자체 내부에서 갱신돼야 함. 안 그러면 값이 계속 `None`으로 유지되는 매
  사이클마다 "1차 매치는 `NoneHandler`, 재귀 호출 뒤 실제 담당은 다른
  핸들러"로 바깥 루프가 오판해 불필요한 `retract`가 반복 호출될 위험 —
  `ROADMAP.md` M2에 반영, `pre-implementation-audit.md`의 "이전 매치
  핸들러 추적" 항목과 같은 부류라 새 우선순위 등급 없이 거기 흡수.

**부수 정리**: `question.md`에서 "미확정"이던 `None` 항목을 해소로
제거하고, 이름 자체(`None`/`NoneHandler`)만 다른 가칭들과 같이 용어
정리 대상(3순위)으로 새로 추가. `ROADMAP.md` M7 체크박스를 "확정 완료"로
갱신.

**같은 세션 후속 — `Dispatch` 함수 네이밍 정리, `canExecute` 시그니처 정정,
Tag/Attribute 전용 문서 신설.** None 논의를 파고들다 디스패치 엔진 자체의
용어가 여러 군데서 흔들리고 있다는 게 드러나 바로 이어서 정리함. 전부
`base/bind-system-plan.md`/`base/lifecycle-pattern.md`/`base/tag-plan.md`
(신규)/`base/attribute-plan.md`(신규)/`ROADMAP.md`에 반영 완료:

- **제 실수 정정 — `canExecute`와 `isHandlable`은 다른 개념** (전체 경위는
  `archive/agent-mistake.md` 1번으로 옮김) — 결론만: `NoneHandler`가
  구현해야 하는 건 `isHandlable`이지 `canExecute`가 아님.
- **`Dispatch.getHandler`/`Dispatch.process`/`Dispatch.addHandler`/
  `Dispatch.drive`로 이름 공식화.** 원래 "확정된 디스패치 모델" 절은
  "스캔+실행"과 "매치된 핸들러 자신의 처리"를 둘 다 그냥 `process`라고
  불러 이름이 겹쳤던 게 혼동의 원인이었음 — `Dispatch.getHandler(inst,k,v):
  Handler?`(순수 스캔)와 `Dispatch.process(inst,k,v)`(오케스트레이터:
  getHandler → 이전 담당자 다르면 그 `retract` → 새 핸들러의 `.process`)로
  분리, Handler 자신의 필드는 계속 `process`/`retract`(이미 확정된 이름,
  재검토 대상 아님) — 겹침은 소유자 표기(`Dispatch.process` vs
  `handler.process`)로 해소, 새 이름 발명 안 함. **`Dispatch.addHandler(handler)`**
  도 신설 — concrete Handler를 우선순위 레지스트리에 등록하는 것도
  결국 quad-roblox가 `BaseModule`을 뮤테이션하는 시점에 해줘야 하는
  일이라(기존 "base 유틸은 인터페이스, 백엔드가 주입" 패턴과 같은 모양).
  **배열→해시 두 패스 순회 드라이버 자신은 `Dispatch.drive(inst,
  flattened)`로 확정** — 문서가 이미 이걸 비공식적으로 "base 디스패치
  드라이버"라 불러왔던 걸 그대로 동사화(`apply`는 기각 — "Dispatch를
  뮤테이션해서 결과를 낸다"는 어감이라 안 맞는다는 사용자 판단).
- **`canExecute` 시그니처 정정: `(handle) -> boolean`, zero-arg 아님.**
  `lifecycle-pattern.md`가 원래 `canExecute: () -> boolean`(바인딩마다
  클로즈오버된 람다)으로 적어뒀던 걸 정정 — 그러면 등록마다 클로저를
  새로 만들어야 해서 "base는 인터페이스만, quad-roblox가 `BaseModule`
  뮤테이션으로 실 구현 주입"이라는 이미 확정된 패턴과 안 맞음. 공유
  함수 하나가 되려면 "어떤 등록을 볼지" 가리키는 인자가 필요 —
  `canExecute(handle: LifetimeHandle): boolean`으로 확정. **quad-roblox
  구현 스케치(참고용, base 결정 아님)**: rbvm 패턴 재사용 — Instance당
  weak-keyed per-instance 저장소에 "gchold" 배열을 두고, 절대 발화 안
  하는 신호에 연결한 Connection의 콜백 클로저 안에 살려두고 싶은
  Observer를 업밸류로 캡쳐(콜백은 안 불려도 클로저의 업밸류는 안 죽음,
  `inst`가 GC되면 gchold 배열째로 같이 죽음). `canExecute(handle)`은 이
  Connection(류)의 `.Connected`를 확인. **미확인 세부사항으로 남긴 것**:
  Observer→Connection 역참조를 별도 weak 릴레이션으로 둘지 그냥 Observer
  테이블 안 평범한 필드로 넣을지(정적 해싱 필드 접근이 더 쌀 수 있음) —
  quad-roblox 구현 단계에서 실측 필요.
- **`Tag`/`Attribute`도 UICorner/Tween처럼 전용 문서가 있어야 한다는
  지적 — 맞아서 `base/tag-plan.md`/`base/attribute-plan.md` 신설.**
  둘 다 이미 `architecture.md`/`ROADMAP.md` M10에 파일로는 계획돼
  있었지만 "1 프리미티브 1 파일" 관례(Blocker/Effect/Ref/PreRef 분리
  선례)를 따르는 전용 설계 문서가 없었음 — 흩어져 있던 내용(Attribute의
  타입 파라미터화 논의 등)을 모으고, 오늘 확정된 `None`/`process`/
  `retract` 동작을 반영. **핵심 발견**: Tag/Attribute 둘 다 UICorner
  숏핸드와 같은 패턴(값이 뭐든 항상 같은 핸들러가 계속 담당, 추가/제거를
  `process` 자신이 처리)이라 **retract가 필요 없음** — "확정된 디스패치
  모델" 절이 원래 Tag/Attribute를 retract 필요 예시로 들었던 게 잘못이었음,
  바로잡고 "retract가 의미 있는 유일한 패턴은 매치되는 핸들러 *타입*
  자체가 사이클마다 바뀌는 경우(Tween↔일반 프로퍼티가 실사례)"로 좁힘.
  Attribute는 특히 깔끔한 사례 — Roblox `SetAttribute(name, nil)` 자체가
  네이티브하게 "지움"이라 `None→nil` 재디스패치가 특별 처리 없이 그대로
  맞아떨어짐.
- `.claude/README.md`에 두 신규 문서 반영, `ROADMAP.md` M2/M10 체크박스
  갱신(`Dispatch` 4개 함수, `canExecute` 시그니처, Tag/Attribute 문서
  참조).

**같은 세션 세 번째 후속 — `canExecute` 옵션 하나 더 검토 후 확정 유지,
`Brand` 통합 판별 메커니즘 신설(`isState`를 10종으로 일반화), `isHandlable`도
`inst`를 받도록 정정.** 전부 `base/bind-system-plan.md`(`Brand` 절, 핸들러
계약 절)/`base/modifier-plan.md`/`ROADMAP.md`/`question.md`에 반영 완료:

- **`canExecute`를 "각 핸들 타입이 직접 구현"(`Observer.canExecute`)할지
  "공유 함수"(`canExecute(any)->boolean`)로 할지 재확인 — 공유 함수 유지,
  솔직한 이유까지 명시.** `Observer` 자체는 quad-base 레벨(엔진 무관)
  타입인데 liveness 체크(Connection 기반)는 본질적으로 엔진 종속적이라,
  `Observer.canExecute`가 직접 구현하면 base/roblox 분리 원칙이 깨지거나
  결국 내부적으로 공유 함수를 다시 호출하는 얇은 래퍼가 될 뿐 — 어느
  쪽이든 공유 함수 쪽이 낫다는 결론 재확인(추가 논의 없이 유지).
- **`Brand` 신설 — `isState`(다섯 번째 세션)를 quad의 다른 branded 타입
  전부(`Observer`/`Effect`/`Tag`/`Attribute`/`Tween`/`Blocker`/`Store`/
  `Source`/`Slot`)로 일반화.** 공유 weak-key 레지스트리 하나(`Brand.set`/
  `Brand.get`) + **문자열이 아니라 테이블 아이덴티티를 태그로 사용**
  (사용자 제안 — Luau 인터닝 문자열도 이미 O(1) 포인터 비교라 성능 차는
  없지만, 오타 안전성이 실질 이득: 잘못된 변수 참조는 즉시 드러나지만
  오타난 문자열 리터럴은 조용히 어긋남). `isX`는 `Brand`를 감싼 얇은
  wrapper — 단순 항등(`isObserver`)과 집합 멤버십이 필요한 경우(`isState`
  = `{State,Source}`)로 갈림. **`None`만 예외 — 싱글턴이라 레지스트리
  없이 `x == None` 항등 비교가 더 싸고 정확**, 대신 `Brand.get`이 범용
  introspection 창구(quad-debug 용도) 역할까지 겸하도록 `None`을 특수
  분기로 앞단에서 걸러줌 — `isNone`이 그 분기의 실제 구현체.
- **정정 — `isSource`는 별도로 필요함, 다섯 번째 세션의 "불필요" 서술을
  뒤집음** (전체 경위는 `archive/agent-mistake.md` 2번으로 옮김) — 결론만:
  `isSource`를 별도 제공, `isState`는 여전히 `{State,Source}` 둘 다 통과.
- **Luau 타입 narrowing은 자동으로 안 됨 — 사용자가 직접 확인, 명시적
  `::` 캐스팅 필요.** `isX(v)`가 참이어도 Luau가 TypeScript의 `x is T`
  같은 사용자 정의 타입 가드를 지원 안 해서 `v`의 정적 타입을 자동으로
  안 좁혀줌 — `if isState(v) then local s = v :: State<any> ... end`처럼
  런타임 검증 뒤 명시적 캐스팅이 실제 패턴. 여전히 duck-typing보다 훨씬
  안전하니 가치는 있지만 자동 narrowing을 기대하면 안 됨.
- **`isHandlable`도 `inst`를 받도록 확정 — `(inst,key,value): boolean`,
  원래 `(key,value)`였던 걸 정정.** `process`/`retract`는 처음부터
  `inst`를 항상 받았는데(핸들러 계약 원 원칙) `isHandlable`만 예외였던
  게 애초에 약간의 불일치 — 지금 당장 `inst`로 매치가 갈리는 케이스는
  없지만, 나중에 필요해지면 핸들러 계약 자체를 깨는 breaking change가
  되므로 지금 넣어두는 게 훨씬 쌈. `Dispatch.getHandler`가 스캔 중
  `handler.isHandlable(inst,k,v)`로 호출하도록 갱신.
- `ROADMAP.md` M2에 `Brand.luau` 체크박스 신설, `Handler.luau`/M7의
  `isState` 항목 갱신. `question.md`에 `Brand` 이름(용어 정리 대상,
  "OOP 클래스명을 얻는 느낌"에 맞는 더 나은 이름 필요 — `Tag`는 이미
  quad-roblox에서 다른 뜻으로 쓰여서 충돌) 반영.

**다음 세션이 할 일**: 안 바뀜(`ROADMAP.md` M0부터) — 이번 세션도 순수
설계 확정이라 M0 착수 우선순위 자체는 그대로.

