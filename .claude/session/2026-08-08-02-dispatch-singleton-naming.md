<!-- quad-v2 세션 로그 원문 — CLAUDE.md에서 이전됨(2026-08-11 정리 세션). -->
<!-- 이 파일은 quadnomicon 개발로그 소재용 원자료로, 당시 시행착오(정정 전 서술 포함)를 그대로 보존함. -->
<!-- 현재 유효한 설계는 이 파일이 아니라 base//research//archive/가 최종 소스 — 이 파일 안의 판단이 이후 세션에서 뒤집혔을 수 있음. -->

## 2026-08-08 두 번째 세션 — Dispatch는 프리미티브가 아니라 탑레벨 싱글톤 확정,
네이밍 케이싱 컨벤션 신설, Handler를 세 번째 카테고리로 명문화

같은 날 이어진 세션. 사용자가 위 4번 미결 항목("Ref/Observer/PreRef leaf
Handler가 어디 사는지")을 다시 짚으며 시작 — "Handler도 실제 런타임 값이
생기는 요소인데 왜 프리미티브로 안 다루나", "Dispatch는 어떻게 되는 거냐,
State 핸들러 안에서 `getHandler`를 부르려면 Dispatch가 이미 존재해야
하는데" 하는 질문으로 확장돼 Dispatch 자체의 정체성(싱글톤 top-level
함수 모음 vs 인스턴스화 가능한 프리미티브) 논의로 이어짐. 네 가지로 정리,
전부 `base/bind-system-plan.md`/`base/store-semantics.md`/
`base/architecture.md`/`question.md`/`ROADMAP.md`에 반영 완료:

**1. Dispatch는 프리미티브가 아니라 탑레벨 싱글톤 — 확정, 지금 형태 유지.**
`Dispatch.process`/`getHandler`/`addHandler`/`drive`를 `Source`/`Ref`처럼
생성자 있는 프리미티브로 바꿀지 검토했으나 기각. 근거: (a) Tween/
`NoneHandler`/`StoreBind`가 자기 `process` 안에서 다시 `Dispatch.process`를
재귀 호출해야 해서, `canExecute`/`bindLifetime`처럼 require 한 번으로 바로
닿는 안정된 전역이어야 함 — 프리미티브화하면 모든 Handler 호출 경로에
Dispatch 핸들을 실어날라야 하는 스레딩 비용이 생기는데 지금은 그 비용이
없음. (b) 사용자가 우려한 "Handler가 Dispatch 원하고 Dispatch가 Handler
원해서 순환참조" 문제는 착시로 확인됨 — "Handler"가 (i) `Handler.luau`의
순수 타입 계약(leaf, Dispatch를 몰라도 됨)과 (ii) 그 계약을 구현하는
concrete 값 모듈(`StoreBind.luau`류, 재귀호출 위해 Dispatch를 참조)
두 가지를 가리켜서 헷갈렸던 것 — 의존 방향은 `Handler.luau` ←
`Dispatch/init.luau` ← `StoreBind.luau`로 항상 한쪽으로만 흐름, 사이클
없음. (c) 모듈 재생성(`New()`)과의 관계도 새 설계가 필요 없음 — 이미
확정된 "팩토리가 `BaseModule`을 뮤테이션" 패턴을 그대로 따르면
`_initializedBy` 마커에 대해 이미 나왔던 결론("`New()`가 생기면 각
인스턴스가 별도 테이블이 되므로 자연히 스코핑됨")이 Dispatch의 handler
레지스트리에도 그대로 적용됨. v1처럼 `require`를 감싸는 `Init(QuadId?)`
방식은 채택 안 함(id 기반 조회 자체가 Ref로 대체되며 이미 기각된 패턴).
`base/bind-system-plan.md`의 "Dispatch는 프리미티브가 아니다" 절,
`base/architecture.md` 13번 항목에 반영.

**2. quad-base 기본 핸들러도 전부 같은 `Dispatch.addHandler` 레지스트리를
공유 — Ref/Observer/PreRef leaf Handler 위치 확정.** `NoneHandler`/
`Dispatch/StoreBind.luau`뿐 아니라, children 배열 숫자 슬롯에 `Ref`/
`Observer`/`PreRef`를 직접 놓는 leaf 값을 매칭하는 Handler도 같은 부류 —
`inst`를 `any`로 취급하고 엔진 특정 API가 필요 없으니 quad-base,
`Dispatch/Leaf.luau`로 확정(위 4번 미결 항목 해소). quad-roblox의
Property/Event/Tween 핸들러도 **같은** 레지스트리에 등록되므로, base
기본 핸들러와 backend 핸들러가 별도 경로로 안 갈리고 하나의 우선순위
스캔을 공유한다는 것도 명시적으로 확인됨. `architecture.md` 소스트리에
`Dispatch/Leaf.luau` 반영, `question.md`/`ROADMAP.md` M2 동기화.

**3. Handler는 "독립 프리미티브 vs 파생 데이터" 분류의 세 번째, 별개
카테고리 — 명문화.** 2026-08-06 후속 세션이 확정한 분류(Source/Ref/Store/
Modifier=독립 프리미티브, State/Observer=파생 데이터)에 Handler가 왜
안 끼는지 사용자가 재확인 요청 — 이유: Handler는 그 자체로 구현체가
없는 **순수 타입 계약**이라 quad 사용자가 다루는 리액티브 값이 아님,
계약을 만족하는 값(`PropertyHandler`류)은 항상 **구현하는 쪽**(base
자신의 기본 핸들러 또는 quad-roblox 백엔드)이 채워 넣는 것이지 `Type(args)`
자유 함수로 사용자가 만드는 게 아니고, State/Observer처럼 어떤 원천에
종속된 파생물도 아님. `base/store-semantics.md`의 "일반 원칙" 절 뒤에
"세 번째 카테고리 — Handler" 절로 반영.

**4. 네이밍 케이싱 컨벤션 신설 — 지금까지 나온 모든 이름이 이미 따르고
있던 규칙을 문서화만 함, 리네임 없음.** 사용자 관찰: "탑레벨 함수는
변수처럼 소문자 시작, 프리미티브 타입의 메서드는 대문자 시작(파스칼
케이싱)이 맞아 보인다"는 규칙 제안 — 검증 결과 기존 이름 전체(생성자
`Source`/`Ref`/`Store`/`Modifier`/`Relate`/`Effect`, 콜론 메서드
`:Get`/`:With`/`:Set`/`:Apply`/`:Subscribe`류는 전부 대문자, `canExecute`/
`bindLifetime`/`isState`류/`Dispatch.process`류/`Brand.set`류는 전부
소문자)가 이미 예외 없이 이 규칙을 따르고 있었음이 확인됨. 유일하게
애매해 보였던 `Modifier.Override(mod1, mod2, ...)`(콜론 아니고 dot-access
인데 대문자)도 규칙 위반이 아니라 세 번째 하위 규칙으로 설명됨 — 콜론
메서드는 아니지만 **`Modifier` 타입 자신의 네임스페이스에 달린 정적
결합 함수**라 "그 프리미티브 타입 고유의 공개 어휘"라는 점에서 생성자/
메서드와 같은 부류. 반대로 `Dispatch.process`/`Brand.set`이 소문자인
이유는 `Dispatch`/`Brand`가 애초에 `Type(args)` 생성자가 없는 프리미티브가
**아닌** 내부 엔진/레지스트리라서. 최종 판단 기준: "이 이름이 특정
프리미티브 타입 하나의 전용 소유물인가?" — 그렇다면 대문자, 아니면(여러
타입에 걸친 범용 유틸이거나 비-프리미티브 엔진 소속) 소문자. `base/
architecture.md`의 "코드 스타일 — 네이밍 케이싱" 절 신설.

**같은 세션 후속 — `module-lifecycle-plan.md`의 "열린 질문" 절이 stale로
방치돼 있던 것을 사용자가 직접 발견.** 문서 상단 "상태" 줄은 이미
"확정되어 승격됨"이라고 말하는데 그 아래 "열린 질문" 절은 2026-08-04
당시 그대로 남아있었음 — 그중 "프로바이더 인터페이스 시그니처 미정"/
"네이밍 미정(provider/processor/plug)" 두 항목이 사실 그 뒤 `Handler`
계약 확정으로 이미 풀려 있었는데 이 문서에 반영이 안 됐던 것. 원문은
남기고 각 항목에 해소 표시+포인터 추가, 절 제목도 "열린 질문이었던 것 —
전부 해소됨"으로 정정. 새 결정 아니라 순수 동기화.

**다음 세션이 할 일**: 안 바뀜(`ROADMAP.md` M0부터) — 이번 세션도 순수
설계/문서 정리라 M0 착수 우선순위 자체는 그대로. 위 2026-08-08 첫 세션이
남긴 "M0/M2 스파이크 검증 목록"에 새로 추가되는 항목 없음.

