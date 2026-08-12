# 2026-08-12 다섯 번째 세션 — Operator 콤비네이터 슈가 신설

## 배경

사용자가 `reduceMotion:Compute(function(r) return not r:Get() end)`류
람다가 정말 단순한 연산(not, +, ...)에도 매번 필요한 게 번거롭다고
지적 — 기본 연산(산술/논리/비트)을 미리 콤비네이터로 만들어두면
`:Compute(Not)`, `:Apply(Sum(a, b))`처럼 짧게 쓸 수 있고, 결합해서
표현하면 가독성/유지보수도 좋아진다는 제안.

## 논의

메커니즘 자체는 새로 필요한 게 없다는 걸 바로 확인함 — 2026-08-12
두 번째 세션에서 확정된 `Animate(info)` 패턴(`function(self)...end`을
반환해 `:Compute`/`:Apply`의 self-lazy-핸들 계약에 바로 꽂히는 것)과
정확히 같은 모양:

- 단항(`Not`)은 그냥 `fn(self)` — `:Compute(Not)`로 바로 씀.
- 다항(`Sum(a, b, ...)`)은 `factory(self)`를 반환해 `:Apply(Sum(a,b))`로
  self까지 포함해서 결합.

각 함수가 서로 독립(공유 상태/의존 없음)이라 부분적으로 나중에
추가하거나 하나만 고쳐도 다른 함수에 영향이 없다는 것도 확인 — 이게
우선순위를 맨 마지막으로 미뤄도 되는 근거. 사용자도 "이건 문서화 준비는
미리 적어두는 게 맞지만 구현 자체는 정말 맨 마지막에 해도 된다"고 직접
우선순위를 명시.

막힌 지점은 네이밍뿐이었음 — `Not`/`Sum`/`And`처럼 흔한 이름을 top-level에
그냥 두면 충돌 위험이 커서 `Tag`/`Attribute`처럼 네임스페이스가 필요한데,
사용자가 예시로 든 `Operator.Not`이 마음에 드는지 스스로도 확신이 없다고
언급. 코퍼스 전체에 `Operator`/`Op` 이름 충돌이 없는지 grep으로 확인(충돌
없음), `Combinator`는 코퍼스 전반에서 `:Apply` 패턴을 설명할 때 이미
일반명사로 자주 쓰여서("Apply 콤비네이터") 네임스페이스 이름으로 쓰면
헷갈릴 수 있어 후보에서 제외 — 최종 이름은 `Operator`/`Op`/`Ops` 중
미정으로 남김.

## 결과 (1차)

`research/operator-sugar-plan.md` 신설(동기/메커니즘/패키지 배치(quad-base,
엔진 종속 없음)/열린 질문 두 가지(네임스페이스 이름, 포함 범위·`Sum`이
self를 포함하는 형태가 맞는지) 전부 기록). `README.md` research 표,
`question.md` 3번(낮은 우선순위)에 반영. 구현은 착수 안 함 — 사용자가
직접 맨 마지막 우선순위로 지정했으므로 이 세션은 설계/문서화만.

이때 초안은 "0항(`Not`)은 `:Compute`에 바로, N항(`Sum`)만 `:Apply`용
팩토리"로 나눠서 썼음 — 아래 후속 논의에서 뒤집힘.

## 후속 논의 — `:Compute` vs `:Apply`, 어느 쪽이 맞는가

사용자가 바로 재검토를 요청: 가독성상 `:Apply(Sum(a,b,c))`가 나아
보이고, `local SumFn = Sum(...)`처럼 만들어 여러 곳에서 `:Apply(SumFn)`로
재사용하는 게 커링의 실제 이점인데 `:Compute`만 쓰면 그게 무색해진다는
지적. `Animate`도 같은 이유로 `:Compute`보다 `:Apply`가 맞지 않냐는
질문도 같이 나옴 — "값에 Tween을 적용한다"는 맥락이지 "계산한다"는
맥락이 아니라는 의미론적 근거, `:Compute`가 v1/Fusion류 "매 스텝 능동
갱신"처럼 읽힐 수 있다는 우려도 제기.

검토 결과 **스타일이 아니라 진짜 정합성 문제였음**을 확인: quad는 Vide식
암묵적 자동 추적을 이미 기각했으므로(`bind-system-plan.md` "암묵적 자동
추적 기각"), `local addTax = Sum(tax, shipping)`처럼 만든 값을
`price:Compute(addTax)`에 바로 꽂으면 `addTax`가 클로저로 캡처한
`tax`/`shipping`이 `:Compute`의 구독 목록(그 호출문의 trailing args만
등록됨)에 안 걸려 조용히 재계산이 멈추는 버그가 됨 — 이게 바로
2026-08-11 세션이 "trailing deps를 fn 위치 인자로 노출"하게 만든 것과
같은 클래스의 중복/드리프트 문제. `:Apply`는 factory가 내부에서
`self:Compute(fn, tax, shipping)`을 스스로 다시 전달해 이 문제가
원천적으로 없음 — 재사용 가능한 이름 붙은 콤비네이터는 `:Apply`가
유일하게 안전한 경로. 기존 문서(`bind-system-plan.md`의 `:Apply` 절이
이미 `state:Apply(makeFormatter("ko-KR"))`를 정석 예시로 들어둔 것)와도
맞아떨어짐 — 오히려 `Animate`가 애초에 `:Compute`를 골랐던 게 이 관용구의
예외였다는 게 드러남.

## 결과 (최종)

- `research/operator-sugar-plan.md`: "0항은 Compute, N항은 Apply" 분기를
  버리고 **전부 `factory(self) -> State` + `:Apply`로 통일**("왜 `:Apply`인가"
  절 신설, 정합성 근거 전문 기록).
- `research/tween-plan.md`: `Animate(info)`를 `function(self) return
  self:Compute(...) end`로 바꿔 `:Apply` 전용으로 정정("왜 `:Apply`로
  정정됐는가" 절 신설), 모든 사용 예시(`:Compute(Animate{...})` →
  `:Apply(Animate{...})`)와 커스텀 조건 이스케이프 예시까지 같이 수정.
  `Animate` 자체의 시그니처/동작(옵션이 deps로 안 걸리는 것 등)은 그대로 —
  바뀐 건 호출 경로뿐.
- `base/bind-system-plan.md`의 `:Apply` 절에 "이름 붙여 재사용하는
  콤비네이터는 항상 `:Apply`" 관용구를 일반 원칙으로 추가 — 나중에
  비슷한 콤비네이터를 또 만들 때 케이스마다 재논의 안 해도 되게.

구현은 여전히 착수 안 함(맨 마지막 우선순위 유지) — 이번 논의는 순전히
설계/문서 정정.
