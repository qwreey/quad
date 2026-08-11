<!-- quad-v2 세션 로그 원문 — CLAUDE.md에서 이전됨(2026-08-11 정리 세션). -->
<!-- 이 파일은 quadnomicon 개발로그 소재용 원자료로, 당시 시행착오(정정 전 서술 포함)를 그대로 보존함. -->
<!-- 현재 유효한 설계는 이 파일이 아니라 base//research//archive/가 최종 소스 — 이 파일 안의 판단이 이후 세션에서 뒤집혔을 수 있음. -->

## 2026-08-06 후속 세션 — 이벤트 self 관습 결정, rbvm GC 참고, 문서 코퍼스 정리

같은 날 이어진 세션에서 세 가지를 처리함. **다음 세션이 새로 알아야 할 것은
없음** — 아래 전부 `base/`/`research/`/`question.md`에 실제로 반영 완료.

**1. 이벤트 핸들러 self(Instance) 관습 — 채택하지 않기로 확정.** 위 절에서
"확인 필요"로 남겨뒀던 것의 결론: v1의 `func(self or this, ...)` 관습은
실존함을 확인했지만(`.claude/initreq/quad/src/event.lua` 82행, 튜토리얼
문서화까지 있음), quad 재설계에서는 채택하지 않음. 근거 네 가지 —
(1) Ref가 이미 "생성 직후/마운트 후 Instance 접근"을 콜백으로 커버해서
중복 채널이 됨, (2) self로 재바인드 가능한 thin wrapper를 준다면 Modifier의
정적 flatten과 경쟁하는 두 번째 쓰기 경로가 생겨 KV 핸들러가 매번
"flatten된 값이냐 wrapper냐"를 분기해야 하는 오버엔지니어링, (3)
quad-debug가 추적하는 반응형 그래프 밖의 mutate 경로가 공식 API로
생기는 셈이라 `purity-and-effects-plan.md`의 이식성 원칙과 충돌, (4)
self를 넘기려면 원본 콜백을 클로저로 한 번 더 감싸야 해서 불필요한 할당
비용 — quad는 어차피 라이프사이클 끝까지 바인딩을 들고 있어 Destroy 시
Connection도 자연히 정리되므로(`lifecycle-pattern.md`, GC-native) 감쌀
이유가 없음. 상세 결정문은 `base/bind-system-plan.md`의 "이벤트 핸들러는
self(Instance)를 받지 않는다" 절. `research/debug-tooling-plan.md`/
`.claude/question.md`의 관련 항목은 "해소됨"으로 갱신 완료, 이 결정을
설명하는 문서화 숙제("왜 thin wrapper를 안 주는가", "권장 이벤트 핸들링
패턴")는 `research/documentation-plan.md` 3번으로 신설(다른 두 항목과
동일하게 아직 백로그 뼈대만).

**2. rbvm GC 패턴 — "실물 검증됨" 근거 보강.** 사용자가 "GC 처리를 봐야
한다면 rbvm을 확인하라, 실제 프로덕션에서 잘 돌아가는 걸 직접 확인한
모듈"이라고 언급 — 실제로 rbvm의 GC 패턴(weak table 4종, `Instance.
Destroying` 기반 gcHold 클로저, 네임스페이스 Dispose 훅 등)은 이미
`base/lifecycle-pattern.md`에 파일:라인까지 인용하며 상세 반영돼 있었지만
"사용자가 직접 실행해서 확인했다"는 신뢰도 근거는 빠져있어서 그 문단을
추가함(사람이 짠 코드라 100% 무결 보장은 아님 — 이미 발견된 버그 2건도
근거로 같이 인용, 규범이 아니라 참고용 비교 대상이라는 톤 유지).

**3. `.claude/` 코퍼스 전체 정리 패스.** 이전 세션들에서 쌓인 stale
참조/모순을 서브에이전트로 전수 감사 후 수정 — `modifier-plan.md`/
`architecture.md`의 `research/component-composition-plan.md` 참조를
승격된 `base/` 경로로 갱신, `comparison-fusion-vide.md`의 낡은 "Vide식
암묵적 추적 vs Fusion식 명시적 축, quad는 미정" 서술을 실제 확정 사실
(`bind-system-plan.md`의 `:With`+`:Compute` 명시적 모델 채택)로 정정,
`tween-plan.md`의 끊긴 절 참조 수정, `documentation-plan.md`의 인용
오류 정정. `module-lifecycle-plan.md`가 스스로 "question.md에도 취합"
표시해뒀지만 누락돼 있던 "프로바이더" 이름(provider/processor/plug)
미정 항목도 `question.md`에 추가함. 여러 문서에 흩어져 있던 진짜 열린
설계 질문들(Slot 형제 순서 보장, Attribute 타입 파라미터화, UI shorthand
이름 등)은 전부 `.claude/question.md`에 이미 반영되어 있음을 재확인만
하고 임의로 결정하지 않음 — **이 파일이 여전히 "지금 열려있는 것"의
단일 소스.**

**4. Store `:Emit`, `:Compute`의 `previous` 인자, `state:Observer(fn)`,
Ref 일반화 — 네 가지 다 확정, 실제 base 문서에 반영 완료.** 같은 세션에서
더 이어진 Store/Ref 설계 논의, 전부 `base/store-semantics.md`와
`base/bind-system-plan.md`에 반영됨:
- **`Store:Emit(key)`** — Source 원천에 한해서만 허용(중간/파생 State엔
  없음). 존재 이유는 clone 불가능한 userdata/엔진 객체가 우선(편의성은
  부차적). `Get()`이 라이브 레퍼런스를 주므로 캐시해서 비교/diff하면
  안 된다는 캐비엇 명시. Modifier는 정적 flatten이라 Store/State 경로에
  아예 안 걸치므로 Emit과 충돌할 지점 자체가 없음(따름정리:
  `Store<T>`의 `T`는 Modifier가 될 수 없음) — `store-semantics.md`.
- **`:Compute(fn)`의 선택적 두 번째 인자 `previous`** — Compute 결과
  자체가 무거운 userdata인 경우(예: 큰 locale 테이블 → Roblox
  `LocalizationTable` 변환) 재생성 대신 이전 결과를 재사용/patch하는
  용도, opt-in. `previous`는 "정확히 한 단계 전"이 보장 안 되므로 반드시
  full diff로 다뤄야 함(React reconciler와 같은 모양). **핵심 캐비엇**:
  이 패턴은 결과 State가 계속 능동적으로 관측(정상 prop 바인딩 또는
  `state:Observer(fn)`+명시적 `Get()`)되지 않으면 mutate 로직 자체가
  다시 실행 안 되어 조용히 영구 정지함 — `bind-system-plan.md`.
- **`state:Observer(fn)`** — 무효화 신호만 주고 값은 안 줌, `fn` 안에서
  명시적으로 `Get()` 해야 실제 값을 얻음(기존 "emit은 저렴한 무효화
  신호" 원칙 재사용). 반환값 자체가 `CreatedRef`처럼 children 배열에
  바로 놓는 leaf 값(별도 `ObserverHolder` 래퍼 불필요, 사용자가 직접
  단순화) — 그 leaf가 살아있는 동안만 구독 유지, `canExecute`로 게이팅.
  `fn` 생략 시 "이 State를 그냥 계속 능동 관측 상태로 유지"하는 유틸로
  씀(위 `previous` 캐비엇의 해결 도구). 구현은 값 내부가 아니라 외부
  weak table로 살아있는 Observer를 추적하는 방식 권장(rbvm
  `getNamespaceOf`류 선례) — `bind-system-plan.md`.
- **Ref 일반화** — "quad가 만든 instance 전용"에서 "아무 사용자 값이나
  담는 범용 값 박스"로 확장(object-ref/function-ref 안 나눔, React
  `useRef`가 선례). `.Value` + `:Wait()`(coroutine 컨텍스트용) + 콜백
  등록(복수 허용, 이미 채워져 있으면 즉시 1회 호출) — 이걸로 "코루틴
  기반 대기 지원 미정"이던 항목 해소. `CreatedRef`는 이 위에 얹힌 특수
  편의 패턴으로 재정리, 상충 없음. **one-shot 여부도 해소됨 — 반복
  재설정 가능으로 확정**(React의 자식 재생성 시 ref 재사용 패턴이 선례,
  라벨 컨테이너 재사용 예시로 확인). 콜백은 발화 후에도 안 소진되고
  매 `:Set()`마다 다시 불림 — 소진되는 건 `:Wait()`의 개별 대기자뿐.
  **Ref는 의도적으로 lazy가 아니고 `:Compute` 파생도 지원 안 함** —
  State와의 이 차이가 중요(예전에 Store가 Ref 역할도 겸했다가 lazy
  모델과 섞여서 안 좋았던 경험에서 나온 의도적 분리). Ref 정의 자체가
  넓어졌으니 용어 정리 때 이름도 같이 재검토 대상. `question.md`의
  관련 항목은 해소됨으로 갱신.

**5. Observer 이름 확정, Ref/Source/Store 생성자 스타일, "독립 프리미티브 vs
파생 데이터" 원칙, Modifier 세부 마무리 — 전부 확정, base 문서 반영 완료.**
- `Observer`로 확정(`ObserverHandle` 아님) — `:Connect()`→`Connection`과
  같은 기존 명명 관례. PA님 코드의 동명 클래스와는 무관, 각주로 구분.
- **생성자 스타일**: `Source(default)`/`Ref(default)`/`Store({defaults})`
  — Kotlin Compose식 "타입 이름 자체가 팩토리 함수". Ref만 예외였던 이유
  없었음(단순 명세 공백).
- **일반 원칙 신설**: 독립 존재 가능한 프리미티브(Source/Ref/Store/
  Modifier, `Type(args)` 자유 함수 생성자) vs 원천에 종속된 파생 데이터
  (State/Observer, 원천에 대한 메소드로만 얻어짐) — `state:Observer(fn)`가
  메소드고 자유 함수가 없는 더 근본적인 이유로 연결(`store-semantics.md`).
- **Modifier 마무리**: (a) Getter를 아예 안 만들기로 확정 —
  `:FontSize(function(old)->new)`가 유일했던 use case를 인라인으로 커버.
  (b) `old`는 항상 "현재 저장된 그대로"(plain이면 raw, State면 State
  핸들) 넘김 — `:Compute`의 self와 같은 결. (c) `func(state)->state`라는
  세 번째 인자 모양은 불필요(함수 합성 + State 직접 대입으로 이미 커버).
  (d) Modifier는 핸들러 계층(Ref/Slot 등)을 몰라도 됨 — 순수 데이터
  merge 레이어라 UB로 흘려보내도 문제없음. (e) **런타임 구현은 base에
  제네릭 `__index` 하나면 충분** — `mod:FontSize(...)`가 `__index(self,
  "FontSize")`로 잡히므로 클래스별 런타임 코드 불필요, FrameModifier류
  타입 생성기는 순전히 정적 타입 체크만을 위한 것. (f) 이벤트도
  store-bind 가능하도록 확정 — 기존 재실행 래핑 재사용, `false`를
  disconnect 센티널로 씀(`nil`은 테이블에서 사라져서 부적합) —
  `bind-system-plan.md`. Modifier가 이벤트 키를 담아도 되는지는 (d)로
  자동 해소(Modifier가 애초에 키 종류를 구분 안 하므로).

**6. 이벤트 store-bind는 부차적 옵션으로 재조정, Observer의 `:Subscribe`/
`:Unsubscribe` 추가 — 둘 다 확정, 반영 완료.**
- 이벤트 store-bind(5번 (f))를 다시 검토 — "구현이 쉽다"가 "구현할
  가치가 있다"를 보장 안 함을 재확인. 저빈도 UI 이벤트의 조건부 처리는
  "핸들러 하나 계속 연결 + 내부에서 `store.enabled:Get()` 분기"가 이미
  Connect/Disconnect 없이 더 싸고 표준적이라 **이걸 기본 권장 패턴으로
  확정**. store-bind는 고빈도 신호(Heartbeat 등)나 로직 자체가 바뀌는
  드문 케이스를 위한 부차적 옵션으로 격하(메커니즘 자체는 유지 — 일관성
  위해 예외로 뺄 근거는 약함). 자주 재계산되는 State에 물리면 Connect/
  Disconnect churn이 숨은 비용이 된다는 캐비엇도 추가.
- **Observer의 `:Subscribe()`/`:Unsubscribe()`** — children 배열에 안
  붙는 "전역/독립" Observer(디버깅용으로 Store에 직접 걸어 print하는
  흔한 패턴, `RunService:IsStudio()` 가드 + BooleanValue 토글)를 위한
  명시적 라이프사이클 경로. 이건 새 설계가 아니라 PA님 코드 교차검증
  때 이미 예고해둔 확장 지점("GC만으로 부족하면 명시적 dispose 경로
  추가 가능")을 실제로 채운 것. liveness 체크는 `self.Subscribed` 필드
  우선, `self.Connection.Connected` 폴백(필드 접근이 weak table 조회보다
  쌈). 내부 레지스트리는 자동 케이스의 weak table과 별개로 강참조
  (weak면 "살려둔다"는 목적이 무의미해짐). 둘 다 idempotent, `:Unsubscribe()`는
  자동 케이스 조기 해제에도 재사용.

