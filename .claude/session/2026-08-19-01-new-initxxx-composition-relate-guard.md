# 2026-08-19 — `New()`의 내부 구성: InitXxx 팩토리 체이닝 + `Relate` 기반 멱등 Init 가드

**요청**: `Quad.New()`가 실제로 어떻게 구현돼야 하는지에 대한 사용자
아이디어 검토 요청으로 시작 — 결론까지 나서 `base/`에 반영, 이어서
핸드오버 감사 루프와 세션 기록 공백 점검까지 같은 세션에서 처리.

## 1. 제안 — `New()`를 InitXxx 팩토리 체이닝으로

사용자 원문: *"New() 가 실행되면 Quad 를 만드는 함수가 있는것으로 처음부터
구현하는게 맞음. ... New 결과 안에 .New 함수를 넣어줌. 즉, 생성형식 자체는
비싱글톤이고, Dispatch 같은것도 Init(module) 을 받는 함수로써 ...
module.Dispatch = ... 형식들로 구현되고 ... 재익스포트식으로 구현하겠다는
이야기였음. 처음부터 InitModuleName 식으로 구현하여 팩토리를 쌓아 모듈을
리턴하는 방식으로, quad v1 의 방식을 가져와봄직 하다는것."*

**조사**: 기존 `base/architecture.md` 13번("모듈은 기본 싱글톤, `New()`는
추가 인스턴스가 필요할 때만")과 14번("pluggable 초기화는 팩토리 함수로"),
`module-lifecycle-plan.md`가 이미 `InitRoblox(Module)` 형태의 backend 주입
패턴을 확정해뒀다는 걸 확인 — 이번 제안은 그 패턴을 quad-base **자기
자신의 내부 구성**(Dispatch 등)에도 대칭 적용하자는 것이라 새 설계가
아니라 기존 원칙의 자연스러운 확장으로 판단. `lifecycle-pattern.md`가
거부한 rbvm `InitNamespace` 패턴(소비자가 라이브러리마다 수동으로 init을
부르는 것)과도 안 겹침 — 여기선 `New()` 하나만 외부에 노출되고 내부에서만
`InitXxx(module)`를 부름.

**결론**: 채택 추천 — `module = {New = New}` 자기참조도 이미 확정된 결정과
정확히 일치, `type Dispatch = InitDispatch.Dispatch` 재익스포트만 실제
Luau 동작 확인 필요하다고 남겨둠.

**사용자 확인**: "그거 타입 익스포트 잘 됨. 구체화 반영해줘." → 실측
확인됐다는 뜻으로 받아 `module-lifecycle-plan.md`에 "New()의 내부 구성"
절 신설, `architecture.md` 13번에서 포인터 연결.

## 2. 정제 — Init을 `require`처럼 멱등하게

사용자 원문: *"Init 은 require 처럼 생각 가능한듯. Init 여러번은 한번만
작동하게 자신 모듈 최상단에 Relate 를 (함수 안 아님. 클로저 바깥) 놓고,
자신 모듈의 init 여부를 저장해. 그리고 한번만 작동하도록 두고, 자신 init
에선 필요한것들을 init 해줘. 디펜던시 느낌인거지. ... 맨 바깥 quad-base
진입점의 New 에선 모든 Init 을 그냥 실행해도 돼."*

이게 1절 문서화 때 "구현 단계에서 정할 것"으로 남겨뒀던 "서브시스템 간
`InitXxx` 호출 순서 의존성" 문제를 실제로 푼다 — 각 `InitXxx` 파일이 자기
톱레벨(클로저 밖)에 `local relate = Relate()`를 두고 `module`을 weak key로
"이미 이 인스턴스에 Init됐는지"를 기록하면, 의존하는 쪽이 자기 의존성을
직접 호출해도 중복/순서 걱정이 없어짐(멱등) — `require`가 파일 단위로 하는
캐싱을, `New()`가 여러 `module` 인스턴스를 만들 수 있다는 차이 때문에
인스턴스 단위로 다시 구현하는 것.

`relate-plan.md`의 확정 API(`Relate()`/`SetWeak`/`GetWeak`/`SetStrong`/
`GetStrong`, "각 모듈이 자기 톱레벨에 `Relate()` 하나 재사용" 관례)와
정확히 부합함을 확인 — 새 메커니즘이 아니라 기존 프리미티브의 정확한
용례. `module-lifecycle-plan.md`에 반영, 순환 의존 대비를 위해 플래그를
실제 작업 전에 먼저 세우는 규칙도 같이 명문화.

## 3. 핸드오버 감사 루프 (2라운드, `conventions.md`의 "핸드오버 준비하고
커밋해" 절차)

바뀐 파일: `base/architecture.md`, `base/module-lifecycle-plan.md`,
`base/dispatch-core-plan.md`, `README.md`, `ROADMAP.md`.

**라운드 1**(`quad-doc-auditor`, agentId `ad95c24230306ab0f`) — 확실 3건 +
의심 3건 + 사용자판단 1건:
- 확실: `architecture.md`의 "M0 스캐폴딩에 주는 함의" 불릿이 이미 InitXxx
  절이 답한 질문을 여전히 미결정으로 서술 / `README.md` 색인에 새 절 요약
  누락 / `module-lifecycle-plan.md`의 "지금은 없음"이 날짜 없는 시한부
  주장.
- 의심: `_initializedBy` 상호 참조가 정의를 못 찾게 함(`bind-system-plan.md`
  누락) / GC 인과 서술이 `relate-plan.md`의 "`inst`는 항상 weak" 규칙과
  어긋나게 읽힘 / `dispatch-core-plan.md`가 새 절을 안 가리켜 상호참조 누락.
- 사용자판단(문서만으론 못 정함, 이번엔 직접 판단해 처리): InitXxx 구조가
  M0/M1 중 어느 마일스톤부터인지 → `ROADMAP.md`의 "M0 — 스켈레톤 +
  기술검증" 절 실제 내용(스파이크 전용, "진짜 마일스톤 아님")을 근거로
  **M1**로 확정, `ROADMAP.md` M1 체크리스트에 항목 신설.

전부 반영(위 6곳 수정 + M1 체크박스 추가).

**라운드 2**(agentId `a1d60d10fc36621ed`) — 라운드 1 수정 자체가 새 stale
2건을 만든 걸 발견:
- `architecture.md`가 인용하던 "M0 스캐폴딩에 주는 함의"라는 절 제목
  문구를 라운드 1 수정이 지워버려 절 인용 규약 사각지대(파일명 없는 같은
  문서 내 인용이라 `doc-check.py`가 안 잡음) 발생 → 원래 제목 문구를 불릿
  맨 앞에 복원하면서 내용만 정정.
- "위 'M0 — 스켈레톤 + 기술검증' 절 참고"가 실제로는 `ROADMAP.md` 안의
  절인데 파일명이 빠져 같은 문서 안인 것처럼 읽힘 → `ROADMAP.md`의 명시.
- 추가로 "확실": 이 새 절 자체가 사용자 발언 3건을 인용하면서
  `session/2026-08-19-*.md` 포인터가 없음(이 문서가 그 포인터).
- 의심: `relate-plan.md`의 "언제 Relate를 쓰는가" 체크리스트에 새 용례가
  안 실림 → 다섯 번째 불릿 추가.
- 사용자판단: Init-완료 플래그 값(`true`)을 `SetWeak`/`SetStrong` 중 뭘로
  적을지가 문서 간 안 맞음 → boolean은 GC 대상이 아니라 실질 차이는 없지만
  `relate-plan.md`의 일반 규칙("다른 곳에서 안 붙잡는 값은 Strong") 기준
  **`SetStrong`으로 통일**.

전부 반영. 라운드 3은 이 문서 작성 이후 진행 예정(아래 미해결 참고).

## 4. 세션 기록 공백 발견 (사용자가 감사 진행 중 별도로 제기)

사용자 질문: *"세션 기록들 요즘 왜 안 적어? ... 18일 자가 하나 뿐이네."*

확인 결과 — `git log`엔 2026-08-18에 커밋 10개(QA 1~2라운드, 감사 루프
재설계, GitHub co-author 정책, git 원격 정책 등), 2026-08-19에 커밋 1개
(QA 3라운드)가 있는데, `session/`엔 2026-08-18 파일이 `pre-implementation-qa-applied.md`
**하나뿐**이고 2026-08-19 파일은 이 문서 이전엔 **0개**였다. 즉 QA
2라운드/3라운드(`todos.md` 00번이 상세히 서술하는, RC-1/RC-3/RC-4를 실제로
찾아 해결한 세션들)와 tooling/research 커밋 다수가 session/ 원문 없이
커밋됨 — 실제 공백.

**한계**: 이 세션은 그 과거 대화의 실제 트랜스크립트에 접근할 수 없다(커밋
메시지와 현재 파일 상태만 볼 수 있음) — `session/`의 정의 자체가 "시행착오
포함 원문"이라, 원문을 못 본 채로 "raw log"를 지어내면 오히려 그 자체가
허위 기록이 된다. 그래서 이 문서는 **이번 세션분만** 원문으로 채웠고,
과거 공백(08-18 QA 2/3라운드 등)을 어떻게 처리할지는 사용자에게 별도로
물어야 함(요약만 `session-summary.md`에 사후 추가할지, 아예 공백으로
인정하고 넘어갈지 등 — 이 문서 자체가 그 판단의 근거 자료).
