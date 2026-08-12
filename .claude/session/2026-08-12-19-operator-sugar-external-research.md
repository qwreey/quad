# 2026-08-12 열아홉 번째 세션 — `Operator` 콤비네이터 슈가 외부 리서치

**배경**: 사용자 요청으로 서브 에이전트(general-purpose, 웹 리서치 전용)를
띄워 `research/operator-sugar-plan.md`가 이미 스케치해둔 `Operator.*` 카탈로그
(Sum/Product/Not/And/Or/Xor/비트연산/비교연산/Concat/Sorted/Filtered)를
다른 언어/리액티브 라이브러리 실제 선례와 대조. 목적은 결정이 아니라
카탈로그 포함 범위와 네임스페이스 이름 논의에 근거를 보강하는 것.

## 리서치 결과 요약

- **선례 있음**: 논리(`Not`/`And`/`Or`) — VueUse `@vueuse/math`의
  `logicAnd`/`logicOr`/`logicNot`이 정확히 같은 모양. `Sum` — VueUse
  `useSum`. `Clamp`/`Min`/`Max` — VueUse `useClamp`/`useMax`/`useMin`,
  Ramda `R.clamp`(quad 카탈로그에 없던 새 후보로 추가 가치).
- **선례 없음/약함**: 비트연산·비교연산자는 어떤 리액티브 프레임워크에서도
  "이름 붙은 파생값 콤비네이터"로 존재한 적이 없음(전부 인라인 연산자로만
  씀) — 포함하면 업계 관행이 아니라 quad가 처음 시도하는 조합. `Sub`/`Div`도
  마찬가지로 선례 전혀 없음(드랍 후보). `Xor`도 VueUse가 나머지 셋은 다
  갖췄으면서 의도적으로 뺀 걸로 보여 약한 후보.
- **누락 발견**: Debounce/Throttle이 업계에서 가장 흔한 리액티브 콤비네이터
  카테고리인데 quad 스케치에 없음 — 그런데 quad의 `Blocker`는 유저가 직접
  여닫는 값 기반 게이트(타이머 없음)라 다른 메커니즘. 실제 시간 기반
  debounce/throttle은 타이머(엔진 종속)가 필요해 `factory(self)->State<U>`
  순수 함수 모양을 벗어나므로, `Operator.*`(quad-base)가 아니라
  quad-roblox 쪽 별도 프리미티브(Tween과 비슷한 위치)일 가능성이 큼 —
  이 문서 범위 밖 별도 질문으로 분리.
- **`Filtered` 판단 뒷받침**: ReactiveUI `IReactiveDerivedList`가 필터링을
  아예 별도의 증분 갱신 전용 컬렉션 타입으로 다루는 것이 quad `Slot`과
  같은 결 — SolidJS `createMemo`+`filter`를 `<For>`에 먹이는 패턴이
  문제없이 동작하는 건 `<For>` 자신이 keyed reconciliation을 하기
  때문(memo identity 처리와 무관). "identity 보존 필요 없으면 plain
  value transform, 필요하면 Slot"이라는 quad의 기존 경계가 정확했음을
  확인.
- **네임스페이스 이름**: Python 표준 라이브러리 `operator` 모듈이 가장
  강한 직접 선례(`operator.add`/`operator.lt` 등, quad와 동일한 동기 —
  연산자를 `map`/`reduce`류에 넘길 이름 붙은 함수로 만드는 것). `Ops`는
  Rust `std::ops`가 근거지만 그건 연산자 오버로딩 trait 네임스페이스라
  결이 다름(약한 선례). `Op`(단수)는 Slate.js `Op`/Immer patch처럼 "낱개
  연산 객체" 지칭에 더 흔해 가장 약함. 최종 결정은 여전히 사용자 몫.

## 반영

`research/operator-sugar-plan.md`에 리서치 결과를 각 해당 절(네임스페이스
이름/포함 범위/`Filtered`)에 인라인으로 통합, Debounce/Throttle을 별도
열린 질문으로 신설. `.claude/question.md` 3번 절 동기화.
