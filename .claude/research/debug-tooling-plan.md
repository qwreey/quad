# quad-debug — 런타임 디버깅/역추적 도구 계획

**상태**: research — 착수 전, 사용자와 계속 논의 필요. 사용자가 "quad 개발이
어느 정도 끝날 때까지는 실제 구현에 못 들어갈 것"이라고 스스로 판단한 후순위
항목이지만, **base 설계(디스패치 엔진/Source/`D` 생성자) 시점에 훅 확장
지점만 미리 고려해두면 나중에 훨씬 싸게 먹힌다**는 문제의식으로 지금 미리
정리해둠. `ROADMAP.md` 백로그 항목("범용 렌더 디버깅 도구로서의 quad-mock")과
목적이 다름 — 아래 "quad-mock 백로그와의 관계" 절 참고.

**2026-08-06 세션 결론(핸드오버 요약)**: 설계를 막던 유일한 기술적 불확실성
(플러그인이 Play 중인 게임과 실시간으로 통신 가능한가)이 사용자의 Studio
실측으로 **해소됨** — `BindableEvent`/`BindableFunction` 둘 다 Plugin↔Play
클라이언트 경계를 넘는다(아래 "데이터 채널" 절). 이후 그 위에서 채널 위치
(quad 모듈 내부+CollectionService 태그), 페이로드 제약(순수 직렬화 값만),
UUID 기반 on-demand compute, Element Inspector, flash 범위 축소까지
설계가 한 라운드 더 수렴함(아래 "핵심 설계 방향" 7/8번, React DevTools
절 4번). **[2026-08-06 기준] 남은 건 세부 API 이름과 구현 착수뿐** —
남은 열린 질문은 전부 후순위/백로그 표시된 것들, 다음 세션에서 뭔가
막혀있지 않음.

## 배경 — 팀원 피드백 원문 요지

Roblox 안의 대부분 렌더러는 "뭐가 어디서 어떻게 렌더링됐는지" 알기 힘들다.
react-lua는 방법이 있긴 하지만 쓰기 어렵고, Studio 안에서 플러그인처럼 바로
볼 수 있으면 좋겠다는 요청. 구체적으로 원하는 것:

- **실물 Frame → 생성한 코드 위치 역추적** (제일 핵심 요청)
- Explorer에서 선택한 인스턴스로부터 코드 위치를 보여주는 플러그인, 또는
  플러그인 자체 트리뷰
- 어떤 프로퍼티가 어떤 파이프(Store/State 체인)에 연결됐는지, 파이프라인이
  어떻게 생겼는지 UI로 확인
- 웹 devtools처럼 변경된 부분을 반짝이게(flash) 보여주기
- 생성된 Source/Store 목록을 스크립트별로 보여주기

스토리북(`ui-labs`, `architecture.md` 9번 항목으로 이미 대체 확정된 것)과는
다른 문제라는 점을 사용자가 명시적으로 구분함 — 스토리북은 컴포넌트 단위
격리 테스트, 이건 **인게임 전체를 실행한 상태에서** 발생하는 실제 버그를
찾는 용도. 실사용 인게임 버그는 이 방식이 훨씬 찾기 쉽다는 게 사용자 판단.

## 스코프 확정 (사용자 확인)

**1차 설계는 클라이언트 UI 한정.** quad는 거의 항상 LocalScript/클라이언트
UI를 다루므로, 1차 통신 채널은 "플러그인 ↔ 같은 머신의 로컬 클라이언트"
BindableEvent 채널로 한정. 서버에서 생성되는 인스턴스(팀 테스트/멀티플레이
시나리오, RemoteEvent 필요)까지 다루는 건 실제 필요성이 확인되면 그때 확장 —
지금 설계를 막지 않음.

## 리서치 결과 요약

서브에이전트로 `.claude/initreq/` 전체(quad v1, fusion, vide, rbvm, tbox,
quad2-try, artworks)를 조사, 일반 지식으로 Roblox 엔진 제약도 확인:

1. **참고할 기존 구현체가 없음** — react-lua/roact devtools 소스 자체가 이
   레포에 없음(react-lua가 애초에 이 프로젝트의 참고 레포 목록에 없음).
   `quad2-try/out/quad-debug/`라는 빈 디렉토리가 이미 예약되어 있었으나
   파일 0개 — 이전 시도도 손댄 적 없는 영역. v1에도 재사용할 인프라 없음
   (`customWarn.lua` 정도, `debug.traceback` 출력만 하는 3줄).
2. **에러 발생 시점 스냅샷 방식은 있지만 상시 레지스트리는 없음** — Vide
   (`src/graph.luau`)와 Fusion(`src/Logging/parseError.luau`)은 둘 다
   `xpcall`+`debug.traceback`/`debug.info`로 **에러 나는 순간에만** 스택을
   찍음. Instance→생성 위치를 항상 기록해두는 상시 레지스트리를 유지하는
   선례는 없음 — quad-debug가 여기까지 해낸다면 차별점.
3. **Roblox Luau의 `debug` 라이브러리는 제한적** — 표준 Lua/LuaJIT에 있는
   `debug.sethook`(라인/콜 단위 훅), `debug.getlocal`/`setlocal`/
   `getupvalue`/`setupvalue`가 Roblox엔 없음(보안/성능 이유로 제거).
   `debug.info`/`debug.traceback`/`debug.profilebegin`류만 노출. **즉 엔진이
   공짜로 주는 동적 트레이싱 방법은 없고, quad 코드 안에 직접 계측을 심는
   것 외엔 방법이 없음** — 사용자가 우려한 그대로 확인됨.
4. **"no-op 기본값 → 나중에 실제 구현으로 교체" 패턴의 실사용 선례 발견** —
   Fusion `src/External.luau`가 정확히 이 모양: 모듈 상단 upvalue
   `currentProvider: ExternalProvider? = nil`을 두고
   `External.setExternalProvider(newProvider)`(31행)로 통째로 교체, 소비
   함수(`logWarn` 등)는 매 호출 시 `if currentProvider then ... end`로만
   분기(101행). `RobloxExternal.luau:51`의 `RobloxExternal.logWarn = warn`도
   같은 기법의 정적 버전. **quad가 이미 쓰기로 확정한 패턴(base는 인터페이스,
   구현은 팩토리가 나중에 주입 — `RobloxFactory` 등)과 정확히 같은 모양** —
   새로 발명할 필요 없이 기존 설계 원칙을 트레이싱에도 그대로 적용하면 됨.
5. **프로덕션에서 완전 제거하고 싶다면**(당장 필요한 결정 아님) darklua의
   전역 값 주입(`inject_global_value`) + dead-branch 제거, 또는 Rojo
   `project.json`을 릴리즈용으로 따로 둬 디버그 전용 파일 자체를 트리에서
   빼는 방법이 있음 — 일반 지식 수준으로만 확인, 실제 필요해지면 재조사.
6. **플러그인과 실행 중인 게임은 별도 Luau VM(별도 보안 컨텍스트)** —
   `_G`/`shared`가 공유되지 않음. `require()`는 공식 문서(creator-docs
   `scripting/module.md`)로 "클라이언트-서버 경계를 넘어 같은 ModuleScript를
   require하면 각 쪽이 **독립적인 참조**를 받는다"가 확인됨 — 플러그인
   경계에도 같은 메커니즘(별도 require 캐시)이 적용될 가능성이 높으나 공식
   문서가 플러그인 케이스를 명시하진 않음. 따라서 플러그인이 게임 내부의
   Store/Source 레지스트리에 직접 접근하는 경로는 없다고 봐야 함.
   - **정정 이력(2026-08-06)**: 이전 초안이 `BindableEvent` 브릿지를
     "차별점"으로 단정했던 건 근거 부족이었음(공식 문서는 플러그인 언급
     없음, DevForum엔 실패 사례도 있었음) — 이후 사용자가 Studio에서 직접
     실측해 **BindableEvent Fire/Connect가 Plugin↔Play 중 클라이언트
     경계를 실제로 넘는다는 걸 확인**(아래 "데이터 채널" 절 5번 참고).
     핵심 원인 추정("react-lua devtools가 쓰기 어렵다")은 여전히 "게임
     쪽에 브릿지를 미리 심어야 하는 설정 부담" 쪽으로 유지 가능해짐 —
     채널 자체는 되는 게 확인됐으므로.

## 핵심 설계 방향

### 1. "존재하는 State 목록"이 아니라 "무엇이 무엇에 연결됐는가" — 사용자 확정

`base/store-plan.md`에 이미 있듯 State는 `store.key`로 접근할 때마다
매번 새로 만들어지는 ephemeral 캐시 핸들이라 "지금 존재하는 State 목록"이라는
개념 자체가 성립하지 않음. **사용자가 이 논의 중 직접 정정**: 값 목록을
보여주는 대신, Frame을 선택했을 때 "어디에 어떻게 훅이 연결돼 있는지", "이
Compute 함수가 어디서 생성됐는지"를 보여주는 **연결 그래프** 중심으로 UX를
잡는 게 맞음. 이건 quad 온톨로지와도 자연히 맞아떨어짐 — 열거해야 할 진짜
실체는 State가 아니라 **Source**(Store가 소유하는 유일한 진짜 값 지점)와
**디스패치 이력**(무엇이 언제 어떤 값으로 `process`됐는가) 둘뿐. 파이프라인
그래프는 이 디스패치 이력을 재구성해서 보여주는 것.

### 2. 계측 지점 3곳 — no-op 훅 upvalue, Fusion `External.luau` 패턴 재사용

사용자가 요청한 "빈 함수 만들어두고 나중에 트레이스 뽑는 동적 계측"을
그대로 적용. `if DEBUG then` 분기를 코드 전체에 뿌리지 않고, 아래 세 지점에
**모듈 upvalue 형태의 no-op 기본 훅**만 심어두면 됨(위 리서치 4번 패턴):

- **`Dispatch/init.luau`의 `process`/`retract` 스캔 루프** — 어차피 매
  호출마다 우선순위 스캔이 도는 지점이라, 여기에 훅 호출 1개(no-op이면
  사실상 함수 호출 오버헤드뿐, 무시 가능 수준) 추가. `(inst, k, v, handler,
  timestamp)`를 훅에 넘기면 "무엇이 무엇을 바꿨는가" 이력의 원천이 됨.
- **`Source.luau` 생성자** — Source 인스턴스를 weak-keyed 전역 레지스트리에
  등록하는 훅(기본 no-op). 켜졌을 때만 이 레지스트리가 존재하므로 GC-native
  원칙(`lifecycle-pattern.md`)과 충돌 없음 — 꺼져 있으면 레지스트리 자체가
  안 만들어짐.
- **quad-roblox `D/init.luau`의 제네릭 생성자(`New(className)`)** — 인스턴스
  생성 순간 `debug.info(2, "sl")`로 caller의 script+line을 얻어 기록하는
  훅(기본 no-op). Instance 생성은 프로퍼티 변경보다 훨씬 드물게 일어나므로
  (렌더 타임 1회), 여기서만 비교적 비싼 `debug.info` 호출을 해도 부담 적음.

이 세 곳 모두 "인터페이스는 base가 정의, 실 구현은 quad-debug가 나중에
주입"하는 기존 확정 원칙(`bind-system-plan.md` "base 유틸은 인터페이스,
실제 구현은 백엔드 팩토리가 주입")과 완전히 같은 모양 — quad-debug를 위해
새 아키텍처 패턴을 만드는 게 아니라 기존 패턴을 재사용하는 것뿐.

### 3. 표준 디버그 인터페이스 — 핸들러가 선택적으로 구현하는 5번째 훅 (사용자 제안)

사용자 제안: "트윈이 뭐 땜에 일어나냐, quad 땜인지 아님 Ref로 밖에 나가진
instance로 직접 트윈되어버리는지" 같은 걸 구분하고 싶음. 이건 디스패치
이력만으론 부족함 — quad가 만든 Tween과 사용자 코드가 `Ref`로 얻은 raw
Instance에 직접 `TweenService:Create()`를 건 것을 구분하려면 **핸들러 자신만
아는 맥락**이 필요.

**제안**: `isHandlable`/`priority`/`process` 3종 계약(2026-08-13 다섯 번째
세션에 `retract`가 `process` 반환값으로 합쳐지기 전엔 4종)에 선택적
훅 하나를 추가 — `describe(inst, k, v): DebugInfo?`(가칭, 기본 미구현
= no-op과 동일 효과). quad-debug가 트레이스 이벤트를 기록할 때 해당 키를
처리한 핸들러에게 `describe`가 있으면 호출해서 사람이 읽을 수 있는 부가
정보(예: Tween 핸들러라면 "store-bind 유발" vs "직접 세팅"인지, 어떤 store
key에서 왔는지)를 이벤트에 덧붙임. `bind-system-plan.md`가 이미 "계약은
지금 확정이지만 실제 구현하며 부족한 지점이 보이면 그때 hook 추가(점진적
확장)"라고 열어둔 것과 정확히 맞아떨어지는 케이스 — 새 원칙이 아니라 이미
예견된 확장.

### 4. 외부 변경 감지 — 보조 신호일 뿐, 핵심 채널로 쓸 수 없음(사용자 정정)

위 3번의 한계: quad가 전혀 모르는 코드 경로(Ref로 얻은 raw Instance에 대한
직접 조작)는 애초에 `process()`를 거치지 않으므로 quad-debug의 계측
지점으로는 절대 안 잡힘. 처음 검토했던 방법: quad가 관리하는 인스턴스에
대해 `inst:GetPropertyChangedSignal(prop)`(Roblox 엔진 자체가 모든
인스턴스에 제공하는 범용 시그널)을 구독해두고, 변경 시점을 직전 quad
디스패치 이력과 타임스탬프로 대조해 "일치하는 트레이스가 없으면 외부
변경"으로 표시하는 아이디어.

**사용자 정정(2026-08-06)**: 이건 quad-debug의 핵심 가치와 맞지 않음 —
"이 프로퍼티가 바뀌었다"는 사실 자체는 `PropertyChangedSignal`로 누구나
알 수 있고, quad-debug가 진짜 필요한 이유는 **그 변경이 quad의 어떤
Store/파이프라인/handler에서 왔는지, 코드 몇 번째 줄에서 유발됐는지**를
보여주는 것 — 순수 관찰(passive observation)만으로는 "무엇이 바뀌었다"만
알 수 있을 뿐 "왜/어디서"는 증발함. **결론: `PropertyChangedSignal` 기반
교차검증은 (실제로 크로스 컨텍스트에서 작동한다는 전제하에도) 기껏해야
"quad가 설명 못 하는 변경이 있었다"는 보조 신호 정도이지, 핵심 트레이스
채널의 대체재가 될 수 없음.** 핵심 채널(어디서/왜)은 여전히 능동적 계측
(위 2번, 3번의 훅)에서 나와야 함 — 그 계측 데이터를 플러그인까지 실제로
전달할 수 있는지는 실측으로 확인됨(아래 "데이터 채널" 절), 이 항목
자체는 채택하더라도 어디까지나 보조 기능으로만 남음(백로그, 아래 "열린
질문" 참고).

### 5. 데이터 채널 — Attribute(스냅샷) + BindableEvent(스트림), **BindableEvent 크로스 컨텍스트 확인 완료**

**상태(2026-08-06): 사용자가 Studio에서 실측 검증 완료 — BindableEvent가
Plugin↔Play 중인 클라이언트(LocalScript) 경계를 실제로 넘는다.**
`plugin-ignoreme.luau`(Explorer에서 선택한 BindableEvent에 Connect)와
`game-ignoreme.luau`(2초마다 반복 Fire)로 테스트한 결과, Fire와 플러그인
수신이 거의 동일한 타임스탬프로 반복 확인됨(`14:10:42.243` Fire /
`14:10:42.243` Plugin 수신 등, 여러 사이클에 걸쳐 안정적).

**사용자가 정리한 이유**: Play 모드에 들어가도 플러그인이 다루는 `game`은
edit 모드와 **별도로 복제된 DataModel이 아니라 같은 DataModel**이고(Play
진입 시 "복사된 컨텍스트"라 부른 건 script identity/보안 컨텍스트가
다르다는 뜻이지 Instance 자체가 별도 메모리에 복제된다는 뜻이 아니었음),
Roblox Luau 샌드박스가 분리하는 건 **스레드/스크립트 컨텍스트**뿐이고
그 밑의 C++ 구현 userdata(Instance 자체)는 어느 컨텍스트에서 접근하든
같은 참조를 가리킴 — 그래서 Instance 기반 메커니즘(시그널 Connect/Fire
포함)이 자연스럽게 경계를 넘어 작동함. `require()`가 컨텍스트별로 독립
모듈 인스턴스를 주는 것(이전 확인 사항)과는 완전히 다른 층위 — 그건
Lua 모듈 캐시가 컨텍스트별로 분리된다는 것이지 Instance 자체가
분리된다는 뜻이 아니었음, 이번 실측으로 그 구분이 명확해짐.

**`BindableFunction`(요청-응답)도 확인 완료**: `Invoke`→`OnInvoke` 실행→
리턴값 수신까지 왕복이 여러 사이클에 걸쳐 안정적으로 동작(`ok=true,
"plugin-received"`). 이걸로 위 "React DevTools에서 가져올 아이디어" 3번의
"기본은 얇은 스트림(BindableEvent), 상세는 on-demand 요청-응답
(BindableFunction)" 구조가 양쪽 다 실측 검증됨.

**설계 제약으로 반영할 관측(사용자 지적)**: 같은 스크립트 컨텍스트 안에서
`BindableEvent`/`Function`은 원래 인자를 직렬화 없이 레퍼런스 그대로
넘기는 게 문서화된 특징(RemoteEvent와 달리 함수/메타테이블도 그대로
통과 가능)인데, **플러그인 경계를 넘을 때는 RemoteEvent와 비슷하게
내부적으로 마샬링(직렬화/역직렬화)되는 것으로 보임** — 실측으로 함수
자체를 못 넘겨본 건 아니지만(테스트는 단순 값만 사용), Instance/Plugin
간 별도 Luau VM 경계라는 점을 고려하면 합리적인 추정. **결론**:
trace 이벤트 페이로드는 처음부터 함수/클로저 없이 **순수 직렬화 가능한
값(숫자/문자열/불리언/plain 테이블/Instance 참조)만** 담는다는 원칙으로
설계 — 애초에 "State를 그대로 넘기고 플러그인이 나중에 `.Get()`한다"류의
설계는 안 되고(State는 클로저를 담은 객체라 직렬화 불가능할 가능성이
높음), 넘길 값은 항상 quad-debug가 미리 원시 값으로 변환해서 보내야 함.

**남은 미확인 범위**: 이번 테스트는 (a) 같은 로컬 머신의 Play/Play Solo
클라이언트 컨텍스트, (b) 원시 값 인자만 확인함. 서버 컨텍스트나 복잡한
중첩 테이블/Instance 배열 전달까지는 실제 구현 단계에서 재확인 권장 —
단, 1차 스코프(클라이언트 한정, 원시 값 위주 trace 이벤트)에서는 이번
검증만으로 채널 자체의 실현 가능성은 확정됐다고 봐도 됨.

- **Attribute**: 인스턴스 생성 시점 1회성 정보(생성 위치, "quad가 관리하는
  인스턴스인가" 마커)에 적합 — DataModel 자체의 일부라 플러그인과 게임이
  별도 Luau VM이어도 문제없이 공유됨(Selection 서비스로 바로 읽힘). 단점:
  문자열 크기 제약, 그리고 배포된 게임에 실수로 남으면 유저가 F9 콘솔이나
  Explorer로 내부 코드 경로를 볼 수 있는 정보 노출 위험 — `RunService:IsStudio()`
  가드가 필수(quad-debug require 자체가 옵트인이라는 1차 방어선 + IsStudio가
  2차 방어선, 이중 게이팅).
- **Value 오브젝트(StringValue/ObjectValue 등)는 기각 — 사용자 확정**:
  Attribute의 대안으로 자식 Instance로 값을 담는 Value 오브젝트도 검토했으나,
  `:GetChildren()`을 호출하면 그대로 드러나 트리를 오염시킴(quad가 실제로
  마운트한 자식과 섞여버려 `base/slot-plan.md`의 자식 재조정 로직이나
  사용자 코드의 children 순회를 방해할 위험) — Attribute는 자식이 아니라
  메타데이터라 이 문제 자체가 없음. **스냅샷성 데이터는 Attribute로 확정,
  Value 오브젝트는 후보에서 제외.**
- **BindableEvent+BindableFunction(크로스 컨텍스트 확인 완료, 위치는
  재검토)**: "지금 이 순간 일어난 일" 스트림은 BindableEvent, 특정
  Instance 선택 시 상세 정보 요청-응답은 BindableFunction — 둘 다 실측
  확인됨(위 참고).
  - **`ReplicatedStorage` 자동 생성 방식은 기각** — 개발자가 의도하지
    않은 Instance를 게임 트리에 주입하는 부작용 때문(상세 경위는
    `archive/debug-channel-replicatedstorage-rejected.md`). 대신 Bindable을
    **quad 모듈 자신의 Instance 트리 안**(quad가 이미 설치돼 있는 위치
    그대로, 새 위치를 따로 안 만듦)에 두고, `CollectionService` 태그로
    노출 — 플러그인은 quad가 어디 설치됐는지 몰라도
    `CollectionService:GetTagged(tag)`로 바로 찾음(`GetDescendants()`로
    전체 트리를 훑어 필터링할 필요 없음). 태그를 모듈 자신에 달지
    Bindable 각각에 달지는 취향 차이 — **사용자 확정**("큰 차이는 없는
    엔지니어링 선택").
- **공통 원칙(사용자 확정)**: 어떤 채널이든 **debug를 안 켰을 땐 CPU/메모리
  영향이 사실상 없어야 함**(패시브하게 가볍게만 들고 있거나, 아예 아무것도
  안 함) — 무거운 트레이스 함수 실행은 debug를 켠 다음부터만. 이건 위
  "계측 지점 3곳"의 no-op 훅 upvalue 패턴과 정확히 같은 원칙의 재확인.

### 6. "관측해야 실체화된다" 원칙 — quad-debug 자신이 위반하면 안 됨

`base/source-state-plan.md`의 전역 원칙: 어떤 파생값도 `:Get()`으로 직접
읽히기 전까지 계산되지 않음. quad-debug UI가 트리뷰를 그리면서 모든 State를
자동으로 펼쳐 값을 미리 읽어버리면, 원래 필요 없었을 계산을 디버그 도구가
유발하는 부작용이 생김 — **디버그 도구 자체도 lazy해야 함**: 사용자가 UI에서
노드를 명시적으로 펼칠 때만 그 시점의 값을 읽고, 자동 폴링/자동 전개는
지양. 이건 UI 설계 시 지켜야 할 제약으로 문서화만 해두고 지금 확정할 필요는
없음.

### 7. UUID 기반 on-demand compute — "관측"을 플러그인 클릭으로 명시화

debug 모드가 켜지면 quad의 내부 객체(Source/State/handler 등)에 uuid를
부여해 trace 이벤트와 함께 플러그인에 넘김(위 "데이터 채널" 절의 페이로드
제약 — uuid 자체는 순수 문자열이라 문제없음). 플러그인 UI에서 특정
State 노드를 클릭하면 그 uuid로 `BindableFunction`을 통해 "지금 이 값을
계산해서 보여줘" 요청을 보내고, quad-debug-roblox가 해당 uuid에
대응하는 실제 State를 찾아 `.Get()`을 호출해 원시 값으로 변환해 돌려줌 —
**사용자 제안**, 위 "6. 관측해야 실체화된다" 원칙과 정확히 맞아떨어짐
(플러그인 클릭이 곧 명시적 관측 행위).

**안전 문서화 경고 필요(사용자 지적)**: 이 compute 호출은 여전히 부작용을
일으킬 수 있음 — `purity-and-effects-plan.md`가 이미 Store는 부작용
허용이 기본이라고 확정해뒀고, Compute 함수는 원래 "State가 최신 상태를
요구받는 시점"에만 실행되는 게 전제인데, 플러그인이 임의의 시점(사용자가
UI를 클릭한 순간)에 강제로 그 계산을 트리거하는 건 이 전제를 벗어남 —
당장 문제를 일으키진 않더라도, quad-debug 문서에는 "State를 눌러보는
행위 자체가 그 계산과 딸린 부작용을 실행시킨다"는 걸 명확히 경고해야 함.

**비직렬화 값의 표시**: 함수/클로저처럼 순수 직렬화 불가능한 값은
`print`류 다른 디버깅 도구들이 흔히 하듯 `"function"` 같은 플레이스홀더
라벨로 표시(루아 사이드에서 포인터 주소를 얻는 표준적 방법은 없어 보임,
필요하면 재조사). 다만 사용자가 직접 만든 복잡한 값(예: 커스텀 Tween류
객체)이 그냥 raw 테이블로만 보이면 알아보기 힘드므로, **개발자가 자기
타입에 대해 "디버거에 어떻게 보여줄지"를 지정할 수 있는 선택적 직렬화
인터페이스**를 제공하는 것도 검토할 만함(사용자 제안) — 단, 사용자가
강조한 대로 **오버엔지니어링 경계 주의 — 디버깅 도구는 한정된 규모에서
도움이 되는 게 목적이지 모든 걸 다 예쁘게 보여주는 게 목적이 아님**,
구현 비용/이점/타당성을 따져서 결정.

### 8. Element Inspector — 마우스로 UI 요소 피킹 (사용자의 실제 pain point)

사용자가 직접 겪은 문제: Roblox가 최근 Play 중 라이브 UI 편집 도구를
꺼버려서, 실제 화면에 보이는 UI 요소의 위치를 찾으려면 Explorer를 계속
펼치고 접으며 찾거나 검색해야 하는데, quad로 만든 요소는 보통 이름을
잘 안 지정해서 특히 힘듦. **웹 devtools의 "inspect element"처럼 화면을
클릭해서 바로 그 자리의 (quad가 관리하는) UI 요소를 선택하는 도구가
필요** — 최상위에 클릭을 가로채는 투명 레이어를 하나 띄우고 마우스
위치를 추적, 그 좌표에 있는 요소를 히트테스트해서 quad 요소로 필터링해
사용자에게 보여주는 방식. Explorer 기반 트리뷰(위 "핵심 설계 방향" 1번)를
보완하는 별도 진입점 — "무엇을 선택할지도 모르는 상태에서 화면만 보고
찾아 들어가야 하는" 초기 탐색 단계의 마찰을 없애는 게 목적. 사용자가
이번 논의에서 원래 요청("Explorer에서 코드 위치를 알려주는 플러그인")
보다 실제로는 더 크게 느낀 pain point로 언급.

### 9. Explorer ↔ 플러그인 트리 동기화, UI 아키텍처 확인 (2026-08-06)

**질문**: 플러그인 자체 트리에는 없는 내부 구현 디테일(예: 특수 핸들러가
자동 생성해 붙인 자식 Instance)을, 사용자가 Roblox 기본 Explorer에서
직접 선택하면 어떻게 처리할까?

**사용자 확정 — 두 경우로 분기**:
- 플러그인 트리에 대응 노드가 **없는** 내부 전용 자동 생성물(quad가
  bind/track하지 않고 그냥 만들어 붙여만 둔 것)이면, 플러그인 트리가
  실제로 알고 있는 가장 가까운 **부모**를 대신 선택/하이라이트.
- 플러그인 트리에 대응 노드가 **있는** 경우(예: 사용자가 어떤 Instance를
  직접 컴포넌트화해서 quad로 bind한 경우 — 이건 UB가 아니라 충분히 유효한
  사용법, `base/component-composition-plan.md`의 "컴포넌트 = 그냥 함수"
  원칙과도 맞음) 트리에 있는 그 실제 노드를 정확히 선택.

**네이밍 컨벤션(사용자 제안)**: 내부 자동 생성 helper Instance는 `_`나
`QUAD_` 같은 접두어를 붙여서 Explorer에서 직접 봤을 때 헷갈리지 않게 함 —
이름 바꾸는 건 비용이 크지 않음. v1이 이미 `_quad_round`/`_quad_padding`/
`_quad_scale` 네이밍(`base/ui-shorthand-plan.md` 참고)으로 정확히
이 관습을 썼던 전례 — quad-v2에서 내부 자동 생성물이 생기면 그대로
재사용. `research/documentation-plan.md`의 "UI 요소 네이밍 컨벤션 문서"
백로그에도 이 구체적 규칙을 추가해둠.

**플러그인 UI 아키텍처 확인(사용자 질문에 대한 답 — 맞음)**: 세 개의
구분된 상호작용면으로 구성됨 —
1. **자기 트리 뷰** — React DevTools 컴포넌트 트리처럼, 플러그인 자체
   `DockWidgetPluginGui` 안에 quad가 관리하는 계층을 보여줌(위 "핵심
   설계 방향" 1번, "무엇이 무엇에 연결됐는가" 그래프).
2. **리프 클릭 → 상세/상태 패널** — 노드(State 등)를 누르면 그 상세를
   on-demand로 보여줌(위 7번, UUID 기반 compute-on-click).
3. **실제 Instance 선택과의 연동** — Roblox 기본 Explorer에서 직접
   선택하거나(`Selection` 서비스로 감지, 위 이 절의 동기화 규칙), 또는
   Element Inspector(위 8번)로 화면을 클릭해서 선택하면, 그 실제
   Instance에 대응하는 노드가 1번의 자기 트리 뷰에서 하이라이트/선택됨.

Explorer(Studio 기본 창)와 플러그인의 트리 뷰(`DockWidgetPluginGui`)는
**서로 다른 별도 창** — 하나로 합쳐진 UI가 아니라 나란히 떠 있는 도킹
위젯 두 개고, 3번이 그 둘을 이어주는 동기화 레이어.

## React DevTools에서 가져올 아이디어 (2026-08-06 조사)

서브에이전트로 React DevTools 오픈소스(`facebook/react` 내
`react-devtools-shared` 등)를 조사. 그대로 베낄 순 없지만(브라우저
익스텐션 ↔ 웹페이지 구조는 Roblox와 다름) 4가지 발상 중 2개는 상당히
바로 적용 가능:

### 1. 전역 훅 주입(`__REACT_DEVTOOLS_GLOBAL_HOOK__`) — 참고는 되지만 그대로는 못 씀

익스텐션이 React 로드 *전에* `window.__REACT_DEVTOOLS_GLOBAL_HOOK__`을
먼저 심어두고, React 렌더러가 부팅하며 그걸 찾아 `hook.inject(...)`로
스스로 등록하는 "로드 순서 무관 레지스트리" 패턴 — Fusion `External.luau`의
"이미 로드된 모듈의 업밸류를 나중에 스왑"과는 다른 축(React 쪽은 "누가
먼저 로드되든 상관없게", Fusion 쪽은 "함수 포인터 교체"). quad-debug에도
개념은 유효하나, Roblox는 플러그인/게임이 애초에 별도 프로세스(VM)라
"전역"이 그 경계를 못 넘는다는 근본 제약이 있어 그대로 못 씀 — 이미 알고
있는 문제(위 "데이터 채널" 절)와 동일선상.

### 2. 소스 위치 캡처는 런타임 스택 트레이스가 아니라 **컴파일타임 주입** — 유력한 대안 후보

확인 결과 React DevTools의 "이 컴포넌트가 어디서 정의됐나"는 런타임
스택 트레이스에 전혀 의존하지 않음 — `@babel/plugin-transform-react-jsx-source`가
**빌드 타임에** 모든 JSX 생성 호출에 `__source: {fileName, lineNumber,
columnNumber}`를 리터럴로 박아 넣는 컴파일타임 트랜스폼. 런타임엔 이미
값으로 존재.

**quad-debug 적용 후보**: 위 "계측 지점 3곳"에서 제안한
`debug.info(2, "sl")` 런타임 캡처(`D` 제네릭 생성자, 호출 시점 caller
위치)의 대안/보완으로, **darklua** 같은 빌드타임 Luau 변환기로 quad
생성자 호출부를 순회하며 파일/라인 리터럴을 인자로 미리 주입하는 방식을
검토할 만함. `debug.info`가 "호출자(caller)의 정확한 라인"을 항상
안정적으로 못 주는 경우(꼬리 호출 최적화, 인라인화 등)에 특히 유용 —
런타임 계측보다 신뢰도가 높을 가능성. 단, **darklua를 빌드 파이프라인에
편입해야 한다는 전제가 새로 생기므로**(지금 프로젝트는 아직 별도
빌드/번들 단계가 없음, 순수 Rojo 싱크) 실제 채택은 quad-debug 착수
시점에 비용 대비 검토.

### 3. 얇은 operation diff + on-demand 상세조회 — 데이터 채널 설계에 바로 적용 가능

content script(페이지) ↔ devtools panel은 별도 프로세스라 매 커밋마다
전체 트리를 보내지 않음 — **압축된 "operation" 배열**(add/remove/reorder
같은 짧은 코드 시퀀스)만 기본으로 보내고, props/state 같은 무거운 데이터는
사용자가 실제로 그 노드를 선택했을 때만 별도 요청-응답(`inspectElement`)으로
가져옴. "기본은 얇은 델타, 상세는 온디맨드"라는 원칙.

**quad-debug 적용**: BindableEvent 크로스 컨텍스트 검증 결과와 무관하게
(되든 안 되든, 채널이 무엇이든) 이 원칙 자체는 그대로 채택할 만함 — 매
`process`/`retract` 호출마다 전체 상태를 흘려보내지 않고 "무슨 일이
있었다"는 최소 메타데이터(대상 id, key, handler id, timestamp)만 기본
스트림으로 보내고, 플러그인이 실제로 그 Instance를 선택했을 때만 상세
정보(생성 스택, props 스냅샷)를 별도로 가져오는 구조. 이러면 채널
대역폭/오버헤드 문제(위 "공통 원칙 — debug 꺼졌을 때 영향 없어야 함"과
직결)가 크게 완화됨.

### 4. flash-on-update 오버레이 — 전체 상시 적용은 기각, 범위를 좁혀 채택

원안: `getBoundingClientRect()`류(Roblox면 `AbsolutePosition`/
`AbsoluteSize`, 3D면 바운딩 박스)를 읽어 오버레이 박스를 그리고 매
커밋마다 갱신 — Studio 플러그인 오버레이(`Highlight`/`SelectionBox`/
`BoxHandleAdornment`)로 이식 가능한 아이디어 자체는 유효.

**사용자 정정(2026-08-06)**: 이걸 quad가 관리하는 **모든** Instance의
**모든** 프로퍼티 변경에 상시 적용하면 안 됨 — "정말 많은 것들이 다
반짝일 것"(노이즈)이고 추적 비용도 큼. 범위를 좁혀서 채택:

- **Instance 마운트/언마운트(생성/파괴)는 상시 flash 가능** — 사용자에게
  "뭔가 새로 생겼다/사라졌다"는 notice로 유용하고 빈도도 낮아 비용 문제
  없음.
- **개별 프로퍼티 변경 flash는 플러그인에서 현재 열어본(inspect 중인)
  Instance 한정** — 위 "핵심 설계 방향" 7/8번의 on-demand 상세조회
  패널을 연 상태에서만 그 Instance의 값 변경을 반짝이게 표시, 나머지는
  안 함. "얇은 스트림 + on-demand 상세"라는 이미 확정된 프로토콜 모양
  (아래 3번)과도 자연히 맞아떨어짐.
- **백로그(낮은 우선순위, 사용자 확정)**: 선택된 Instance에서 quad가
  건드리지 않은 프로퍼티 중 기본값이 아닌 것까지 같이 알려주는 기능 —
  "쉽다면 있으면 좋겠지만 엄청 중요하진 않다"는 평가, 초기 설계 시
  가능성 정도만 열어두고 실제 채택은 나중에.

## quad-mock 백로그와의 관계

`architecture.md`의 기존 백로그("범용 렌더 디버깅 도구로서의 quad-mock,
Tween mock 등 동적 동작 포함")와 목적이 다름:

| | quad-mock 확장판 (기존 백로그) | quad-debug (이 문서) |
|---|---|---|
| 실행 환경 | Studio 불필요, 순수 `luau` CLI, CI | Studio Play 세션, 실제 엔진 |
| 시점 | 오프라인 스냅샷/리플레이 | 실시간 라이브 관찰 |
| 목적 | 렌더 결과 회귀 검증 | 실사용 중 버그 위치 역추적 |

**공유 가능한 기반**: 둘 다 "quad 내부 이벤트(process/retract 호출, Source
변경)를 관찰 가능한 스트림으로 노출하는 계측 레이어"가 필요하다는 점은
같음 — 위 "계측 지점 3곳"에서 정의하는 trace 이벤트 스키마를 하나로
설계해두면, quad-mock(오프라인 검증)과 quad-debug(실시간 스트리밍)가 같은
이벤트 포맷을 재사용할 수 있음. 지금 당장 통합할 필요는 없고, quad-mock을
실제로 확장하게 될 때 이 문서를 먼저 참고하라는 정도로만 기록.

## 패키지 구조 제안 (가칭, 확정 아님)

기존 `quad-base`/`quad-roblox` 경계 원칙을 그대로 따름 — base는 인터페이스만,
실 구현은 백엔드/애드온이 주입:

- **`quad-debug`** — 엔진 무관 core. trace 이벤트 스키마 정의, 위 5개 훅
  지점의 no-op 기본 구현, 이벤트 버퍼/필터링 같은 순수 로직. `quad-base`
  자체에 넣지 않고 별도 패키지로 두는 이유: `quad-base`는 프로덕션 코드가
  항상 의존하는 코어라 디버그 전용 코드를 섞고 싶지 않음(위 리서치 5번,
  나중에 완전 제거하고 싶을 때도 별도 패키지면 그냥 require 자체를 안 하면
  끝).
- **`quad-debug-roblox`** — 게임(클라이언트) 쪽에서 require하는 provider.
  quad-roblox의 Dispatch/`D`에 실제 훅을 꽂고, BindableEvent/Function을
  **quad 모듈 자신의 Instance 트리 안에** 만들어 CollectionService
  태그로 노출(위 "데이터 채널" 절 — `ReplicatedStorage` 등 게임 트리에
  별도 주입 안 함), `IsStudio` 가드 포함.
- **`quad-debug-roblox-plugin`** — Studio 플러그인. `DockWidgetPluginGui` UI,
  `Selection` 서비스로 Explorer 선택 감지, 브릿지 BindableEvent 구독,
  연결 그래프/트리뷰/flash 렌더링.

## 지금 로드맵에 반영할 것 (최소한만)

사용자도 동의한 대로 지금 구현할 단계는 아님 — 다만 아래는 관련 마일스톤
설계 시 "고려는 해두되 지금 확정/구현하지는 않는" 참고용 메모로 남김
(`ROADMAP.md`의 M2/M3/M5 근처에 훅 확장 지점 존재 가능성만 인지해두는 정도):

- M3(디스패치 엔진) 구현 시 `process`/`retract` 스캔 루프에 나중에 훅
  하나를 끼워 넣기 쉬운 모양으로 짜여 있는지 정도만 유의(지금 훅 자체를
  만들 필요는 없음).
- M2(Source) 구현 시 마찬가지로 나중에 weak-registry 등록 훅을 끼우기
  쉬운 생성자 모양인지만 유의.
- M5(quad-roblox `D` 제네릭 생성자) 구현 시 caller 정보를 나중에 끼워넣기
  쉬운 단일 진입점(생성자 함수 하나)인지만 유의 — 이건 이미
  `bind-system-plan.md`가 "제네릭 생성자 함수 하나로 통일"이라 확정해둔
  것과 자연히 맞아떨어짐, 별도 조치 불필요할 가능성이 큼.

**중요**: 위는 "이런 게 나중에 필요할 수 있으니 지금 설계를 크게 바꾸라"는
게 아니라, 이미 확정된 설계(단일 디스패치 진입점, 단일 생성자 진입점)가
우연히도 계측 친화적이라는 걸 확인해두는 것에 가까움 — M0~M11 순서/범위
자체를 바꿀 이유는 없음.

## 열린 질문 (`.claude/question.md`에도 취합)

기술적 실현 가능성은 전부 해소됨(위 핸드오버 요약) — 아래는 우선순위별로만
분류, 다음 세션 진행을 막는 항목 없음.

**해소됨 (2026-08-06 후속 세션)**

- "이벤트 함수들이 실제 instance를 읽을 수 있게 self를 건네받는 게 quad의
  관습"이라는 언급 — v1 `event.lua`의 `func(self or this, ...)` 관습이
  실존함은 확인됐으나(v1 튜토리얼에도 문서화), **quad 재설계에서는
  채택하지 않기로 확정**. Ref가 이미 인스턴스 접근 용도를 커버하고,
  thin wrapper를 준다면 Modifier 정적 flatten과 경쟁하는 두 번째 쓰기
  경로가 생겨 오버엔지니어링/성능/디버깅 추적성 문제가 생긴다는 게
  이유 — 클로저 래핑 비용도 근거로 추가됨. 상세 근거와 결정문은
  `base/event-plan.md`의 "이벤트 핸들러는 self(Instance)를 받지
  않는다" 절 참고. quad-debug 입장에서는 self/thin wrapper 경로가
  아예 없어지므로 오히려 계측 대상이 단순해짐(추적 안 되는 경로 자체가
  존재하지 않게 됨).

**세부 API 이름 (후순위, 구현 착수 시점에 자연히 정리)**

- `describe`(가칭) 5번째 핸들러 훅의 정확한 시그니처/이름.
- Attribute 이름 네임스페이싱(`__quadSource`류)과 노출 정보 범위(스크립트
  전체 경로를 노출해도 되는지, 파일명만 남길지 등 보안/정보노출 고려).

**`Claim` debug 검사의 범위 — [2026-08-28 `base/claim-plan.md` §7-4에서 이관]**

- `Claim(inst, D.Mapper…)`은 이름 중복·부재를 UB로 두고 debug 모드에서만 `seen`
  맵으로 잡는다(사용자 제안). **어디까지 잡을지는 여기서 정한다** — 후보: 이름
  중복 / 부재 / 클래스 불일치 / 미매핑 부기 대상 자식 / 디스크립터 순서와 물리
  순서 불일치(web) / 루트 센티널 `D.Mapper.Root`가 자식 자리에 온 것(같은 `inst`
  이중 claim은 debug가 아니라 `nativeClaim` 앞 런타임 error — `base/claim-plan.md` §7-10). 사용자 판단(2026-08-28): *"디버깅 도구 만들 때 고려해야할 점으로
  옮겨져야해. 부분 부분 디버깅 가능성을 아직 다 논한게 없어서 지금 그림으로 보면
  작은 그림을 먼저 그리는거라서, 미결상황으로, 위치 이동이 필요함"* — 즉 "debug
  모드가 무엇을 언제 검사하는가"의 큰 그림(이 문서) 안에서 같이 정할 것.

**백로그(채택 여부만 남음, 핵심 설계와 무관)**

- 외부 변경 감지(핵심 설계 방향 4번)를 보조 신호로라도 실제로 켤지 — 타이밍
  매칭 정확도는 프로토타입 단계에서 검증 필요.
- 서버 확장(RemoteEvent) 여부 — 필요성이 실제로 드러나면 그때.
- quad-mock과 trace 이벤트 스키마를 실제로 공유할지, 아니면 별도로 갈지 —
  quad-mock 확장 착수 시점에 재검토.
- 인스턴스 변경을 추적하는 전용 새 Source 메커니즘(다크패턴 방지용으로
  사용자가 제안했다가 스스로 낮게 평가) — quad가 이미 생성 객체에
  `GetPropertyChangedSignal` 역바인딩 옵션을 제공해서 3줄로 되는 것과 큰
  차별점이 없어 보임, 타당성 조사만 백로그로.

**범위 밖 — 별도 문서로 분리됨**

- 이번 논의에서 파생된 문서화 숙제(UI 네이밍 컨벤션, Store 부작용을 게임
  시스템에서 깔끔하게 쓰는 패턴)는 quad-debug 범위가 아니라
  `research/documentation-plan.md`로 분리해 뼈대만 기록함.
