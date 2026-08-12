# 2026-08-12 스물한 번째 세션 — 네이밍 정리 후속: `Pipe` 기각 근거, `Compute` vs `Computed`, `:With`/`Tag`·`Modifier` clone 대조 명문화

**배경**: `State` 이름 확정(스무 번째 세션) 이후 사용자가 두 가지를 더
검토·기록 요청.

## `:With`가 `Tag`/`Modifier`의 clone 체이닝과 혼동될 여지 (직전 턴)

사용자가 `:With`의 clone 여부를 스스로 점검("cloned로 안 보이긴 하는데")
하며 문서화만 좀 더 신경 쓰면 좋겠다고 언급. `bind-system-plan.md`의
"`:With`도 새 State 노드" 절 자체는 이미 clone이 아님을 확정해뒀지만,
`Tag`(`:Added`/`:Removed`)·`Modifier`(`:Apply`)가 겉보기엔 같은 `:`
체이닝 문법을 쓰면서 실제로는 clone-then-return이라는 대조가 문서에
명시적으로 없었던 갭 — 헷갈리기 쉬운 지점이라 판단해 같은 절에 "⚠️ 문서
읽을 때 혼동 주의" 문단으로 대조 추가(clone 계열=Tag/Modifier, 새-노드
계열=State의 With/Compute).

## `Pipe` — `State` 대안으로 검토했으나 기각(사용자가 기각 근거 제시)

1. "캐시한다"는 State의 실제 동작이 파이프라는 비유와 안 맞음 — 파이프는
   통과시키는 채널 이미지라 값을 들고/캐시한다는 감각이 잘 안 붙음.
2. 파이프는 흐름/연결의 이미지라, State가 실제로는 각각 주소를 가진
   독립된 그래프 노드 단위라는 사실과 안 맞음 — "노드"로 보기 애매해짐.

## `Compute` vs `Computed` — 사용자 직감, Claude 동의 + 근거 보강

사용자 직감: quad의 다른 것들(Tag/Modifier)은 immutable하고 non-lazy해서
호출 즉시 확정되는데, `:Compute`가 만드는 노드는 `fn`을 등록해둘 뿐 실제
계산(`compute`)은 나중에 일어나는 것 같다 — 그러니 진짜 "compute'd"(완료된
상태)가 아닌 것 같다는 느낌.

**Claude 검토 — 동의, 근거를 한 겹 더 정확하게 다듬음**: Vue `computed()`/
Svelte `$derived`도 실제로는 lazy이고 그 이름을 그대로 쓰는 게 각자
생태계에서 문제없음 — 그러니 "-ed는 항상 eager를 뜻한다"는 보편 법칙은
아님. 하지만 **quad 자기 코퍼스 안에서는 다름**: `Tag.Added`/`Removed`,
`Modifier.Overridden`이 이미 "-ed 어미 = clone 후 즉시 확정된 값"이라는
관례를 선점해뒀음(`tag-plan.md`, "`Add`/`Remove`로 쓰면 뮤테이션 API처럼
보이기 때문"). 그 관례가 이미 있는 상태에서 lazy한 State 노드에 같은
어미(`Computed`)를 재사용하면 quad 자신의 기존 신호와 충돌해 "이미 계산
끝난 값"으로 오해하기 쉬움 — 다른 생태계와의 비교가 아니라 quad 내부
일관성 문제. 그래서 `Compute`(동사 원형, "계산을 등록/설정"이라는 뜻)가
`Computed`보다 정확.

## 반영

- `base/bind-system-plan.md`: "`:With`도 새 State 노드" 절에 clone 대조
  경고 문단 추가. "여러 Store 값을 묶어 파생값 만들기" 절에 "네이밍 —
  `Compute`가 `-ed`가 아닌 이유" 소절 신설.
- `.claude/question.md`: `State` 해소 항목에 `Pipe` 기각 근거 + `Compute`
  vs `Computed` 근거를 추가해 보강.
